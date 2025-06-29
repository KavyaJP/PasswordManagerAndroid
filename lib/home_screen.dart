import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
          onSave:
              ({
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
          onSave:
              ({
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
      await VaultBackupManager.uploadToDrive(account, _entries);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Vault backup uploaded to Drive")),
      );
      _listAppDataFiles(); // 👈 Add this line
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Google sign-in failed")));
    }
  }

  // ✅ Step to list files from appDataFolder
  Future<void> _listAppDataFiles() async {
    final account = await GoogleSignIn(
      scopes: [drive.DriveApi.driveAppdataScope],
    ).signIn();
    if (account == null) {
      debugPrint("❌ Sign in failed");
      return;
    }

    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(client);

    final fileList = await driveApi.files.list(spaces: 'appDataFolder');

    if (fileList.files == null || fileList.files!.isEmpty) {
      debugPrint("📭 No files found in appDataFolder.");
    } else {
      for (var file in fileList.files!) {
        debugPrint("📄 File: ${file.name}, ID: ${file.id}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔐 Your Vault"),
        actions: [
          IconButton(
            onPressed: _openAddEntryForm,
            icon: const Icon(Icons.add),
            tooltip: "Add entry",
          ),
          IconButton(
            onPressed: _backupVaultToDrive,
            icon: const Icon(Icons.cloud_upload),
            tooltip: "Backup to Google Drive",
          ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(child: Text("No passwords saved yet."))
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: Text(
                    "Service: ${entry.service}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Username: ${entry.username}"),
                      Text(
                        "Password: ${_visiblePasswords.contains(entry.id) ? entry.password : "••••••••"}",
                      ),
                      if (entry.note != null && entry.note!.isNotEmpty)
                        Text("Note: ${entry.note}"),
                    ],
                  ),
                  isThreeLine: entry.note != null && entry.note!.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                );
              },
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

      // Step 1: Check for existing backup file in appDataFolder
      final existingFiles = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'vault_backup.json'",
      );

      for (var file in existingFiles.files ?? []) {
        await driveApi.files.delete(file.id!);
        debugPrint("🗑️ Deleted old backup: ${file.id}");
      }

      // Step 2: Create new file
      final fileToUpload = await createBackupFile(entries);
      final media = drive.Media(
        fileToUpload.openRead(),
        fileToUpload.lengthSync(),
      );

      final driveFile = drive.File()
        ..name = 'vault_backup.json'
        ..parents = ['appDataFolder'];

      final uploaded = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      debugPrint("✅ Uploaded new backup: ${uploaded.id}");
    } catch (e) {
      debugPrint("❌ Failed to upload to Drive: $e");
    }
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
