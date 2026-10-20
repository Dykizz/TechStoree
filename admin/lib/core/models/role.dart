// Mô hình dữ liệu Vai trò (Role) và Quyền hạn (Permission)
// Khớp với hợp đồng API Backend WebBanHang.Api

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
      roleId: (json['roleId'] ?? json['id'] ?? '') as String,
      roleName: (json['roleName'] ?? json['name'] ?? '') as String,
      description: json['description'] as String?,
      isSystem: json['isSystem'] == true,
      userCount: (json['userCount'] is num) ? (json['userCount'] as num).toInt() : 0,
      permissions: (json['permissions'] is List)
          ? List<String>.from(json['permissions'].map((e) => e.toString()))
          : const [],
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
      permissionId: (json['permissionId'] ?? json['id'] ?? '') as String,
      permissionName: (json['permissionName'] ?? json['name'] ?? '') as String,
      module: (json['module'] ?? '') as String,
      description: json['description'] as String?,
      isReserved: json['isReserved'] == true,
      endpointCount: (json['endpointCount'] is num) ? (json['endpointCount'] as num).toInt() : 0,
      endpoints: (json['endpoints'] is List)
          ? List<String>.from(json['endpoints'].map((e) => e.toString()))
          : const [],
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
      roleId: (json['roleId'] ?? json['id'] ?? '') as String,
      roleName: (json['roleName'] ?? json['name'] ?? '') as String,
      description: json['description'] as String?,
      isSystem: json['isSystem'] == true,
      userCount: (json['userCount'] is num) ? (json['userCount'] as num).toInt() : 0,
      permissions: (json['permissions'] is List)
          ? List<String>.from(json['permissions'].map((e) => e.toString()))
          : const [],
      permissionDetails: (json['permissionDetails'] is List)
          ? (json['permissionDetails'] as List)
              .map((e) => PermissionDetailModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
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
      module: (json['module'] ?? '') as String,
      permissions: (json['permissions'] is List)
          ? (json['permissions'] as List)
              .map((e) => PermissionDetailModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'module': module,
    'permissions': permissions.map((e) => e.toJson()).toList(),
  };
}
