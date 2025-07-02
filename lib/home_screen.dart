import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_entry_screen.dart';
import 'models/password_entry.dart';
import 'secure_storage_manager.dart';
import 'settings_screen.dart';

enum FilterType { both, service, username }

class HomeScreen extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkTheme;
  final VoidCallback onManualLock; // 👈 new

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkTheme,
    required this.onManualLock,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PasswordEntry> _entries = [];
  final Set<String> _visiblePasswords = {};
  GoogleSignInAccount? _currentUser;
  String _searchQuery = "";
  FilterType _selectedFilter = FilterType.both;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadVault();
    _checkSignedInUser();
  }

  Future<void> _checkSignedInUser() async {
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveAppdataScope],
    );

    // Try silent sign-in (restores previous user if available)
    final user = await googleSignIn.signInSilently();

    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadVault() async {
    final saved = await SecureStorageManager.loadVault();
    setState(() {
      _entries.clear();
      _entries.addAll(saved);
    });
  }

  Future<void> _saveAndRefresh() async {
    await SecureStorageManager.saveVault(_entries);
    setState(() {});
  }

  void _openAddEntryForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          onSave:
              ({
                required String id,
                required String service,
                required String username,
                required String password,
                String? note,
                required List<String> imagePaths,
              }) {
                final entry = PasswordEntry(
                  id: id,
                  service: service,
                  username: username,
                  password: password,
                  note: note,
                  imagePaths: imagePaths,
                );
                _entries.add(entry);
                _saveAndRefresh();
              },
        ),
      ),
    );
  }

  void _openEditEntryForm(PasswordEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          existingEntry: entry,
          onSave:
              ({
                required String id,
                required String service,
                required String username,
                required String password,
                String? note,
                required List<String> imagePaths,
              }) {
                final updated = PasswordEntry(
                  id: id,
                  service: service,
                  username: username,
                  password: password,
                  note: note,
                  imagePaths: imagePaths,
                  isFavorite: entry.isFavorite, // retain favorite flag
                );
                final index = _entries.indexWhere((e) => e.id == id);
                if (index != -1) {
                  _entries[index] = updated;
                  _saveAndRefresh();
                }
              },
        ),
      ),
    );
  }

  void _confirmDelete(PasswordEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry"),
        content: Text(
          "Are you sure you want to delete the password for '${entry.service}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(PasswordEntry entry) async {
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
      _visiblePasswords.remove(entry.id);
    });
    await SecureStorageManager.saveVault(_entries);
  }

  Future<void> _backupVaultToDrive() async {
    final account = await GoogleSignIn(
      scopes: [drive.DriveApi.driveAppdataScope],
    ).signIn();
    if (account != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await VaultBackupManager.uploadToDrive(account, _entries);
      Navigator.pop(context); // Close the loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Vault backup uploaded to Drive")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Google sign-in failed")));
    }
  }

  Future<void> _restoreVaultFromDrive() async {
    final account = await GoogleSignIn(
      scopes: [drive.DriveApi.driveAppdataScope],
    ).signIn();
    if (account != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        final restoredEntries = await VaultBackupManager.restoreFromDrive(
          account,
        );
        Navigator.pop(context); // Close the loader
        setState(() {
          _entries.clear();
          _entries.addAll(restoredEntries);
        });
        await SecureStorageManager.saveVault(_entries);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Vault restored from Google Drive")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed to restore: $e")));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Google sign-in failed")));
    }
  }

  List<PasswordEntry> _filterEntries() {
    List<PasswordEntry> filtered = _entries;

    if (_showOnlyFavorites) {
      filtered = filtered.where((e) => e.isFavorite == true).toList();
    }

    if (_searchQuery.trim().isEmpty) return filtered;

    final query = _searchQuery.toLowerCase();
    return filtered.where((entry) {
      final service = entry.service.toLowerCase();
      final username = entry.username.toLowerCase();

      switch (_selectedFilter) {
        case FilterType.both:
          return service.contains(query) || username.contains(query);
        case FilterType.service:
          return service.contains(query);
        case FilterType.username:
          return username.contains(query);
      }
    }).toList();
  }

  Map<String, List<PasswordEntry>> _groupedEntries() {
    final List<PasswordEntry> filtered = _filterEntries()
      ..sort(
        (a, b) => a.service.toLowerCase().compareTo(b.service.toLowerCase()),
      );

    final Map<String, List<PasswordEntry>> grouped = {};
    for (final entry in filtered) {
      grouped.putIfAbsent(entry.service, () => []).add(entry);
    }
    return grouped;
  }

  Future<void> _downloadVaultLocally() async {
    try {
      final baseDir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderPath = '${baseDir.path}/VaultBackup_$timestamp';
      final folder = Directory(folderPath);
      await folder.create(recursive: true);

      // Copy images and update imagePaths
      final entriesToSave = <PasswordEntry>[];

      for (final entry in _entries) {
        final newImagePaths = <String>[];

        for (int i = 0; i < entry.imagePaths.length; i++) {
          final image = File(entry.imagePaths[i]);
          if (await image.exists()) {
            final newImagePath = '$folderPath/vault_image_${entry.id}_$i.png';
            await image.copy(newImagePath);
            newImagePaths.add(newImagePath);
          }
        }

        entriesToSave.add(
          PasswordEntry(
            id: entry.id,
            service: entry.service,
            username: entry.username,
            password: entry.password,
            note: entry.note,
            isFavorite: entry.isFavorite,
            imagePaths: newImagePaths,
          ),
        );
      }

      // Save JSON with new image paths
      final jsonFile = File('$folderPath/vault_backup_download.json');
      final jsonData = entriesToSave.map((e) => e.toJson()).toList();
      await jsonFile.writeAsString(jsonEncode(jsonData));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Vault and images saved at:\n$folderPath"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to download vault: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔐 Your Vault"),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.star : Icons.star_border,
              color: _showOnlyFavorites ? Colors.amber : Colors.white,
            ),
            tooltip: _showOnlyFavorites
                ? 'Showing Favorites'
                : 'Show Favorites Only',
            onPressed: () {
              setState(() => _showOnlyFavorites = !_showOnlyFavorites);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GestureDetector(
              onTapDown: (details) async {
                final googleSignIn = GoogleSignIn(
                  scopes: [drive.DriveApi.driveAppdataScope],
                );

                if (_currentUser != null) {
                  final selected = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      0,
                      0,
                    ),
                    items: [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentUser!.displayName != null)
                              Text(
                                _currentUser!.displayName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (_currentUser!.email.isNotEmpty)
                              Text(
                                _currentUser!.email,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const Divider(),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'switch',
                        child: Text("🔄 Switch Account"),
                      ),
                      const PopupMenuItem<String>(
                        value: 'signout',
                        child: Text("🚪 Sign Out"),
                      ),
                    ],
                  );

                  if (selected == 'signout') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Sign Out"),
                        content: const Text(
                          "Are you sure you want to sign out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Sign Out",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await googleSignIn.signOut();
                      setState(() => _currentUser = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Signed out")),
                      );
                    }
                  } else if (selected == 'switch') {
                    final user = await googleSignIn.signInSilently();
                    await googleSignIn.disconnect();
                    final newUser = await googleSignIn.signIn();
                    if (newUser != null) {
                      setState(() => _currentUser = newUser);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Switched to ${newUser.email}")),
                      );
                    }
                  }
                } else {
                  try {
                    final user = await googleSignIn.signIn();
                    if (user != null) {
                      setState(() => _currentUser = user);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Signed in as ${user.email}")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Sign-in failed: $e")),
                    );
                  }
                }
              },
              child: CircleAvatar(
                backgroundImage: _currentUser?.photoUrl != null
                    ? NetworkImage(_currentUser!.photoUrl!)
                    : null,
                child: _currentUser?.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: PopupMenuButton<FilterType>(
                  tooltip: "Search filter",
                  icon: const Icon(Icons.filter_list),
                  onSelected: (FilterType selected) {
                    setState(() => _selectedFilter = selected);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: FilterType.service,
                      child: Text('Search by Service'),
                    ),
                    const PopupMenuItem(
                      value: FilterType.username,
                      child: Text('Search by Username'),
                    ),
                    const PopupMenuItem(
                      value: FilterType.both,
                      child: Text('Search by Both'),
                    ),
                  ],
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                '🔧 Options',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onThemeChanged: widget.onThemeChanged,
                      isDarkTheme: widget.isDarkTheme,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Lock Now'),
              onTap: () {
                Navigator.pop(context);
                widget.onManualLock(); // 👈 Triggers lock
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Backup to Drive'),
              onTap: () {
                Navigator.pop(context);
                _backupVaultToDrive();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from Drive'),
              onTap: () {
                Navigator.pop(context);
                _restoreVaultFromDrive();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Vault (Local)'),
              onTap: () {
                Navigator.pop(context);
                _downloadVaultLocally();
              },
            ),
          ],
        ),
      ),
      body: grouped.isEmpty
          ? const Center(child: Text("No passwords found."))
          : ListView(
              children: grouped.entries.map((entryGroup) {
                return ExpansionTile(
                  title: Text(
                    entryGroup.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: entryGroup.value.map((entry) {
                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.vpn_key),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  _visiblePasswords.contains(entry.id)
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_visiblePasswords.contains(entry.id)) {
                                      _visiblePasswords.remove(entry.id);
                                    } else {
                                      _visiblePasswords.add(entry.id);
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openEditEntryForm(entry),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(entry),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              entry.isFavorite ? Icons.star : Icons.star_border,
                              color: entry.isFavorite ? Colors.amber : null,
                            ),
                            tooltip: entry.isFavorite
                                ? "Unfavorite"
                                : "Mark as Favorite",
                            onPressed: () {
                              setState(() {
                                entry.isFavorite = !entry.isFavorite;
                                _saveAndRefresh(); // Persist favorite status
                              });
                            },
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text("Username: ${entry.username}"),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: "Copy Username",
                                onPressed: () async {
                                  Clipboard.setData(
                                    ClipboardData(text: entry.password),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Password copied"),
                                    ),
                                  );
                                  // Auto-clear clipboard (if timeout is not 0)
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final clearTime =
                                      prefs.getInt('clipboardClearTime') ?? 10;
                                  if (clearTime > 0) {
                                    Future.delayed(
                                      Duration(seconds: clearTime),
                                      () async {
                                        final current = await Clipboard.getData(
                                          'text/plain',
                                        );
                                        // Only clear if clipboard still has the same value
                                        if (current?.text == entry.password) {
                                          Clipboard.setData(
                                            const ClipboardData(text: ''),
                                          );
                                        }
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Password: ${_visiblePasswords.contains(entry.id) ? entry.password : "••••••••"}",
                                ),
                              ),
                              if (_visiblePasswords.contains(entry.id))
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: "Copy Password",
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: entry.password),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Password copied"),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty)
                            Text("Note: ${entry.note}"),
                          if (entry.imagePaths.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: entry.imagePaths.length,
                                itemBuilder: (context, index) {
                                  final path = entry.imagePaths[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            child: Image.file(File(path)),
                                          ),
                                        );
                                      },
                                      child: Image.file(
                                        File(path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  }).toList(),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEntryForm,
        child: const Icon(Icons.add),
        tooltip: "Add Entry",
      ),
    );
  }
}

class VaultBackupManager {
  static Future<File> createBackupFile(List<PasswordEntry> entries) async {
    final jsonData = entries.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/vault_backup.json');

    return file.writeAsString(jsonString);
  }

  static Future<void> uploadToDrive(
    GoogleSignInAccount googleUser,
    List<PasswordEntry> entries,
  ) async {
    try {
      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      // 1. Delete old backup files and images
      final fileList = await driveApi.files.list(spaces: 'appDataFolder');
      for (final file in fileList.files ?? []) {
        if (file.name == 'vault_backup.json' ||
            file.name.startsWith('vault_image_')) {
          await driveApi.files.delete(file.id!);
        }
      }

      // 2. Upload main JSON
      final fileToUpload = await createBackupFile(entries);
      final media = drive.Media(
        fileToUpload.openRead(),
        fileToUpload.lengthSync(),
      );
      final driveFile = drive.File()
        ..name = 'vault_backup.json'
        ..parents = ['appDataFolder'];

      await driveApi.files.create(driveFile, uploadMedia: media);

      // 3. Upload each image
      for (final entry in entries) {
        for (int i = 0; i < entry.imagePaths.length; i++) {
          final imageFile = File(entry.imagePaths[i]);
          if (!imageFile.existsSync()) continue;

          final media = drive.Media(
            imageFile.openRead(),
            imageFile.lengthSync(),
          );

          final imageDriveFile = drive.File()
            ..name = 'vault_image_${entry.id}_$i.png'
            ..parents = ['appDataFolder'];

          await driveApi.files.create(imageDriveFile, uploadMedia: media);
        }
      }

      debugPrint("✅ Backup (including images) uploaded to Google Drive");
    } catch (e) {
      debugPrint("❌ Failed to upload to Drive: $e");
    }
  }

  static Future<List<PasswordEntry>> restoreFromDrive(
      GoogleSignInAccount googleUser,
      ) async {
    final authHeaders = await googleUser.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(client);

    // Fetch file list
    final fileList = await driveApi.files.list(spaces: 'appDataFolder');
    final allFiles = fileList.files ?? [];

    // Find the backup file
    final backupFile = allFiles.firstWhere(
          (f) => f.name == 'vault_backup.json',
      orElse: () => throw Exception("Backup file not found"),
    );

    if (backupFile.id == null) {
      throw Exception("Backup file missing ID.");
    }

    final media = await driveApi.files.get(
      backupFile.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await utf8.decoder.bind(media.stream).join();
    final jsonData = jsonDecode(content) as List<dynamic>;
    final restoredEntries = jsonData.map((e) => PasswordEntry.fromJson(e)).toList();

    // Restore images
    final tempDir = await getTemporaryDirectory();

    for (final entry in restoredEntries) {
      entry.imagePaths.clear();
      int index = 0;

      while (true) {
        final expectedName = 'vault_image_${entry.id}_$index.png';
        final matching = allFiles.where((f) => f.name == expectedName).toList();

        if (matching.isEmpty || matching.first.id == null) break;

        final imageMedia = await driveApi.files.get(
          matching.first.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final filePath = '${tempDir.path}/$expectedName';
        final imageFile = File(filePath);
        final sink = imageFile.openWrite();
        await imageMedia.stream.pipe(sink);

        entry.imagePaths.add(filePath);
        index++;
      }
    }

    return restoredEntries;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

class FullImageView extends StatelessWidget {
  final String imagePath;

  const FullImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Screenshot")),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}
