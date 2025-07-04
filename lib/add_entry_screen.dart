import 'package:flutter/material.dart';
import 'models/password_entry.dart';
import 'utils/password_generator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddEntryScreen extends StatefulWidget {
  final PasswordEntry? existingEntry;
  final String? prefilledService;
  final String? prefilledCategory;
  final List<String> existingCategories;

  final void Function({
  required String id,
  required String service,
  required String username,
  required String password,
  String? note,
  required List<String> imagePaths,
  String? category,
  }) onSave;

  const AddEntryScreen({
    super.key,
    this.existingEntry,
    this.prefilledService,
    this.prefilledCategory,
    this.existingCategories = const [],
    required this.onSave,
  });

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
  final _categoryController = TextEditingController();
  String? _selectedCategoryFromDropdown;

  @override
  void initState() {
    super.initState();

    if (widget.existingEntry != null) {
      _serviceController.text = widget.existingEntry!.service;
      _usernameController.text = widget.existingEntry!.username;
      _passwordController.text = widget.existingEntry!.password;
      _noteController.text = widget.existingEntry!.note ?? '';
      _selectedImagePaths = widget.existingEntry!.imagePaths;
      _categoryController.text = widget.existingEntry!.category ?? '';
    } else {
      if (widget.prefilledService != null) {
        _serviceController.text = widget.prefilledService!;
      }
      if (widget.prefilledCategory != null) {
        _categoryController.text = widget.prefilledCategory!;
      }
    }
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final id = widget.existingEntry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final trimmedCategory = _categoryController.text.trim();

      widget.onSave(
        id: id,
        service: _serviceController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        imagePaths: _selectedImagePaths,
        category: trimmedCategory.isEmpty ? null : trimmedCategory,
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

  void _showPasswordGeneratorDialog() {
    int length = 16;
    bool upper = true;
    bool lower = true;
    bool numbers = true;
    bool symbols = true;
    String generated = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("🔐 Generate Password"),
            content: SingleChildScrollView( // 👈 Prevents overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: length.toDouble(),
                          min: 6,
                          max: 64,
                          divisions: 58,
                          label: length.toString(),
                          onChanged: (value) {
                            setState(() {
                              length = value.toInt();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: TextEditingController(text: length.toString()),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          ),
                          onSubmitted: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null && intValue >= 6 && intValue <= 64) {
                              setState(() {
                                length = intValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text("Include Uppercase"),
                    value: upper,
                    onChanged: (val) => setState(() => upper = val!),
                  ),
                  CheckboxListTile(
                    title: const Text("Include Lowercase"),
                    value: lower,
                    onChanged: (val) => setState(() => lower = val!),
                  ),
                  CheckboxListTile(
                    title: const Text("Include Numbers"),
                    value: numbers,
                    onChanged: (val) => setState(() => numbers = val!),
                  ),
                  CheckboxListTile(
                    title: const Text("Include Symbols"),
                    value: symbols,
                    onChanged: (val) => setState(() => symbols = val!),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final result = PasswordGenerator.generate(
                        length: length,
                        includeUpper: upper,
                        includeLower: lower,
                        includeNumbers: numbers,
                        includeSymbols: symbols,
                      );
                      setState(() => generated = result);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Generate"),
                  ),
                  if (generated.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      generated,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              if (generated.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _passwordController.text = generated;
                    Navigator.pop(context);
                  },
                  child: const Text("Use Password"),
                ),
            ],
          );
        });
      },
    );
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
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'icons/password_generate_white.png'
                          : 'icons/password_generate_black.png',
                      width: 24,
                      height: 24,
                    ),
                    tooltip: "Generate Password",
                    onPressed: _showPasswordGeneratorDialog,
                  ),
                ),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Note (Optional)"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text("Category (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select existing category"),
                value: _selectedCategoryFromDropdown,
                items: widget.existingCategories
                    .toSet()
                    .where((c) => c.trim().isNotEmpty)
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryFromDropdown = value;
                    _categoryController.text = value ?? '';
                  });
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Or enter new category"),
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
