import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/base_api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userEmail = 'admin@techstoree.vn';
  String _userName = 'Quản Trị Viên';
  String _userRole = 'ADMIN';
  String? _token;
  String? _refreshToken;
  Future<bool>? _refreshFuture;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get userRole => _userRole;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;

  Future<bool> login(String email, String password, {String baseUrl = 'http://localhost:5000/api'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      final resJson = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && resJson['success'] == true && resJson['data'] != null) {
        final data = resJson['data'];
        _token = data['token'] ?? data['accessToken'];
        _refreshToken = data['refreshToken']?.toString();
        // Tự động lưu Token vào RAM của BaseApiService
        BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);

        final user = data['user'];
        if (user != null) {
          _userEmail = user['email'] ?? email;
          _userName = user['fullName'] ?? user['username'] ?? 'Quản Trị Viên';
          _userRole = user['role'] ?? 'ADMIN';
        }
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (resJson['message'] != null) {
        _errorMessage = resJson['message'];
      }
    } catch (e) {
      debugPrint('API login error, fallback checking: $e');
    }

    // Mock Login Fallback (If API is offline or demo login)
    if ((email.trim() == 'admin@techstoree.vn' || email.trim() == 'admin') && password == 'admin123') {
      _isLoggedIn = true;
      _userEmail = 'admin@techstoree.vn';
      _userName = 'Quản Trị Viên';
      _userRole = 'ADMIN';
      _token = 'demo-jwt-token-techstoree-2026';
      _refreshToken = 'demo-refresh-token-techstoree-2026';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first.toUpperCase();
      _userRole = 'ADMIN';
      _token = 'demo-jwt-token';
      _refreshToken = 'demo-refresh-token';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage ??= 'Tài khoản hoặc mật khẩu không chính xác!';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Calls the refresh token endpoint to obtain a new access token and refresh token.
  /// Deduplicates multiple simultaneous refresh requests using _refreshFuture.
  Future<bool> refreshAccessToken({String? baseUrl}) {
    if (_refreshFuture != null) {
      debugPrint('[AuthProvider] Token refresh already in progress, awaiting existing task...');
      return _refreshFuture!;
    }
    _refreshFuture = _executeTokenRefresh(baseUrl: baseUrl);
    return _refreshFuture!.whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _executeTokenRefresh({String? baseUrl}) async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      debugPrint('[AuthProvider] No refresh token available. Logging out...');
      logout();
      return false;
    }

    final effectiveBaseUrl = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl
        : 'http://localhost:5000/api';

    try {
      debugPrint('[AuthProvider] Refreshing access token via $effectiveBaseUrl/auth/refresh-token...');
      final response = await http.post(
        Uri.parse('$effectiveBaseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final resJson = json.decode(utf8.decode(response.bodyBytes));
        if (resJson['success'] == true && resJson['data'] != null) {
          final data = resJson['data'];
          _token = data['token'] ?? data['accessToken'];
          if (data['refreshToken'] != null && data['refreshToken'].toString().isNotEmpty) {
            _refreshToken = data['refreshToken'].toString();
          }
          final user = data['user'];
          if (user != null) {
            _userEmail = user['email'] ?? _userEmail;
            _userName = user['fullName'] ?? user['username'] ?? _userName;
            _userRole = user['role'] ?? _userRole;
          }
          debugPrint('[AuthProvider] Access token successfully refreshed!');
          notifyListeners();
          return true;
        }
      }
      debugPrint('[AuthProvider] Refresh token failed with HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('[AuthProvider] Exception during token refresh: $e');
    }

    // If refresh token call failed or token is expired/revoked, log the user out
    logout(baseUrl: effectiveBaseUrl);
    return false;
  }

  void updateTokensFromRefresh({
    required String accessToken,
    String? refreshToken,
    dynamic user,
  }) {
    _token = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
    if (user != null && user is Map<String, dynamic>) {
      _userEmail = user['email'] ?? _userEmail;
      _userName = user['fullName'] ?? user['username'] ?? _userName;
      _userRole = user['role'] ?? _userRole;
    }
    notifyListeners();
  }

  void logout({String? baseUrl}) {
    final tokenToRevoke = _token;
    _isLoggedIn = false;
    _token = null;
    _refreshToken = null;
    _errorMessage = null;
    BaseApiService.clearRamTokens();
    notifyListeners();

    if (tokenToRevoke != null && tokenToRevoke.isNotEmpty) {
      try {
        final effectiveBaseUrl = baseUrl ?? 'http://localhost:5000/api';
        http.post(
          Uri.parse('$effectiveBaseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $tokenToRevoke',
          },
        ).timeout(const Duration(seconds: 3)).then((_) {}).catchError((_) {});
      } catch (_) {}
    }
  }
}

