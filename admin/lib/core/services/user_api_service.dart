import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/demographics_report.dart';
import 'base_api_service.dart';

mixin UserApiService on BaseApiService {
  final Map<String, AppUser> _userCache = {};

  /// Lấy danh sách tài khoản người dùng từ Backend API (PostgreSQL)
  /// isStaffOnly = true: Chỉ lấy danh sách nhân viên nội bộ
  /// isStaffOnly = false: Chỉ lấy danh sách khách hàng
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
      debugPrint('[UserApiService] Lỗi kết nối getUsers: $e');
    }
    // Hoàn toàn không dùng mock fallback - trả về danh sách rỗng nếu lỗi kết nối
    return <AppUser>[];
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
      debugPrint('[UserApiService] Lỗi createUser: $e');
      return ApiResult(success: false, message: 'Không thể kết nối máy chủ để tạo tài khoản: $e');
    }
  }

  Future<ApiResult> updateUser(AppUser user, {String? token}) async {
    final oldUser = _userCache[user.id];
    _userCache[user.id] = user;

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
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật thông tin người dùng thành công!');
    } catch (e) {
      debugPrint('[UserApiService] Lỗi updateUser: $e');
      return ApiResult(success: false, message: 'Lỗi cập nhật người dùng: $e');
    }
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
        final existing = _userCache[userId];
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
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[UserApiService] Lỗi toggleUserLock: $e');
    }
    return false;
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
        final existing = _userCache[userId];
        if (existing != null) {
          final updated = AppUser(
            id: existing.id,
            userName: existing.userName,
            fullName: existing.fullName,
            email: existing.email,
            role: primaryRole,
            roles: roles,
            status: existing.status,
            isLocked: existing.isLocked,
            phone: existing.phone,
            techInterest: existing.techInterest,
            dateOfBirth: existing.dateOfBirth,
            address: existing.address,
            createdAt: existing.createdAt,
          );
          _userCache[userId] = updated;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[UserApiService] Lỗi updateUserRoles: $e');
    }
    return false;
  }
}
