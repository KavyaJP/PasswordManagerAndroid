import 'package:flutter/material.dart';
import 'models/password_entry.dart'; // Needed if you want to pass existingEntry from HomeScreen

class AddEntryScreen extends StatefulWidget {
  final void Function({
  required String id,
  required String service,
  required String username,
  required String password,
  String? note,
  }) onSave;

  final PasswordEntry? existingEntry;

  const AddEntryScreen({
    super.key,
    required this.onSave,
    this.existingEntry,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.existingEntry?.service ?? '');
    _usernameController = TextEditingController(text: widget.existingEntry?.username ?? '');
    _passwordController = TextEditingController(text: widget.existingEntry?.password ?? '');
    _noteController = TextEditingController(text: widget.existingEntry?.note ?? '');
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        id: widget.existingEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        service: _serviceController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry == null ? "Add New Entry" : "Edit Entry"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(labelText: "Service"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username / Email"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Note (Optional)"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
