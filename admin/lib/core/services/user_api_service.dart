import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/tech_interests.dart';
import '../models/app_user.dart';
import '../models/demographics_report.dart';
import '../utils/json_parse_helper.dart';
import 'base_api_service.dart';

mixin UserApiService on BaseApiService {
  final Map<String, AppUser> _userCache = {};
  List<TechInterestOption>? _techInterestsCache;

  /// Danh sách sở thích công nghệ đã tải (mặc định fallback từ [TechInterestCatalog.defaults]).
  List<TechInterestOption> get cachedTechInterests =>
      _techInterestsCache ?? TechInterestCatalog.defaults;

  /// Lấy danh mục sở thích công nghệ chuẩn hóa từ API `GET /users/tech-interests`.
  Future<List<TechInterestOption>> getTechInterests({
    String? token,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _techInterestsCache != null) {
      return _techInterestsCache!;
    }
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/users/tech-interests'),
        token: token,
      );
      final data = parseApiResponse(response);
      if (data is List) {
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map(TechInterestOption.fromJson)
            .where((o) => o.key.isNotEmpty && o.displayName.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) {
          _techInterestsCache = parsed;
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[UserApiService] Lỗi getTechInterests: $e');
    }
    return cachedTechInterests;
  }

  AppUser _mapAndCacheUser(Map<String, dynamic> json) {
    final apiUser = AppUser.fromJson(json);
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
  }

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
          return itemsList.map((json) => _mapAndCacheUser(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[UserApiService] Lỗi kết nối getUsers: $e');
    }
    // Hoàn toàn không dùng mock fallback - trả về danh sách rỗng nếu lỗi kết nối
    return <AppUser>[];
  }

  /// Lấy toàn bộ tài khoản người dùng qua mọi trang (`pageSize=100`) phục vụ gán khảo sát / bộ chọn đầy đủ.
  Future<List<AppUser>> getAllUsers({
    String? token,
    bool? isStaffOnly,
    bool? isLocked,
    String? search,
    bool throwOnError = false,
  }) async {
    final List<AppUser> allUsers = [];
    int currentPage = 1;
    const int pageSize = 100;

    try {
      while (true) {
        final queryParams = <String, String>{
          'page': currentPage.toString(),
          'pageSize': pageSize.toString(),
        };
        if (isStaffOnly != null) queryParams['isStaffOnly'] = isStaffOnly.toString();
        if (isLocked != null) queryParams['isLocked'] = isLocked.toString();
        if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

        final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
        final response = await httpGet(uri, token: token);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          extractErrorMessage(response);
          if (throwOnError) {
            throw Exception(
              lastErrorMessage.isNotEmpty
                  ? lastErrorMessage
                  : 'Không thể tải danh sách người dùng (HTTP ${response.statusCode})',
            );
          }
          break;
        }

        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is! Map<String, dynamic> || jsonRes['success'] != true) {
          extractErrorMessage(response);
          if (throwOnError) {
            throw Exception(lastErrorMessage.isNotEmpty ? lastErrorMessage : 'Dữ liệu người dùng không hợp lệ.');
          }
          break;
        }

        lastErrorMessage = '';
        final data = jsonRes['data'];
        List itemsList = [];
        Map<String, dynamic>? meta;

        if (data is List) {
          itemsList = data;
        } else if (data is Map<String, dynamic>) {
          if (data['items'] is List) itemsList = data['items'] as List;
          if (data['meta'] is Map<String, dynamic>) meta = data['meta'] as Map<String, dynamic>;
        }

        final pageUsers = itemsList
            .whereType<Map<String, dynamic>>()
            .map(_mapAndCacheUser)
            .toList();
        allUsers.addAll(pageUsers);

        final totalPages = (meta?['totalPages'] as num?)?.toInt();
        final hasNext = meta?['hasNextPage'] == true ||
            (totalPages != null && currentPage < totalPages);

        if (!hasNext || pageUsers.isEmpty || currentPage >= 50) {
          break;
        }
        currentPage++;
      }
      return allUsers;
    } catch (e) {
      debugPrint('[UserApiService] Lỗi getAllUsers: $e');
      if (throwOnError) rethrow;
      return allUsers;
    }
  }

  Future<DemographicsReport> getDemographicsReport({String? token}) async {
    final response = await httpGet(
      Uri.parse('$baseUrl/users/demographics'),
      token: token,
    );
    final data = parseApiResponse(response);
    if (data is Map<String, dynamic>) {
      return DemographicsReport.fromJson(data);
    }
    throw Exception(
      lastErrorMessage.isNotEmpty
          ? lastErrorMessage
          : 'Không thể tải báo cáo nhân khẩu học (HTTP ${response.statusCode})',
    );
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
          'phone': user.phone.isNotEmpty ? user.phone : null,
          'techInterest': user.techInterest,
          'dateOfBirth': user.dateOfBirth != null
              ? JsonParseHelper.toUtcDateOnlyIsoString(user.dateOfBirth!)
              : null,
          'address': user.address,
          'roles': user.roles.isNotEmpty ? user.roles : [user.role],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo tài khoản thành công!');
      }

      if (response.statusCode == 400 || response.statusCode == 409) {
        return ApiResult(success: false, message: extractErrorMessage(response));
      }

      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('[UserApiService] Lỗi createUser: $e');
      return ApiResult(success: false, message: 'Không thể kết nối máy chủ để tạo tài khoản: $e');
    }
  }

  Future<ApiResult> updateUser(AppUser user, {String? token}) async {
    final oldUser = _userCache[user.id];

    try {
      final putResp = await httpPut(
        Uri.parse('$baseUrl/users/${user.id}'),
        token: token,
        body: json.encode({
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone.isNotEmpty ? user.phone : null,
          'dateOfBirth': user.dateOfBirth != null
              ? JsonParseHelper.toUtcDateOnlyIsoString(user.dateOfBirth!)
              : null,
          'techInterest': user.techInterest,
          'address': user.address,
          'roles': user.roles.isNotEmpty ? user.roles : [user.role],
        }),
      );

      if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
        return ApiResult(success: false, message: extractErrorMessage(putResp));
      }

      // Cập nhật trạng thái khóa nếu có thay đổi
      if (oldUser != null && oldUser.isLocked != user.isLocked) {
        final lockUpdated = await toggleUserLock(user.id, isLocked: user.isLocked, token: token);
        if (!lockUpdated) {
          // Hồ sơ đã được lưu ở bước PUT trên, giữ nguyên trạng thái khóa cũ trong cache
          _userCache[user.id] = AppUser(
            id: user.id,
            userName: user.userName,
            fullName: user.fullName,
            email: user.email,
            role: user.role,
            roles: user.roles,
            status: oldUser.status,
            isLocked: oldUser.isLocked,
            phone: user.phone,
            techInterest: user.techInterest,
            dateOfBirth: user.dateOfBirth,
            address: user.address,
            createdAt: user.createdAt,
          );
          notifyListeners();
          final detail = lastErrorMessage.isNotEmpty
              ? lastErrorMessage
              : 'không thể thay đổi trạng thái khóa.';
          return ApiResult(
            success: false,
            message: 'Đã lưu hồ sơ nhưng lỗi cập nhật trạng thái khóa: $detail',
          );
        }
      }

      _userCache[user.id] = user;
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
