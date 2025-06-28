import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'dart:math';
import 'add_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PasswordEntry> _entries = [];
  final Set<String> _visiblePasswords = {};

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
            setState(() {
              _entries.add(
                PasswordEntry(
                  id: id,
                  service: service,
                  username: username,
                  password: password,
                  note: note,
                ),
              );
            });
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
            tooltip: "Add dummy entry",
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
            title: Text(entry.service),
            subtitle: Text(
              _visiblePasswords.contains(entry.id)
                  ? "${entry.username}\n${entry.password}${entry.note != null ? "\n${entry.note}" : ""}"
                  : entry.note != null
                  ? "${entry.username}\n${entry.note}"
                  : entry.username,
            ),
            isThreeLine: entry.note != null,
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
