class PasswordEntry {
  final String id;
  final String service;
  final String username;
  final String password;
  final String? note;
  bool isFavorite;
  final List<String> imagePaths;

  PasswordEntry({
    required this.id,
    required this.service,
    required this.username,
    required this.password,
    this.note,
    this.isFavorite = false,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "service": service,
    "username": username,
    "password": password,
    "note": note,
    "isFavorite": isFavorite,
    "imagePaths": imagePaths,
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    id: json["id"],
    service: json["service"],
    username: json["username"],
    password: json["password"],
    note: json["note"],
    isFavorite: json["isFavorite"] ?? false,
    imagePaths: List<String>.from(json["imagePaths"] ?? []),
  );
}
