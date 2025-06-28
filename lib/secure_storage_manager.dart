import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/password_entry.dart';

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
}
