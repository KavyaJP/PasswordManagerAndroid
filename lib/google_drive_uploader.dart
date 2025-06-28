import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class GoogleDriveUploader {
  static Future<bool> uploadFileToDrive({
    required String accessToken,
    required File file,
    String fileName = "vault_backup.json",
  }) async {
    final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');

    final mimeType = lookupMimeType(file.path) ?? 'application/json';
    final mediaType = MediaType.parse(mimeType);
    final fileContent = await file.readAsBytes();

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['name'] = fileName
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileContent,
          filename: fileName,
          contentType: mediaType,
        ),
      );

    final response = await http.Response.fromStream(await request.send());

    return response.statusCode == 200 || response.statusCode == 201;
  }
}
