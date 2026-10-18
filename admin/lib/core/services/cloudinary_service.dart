import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  /// Đọc cấu hình Cloudinary từ biến môi trường (Build-time --dart-define hoặc OS Environment Variables).
  /// Tuyệt đối KHÔNG hardcode API Key / Secret trong mã nguồn.
  static String get _cloudName {
    const fromDef = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    if (fromDef.isNotEmpty) return fromDef;
    if (!kIsWeb) {
      return Platform.environment['CLOUDINARY_CLOUD_NAME'] ??
          Platform.environment['CLOUDINARY__CLOUDNAME'] ??
          '';
    }
    return '';
  }

  static String get _apiKey {
    const fromDef = String.fromEnvironment('CLOUDINARY_API_KEY');
    if (fromDef.isNotEmpty) return fromDef;
    if (!kIsWeb) {
      return Platform.environment['CLOUDINARY_API_KEY'] ??
          Platform.environment['CLOUDINARY__APIKEY'] ??
          '';
    }
    return '';
  }

  static String get _apiSecret {
    const fromDef = String.fromEnvironment('CLOUDINARY_API_SECRET');
    if (fromDef.isNotEmpty) return fromDef;
    if (!kIsWeb) {
      return Platform.environment['CLOUDINARY_API_SECRET'] ??
          Platform.environment['CLOUDINARY__APISECRET'] ??
          '';
    }
    return '';
  }

  /// Tải ảnh lên Cloudinary.
  /// 1. Ưu tiên xin chữ ký số (Signature) bảo mật từ Backend API (POST /api/Media/signature).
  /// 2. Nếu Backend không hỗ trợ hoặc lỗi, fallback dùng cấu hình từ biến môi trường.
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? backendBaseUrl,
    String? token,
    String folder = 'techstore',
  }) async {
    // 1. Lấy chữ ký từ Backend
    if (backendBaseUrl != null && backendBaseUrl.isNotEmpty) {
      final backendResult = await _uploadViaBackendSignature(
        bytes: bytes,
        fileName: fileName,
        backendBaseUrl: backendBaseUrl,
        token: token,
        folder: folder,
      );
      if (backendResult != null) return backendResult;
    }

    // 2. Fallback dùng biến môi trường (nếu có)
    final cloudName = _cloudName;
    final apiKey = _apiKey;
    final apiSecret = _apiSecret;

    if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
      debugPrint(
        'Cloudinary Error: Không tìm thấy API keys từ Backend hoặc Biến môi trường. '
        'Vui lòng cấu hình môi trường Backend hoặc truyền qua --dart-define / OS Environment Variable.',
      );
      return null;
    }

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final stringToSign = 'folder=$folder&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

      final req = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..fields['folder'] = folder
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
    } catch (e) {
      debugPrint('Lỗi kết nối upload Cloudinary: $e');
    }

    return null;
  }

  static Future<String?> _uploadViaBackendSignature({
    required Uint8List bytes,
    required String fileName,
    required String backendBaseUrl,
    String? token,
    required String folder,
  }) async {
    try {
      var cleanBaseUrl = backendBaseUrl.replaceAll(RegExp(r'/+$'), '');
      if (!cleanBaseUrl.endsWith('/api')) {
        cleanBaseUrl = '$cleanBaseUrl/api';
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      Uri sigUri = Uri.parse('$cleanBaseUrl/Media/signature');
      var sigResponse = await http
          .post(
            sigUri,
            headers: headers,
            body: jsonEncode({'folder': folder}),
          )
          .timeout(const Duration(seconds: 5));

      if (sigResponse.statusCode == 404) {
        sigUri = Uri.parse('$cleanBaseUrl/media/signature');
        sigResponse = await http
            .post(
              sigUri,
              headers: headers,
              body: jsonEncode({'folder': folder}),
            )
            .timeout(const Duration(seconds: 5));
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
          }
        }
      } else {
        debugPrint('Backend signature status ${sigResponse.statusCode}: ${sigResponse.body}');
      }
    } catch (e) {
      debugPrint('Backend signature error: $e');
    }
    return null;
  }
}


