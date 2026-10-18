import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/role.dart';
import 'base_api_service.dart';

mixin RoleApiService on BaseApiService {
  /// 1. Lấy danh sách tất cả các vai trò
  Future<List<RoleModel>> getRoles({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/roles'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => RoleModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[RoleApiService] Lỗi getRoles: $e');
    }
    // Không dùng mock fallback - trả về danh sách rỗng nếu lỗi
    return [];
  }

  /// 2. Lấy danh mục tất cả các quyền hạn gom nhóm theo Module
  Future<List<ModulePermissionsModel>> getPermissionCatalog({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/roles/permissions'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data
            .map((json) => ModulePermissionsModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[RoleApiService] Lỗi getPermissionCatalog: $e');
    }
    return [];
  }

  /// 3. Lấy thông tin chi tiết và danh sách quyền của một vai trò
  Future<RoleDetailModel?> getRoleById(String roleId, {String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/roles/$roleId'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = parseApiResponse(response);
        if (data != null && data is Map<String, dynamic>) {
          return RoleDetailModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[RoleApiService] Lỗi getRoleById: $e');
    }
    return null;
  }

  /// 4. Tạo vai trò mới
  Future<ApiResult> createRole({
    required String roleName,
    String? roleId,
    String? description,
    required List<String> permissions,
    String? token,
  }) async {
    try {
      final payload = <String, dynamic>{
        'roleName': roleName.trim(),
        'permissions': permissions,
      };
      if (roleId != null && roleId.trim().isNotEmpty) {
        payload['roleId'] = roleId.trim().toUpperCase();
      }
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }

      final response = await httpPost(
        Uri.parse('$baseUrl/roles'),
        token: token,
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final data = parseApiResponse(response);
        return ApiResult(
          success: true,
          message: 'Tạo vai trò thành công!',
          data: data,
        );
      }
      return ApiResult(
        success: false,
        message: extractErrorMessage(response),
      );
    } catch (e) {
      debugPrint('[RoleApiService] Ngoại lệ createRole: $e');
      return ApiResult(
        success: false,
        message: 'Lỗi kết nối khi tạo vai trò: $e',
      );
    }
  }

  /// 5. Cập nhật thông tin vai trò (roleName, description, permissions)
  Future<ApiResult> updateRole(
    String roleId, {
    required String roleName,
    String? description,
    required List<String> permissions,
    String? token,
  }) async {
    try {
      final payload = <String, dynamic>{
        'roleName': roleName.trim(),
        'description': description?.trim(),
        'permissions': permissions,
      };

      final response = await httpPut(
        Uri.parse('$baseUrl/roles/$roleId'),
        token: token,
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final data = parseApiResponse(response);
        return ApiResult(
          success: true,
          message: 'Cập nhật thông tin vai trò thành công!',
          data: data,
        );
      }
      return ApiResult(
        success: false,
        message: extractErrorMessage(response),
      );
    } catch (e) {
      debugPrint('[RoleApiService] Ngoại lệ updateRole: $e');
      return ApiResult(
        success: false,
        message: 'Lỗi kết nối khi cập nhật vai trò: $e',
      );
    }
  }

  /// 6. Gán danh sách quyền hạn cho vai trò
  Future<ApiResult> assignPermissions(
    String roleId,
    List<String> permissionIds, {
    String? token,
  }) async {
    try {
      final response = await httpPut(
        Uri.parse('$baseUrl/roles/$roleId/permissions'),
        token: token,
        body: json.encode({
          'permissions': permissionIds,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final data = parseApiResponse(response);
        return ApiResult(
          success: true,
          message: 'Cập nhật quyền hạn thành công!',
          data: data,
        );
      }
      return ApiResult(
        success: false,
        message: extractErrorMessage(response),
      );
    } catch (e) {
      debugPrint('[RoleApiService] Ngoại lệ assignPermissions: $e');
      return ApiResult(
        success: false,
        message: 'Lỗi kết nối khi gán quyền hạn: $e',
      );
    }
  }

  /// 7. Xóa vai trò (chỉ hỗ trợ vai trò tùy chỉnh isSystem = false)
  Future<ApiResult> deleteRole(String roleId, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/roles/$roleId'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: 'Xóa vai trò thành công!',
        );
      }
      return ApiResult(
        success: false,
        message: extractErrorMessage(response),
      );
    } catch (e) {
      debugPrint('[RoleApiService] Ngoại lệ deleteRole: $e');
      return ApiResult(
        success: false,
        message: 'Lỗi kết nối khi xóa vai trò: $e',
      );
    }
  }
}
