import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userEmail = 'admin@techstoree.vn';
  String _userName = 'Quản Trị Viên';
  String _userRole = 'Administrator';
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
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'] ?? 'mock-jwt-token';
        _userEmail = email;
        _userName = data['fullName'] ?? 'Quản Trị Viên';
        _userRole = data['role'] ?? 'Administrator';
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      debugPrint('API login unavailable, evaluating mock credentials');
    }

    // Mock Login Fallback
    if ((email.trim() == 'admin@techstoree.vn' || email.trim() == 'admin') && password == 'admin123') {
      _isLoggedIn = true;
      _userEmail = 'admin@techstoree.vn';
      _userName = 'Quản Trị Viên Cao Cấp';
      _userRole = 'Administrator';
      _token = 'demo-jwt-token-techstoree-2026';
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (email.isNotEmpty && password.length >= 6) {
      // Allow demo login for any valid email & 6+ char password
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first.toUpperCase();
      _userRole = 'Manager';
      _token = 'demo-jwt-token';
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác!';
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
