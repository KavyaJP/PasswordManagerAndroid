import 'dart:io';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

import 'models/password_entry.dart';

class DriveBackupManager {
  /// Saves the vault data as a JSON file locally and returns the file path
  static Future<File> createBackupFile(List<PasswordEntry> entries) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/vault_backup.json';

    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    final file = File(filePath);

    return file.writeAsString(json);
  }
}

class SecureStorageManager {
  static const _storage = FlutterSecureStorage();
  static const _vaultKey = 'vault_entries';

  static Future<void> saveVault(List<PasswordEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _storage.write(key: _vaultKey, value: encoded);
  }

  static Future<List<PasswordEntry>> loadVault() async {
    final data = await _storage.read(key: _vaultKey);
    if (data == null) return [];
    final decoded = jsonDecode(data) as List;
    return decoded.map((e) => PasswordEntry.fromJson(e)).toList();
  }

  static Future<void> clearVault() async {
    await _storage.delete(key: _vaultKey);
  }

  Future<List<PasswordEntry>> getAllEntries() async {
    final box = await Hive.openBox<PasswordEntry>('passwords');
    return box.values.toList();
  }
}
