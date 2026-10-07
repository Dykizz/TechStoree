import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ApiResult {
  final bool success;
  final String message;
  final dynamic data;

  ApiResult({required this.success, this.message = '', this.data});
}

/// Custom HTTP Client tự động gắn Token từ RAM và tự động Refresh Token khi gặp 401
class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Tự động gắn Bearer Token từ RAM nếu chưa có trong header
    if (!request.headers.containsKey('Authorization')) {
      final token = BaseApiService.ramAccessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    // Sao lưu body bytes nếu cần retry khi gặp 401
    List<int>? bodyBytes;
    if (request is http.Request) {
      bodyBytes = request.bodyBytes;
    }

    var streamedResponse = await _inner.send(request);

    // 2. Tự động bắt 401 Unauthorized và refresh token nếu có Refresh Token trong RAM
    if (streamedResponse.statusCode == 401 && BaseApiService.hasRamRefreshToken) {
      debugPrint('[AuthenticatedHttpClient] Gặp 401 (Access Token hết hạn). Đang tự động làm mới token...');
      final refreshed = await BaseApiService.refreshTokensGlobal();
      if (refreshed && BaseApiService.ramAccessToken != null) {
        final newRequest = _copyRequest(request, bodyBytes);
        newRequest.headers['Authorization'] = 'Bearer ${BaseApiService.ramAccessToken}';
        debugPrint('[AuthenticatedHttpClient] Gửi lại request với Access Token mới từ RAM...');
        streamedResponse = await _inner.send(newRequest);
      }
    }

    return streamedResponse;
  }

  http.BaseRequest _copyRequest(http.BaseRequest original, List<int>? bodyBytes) {
    if (original is http.Request) {
      final copy = http.Request(original.method, original.url);
      copy.headers.addAll(original.headers);
      if (bodyBytes != null && bodyBytes.isNotEmpty) {
        copy.bodyBytes = bodyBytes;
      }
      return copy;
    }
    return original;
  }
}

abstract class BaseApiService extends ChangeNotifier {
  String _baseUrl = 'http://localhost:5000/api';
  bool isConnected = false;
  final bool _isLoading = false;
  AuthProvider? _authProvider;

  // =========================================================================
  // BỘ NHỚ RAM LƯU TRỮ ACCESS TOKEN & REFRESH TOKEN TOÀN CỤC
  // Tự động gắn vào mọi API call mà không cần truyền token thủ công ở từng hàm
  // =========================================================================
  static String? _ramAccessToken;
  static String? _ramRefreshToken;
  static Future<bool>? _refreshFuture;

  /// Lấy Access Token hiện tại trong RAM
  static String? get ramAccessToken => _ramAccessToken;

  /// Lấy Refresh Token hiện tại trong RAM
  static String? get ramRefreshToken => _ramRefreshToken;

  /// Kiểm tra có Refresh Token hợp lệ trong RAM hay không
  static bool get hasRamRefreshToken => _ramRefreshToken != null && _ramRefreshToken!.isNotEmpty;

  /// Cập nhật Tokens vào RAM
  static void setRamTokens({String? accessToken, String? refreshToken}) {
    if (accessToken != null && accessToken.isNotEmpty) {
      _ramAccessToken = accessToken;
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _ramRefreshToken = refreshToken;
    }
  }

  /// Xóa toàn bộ Tokens trong RAM (khi Đăng xuất hoặc Token hết hạn)
  static void clearRamTokens() {
    _ramAccessToken = null;
    _ramRefreshToken = null;
  }

  /// Client HTTP tự động gắn token từ RAM và auto-refresh khi gặp 401
  static final http.Client autoClient = AuthenticatedHttpClient();

