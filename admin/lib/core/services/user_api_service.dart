import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'base_api_service.dart';

mixin UserApiService on BaseApiService {
  final List<AppUser> mockUsers = [
    AppUser(id: '1', userName: 'Nguyễn Văn An', email: 'an.nguyen@gmail.com', role: 'ADMIN', status: 'Hoạt động', isLocked: false, phone: '0903112233', createdAt: DateTime.now().subtract(const Duration(days: 120))),
    AppUser(id: '2', userName: 'Trần Thị Bình', email: 'binh.tran@yahoo.com', role: 'USER', status: 'Hoạt động', isLocked: false, phone: '0912334455', createdAt: DateTime.now().subtract(const Duration(days: 45))),
    AppUser(id: '3', userName: 'Phạm Minh Đức', email: 'duc.pham@hotmail.com', role: 'USER', status: 'Tạm khóa', isLocked: true, phone: '0977112244', createdAt: DateTime.now().subtract(const Duration(days: 8))),
  ];

  Future<List<AppUser>> getUsers({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => AppUser.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getUsers: $e');
    }
    return mockUsers;
  }

  Future<ApiResult> createUser(AppUser user, String password, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers(token),
        body: json.encode({
          'username': user.userName.toLowerCase().replaceAll(' ', '_'),
          'email': user.email,
          'password': password,
          'fullName': user.userName,
          'phone': user.phone,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo tài khoản thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error createUser: $e');
    }
    mockUsers.add(user);
    notifyListeners();
    return ApiResult(success: true, message: 'Tạo tài khoản thành công (Offline Mode)!');
  }

  Future<bool> toggleUserLock(String userId, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/toggle-lock'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error toggleUserLock: $e');
    }
    final idx = mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = mockUsers[idx];
      mockUsers[idx] = AppUser(
        id: old.id,
        userName: old.userName,
        email: old.email,
        role: old.role,
        status: old.isLocked ? 'Hoạt động' : 'Tạm khóa',
        isLocked: !old.isLocked,
        phone: old.phone,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
    return true;
  }

  Future<bool> updateUserRole(String userId, String roleId, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/role'),
        headers: headers(token),
        body: json.encode({'roleId': roleId}),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateUserRole: $e');
    }
    final idx = mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = mockUsers[idx];
      mockUsers[idx] = AppUser(
        id: old.id,
        userName: old.userName,
        email: old.email,
        role: roleId,
        status: old.status,
        isLocked: old.isLocked,
        phone: old.phone,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
    return true;
  }
}
