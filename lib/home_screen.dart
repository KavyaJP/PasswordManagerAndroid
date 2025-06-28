import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'add_entry_screen.dart';
import 'secure_storage_manager.dart';
import 'google_drive_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'drive_backup_manager.dart' as backup;
import 'google_drive_uploader.dart';

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
      _entries.addAll(saved);
    });
  }

  Future<void> _addEntry(PasswordEntry entry) async {
    setState(() {
      _entries.add(entry);
    });
    await SecureStorageManager.saveVault(_entries);
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

            setState(() {
              final index = _entries.indexWhere((e) => e.id == id);
              if (index != -1) {
                _entries[index] = entry; // Update
              } else {
                _entries.add(entry); // New
              }
            });

            SecureStorageManager.saveVault(_entries);
          },
        ),
      ),
    );
  }

  void _signInWithGoogleDrive() async {
    final account = await GoogleDriveAuth.signIn();
    if (!mounted) return; // ← this is the fix

    if (account != null) {
      final token = await GoogleDriveAuth.getAccessToken();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in as ${account.email}')),
      );
      print('Access Token: $token');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔐 Your Vault"),
        actions: [
          // Add Google Drive button here
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Sign in to Google Drive',
            onPressed: _signInWithGoogleDrive,
          ),
          IconButton(
            onPressed: _openAddEntryForm,
            icon: const Icon(Icons.add),
            tooltip: "Add entry",
          )
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
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: "Username: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: entry.username),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: "Password: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: _visiblePasswords.contains(entry.id)
                            ? entry.password
                            : "••••••••",
                      ),
                    ],
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: "Note: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: entry.note),
                      ],
                    ),
                  ),
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
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(entry),
                ),
              ],
            ),
            onTap: () {
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
                      setState(() {
                        final index = _entries.indexWhere((e) => e.id == id);
                        if (index != -1) _entries[index] = updated;
                      });
                      SecureStorageManager.saveVault(_entries);
                    },
                  ),
                ),
              );
            },
          );
        },
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
  void _deleteEntry(PasswordEntry entry) async {
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
      _visiblePasswords.remove(entry.id);
    });
    await SecureStorageManager.saveVault(_entries);
  }

  Future<void> _backupToDrive() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.file']).signIn();
      if (googleUser == null) return; // User cancelled

      final auth = await googleUser.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) throw Exception("Failed to retrieve access token.");

      final file = await backup.VaultBackupManager.createBackupFile(_entries);
      final success = await GoogleDriveUploader.uploadFileToDrive(
        accessToken: accessToken,
        file: file,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Backup uploaded to Drive!" : "Upload failed."),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
      ));
    }
  }

}