  String get baseUrl => _baseUrl;
  bool get isLoading => _isLoading;
  AuthProvider? get authProvider => _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
    if (auth.token != null && auth.token!.isNotEmpty) {
      setRamTokens(accessToken: auth.token, refreshToken: auth.refreshToken);
    }
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    checkBackendConnection();
  }

  /// Tạo Header tự động: Tự lấy Access Token từ RAM nếu không truyền vào
  Map<String, String> headers([String? token, Map<String, String>? extraHeaders]) {
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : (_ramAccessToken ?? _authProvider?.token);
    final h = {'Content-Type': 'application/json'};
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $effectiveToken';
    }
    if (extraHeaders != null) {
      h.addAll(extraHeaders);
    }
    return h;
  }

  /// Hàm làm mới Token toàn cục từ RAM, chống trùng lặp nhiều request đồng thời
  static Future<bool> refreshTokensGlobal({String? baseUrl, AuthProvider? authProvider}) {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _executeRefreshTokens(baseUrl: baseUrl, authProvider: authProvider);
    return _refreshFuture!.whenComplete(() {
      _refreshFuture = null;
    });
  }

  static Future<bool> _executeRefreshTokens({String? baseUrl, AuthProvider? authProvider}) async {
    final tokenToRefresh = _ramRefreshToken ?? authProvider?.refreshToken;
    if (tokenToRefresh == null || tokenToRefresh.isEmpty) {
      debugPrint('[BaseApiService] Không tìm thấy Refresh Token trong RAM để gia hạn.');
      clearRamTokens();
      authProvider?.logout();
      return false;
    }

    final targetUrl = baseUrl ?? 'http://localhost:5000/api';
    try {
      debugPrint('[BaseApiService] Đang tự động gọi API Refresh Token...');
      final response = await http.post(
        Uri.parse('$targetUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': tokenToRefresh}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resJson = json.decode(utf8.decode(response.bodyBytes));
        if (resJson is Map<String, dynamic> && resJson['success'] == true && resJson['data'] != null) {
          final data = resJson['data'];
          final newAccessToken = (data['token'] ?? data['accessToken'])?.toString();
          final newRefreshToken = data['refreshToken']?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            setRamTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
            debugPrint('[BaseApiService] Refresh Token thành công! Đã tự động lưu Access Token mới vào RAM.');

            // Đồng bộ sang AuthProvider nếu có
            if (authProvider != null) {
              authProvider.updateTokensFromRefresh(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                user: data['user'],
              );
            }
            return true;
          }
        }
      }
      debugPrint('[BaseApiService] Refresh Token thất bại (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[BaseApiService] Ngoại lệ khi refresh token: $e');
    }

    // Refresh thất bại (hết hạn / bị thu hồi) -> xóa RAM và đăng xuất
    clearRamTokens();
    authProvider?.logout();
    return false;
  }

  /// Bao bọc mọi request: Tự gắn token từ RAM, bắt 401, tự refresh token và retry
  Future<http.Response> executeWithAuth(
    Future<http.Response> Function(String? currentToken) sendRequest, {
    String? token,
  }) async {
    final initialToken = (token != null && token.isNotEmpty)
        ? token
        : (_ramAccessToken ?? _authProvider?.token);
    var response = await sendRequest(initialToken);

    // Nếu gặp 401 Unauthorized và có refresh token trong RAM
    if (response.statusCode == 401 && (hasRamRefreshToken || (_authProvider?.hasRefreshToken ?? false))) {
      debugPrint('[BaseApiService] Nhận HTTP 401 (Access Token hết hạn). Đang tự động gọi Refresh Token...');
      final refreshed = await refreshTokensGlobal(baseUrl: _baseUrl, authProvider: _authProvider);
      if (refreshed) {
        final newToken = _ramAccessToken ?? _authProvider?.token;
        debugPrint('[BaseApiService] Refresh thành công! Tự động retry request với Access Token mới từ RAM...');
        response = await sendRequest(newToken);
      }
    }

    return response;
  }

  // =========================================================================
  // CÁC HÀM GỌI API CHUẨN: TỰ ĐỘNG GẮN ACCESS TOKEN TỪ RAM & TỰ RETRY KHI 401
  // =========================================================================

  Future<http.Response> httpGet(
    Uri uri, {
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return executeWithAuth((activeToken) {
      return http.get(uri, headers: headers(activeToken, extraHeaders)).timeout(timeout);
    }, token: token);
  }

  Future<http.Response> httpPost(
    Uri uri, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return executeWithAuth((activeToken) {
      return http.post(uri, headers: headers(activeToken, extraHeaders), body: body).timeout(timeout);
    }, token: token);
  }

  Future<http.Response> httpPut(
    Uri uri, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return executeWithAuth((activeToken) {
      return http.put(uri, headers: headers(activeToken, extraHeaders), body: body).timeout(timeout);
    }, token: token);
  }

  Future<http.Response> httpPatch(
    Uri uri, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return executeWithAuth((activeToken) {
      return http.patch(uri, headers: headers(activeToken, extraHeaders), body: body).timeout(timeout);
    }, token: token);
  }

  Future<http.Response> httpDelete(
    Uri uri, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return executeWithAuth((activeToken) {
      return http.delete(uri, headers: headers(activeToken, extraHeaders), body: body).timeout(timeout);
    }, token: token);
  }

  // =========================================================================
  // CÁC HÀM TIỆN ÍCH RÚT GỌN (CHỈ CẦN TRUYỀN PATH - TỰ GẮN BASE URL & RAM TOKEN)
  // Ví dụ: await get('/categories') hoặc await post('/products', body: ...)
  // =========================================================================

  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    var cleanBase = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    var cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanBase$cleanPath');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? params, String? token, Duration? timeout}) {
    return httpGet(buildUri(path, params), token: token, timeout: timeout ?? const Duration(seconds: 10));
  }

  Future<http.Response> post(String path, {Object? body, String? token, Duration? timeout}) {
    return httpPost(buildUri(path), body: body, token: token, timeout: timeout ?? const Duration(seconds: 10));
  }

  Future<http.Response> put(String path, {Object? body, String? token, Duration? timeout}) {
    return httpPut(buildUri(path), body: body, token: token, timeout: timeout ?? const Duration(seconds: 10));
  }

  Future<http.Response> patch(String path, {Object? body, String? token, Duration? timeout}) {
    return httpPatch(buildUri(path), body: body, token: token, timeout: timeout ?? const Duration(seconds: 10));
  }

  Future<http.Response> delete(String path, {Object? body, String? token, Duration? timeout}) {
    return httpDelete(buildUri(path), body: body, token: token, timeout: timeout ?? const Duration(seconds: 10));
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
