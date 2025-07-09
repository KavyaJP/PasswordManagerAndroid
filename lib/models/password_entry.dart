import 'package:hive/hive.dart';

part 'password_entry.g.dart'; // Needed for code generation

@HiveType(typeId: 0)
class PasswordEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String service;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  final List<String> imagePaths;

  @HiveField(7)
  final String? category;

  PasswordEntry({
    required this.id,
    required this.service,
    required this.username,
    required this.password,
    this.note,
    this.isFavorite = false,
    this.imagePaths = const [],
    this.category,
  });

  PasswordEntry copyWith({
    String? id,
    String? service,
    String? username,
    String? password,
    String? note,
    bool? isFavorite,
    List<String>? imagePaths,
    String? category,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      service: service ?? this.service,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePaths: imagePaths ?? this.imagePaths,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "service": service,
    "username": username,
    "password": password,
    "note": note,
    "isFavorite": isFavorite,
    "imagePaths": imagePaths,
    "category": category,
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    id: json["id"],
    service: json["service"],
    username: json["username"],
    password: json["password"],
    note: json["note"],
    isFavorite: json["isFavorite"] ?? false,
    imagePaths: List<String>.from(json["imagePaths"] ?? []),
    category: json["category"],
  );
}