import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  /// Tải ảnh lên Cloudinary bằng Signed Upload thông qua Backend API (POST /api/Media/signature).
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? backendBaseUrl,
    String? token,
    String folder = 'techstore',
  }) async {
    final rawBaseUrl = (backendBaseUrl != null && backendBaseUrl.isNotEmpty)
        ? backendBaseUrl
        : 'http://localhost:5000/api';
    
    var cleanBaseUrl = rawBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (!cleanBaseUrl.endsWith('/api')) {
      cleanBaseUrl = '$cleanBaseUrl/api';
    }

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Thử endpoint /Media/signature (hoặc /media/signature nếu lowercase)
      Uri sigUri = Uri.parse('$cleanBaseUrl/Media/signature');
      var sigResponse = await http.post(
        sigUri,
        headers: headers,
        body: jsonEncode({'folder': folder}),
      ).timeout(const Duration(seconds: 5));

      if (sigResponse.statusCode == 404) {
        sigUri = Uri.parse('$cleanBaseUrl/media/signature');
        sigResponse = await http.post(
          sigUri,
          headers: headers,
          body: jsonEncode({'folder': folder}),
        ).timeout(const Duration(seconds: 5));
      }

      if (sigResponse.statusCode == 200) {
        final sigData = jsonDecode(utf8.decode(sigResponse.bodyBytes));
        if (sigData['success'] == true && sigData['data'] != null) {
          final d = sigData['data'];
          final String uploadUrl = d['uploadUrl'] ?? '';
          final String signature = d['signature'] ?? '';
          final String timestamp = d['timestamp']?.toString() ?? '';
          final String apiKey = d['apiKey'] ?? '';
          final String targetFolder = d['folder'] ?? folder;

          if (uploadUrl.isNotEmpty && signature.isNotEmpty && apiKey.isNotEmpty) {
            final req = http.MultipartRequest('POST', Uri.parse(uploadUrl))
              ..fields['api_key'] = apiKey
              ..fields['timestamp'] = timestamp
              ..fields['signature'] = signature
              ..fields['folder'] = targetFolder
              ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

            final streamedRes = await req.send().timeout(const Duration(seconds: 30));
            final res = await http.Response.fromStream(streamedRes);

            if (res.statusCode >= 200 && res.statusCode < 300) {
              final jsonRes = jsonDecode(utf8.decode(res.bodyBytes));
              if (jsonRes['secure_url'] != null) {
                return jsonRes['secure_url'].toString();
              }
            } else {
              debugPrint('Cloudinary Upload Failed HTTP ${res.statusCode}: ${res.body}');
            }
          } else {
            debugPrint('Dữ liệu chữ ký từ Backend không đầy đủ (thiếu uploadUrl, signature hoặc apiKey).');
          }
        }
      } else {
        debugPrint('Lấy chữ ký từ Backend thất bại HTTP ${sigResponse.statusCode}: ${sigResponse.body}');
      }
    } catch (e) {
      debugPrint('Lỗi kết nối Backend lấy chữ ký Cloudinary: $e');
    }

    return null;
  }
}

