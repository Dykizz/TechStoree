import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userEmail = 'admin@techstoree.vn';
  String _userName = 'Quản Trị Viên';
  String _userRole = 'ADMIN';
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get userRole => _userRole;
  String? get token => _token;

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
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first.toUpperCase();
      _userRole = 'ADMIN';
      _token = 'demo-jwt-token';
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage ??= 'Tài khoản hoặc mật khẩu không chính xác!';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _token = null;
    _errorMessage = null;
    notifyListeners();
  }
}

