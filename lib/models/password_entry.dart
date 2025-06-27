class PasswordEntry {
  final String id;
  final String service;
  final String username;
  final String password;
  final String? note; // 👈 note is now nullable

  PasswordEntry({
    required this.id,
    required this.service,
    required this.username,
    required this.password,
    this.note, // 👈 not required
  });
}
