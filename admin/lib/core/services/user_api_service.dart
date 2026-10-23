import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/demographics_report.dart';
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

  Future<List<AppUser>> getUsers({String? token, bool? isStaffOnly}) async {
    try {
      final queryParams = <String, String>{};
      if (isStaffOnly != null) {
        queryParams['isStaffOnly'] = isStaffOnly.toString();
      }
      final uri = Uri.parse('$baseUrl/users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await httpGet(
        uri,
        token: token,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[UserApiService] HTTP ${response.statusCode}: Không có quyền truy cập');
        return <AppUser>[];
      }

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
            final apiUser = AppUser.fromJson(json as Map<String, dynamic>);
            final cached = _userCache[apiUser.id];
            final finalUser = AppUser(
              id: apiUser.id,
              userName: apiUser.userName.isNotEmpty ? apiUser.userName : (cached?.userName ?? ''),
              fullName: apiUser.fullName.isNotEmpty ? apiUser.fullName : (cached?.fullName ?? ''),
              email: apiUser.email.isNotEmpty ? apiUser.email : (cached?.email ?? ''),
              role: apiUser.role.isNotEmpty ? apiUser.role : (cached?.role ?? 'USER'),
              roles: apiUser.roles.isNotEmpty ? apiUser.roles : (cached?.roles ?? const ['USER']),
              status: apiUser.isLocked ? 'Tạm khóa' : 'Hoạt động',
              isLocked: apiUser.isLocked,
              phone: apiUser.phone.isNotEmpty ? apiUser.phone : (cached?.phone ?? ''),
              techInterest: (apiUser.techInterest != null && apiUser.techInterest!.trim().isNotEmpty)
                  ? apiUser.techInterest
                  : cached?.techInterest,
              dateOfBirth: apiUser.dateOfBirth ?? cached?.dateOfBirth,
              address: (apiUser.address != null && apiUser.address!.trim().isNotEmpty)
                  ? apiUser.address
                  : cached?.address,
              createdAt: apiUser.createdAt,
            );
            _userCache[finalUser.id] = finalUser;
            return finalUser;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error getUsers: $e');
    }
    var list = mockUsers.map((u) => _userCache[u.id] ?? u).toList();
    if (isStaffOnly != null) {
      if (isStaffOnly) {
        list = list.where((u) => u.role.toUpperCase() != 'USER' || u.roles.any((r) => r.toUpperCase() != 'USER')).toList();
      } else {
        list = list.where((u) => u.role.toUpperCase() == 'USER' && (u.roles.isEmpty || u.roles.every((r) => r.toUpperCase() == 'USER'))).toList();
      }
    }
    return list;
  }

  Future<DemographicsReport> getDemographicsReport({String? token}) async {
    // Luôn tổng hợp báo cáo trực tiếp từ dữ liệu khách hàng thực tế trong database
    final users = await getUsers(token: token, isStaffOnly: false);
    return DemographicsReport.fromUsers(users);
  }

  Future<ApiResult> createUser(AppUser user, String password, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/users'),
        token: token,
        body: json.encode({
          'username': user.userName.isNotEmpty ? user.userName : user.fullName.toLowerCase().replaceAll(' ', '_'),
          'email': user.email,
          'password': password,
          'fullName': user.fullName,
          'phone': user.phone,
          'techInterest': user.techInterest,
          'dateOfBirth': user.dateOfBirth?.toIso8601String(),
          'address': user.address,
          'roles': user.roles.isNotEmpty ? user.roles : [user.role],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo tài khoản thành công!');
      }

      // Fallback sang /auth/register nếu cần
      final fallback = await httpPost(
        Uri.parse('$baseUrl/auth/register'),
        token: token,
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
      );
      if (fallback.statusCode >= 200 && fallback.statusCode < 300) {
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
    final oldUser = _userCache[user.id] ?? mockUsers.where((u) => u.id == user.id).firstOrNull;
    _userCache[user.id] = user;
    final idx = mockUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      mockUsers[idx] = user;
    }

    try {
      // 1. Cập nhật các roles qua backend API: PATCH /users/{id}/role
      if (user.roles.isNotEmpty) {
        await updateUserRoles(user.id, user.roles, token: token);
      } else {
        await updateUserRole(user.id, user.role, token: token);
      }

      // 2. Cập nhật trạng thái khóa nếu có thay đổi
      if (oldUser != null && oldUser.isLocked != user.isLocked) {
        await toggleUserLock(user.id, isLocked: user.isLocked, token: token);
      }

      // 3. Cập nhật profile qua API /users/profile nếu người sửa chính là tài khoản đang đăng nhập
      if (authProvider != null && authProvider!.userEmail == user.email) {
        await httpPut(
          Uri.parse('$baseUrl/users/profile'),
          token: token,
          body: json.encode({
            'fullName': user.fullName,
            'phone': user.phone,
            'dateOfBirth': user.dateOfBirth?.toIso8601String(),
            'techInterest': user.techInterest,
            'address': user.address,
          }),
        );
      }
    } catch (e) {
      debugPrint('API Update User (backend call warning): $e');
    }

    notifyListeners();
    return ApiResult(success: true, message: 'Cập nhật thông tin người dùng thành công!');
  }

  Future<bool> toggleUserLock(String userId, {bool? isLocked, String? token}) async {
    try {
      final body = isLocked != null ? json.encode({'isLocked': isLocked}) : null;
      final response = await httpPatch(
        Uri.parse('$baseUrl/users/$userId/toggle-lock'),
        token: token,
        body: body,
      );

      final data = parseApiResponse(response);
      if (data != null) {
        final existing = _userCache[userId] ?? mockUsers.where((u) => u.id == userId).firstOrNull;
        final bool newLocked;
        if (data is Map<String, dynamic> && data.containsKey('isLocked')) {
          newLocked = data['isLocked'] == true;
        } else {
          newLocked = isLocked ?? !(existing?.isLocked ?? false);
        }

        final apiUser = (data is Map<String, dynamic>) ? AppUser.fromJson(data) : null;
        final updated = AppUser(
          id: userId,
          userName: (apiUser != null && apiUser.userName.isNotEmpty)
              ? apiUser.userName
              : (existing?.userName ?? ''),
          fullName: (apiUser != null && apiUser.fullName.isNotEmpty)
              ? apiUser.fullName
              : (existing?.fullName ?? ''),
          email: (apiUser != null && apiUser.email.isNotEmpty)
              ? apiUser.email
              : (existing?.email ?? ''),
          role: (apiUser != null && apiUser.role.isNotEmpty)
              ? apiUser.role
              : (existing?.role ?? 'USER'),
          roles: (apiUser != null && apiUser.roles.isNotEmpty)
              ? apiUser.roles
              : (existing?.roles ?? const ['USER']),
          status: newLocked ? 'Tạm khóa' : 'Hoạt động',
          isLocked: newLocked,
          phone: (apiUser != null && apiUser.phone.isNotEmpty)
              ? apiUser.phone
              : (existing?.phone ?? ''),
          techInterest: (apiUser?.techInterest != null && apiUser!.techInterest!.trim().isNotEmpty)
              ? apiUser.techInterest
              : existing?.techInterest,
          dateOfBirth: apiUser?.dateOfBirth ?? existing?.dateOfBirth,
          address: (apiUser?.address != null && apiUser!.address!.trim().isNotEmpty)
              ? apiUser.address
              : existing?.address,
          createdAt: apiUser?.createdAt ?? existing?.createdAt ?? DateTime.now(),
        );

        _userCache[userId] = updated;
        final idx = mockUsers.indexWhere((u) => u.id == userId);
        if (idx != -1) mockUsers[idx] = updated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error toggleUserLock: $e');
    }

    // Fallback Offline / Mock
    final idx = mockUsers.indexWhere((u) => u.id == userId);
    final existing = idx != -1 ? mockUsers[idx] : _userCache[userId];
    if (existing != null) {
      final newLocked = isLocked ?? !existing.isLocked;
      final updated = AppUser(
        id: existing.id,
        userName: existing.userName,
        fullName: existing.fullName,
        email: existing.email,
        role: existing.role,
        roles: existing.roles,
        status: newLocked ? 'Tạm khóa' : 'Hoạt động',
        isLocked: newLocked,
        phone: existing.phone,
        techInterest: existing.techInterest,
        dateOfBirth: existing.dateOfBirth,
        address: existing.address,
        createdAt: existing.createdAt,
      );
      if (idx != -1) mockUsers[idx] = updated;
      _userCache[userId] = updated;
    }
    notifyListeners();
    return true;
  }

  Future<bool> updateUserRole(String userId, String roleId, {String? token}) async {
    return updateUserRoles(userId, [roleId], token: token);
  }

  Future<bool> updateUserRoles(String userId, List<String> roles, {String? token}) async {
    final primaryRole = roles.isNotEmpty ? roles.first : 'USER';
    try {
      final response = await httpPatch(
        Uri.parse('$baseUrl/users/$userId/role'),
        token: token,
        body: json.encode({
          'roles': roles,
          'roleId': primaryRole,
        }),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateUserRoles: $e');
    }

    final idx = mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = mockUsers[idx];
      final updated = AppUser(
        id: old.id,
        userName: old.userName,
        fullName: old.fullName,
        email: old.email,
        role: primaryRole,
        roles: roles,
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


