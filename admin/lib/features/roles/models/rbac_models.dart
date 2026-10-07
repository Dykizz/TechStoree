import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Representation of a User Role in the system
class RoleModel {
  final String id;
  final String code; // ADMIN, SALES_STAFF, SURVEY_STAFF, USER, WAREHOUSE_STAFF
  final String name; // Vietnamese display name
  final String description;
  final IconData icon;
  final Color color;

  const RoleModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Representation of a Module / Feature area in the system
class ModuleModel {
  final String id; // products, promotions, vouchers, orders, warehouse, surveys, users
  final String name; // Vietnamese title
  final String description;
  final IconData icon;

  const ModuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Permission Action types
enum PermissionAction {
  read('read', 'Xem (Read)'),
  create('create', 'Thêm mới (Create)'),
  update('update', 'Chỉnh sửa (Update)'),
  delete('delete', 'Xóa (Delete)');

  final String key;
  final String label;
  const PermissionAction(this.key, this.label);
}

/// Mock initial data generator for Dynamic RBAC
class MockRbacData {
  /// 5 Database Roles as requested
  static const List<RoleModel> roles = [
    RoleModel(
      id: 'role_admin',
      code: 'ADMIN',
      name: 'Quản trị viên',
      description: 'Toàn quyền quản trị hệ thống, người dùng và cài đặt',
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.primary,
    ),
    RoleModel(
      id: 'role_sales',
      code: 'SALES_STAFF',
      name: 'Nhân viên bán hàng',
      description: 'Quản lý đơn hàng, mã giảm giá, khuyến mãi & xem SP',
      icon: Icons.point_of_sale_rounded,
      color: AppColors.success,
    ),
    RoleModel(
      id: 'role_survey',
      code: 'SURVEY_STAFF',
      name: 'Nhân viên khảo sát & CRM',
      description: 'Quản lý khảo sát thị trường và dữ liệu CRM khách hàng',
      icon: Icons.poll_rounded,
      color: AppColors.warning,
    ),
    RoleModel(
      id: 'role_warehouse',
      code: 'WAREHOUSE_STAFF',
      name: 'Nhân viên quản lý kho',
      description: 'Quản lý tồn kho, nhập hàng, sản phẩm và nhà cung cấp',
      icon: Icons.warehouse_rounded,
      color: Color(0xFF8B5CF6),
    ),
    RoleModel(
      id: 'role_user',
      code: 'USER',
      name: 'Khách hàng',
      description: 'Người dùng mua sắm thành viên giao diện Storefront',
      icon: Icons.person_rounded,
      color: Color(0xFF64748B),
    ),
  ];

  /// 7 Modules as requested
  static const List<ModuleModel> modules = [
    ModuleModel(
      id: 'products',
      name: 'Sản phẩm (Products)',
      description: 'Danh mục sản phẩm, biến thể, giá cả & hình ảnh',
      icon: Icons.inventory_2_outlined,
    ),
    ModuleModel(
      id: 'promotions',
      name: 'Khuyến mãi (Promotions)',
      description: 'Chương trình ưu đãi, giảm giá sản phẩm & banner',
      icon: Icons.local_offer_outlined,
    ),
    ModuleModel(
      id: 'vouchers',
      name: 'Mã giảm giá (Vouchers)',
      description: 'Tạo và quản lý voucher giảm giá đơn hàng',
      icon: Icons.confirmation_number_outlined,
    ),
    ModuleModel(
      id: 'orders',
      name: 'Đơn hàng (Orders)',
      description: 'Theo dõi, xử lý và cập nhật trạng thái đơn hàng',
      icon: Icons.shopping_bag_outlined,
    ),
    ModuleModel(
      id: 'warehouse',
      name: 'Quản lý kho (Warehouse)',
      description: 'Phiếu nhập hàng, tồn kho và nhà cung cấp',
      icon: Icons.domain_outlined,
    ),
    ModuleModel(
      id: 'surveys',
      name: 'Khảo sát & CRM (Surveys/CRM)',
      description: 'Khảo sát nhu cầu khách hàng và phân tích CRM',
      icon: Icons.rate_review_outlined,
    ),
    ModuleModel(
      id: 'users',
      name: 'Người dùng (Users)',
      description: 'Tài khoản nhân viên, phân quyền và khách hàng',
      icon: Icons.people_outline_rounded,
    ),
  ];

  /// Generate default permission key helper: e.g. "products:read"
  static String buildKey(String moduleId, PermissionAction action) {
    return '$moduleId:${action.key}';
  }

  /// Initial Mock Permission State mapping role code -> Set of permission keys
  static Map<String, Set<String>> getInitialRolePermissions() {
    final allKeys = <String>{};
    for (var m in modules) {
      for (var a in PermissionAction.values) {
        allKeys.add(buildKey(m.id, a));
      }
    }

    return {
      // ADMIN has full access across all 7 modules x 4 actions
      'ADMIN': Set<String>.from(allKeys),

      // SALES_STAFF:
      // Products: Read, Update
      // Orders: Full CRUD
      // Vouchers: Full CRUD
      // Promotions: Read, Create, Update
      // CRM/Surveys: Read
      // Users: Read
      'SALES_STAFF': {
        'products:read',
        'products:update',
        'orders:read',
        'orders:create',
        'orders:update',
        'orders:delete',
        'vouchers:read',
        'vouchers:create',
        'vouchers:update',
        'vouchers:delete',
        'promotions:read',
        'promotions:create',
        'promotions:update',
        'surveys:read',
        'users:read',
      },

      // SURVEY_STAFF:
      // Surveys & CRM: Full CRUD
      // Users: Read
      // Products: Read
      'SURVEY_STAFF': {
        'surveys:read',
        'surveys:create',
        'surveys:update',
        'surveys:delete',
        'users:read',
        'products:read',
      },

      // WAREHOUSE_STAFF:
      // Warehouse: Full CRUD
      // Products: Full CRUD
      // Orders: Read, Update
      'WAREHOUSE_STAFF': {
        'warehouse:read',
        'warehouse:create',
        'warehouse:update',
        'warehouse:delete',
        'products:read',
        'products:create',
        'products:update',
        'products:delete',
        'orders:read',
        'orders:update',
      },

      // USER (Customer):
      // Products: Read
      // Promotions: Read
      // Vouchers: Read
      'USER': {
        'products:read',
        'promotions:read',
        'vouchers:read',
      },
    };
  }
}
