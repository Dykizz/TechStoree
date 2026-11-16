import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/tech_interests.dart';
import '../models/app_user.dart';
import '../models/demographics_report.dart';
import '../models/role.dart';
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

  /// Lấy toàn bộ tài khoản người dùng qua mọi trang (`pageSize=100`) phục vụ quản trị nhân sự / tài khoản.
  Future<List<AppUser>> getAllUsers({
    String? token,
    bool? isStaffOnly,
    bool? isLocked,
    String? search,
    bool throwOnError = false,
  }) {
    return _fetchAllPagedAccounts(
      path: '$baseUrl/users',
      token: token,
      isStaffOnly: isStaffOnly,
      isLocked: isLocked,
      search: search,
      throwOnError: throwOnError,
      logLabel: 'getAllUsers',
    );
  }

  /// Lấy toàn bộ khách hàng qua mọi trang (`pageSize=100`) từ endpoint `GET /customers` (quyền `Customers.View`).
  Future<List<AppUser>> getAllCustomers({
    String? token,
    bool? isLocked,
    String? techInterest,
    String? search,
    bool throwOnError = false,
  }) {
    return _fetchAllPagedAccounts(
      path: '$baseUrl/customers',
      token: token,
      isLocked: isLocked,
      techInterest: techInterest,
      search: search,
      throwOnError: throwOnError,
      logLabel: 'getAllCustomers',
    );
  }

  /// Lấy toàn bộ nhân viên nội bộ qua mọi trang (`pageSize=100`) từ endpoint `GET /employees` (quyền `Employees.View`).
  Future<List<AppUser>> getAllEmployees({
    String? token,
    String? role,
    bool? isLocked,
    String? search,
    bool throwOnError = false,
  }) {
    return _fetchAllPagedAccounts(
      path: '$baseUrl/employees',
      token: token,
      role: role,
      isLocked: isLocked,
      search: search,
      throwOnError: throwOnError,
      logLabel: 'getAllEmployees',
    );
  }

  /// Lấy danh sách vai trò nhân sự phục vụ tạo mới / gán vai trò nhân viên (không đòi `Roles.View`).
  Future<List<RoleModel>> getAssignableRoles({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/employees/assignable-roles'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(RoleModel.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[UserApiService] Lỗi getAssignableRoles: $e');
    }
    return [];
  }

  Future<List<AppUser>> _fetchAllPagedAccounts({
    required String path,
    String? token,
    bool? isStaffOnly,
    String? role,
    bool? isLocked,
    String? techInterest,
    String? search,
    bool throwOnError = false,
    required String logLabel,
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
        if (role != null && role.trim().isNotEmpty) queryParams['role'] = role.trim();
        if (isLocked != null) queryParams['isLocked'] = isLocked.toString();
        if (techInterest != null && techInterest.trim().isNotEmpty) {
          queryParams['techInterest'] = techInterest.trim();
        }
        if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

        final uri = Uri.parse(path).replace(queryParameters: queryParams);
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
      debugPrint('[UserApiService] Lỗi $logLabel: $e');
      if (throwOnError) rethrow;
      return allUsers;
    }
  }

  Future<DemographicsReport> getDemographicsReport({String? token}) async {
    final response = await httpGet(
      Uri.parse('$baseUrl/customers/demographics'),
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

  Future<ApiResult> createUser(AppUser user, String password, {String? token}) {
    return _createAccount(
      endpoint: '$baseUrl/users',
      user: user,
      password: password,
      includeRoles: true,
      token: token,
      logLabel: 'createUser',
    );
  }

  Future<ApiResult> createCustomer(AppUser user, String password, {String? token}) {
    return _createAccount(
      endpoint: '$baseUrl/customers',
      user: user,
      password: password,
      includeRoles: false,
      token: token,
      logLabel: 'createCustomer',
    );
  }

  Future<ApiResult> createEmployee(AppUser user, String password, {String? token}) {
    return _createAccount(
      endpoint: '$baseUrl/employees',
      user: user,
      password: password,
      includeRoles: true,
      token: token,
      logLabel: 'createEmployee',
    );
  }

  Future<ApiResult> _createAccount({
    required String endpoint,
    required AppUser user,
    required String password,
    required bool includeRoles,
    String? token,
    required String logLabel,
  }) async {
    try {
      final payload = <String, dynamic>{
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
      };
      if (includeRoles) {
        payload['roles'] = user.roles.isNotEmpty ? user.roles : [user.role];
      }

      final response = await httpPost(
        Uri.parse(endpoint),
        token: token,
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo tài khoản thành công!');
      }

      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('[UserApiService] Lỗi $logLabel: $e');
      return ApiResult(success: false, message: 'Không thể kết nối máy chủ để tạo tài khoản: $e');
    }
  }

  Future<ApiResult> updateUser(AppUser user, {String? token}) {
    return _updateAccount(
      endpoint: '$baseUrl/users/${user.id}',
      lockEndpoint: '$baseUrl/users/${user.id}/toggle-lock',
      user: user,
      includeRoles: true,
      clearEmptyOptionalFields: false,
      token: token,
      logLabel: 'updateUser',
    );
  }

  Future<ApiResult> updateCustomer(AppUser user, {String? token}) {
    return _updateAccount(
      endpoint: '$baseUrl/customers/${user.id}',
      lockEndpoint: '$baseUrl/customers/${user.id}/toggle-lock',
      user: user,
      includeRoles: false,
      clearEmptyOptionalFields: true,
      token: token,
      logLabel: 'updateCustomer',
    );
  }

  Future<ApiResult> updateEmployee(AppUser user, {String? token}) {
    return _updateAccount(
      endpoint: '$baseUrl/employees/${user.id}',
      lockEndpoint: '$baseUrl/employees/${user.id}/toggle-lock',
      user: user,
      includeRoles: false,
      clearEmptyOptionalFields: false,
      syncLockOnPut: false,
      token: token,
      logLabel: 'updateEmployee',
    );
  }

  Future<ApiResult> _updateAccount({
    required String endpoint,
    required String lockEndpoint,
    required AppUser user,
    required bool includeRoles,
    required bool clearEmptyOptionalFields,
    bool syncLockOnPut = true,
    String? token,
    required String logLabel,
  }) async {
    final oldUser = _userCache[user.id];

    try {
      final payload = <String, dynamic>{
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone.isNotEmpty ? user.phone : (clearEmptyOptionalFields ? '' : null),
        'dateOfBirth': user.dateOfBirth != null
            ? JsonParseHelper.toUtcDateOnlyIsoString(user.dateOfBirth!)
            : null,
        'techInterest': clearEmptyOptionalFields ? (user.techInterest ?? '') : user.techInterest,
        'address': clearEmptyOptionalFields ? (user.address ?? '') : user.address,
      };
      if (includeRoles) {
        payload['roles'] = user.roles.isNotEmpty ? user.roles : [user.role];
      }

      final putResp = await httpPut(
        Uri.parse(endpoint),
        token: token,
        body: json.encode(payload),
      );

      if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
        return ApiResult(success: false, message: extractErrorMessage(putResp));
      }

      // Cập nhật trạng thái khóa nếu luồng gọi cho phép đồng bộ lock trong PUT
      if (syncLockOnPut && oldUser != null && oldUser.isLocked != user.isLocked) {
        final lockUpdated = await _toggleAccountLock(
          endpoint: lockEndpoint,
          userId: user.id,
          isLocked: user.isLocked,
          token: token,
          logLabel: logLabel,
        );
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
      debugPrint('[UserApiService] Lỗi $logLabel: $e');
      return ApiResult(success: false, message: 'Lỗi cập nhật người dùng: $e');
    }
  }

  Future<bool> toggleUserLock(String userId, {bool? isLocked, String? token}) {
    return _toggleAccountLock(
      endpoint: '$baseUrl/users/$userId/toggle-lock',
      userId: userId,
      isLocked: isLocked,
      token: token,
      logLabel: 'toggleUserLock',
    );
  }

  Future<bool> toggleCustomerLock(String customerId, {bool? isLocked, String? token}) {
    return _toggleAccountLock(
      endpoint: '$baseUrl/customers/$customerId/toggle-lock',
      userId: customerId,
      isLocked: isLocked,
      token: token,
      logLabel: 'toggleCustomerLock',
    );
  }

  Future<bool> toggleEmployeeLock(String employeeId, {bool? isLocked, String? token}) {
    return _toggleAccountLock(
      endpoint: '$baseUrl/employees/$employeeId/toggle-lock',
      userId: employeeId,
      isLocked: isLocked,
      token: token,
      logLabel: 'toggleEmployeeLock',
    );
  }

  Future<bool> _toggleAccountLock({
    required String endpoint,
    required String userId,
    bool? isLocked,
    String? token,
    required String logLabel,
  }) async {
    try {
      final body = isLocked != null ? json.encode({'isLocked': isLocked}) : null;
      final response = await httpPatch(
        Uri.parse(endpoint),
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
      debugPrint('[UserApiService] Lỗi $logLabel: $e');
    }
    return false;
  }

  Future<ApiResult> updateEmployeeRoles(String employeeId, List<String> roles, {String? token}) async {
    final primaryRole = roles.isNotEmpty ? roles.first : 'SALES_STAFF';
    try {
      final response = await httpPatch(
        Uri.parse('$baseUrl/employees/$employeeId/role'),
        token: token,
        body: json.encode({
          'roles': roles,
          'roleId': primaryRole,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final existing = _userCache[employeeId];
        if (existing != null) {
          _userCache[employeeId] = AppUser(
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
        }
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật vai trò nhân viên thành công!');
      }

      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('[UserApiService] Lỗi updateEmployeeRoles: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối khi phân vai trò: $e');
    }
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
