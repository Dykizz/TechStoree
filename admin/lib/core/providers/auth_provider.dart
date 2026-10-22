import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/base_api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userEmail = '';
  String _userName = '';
  String _userRole = '';
  List<String> _userRoles = [];
  List<String> _permissions = [];
  String? _token;
  String? _refreshToken;
  Future<bool>? _refreshFuture;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get userRole => _userRole;
  List<String> get userRoles => _userRoles;
  List<String> get permissions => _permissions;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;

  /// Kiểm tra xem người dùng hiện tại có ở chế độ Offline (mock JWT) hay không
  bool get isOfflineMode => _token != null && _token!.startsWith('demo-jwt-token');

  /// Kiểm tra quyền hạn cụ thể (ADMIN mặc định có tất cả quyền)
  bool can(String permission) {
    if (isAdmin) return true;
    final target = permission.trim().toLowerCase();
    return _permissions.any((p) => p.trim().toLowerCase() == target);
  }

  bool get isAdmin =>
      _userRoles.any((r) => r.trim().toUpperCase() == 'ADMIN') ||
      _userRole.trim().toUpperCase() == 'ADMIN';
  bool get isSalesStaff =>
      _userRoles.any((r) => r.trim().toUpperCase() == 'SALES_STAFF') ||
      _userRole.trim().toUpperCase() == 'SALES_STAFF';
  bool get isWarehouseStaff =>
      _userRoles.any((r) => r.trim().toUpperCase() == 'WAREHOUSE_STAFF') ||
      _userRole.trim().toUpperCase() == 'WAREHOUSE_STAFF';
  bool get isSurveyStaff =>
      _userRoles.any((r) => r.trim().toUpperCase() == 'SURVEY_STAFF') ||
      _userRole.trim().toUpperCase() == 'SURVEY_STAFF';

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
          _userName = user['fullName'] ?? user['username'] ?? 'Người Dùng';
          if (user['roles'] != null && user['roles'] is List) {
            _userRoles = List<String>.from(user['roles'].map((e) => e.toString()));
          } else {
            _userRoles = [];
          }
          if (user['permissions'] != null && user['permissions'] is List) {
            _permissions = List<String>.from(user['permissions'].map((e) => e.toString()));
          } else {
            _permissions = [];
          }
          final rawRole = user['primaryRole']?.toString() ?? user['role']?.toString();
          _userRole = (rawRole != null && rawRole.isNotEmpty)
              ? rawRole
              : (_userRoles.isNotEmpty ? _userRoles.first : 'USER');
        }
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Máy chủ phản hồi lỗi (sai mật khẩu hoặc không có tài khoản)
        _errorMessage = resJson['message']?.toString() ?? 'Email hoặc mật khẩu không chính xác!';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('API login error, fallback checking: $e');
    }

    // Mock Login Fallback (Chỉ chạy khi máy chủ API hoàn toàn offline / không thể kết nối)
    final cleanEmail = email.trim().toLowerCase();
    if ((cleanEmail == 'admin@techstoree.vn' || cleanEmail == 'admin') && password == 'admin123') {
      _isLoggedIn = true;
      _userEmail = 'admin@techstoree.vn';
      _userName = 'Quản Trị Viên';
      _userRole = 'ADMIN';
      _userRoles = ['ADMIN'];
      _permissions = [
        'Categories.Create', 'Categories.Delete', 'Categories.Update', 'Categories.View',
        'Orders.Cancel', 'Orders.UpdateStatus', 'Orders.View',
        'Products.Create', 'Products.Delete', 'Products.Update', 'Products.View',
        'Promotions.Create', 'Promotions.Delete', 'Promotions.Update', 'Promotions.View',
        'PurchaseOrders.Create', 'PurchaseOrders.Update', 'PurchaseOrders.View',
        'Roles.Create', 'Roles.Delete', 'Roles.Update', 'Roles.View',
        'Suppliers.Create', 'Suppliers.Delete', 'Suppliers.Update', 'Suppliers.View',
        'Surveys.Assign', 'Surveys.Create', 'Surveys.Delete', 'Surveys.Update', 'Surveys.View',
        'Users.AssignRoles', 'Users.Create', 'Users.Lock', 'Users.Update', 'Users.View',
        'Vouchers.Assign', 'Vouchers.Create', 'Vouchers.Delete', 'Vouchers.Update', 'Vouchers.View'
      ];
      _token = 'demo-jwt-token-techstoree-2026';
      _refreshToken = 'demo-refresh-token-techstoree-2026';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (cleanEmail == 'sales@techstoree.vn' && password == 'staff123') {
      _isLoggedIn = true;
      _userEmail = 'sales@techstoree.vn';
      _userName = 'Lê Thị Bán Hàng';
      _userRole = 'SALES_STAFF';
      _userRoles = ['SALES_STAFF'];
      _permissions = [
        'Products.View', 'Orders.View', 'Orders.UpdateStatus',
        'Promotions.View', 'Vouchers.View', 'Users.View',
      ];
      _token = 'demo-jwt-token-sales';
      _refreshToken = 'demo-refresh-token-sales';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (cleanEmail == 'kho@techstoree.vn' && password == 'staff123') {
      _isLoggedIn = true;
      _userEmail = 'kho@techstoree.vn';
      _userName = 'Trần Văn Kho';
      _userRole = 'WAREHOUSE_STAFF';
      _userRoles = ['WAREHOUSE_STAFF'];
      _permissions = [
        'Products.View', 'Products.Create', 'Products.Update',
        'Categories.View', 'Categories.Create', 'Categories.Update',
        'Suppliers.View', 'Suppliers.Create', 'Suppliers.Update',
        'PurchaseOrders.View', 'PurchaseOrders.Create', 'PurchaseOrders.Update',
      ];
      _token = 'demo-jwt-token-kho';
      _refreshToken = 'demo-refresh-token-kho';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (cleanEmail == 'survey@techstoree.vn' && password == 'staff123') {
      _isLoggedIn = true;
      _userEmail = 'survey@techstoree.vn';
      _userName = 'Phạm Văn Chăm Sóc';
      _userRole = 'SURVEY_STAFF';
      _userRoles = ['SURVEY_STAFF'];
      _permissions = [
        'Surveys.View', 'Surveys.Create', 'Surveys.Update', 'Surveys.Assign',
        'Users.View',
      ];
      _token = 'demo-jwt-token-survey';
      _refreshToken = 'demo-refresh-token-survey';
      BaseApiService.setRamTokens(accessToken: _token, refreshToken: _refreshToken);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác!';
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
            if (user['roles'] != null && user['roles'] is List) {
              _userRoles = List<String>.from(user['roles']);
            }
            if (user['permissions'] != null && user['permissions'] is List) {
              _permissions = List<String>.from(user['permissions']);
            }
            _userRole = user['primaryRole'] ?? user['role'] ?? _userRole;
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
      if (user['roles'] != null && user['roles'] is List) {
        _userRoles = List<String>.from(user['roles']);
      }
      if (user['permissions'] != null && user['permissions'] is List) {
        _permissions = List<String>.from(user['permissions']);
      }
      _userRole = user['primaryRole'] ?? user['role'] ?? _userRole;
    }
    notifyListeners();
  }

  void logout({String? baseUrl}) {
    final tokenToRevoke = _token;
    _isLoggedIn = false;
    _token = null;
    _refreshToken = null;
    _userEmail = '';
    _userName = '';
    _userRole = '';
    _userRoles = [];
    _permissions = [];
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

