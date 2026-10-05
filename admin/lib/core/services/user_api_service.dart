import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'base_api_service.dart';

mixin UserApiService on BaseApiService {
  final Map<String, AppUser> _userCache = {};

  final List<AppUser> mockUsers = [
    AppUser(
      id: '1',
      userName: 'nguyenvanan',
      fullName: 'Nguyễn Văn An',
      email: 'an.nguyen@gmail.com',
      role: 'ADMIN',
      status: 'Hoạt động',
      isLocked: false,
      phone: '0903112233',
      techInterest: 'Coding / AI',
      dateOfBirth: DateTime(1995, 5, 20),
      address: '72 Lê Thánh Tôn, Q.1, TP.HCM',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    AppUser(
      id: '2',
      userName: 'tranbinh',
      fullName: 'Trần Thị Bình',
      email: 'binh.tran@yahoo.com',
      role: 'USER',
      status: 'Hoạt động',
      isLocked: false,
      phone: '0912334455',
      techInterest: 'Gaming',
      dateOfBirth: DateTime(2001, 8, 15),
      address: '123 Nguyễn Thị Minh Khai, Q.3, TP.HCM',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    AppUser(
      id: '3',
      userName: 'phamduc',
      fullName: 'Phạm Minh Đức',
      email: 'duc.pham@hotmail.com',
      role: 'USER',
      status: 'Tạm khóa',
      isLocked: true,
      phone: '0977112244',
      techInterest: 'Audio / Studio',
      dateOfBirth: DateTime(1998, 11, 10),
      address: '45 Trần Hưng Đạo, Q.5, TP.HCM',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  Future<List<AppUser>> getUsers({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null) {
        List itemsList = [];
        if (data is List) {
          itemsList = data;
        } else if (data is Map && data['items'] is List) {
          itemsList = data['items'] as List;
        }
        if (itemsList.isNotEmpty) {
          return itemsList.map((json) {
            final user = AppUser.fromJson(json as Map<String, dynamic>);
            return _userCache[user.id] ?? user;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error getUsers: $e');
    }
    return mockUsers.map((u) => _userCache[u.id] ?? u).toList();
  }

  Future<ApiResult> createUser(AppUser user, String password, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers(token),
        body: json.encode({
          'username': user.userName.isNotEmpty ? user.userName : user.fullName.toLowerCase().replaceAll(' ', '_'),
          'email': user.email,
          'password': password,
          'fullName': user.fullName,
          'phone': user.phone,
          'techInterest': user.techInterest,
          'dateOfBirth': user.dateOfBirth?.toIso8601String(),
          'address': user.address,
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
    _userCache[user.id] = user;
    notifyListeners();
    return ApiResult(success: true, message: 'Tạo tài khoản thành công (Offline Mode)!');
  }

  Future<ApiResult> updateUser(AppUser user, {String? token}) async {
    _userCache[user.id] = user;
    final idx = mockUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      mockUsers[idx] = user;
    }

    try {
      // 1. Cập nhật role qua backend API nếu role thay đổi
      await updateUserRole(user.id, user.role, token: token);

      // 2. Cập nhật profile qua API /users/profile (nếu khớp với user token)
      await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers(token),
        body: json.encode({
          'fullName': user.fullName,
          'phone': user.phone,
          'dateOfBirth': user.dateOfBirth?.toIso8601String(),
          'techInterest': user.techInterest,
          'address': user.address,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('API Update User (backend call warning): $e');
    }

    notifyListeners();
    return ApiResult(success: true, message: 'Cập nhật thông tin người dùng thành công!');
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
      final updated = AppUser(
        id: old.id,
        userName: old.userName,
        fullName: old.fullName,
        email: old.email,
        role: old.role,
        status: old.isLocked ? 'Hoạt động' : 'Tạm khóa',
        isLocked: !old.isLocked,
        phone: old.phone,
        techInterest: old.techInterest,
        dateOfBirth: old.dateOfBirth,
        address: old.address,
        createdAt: old.createdAt,
      );
      mockUsers[idx] = updated;
      _userCache[userId] = updated;
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
      final updated = AppUser(
        id: old.id,
        userName: old.userName,
        fullName: old.fullName,
        email: old.email,
        role: roleId,
        status: old.status,
        isLocked: old.isLocked,
        phone: old.phone,
        techInterest: old.techInterest,
        dateOfBirth: old.dateOfBirth,
        address: old.address,
        createdAt: old.createdAt,
      );
      mockUsers[idx] = updated;
      _userCache[userId] = updated;
    }
    notifyListeners();
    return true;
  }
}


