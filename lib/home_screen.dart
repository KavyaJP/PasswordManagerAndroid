import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'add_entry_screen.dart';
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
            required String service,
            required String username,
            required String password,
            String? note,
          }) {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final entry = PasswordEntry(
              id: id,
              service: service,
              username: username,
              password: password,
              note: note,
            );
            _addEntry(entry);
          },
        ),
      ),
    );
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
            title: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: "Service: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: entry.service),
                ],
              ),
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
            trailing: IconButton(
              icon: Icon(_visiblePasswords.contains(entry.id)
                  ? Icons.visibility
                  : Icons.visibility_off),
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
          );
        },
      ),
    );
  }
}
