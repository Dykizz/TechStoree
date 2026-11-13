// Mô hình dữ liệu Vai trò (Role) và Quyền hạn (Permission)
// Khớp với hợp đồng API Backend WebBanHang.Api
import '../utils/json_parse_helper.dart';

class RoleModel {
  final String roleId;
  final String roleName;
  final String? description;
  final bool isSystem;
  final int userCount;
  final List<String> permissions;

  const RoleModel({
    required this.roleId,
    required this.roleName,
    this.description,
    this.isSystem = false,
    this.userCount = 0,
    this.permissions = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: (json['roleId'] ?? json['id'] ?? '').toString(),
      roleName: (json['roleName'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      isSystem: JsonParseHelper.parseBool(json['isSystem']),
      userCount: JsonParseHelper.parseInt(json['userCount']),
      permissions: JsonParseHelper.parseStringList(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'roleName': roleName,
    'description': description,
    'isSystem': isSystem,
    'userCount': userCount,
    'permissions': permissions,
  };
}

class PermissionDetailModel {
  final String permissionId;
  final String permissionName;
  final String module;
  final String? description;
  final bool isReserved;
  final int endpointCount;
  final List<String> endpoints;

  const PermissionDetailModel({
    required this.permissionId,
    required this.permissionName,
    required this.module,
    this.description,
    this.isReserved = false,
    this.endpointCount = 0,
    this.endpoints = const [],
  });

  factory PermissionDetailModel.fromJson(Map<String, dynamic> json) {
    return PermissionDetailModel(
      permissionId: (json['permissionId'] ?? json['id'] ?? '').toString(),
      permissionName: (json['permissionName'] ?? json['name'] ?? '').toString(),
      module: (json['module'] ?? '').toString(),
      description: json['description']?.toString(),
      isReserved: JsonParseHelper.parseBool(json['isReserved']),
      endpointCount: JsonParseHelper.parseInt(json['endpointCount']),
      endpoints: JsonParseHelper.parseStringList(json['endpoints']),
    );
  }

  Map<String, dynamic> toJson() => {
    'permissionId': permissionId,
    'permissionName': permissionName,
    'module': module,
    'description': description,
    'isReserved': isReserved,
    'endpointCount': endpointCount,
    'endpoints': endpoints,
  };
}

class RoleDetailModel {
  final String roleId;
  final String roleName;
  final String? description;
  final bool isSystem;
  final int userCount;
  final List<String> permissions;
  final List<PermissionDetailModel> permissionDetails;

  const RoleDetailModel({
    required this.roleId,
    required this.roleName,
    this.description,
    this.isSystem = false,
    this.userCount = 0,
    this.permissions = const [],
    this.permissionDetails = const [],
  });

  factory RoleDetailModel.fromJson(Map<String, dynamic> json) {
    return RoleDetailModel(
      roleId: (json['roleId'] ?? json['id'] ?? '').toString(),
      roleName: (json['roleName'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      isSystem: JsonParseHelper.parseBool(json['isSystem']),
      userCount: JsonParseHelper.parseInt(json['userCount']),
      permissions: JsonParseHelper.parseStringList(json['permissions']),
      permissionDetails: JsonParseHelper.parseJsonList(
        json['permissionDetails'],
        PermissionDetailModel.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'roleName': roleName,
    'description': description,
    'isSystem': isSystem,
    'userCount': userCount,
    'permissions': permissions,
    'permissionDetails': permissionDetails.map((e) => e.toJson()).toList(),
  };
}

class ModulePermissionsModel {
  final String module;
  final List<PermissionDetailModel> permissions;

  const ModulePermissionsModel({
    required this.module,
    this.permissions = const [],
  });

  factory ModulePermissionsModel.fromJson(Map<String, dynamic> json) {
    return ModulePermissionsModel(
      module: (json['module'] ?? '').toString(),
      permissions: JsonParseHelper.parseJsonList(
        json['permissions'],
        PermissionDetailModel.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'module': module,
    'permissions': permissions.map((e) => e.toJson()).toList(),
  };
}
