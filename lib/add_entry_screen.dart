import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddEntryScreen extends StatefulWidget {
  final PasswordEntry? existingEntry;
  final void Function({
    required String id,
    required String service,
    required String username,
    required String password,
    String? note,
    required List<String> imagePaths,
  })
  onSave;

  const AddEntryScreen({super.key, this.existingEntry, required this.onSave});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noteController = TextEditingController();
  List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _serviceController.text = widget.existingEntry!.service;
      _usernameController.text = widget.existingEntry!.username;
      _passwordController.text = widget.existingEntry!.password;
      _noteController.text = widget.existingEntry!.note ?? '';
      _selectedImagePaths = widget.existingEntry?.imagePaths ?? [];
    }
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
      final id =
          widget.existingEntry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      widget.onSave(
        id: id,
        service: _serviceController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        imagePaths: _selectedImagePaths,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() {
        _selectedImagePaths.addAll(pickedList.map((e) => e.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingEntry == null ? "Add New Entry" : "Edit Entry",
        ),
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
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username / Email",
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Note (Optional)"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                "Attach Screenshot (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_selectedImagePaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImagePaths.length,
                    itemBuilder: (context, index) {
                      final path = _selectedImagePaths[index];
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Image.file(
                              File(path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(
                                  () => _selectedImagePaths.removeAt(index),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Add Screenshot(s)"),
              ),
              const SizedBox(height: 20),
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
