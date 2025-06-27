import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PasswordEntry> _entries = [];

  void _addDummyEntry() {
    final id = Random().nextInt(99999).toString();
    setState(() {
      _entries.add(
        PasswordEntry(
          id: id,
          service: "Service $id",
          username: "user$id@example.com",
          password: "pass$id",
          note: id.hashCode.isEven ? "This is a dummy note for $id" : null,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔐 Your Vault"),
        actions: [
          IconButton(
            onPressed: _addDummyEntry,
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
              entry.note != null
                  ? "${entry.username}\n${entry.note}"
                  : entry.username,
            ),
            isThreeLine: entry.note != null,
            trailing: const Icon(Icons.visibility_off),
          );
        },
      ),
    );
  }
}
