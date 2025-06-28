class PasswordEntry {
  final String id;
  final String service;
  final String username;
  final String password;
  final String? note;

  PasswordEntry({
    required this.id,
    required this.service,
    required this.username,
    required this.password,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'username': username,
      'password': password,
      'note': note,
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'],
      service: json['service'],
      username: json['username'],
      password: json['password'],
      note: json['note'],
    );
  }
}
