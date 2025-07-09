import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import '../models/password_entry.dart';
import '../secure_storage_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class VaultExporter {
  /// Exports all password entries into a .vault file, encrypted with the given passphrase.
  static Future<String?> exportVault(
      BuildContext context,
      List<PasswordEntry> entries,
      String passphrase,
      ) async {
    try {
      // Request permission
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      bool isGranted = false;
      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        isGranted = photos.isGranted;
      } else {
        final storage = await Permission.storage.request();
        isGranted = storage.isGranted;
      }

      if (!isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Permission denied to access storage.")),
        );
        return null;
      }

      // Convert entries to JSON
      final List<Map<String, dynamic>> jsonList = entries.map((e) => e.toJson()).toList();
      final String jsonStr = jsonEncode(jsonList);

      // Generate salt + derive key
      final Uint8List salt = _generateSalt();
      final encrypt.Key key = _deriveKey(passphrase, salt);

      // Encrypt
      final encrypt.IV iv = encrypt.IV.fromSecureRandom(16);
      final encrypt.Encrypter aes = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypt.Encrypted encrypted = aes.encrypt(jsonStr, iv: iv);

      // Combine all parts
      final Uint8List encryptedData = Uint8List.fromList([
        ...salt,
        ...iv.bytes,
        ...encrypted.bytes,
      ]);

      // Save to custom folder
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderPath = '${downloadsDir.path}/Password Manager/VaultBackup_$timestamp';
      final folder = Directory(folderPath);
      await folder.create(recursive: true);

      final filePath = '$folderPath/vault_backup.vault';
      final file = File(filePath);
      await file.writeAsBytes(encryptedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Vault exported at:\n$filePath")),
      );

      return filePath;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to export vault: $e")),
      );
      return null;
    }
  }

  /// Generates a random salt for key derivation.
  static Uint8List _generateSalt([int length = 8]) {
    final secureRandom = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(Uint8List.fromList(List.generate(32, (_) => 1))));
    return secureRandom.nextBytes(length);
  }

  /// Derives a 256-bit AES key from passphrase using PBKDF2 and the provided salt.
  static encrypt.Key _deriveKey(String passphrase, Uint8List salt) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(pc.Pbkdf2Parameters(salt, 10000, 32));
    final Uint8List keyBytes = pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
    return encrypt.Key(keyBytes);
  }
}