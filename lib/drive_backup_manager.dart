import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'models/password_entry.dart';

class VaultBackupManager {
  static Future<File> createBackupFile(List<PasswordEntry> entries) async {
    final jsonData = entries.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/vault_backup.json');

    return file.writeAsString(jsonString);
  }
}
