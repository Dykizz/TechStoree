import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiResult {
  final bool success;
  final String message;
  final dynamic data;

  ApiResult({required this.success, this.message = '', this.data});
}

abstract class BaseApiService extends ChangeNotifier {
  String _baseUrl = 'http://localhost:5000/api';
  bool isConnected = false;
  final bool _isLoading = false;

  String get baseUrl => _baseUrl;
  bool get isLoading => _isLoading;

  void setBaseUrl(String url) {
    _baseUrl = url;
    checkBackendConnection();
  }

  Map<String, String> headers([String? token]) {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  String extractErrorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'Phiên làm việc hết hạn hoặc chưa được xác thực (HTTP 401). Vui lòng đăng nhập lại!';
    }
    try {
      if (response.body.isNotEmpty) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic>) {
          if (jsonRes['message'] != null && jsonRes['message'].toString().isNotEmpty) {
            return jsonRes['message'].toString();
          }
          if (jsonRes['errors'] != null) {
            final errs = jsonRes['errors'];
            if (errs is Map<String, dynamic>) {
              final messages = <String>[];
              errs.forEach((k, v) {
                if (v is List) {
                  messages.addAll(v.map((e) => e.toString()));
                } else {
                  messages.add(v.toString());
                }
              });
              if (messages.isNotEmpty) return messages.join('\n');
            } else if (errs is List) {
              return errs.join('\n');
            }
            return errs.toString();
          }
          if (jsonRes['title'] != null) {
            return jsonRes['title'].toString();
          }
        }
      }
    } catch (_) {}
    return 'Lỗi yêu cầu HTTP ${response.statusCode}';
  }

  dynamic parseApiResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      final jsonRes = json.decode(utf8.decode(response.bodyBytes));
      if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('success')) {
        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (data is Map<String, dynamic> && data.containsKey('items')) {
            return data['items'];
          }
          return data ?? true;
        }
      } else if (jsonRes is List) {
        return jsonRes;
      }
      return jsonRes;
    }
    return null;
  }

  Future<bool> checkBackendConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories')).timeout(const Duration(seconds: 3));
      isConnected = response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      isConnected = false;
    }
    notifyListeners();
    return isConnected;
  }
}
