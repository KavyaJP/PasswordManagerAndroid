import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'add_entry_screen.dart';
import 'models/password_entry.dart';
import 'secure_storage_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PasswordEntry> _entries = [];
  final Set<String> _visiblePasswords = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadVault();
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
          onSave: ({
            required String id,
            required String service,
            required String username,
            required String password,
            String? note,
          }) {
            final entry = PasswordEntry(
              id: id,
              service: service,
              username: username,
              password: password,
              note: note,
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
          onSave: ({
            required String id,
            required String service,
            required String username,
            required String password,
            String? note,
          }) {
            final updated = PasswordEntry(
              id: id,
              service: service,
              username: username,
              password: password,
              note: note,
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
        content: Text("Are you sure you want to delete the password for '${entry.service}'?"),
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
    final account = await GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]).signIn();
    if (account != null) {
      await VaultBackupManager.uploadToDrive(account, _entries);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Vault backup uploaded to Drive")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Google sign-in failed")),
      );
    }
  }

  Future<void> _restoreVaultFromDrive() async {
    final account = await GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]).signIn();
    if (account != null) {
      try {
        final restoredEntries = await VaultBackupManager.restoreFromDrive(account);
        setState(() {
          _entries.clear();
          _entries.addAll(restoredEntries);
        });
        await SecureStorageManager.saveVault(_entries);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Vault restored from Google Drive")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to restore: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Google sign-in failed")),
      );
    }
  }

  List<PasswordEntry> _filterEntries() {
    if (_searchQuery.trim().isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((e) {
      return e.service.toLowerCase().contains(query) ||
          e.username.toLowerCase().contains(query) ||
          (e.note?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Map<String, List<PasswordEntry>> _groupedEntries() {
    final Map<String, List<PasswordEntry>> grouped = {};
    for (final entry in _filterEntries()) {
      grouped.putIfAbsent(entry.service, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔐 Your Vault"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username row with copy
                    Row(
                      children: [
                        Expanded(child: Text("Username: ${entry.username}")),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: "Copy Username",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: entry.username));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Username copied")),
                            );
                          },
                        ),
                      ],
                    ),

                    // Password row with copy only if visible
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
                              Clipboard.setData(ClipboardData(text: entry.password));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Password copied")),
                              );
                            },
                          ),
                      ],
                    ),

                    // Note (no copy)
                    if (entry.note != null && entry.note!.isNotEmpty)
                      Text("Note: ${entry.note}"),
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

      // Delete old backup(s)
      final fileList = await driveApi.files.list(spaces: 'appDataFolder');
      for (final file in fileList.files ?? []) {
        if (file.name == 'vault_backup.json') {
          await driveApi.files.delete(file.id!);
        }
      }

      final fileToUpload = await createBackupFile(entries);
      final media = drive.Media(fileToUpload.openRead(), fileToUpload.lengthSync());
      final driveFile = drive.File()
        ..name = 'vault_backup.json'
        ..parents = ['appDataFolder'];

      await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint("✅ Backup uploaded to Google Drive");
    } catch (e) {
      debugPrint("❌ Failed to upload to Drive: $e");
    }
  }

  static Future<List<PasswordEntry>> restoreFromDrive(GoogleSignInAccount googleUser) async {
    final authHeaders = await googleUser.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(client);

    final fileList = await driveApi.files.list(spaces: 'appDataFolder');
    final file = fileList.files?.firstWhere((f) => f.name == 'vault_backup.json');

    if (file == null || file.id == null) {
      throw Exception("Backup file not found");
    }

    final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final content = await utf8.decoder.bind(media.stream).join();
    final jsonData = jsonDecode(content) as List<dynamic>;

    return jsonData.map((e) => PasswordEntry.fromJson(e)).toList();
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
