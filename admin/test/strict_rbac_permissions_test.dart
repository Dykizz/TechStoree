import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/models/app_user.dart';
import 'package:techstore_admin/core/models/review.dart';
import 'package:techstore_admin/core/models/role.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/navigation_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/features/reviews/widgets/review_data_table.dart';
import 'package:techstore_admin/features/roles/roles_screen.dart';
import 'package:techstore_admin/features/staff/staff_screen.dart';

class _StrictAuthProvider extends AuthProvider {
  final Set<String> _perms;
  final String _roleValue;
  final bool _isAdminValue;

  _StrictAuthProvider({
    required Set<String> permissions,
    String role = 'ROLE_CUSTOM',
    bool isAdmin = false,
  })  : _perms = permissions.map((p) => p.toLowerCase()).toSet(),
        _roleValue = role,
        _isAdminValue = isAdmin;

  @override
  bool get isLoggedIn => true;

  @override
  String get userName => 'Tester';

  @override
  String get userEmail => 'tester@techstoree.vn';

  @override
  String get userRole => _roleValue;

  @override
  List<String> get userRoles => [_roleValue];

  @override
  bool get isAdmin => _isAdminValue;

  @override
  bool get isOfflineMode => false;

  @override
  String? get token => 'live-test-token';

  @override
  bool can(String permission) => _perms.contains(permission.trim().toLowerCase());

  @override
  void updatePermissions(List<String> newPermissions) {}

  @override
  Future<void> reloadCurrentPermissions({String? baseUrl}) async {}
}

class _FakeStrictApiService extends ApiService {
  int getUsersCalls = 0;
  int getAllEmployeesCalls = 0;
  int getAssignableRolesCalls = 0;
  int updateEmployeeCalls = 0;
  int updateEmployeeRolesCalls = 0;
  int toggleEmployeeLockCalls = 0;
  int assignPermissionsCalls = 0;
  int getRoleUsersCalls = 0;

  bool throwOnEmployees = false;
  List<String>? lastAssignedRoles;
  List<String>? lastSavedPermissions;
  String? lastSavedRoleId;

  final List<AppUser> employees = [
    AppUser(
      id: '10',
      userName: 'nhanvien01',
      fullName: 'Trần Văn Kho',
      email: 'kho01@techstoree.vn',
      role: 'WAREHOUSE_STAFF',
      roles: const ['WAREHOUSE_STAFF'],
      status: 'Hoạt động',
      isLocked: false,
      phone: '0901234567',
      createdAt: DateTime(2026, 10, 18),
    ),
  ];

  final List<RoleModel> rolesList = const [
    RoleModel(
      roleId: 'ADMIN',
      roleName: 'Quản trị viên',
      description: 'Quản trị hệ thống',
      isSystem: true,
      userCount: 1,
      permissions: ['Roles.View', 'Roles.Update', 'PurchaseOrders.View'],
    ),
    RoleModel(
      roleId: 'WAREHOUSE_STAFF',
      roleName: 'Thủ kho',
      description: 'Nhân viên kho',
      isSystem: true,
      userCount: 1,
      permissions: ['PurchaseOrders.View'],
    ),
  ];

  final List<ModulePermissionsModel> catalog = const [
    ModulePermissionsModel(
      module: 'Phân quyền hệ thống',
      permissions: [
        PermissionDetailModel(
          permissionId: 'Roles.View',
          permissionName: 'Xem vai trò',
          module: 'Phân quyền hệ thống',
          description: 'Xem vai trò',
        ),
        PermissionDetailModel(
          permissionId: 'Roles.Update',
          permissionName: 'Sửa vai trò',
          module: 'Phân quyền hệ thống',
          description: 'Sửa quyền',
        ),
      ],
    ),
    ModulePermissionsModel(
      module: 'Quản lý nhập hàng',
      permissions: [
        PermissionDetailModel(
          permissionId: 'PurchaseOrders.View',
          permissionName: 'Xem đơn nhập hàng',
          module: 'Quản lý nhập hàng',
          description: 'Xem phiếu nhập',
        ),
      ],
    ),
  ];

  @override
  Future<List<AppUser>> getUsers({String? token, bool? isStaffOnly}) async {
    getUsersCalls++;
    return const [];
  }

  @override
  Future<List<AppUser>> getAllEmployees({
    String? token,
    String? role,
    bool? isLocked,
    String? search,
    bool throwOnError = false,
  }) async {
    getAllEmployeesCalls++;
    if (throwOnEmployees) {
      throw Exception('Bạn không có quyền Employees.View');
    }
    return List<AppUser>.from(employees);
  }

  @override
  Future<List<RoleModel>> getAssignableRoles({String? token}) async {
    getAssignableRolesCalls++;
    return rolesList;
  }

  @override
  Future<ApiResult> updateEmployee(AppUser user, {String? token}) async {
    updateEmployeeCalls++;
    return ApiResult(success: true, message: 'OK');
  }

  @override
  Future<ApiResult> updateEmployeeRoles(String employeeId, List<String> roles, {String? token}) async {
    updateEmployeeRolesCalls++;
    lastAssignedRoles = List<String>.from(roles);
    return ApiResult(success: true, message: 'OK');
  }

  @override
  Future<bool> toggleEmployeeLock(String employeeId, {bool? isLocked, String? token}) async {
    toggleEmployeeLockCalls++;
    return true;
  }

  @override
  Future<List<RoleModel>> getRoles({String? token}) async => rolesList;

  @override
  Future<List<ModulePermissionsModel>> getPermissionCatalog({String? token}) async => catalog;

  @override
  Future<RoleDetailModel?> getRoleById(String roleId, {String? token}) async {
    final role = rolesList.firstWhere(
      (r) => r.roleId.toUpperCase() == roleId.toUpperCase(),
      orElse: () => rolesList.first,
    );
    return RoleDetailModel(
      roleId: role.roleId,
      roleName: role.roleName,
      description: role.description,
      isSystem: role.isSystem,
      userCount: role.userCount,
      permissions: role.permissions,
    );
  }

  @override
  Future<List<AppUser>> getRoleUsers(String roleId, {String? token}) async {
    getRoleUsersCalls++;
    return employees;
  }

  @override
  Future<ApiResult> assignPermissions(String roleId, List<String> permissionIds, {String? token}) async {
    assignPermissionsCalls++;
    lastSavedRoleId = roleId;
    lastSavedPermissions = List<String>.from(permissionIds);
    return ApiResult(success: true, message: 'Lưu phân quyền thành công!');
  }
}

Widget _wrap({
  required Widget child,
  required AuthProvider authProvider,
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('StaffScreen ignores Users.* and separates Employees.Update vs Employees.AssignRoles vs Employees.Lock', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Granting only Users.* does NOT unlock Create/Edit/Lock on StaffScreen
    final usersOnlyAuth = _StrictAuthProvider(
      permissions: const {'Employees.View', 'Users.Create', 'Users.Update', 'Users.Lock', 'Users.AssignRoles'},
    );
    final api = _FakeStrictApiService();

    await tester.pumpWidget(_wrap(child: const StaffScreen(), authProvider: usersOnlyAuth, apiService: api));
    await tester.pumpAndSettle();

    expect(api.getAllEmployeesCalls, 1);
    expect(api.getAssignableRolesCalls, 1);
    expect(api.getUsersCalls, 0);
    expect(find.text('Thêm nhân viên'), findsNothing);
    expect(find.byIcon(Icons.manage_accounts_outlined), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

    // 2. Granting Employees.View + Employees.Update (WITHOUT AssignRoles/Lock) allows updating profile only
    final updateOnlyAuth = _StrictAuthProvider(permissions: const {'Employees.View', 'Employees.Update'});
    await tester.pumpWidget(_wrap(child: const StaffScreen(), authProvider: updateOnlyAuth, apiService: api));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('Employees.AssignRoles'), findsOneWidget);
    expect(find.text('Khóa tài khoản này'), findsNothing);

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(api.updateEmployeeCalls, 1);
    expect(api.updateEmployeeRolesCalls, 0);
    expect(api.toggleEmployeeLockCalls, 0);
  });

  testWidgets('StaffScreen with Employees.AssignRoles only calls updateEmployeeRoles without calling updateEmployee', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final assignOnlyAuth = _StrictAuthProvider(permissions: const {'Employees.View', 'Employees.AssignRoles'});
    final api = _FakeStrictApiService();

    await tester.pumpWidget(_wrap(child: const StaffScreen(), authProvider: assignOnlyAuth, apiService: api));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();

    // Toggle a new role (ADMIN)
    await tester.tap(find.textContaining('ADMIN'));
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(api.updateEmployeeCalls, 0);
    expect(api.updateEmployeeRolesCalls, 1);
    expect(api.lastAssignedRoles, containsAll(const ['WAREHOUSE_STAFF', 'ADMIN']));
  });

  testWidgets('RolesScreen locks editing when missing Roles.Update and keeps ADMIN core Roles.* permissions protected', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // View-only Roles.View cannot edit or save
    final viewOnlyAuth = _StrictAuthProvider(permissions: const {'Roles.View'});
    final api = _FakeStrictApiService();

    await tester.pumpWidget(_wrap(child: const RolesScreen(), authProvider: viewOnlyAuth, apiService: api));
    await tester.pumpAndSettle();

    final selectAllBtn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Chọn tất cả'));
    expect(selectAllBtn.onPressed, isNull);

    // Switch to ADMIN and verify Roles.Update user can disable operational perm but never drop Roles.View/Roles.Update
    final updaterAuth = _StrictAuthProvider(permissions: const {'Roles.View', 'Roles.Update'});
    await tester.pumpWidget(_wrap(child: const RolesScreen(), authProvider: updaterAuth, apiService: api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quản trị viên').first);
    await tester.pumpAndSettle();

    final deselectAllFinder = find.widgetWithText(TextButton, 'Bỏ chọn tất cả');
    await tester.ensureVisible(deselectAllFinder);
    await tester.pumpAndSettle();
    await tester.tap(deselectAllFinder);
    await tester.pumpAndSettle();

    final saveFinder = find.text('Lưu thay đổi');
    await tester.ensureVisible(saveFinder);
    await tester.pumpAndSettle();
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    expect(api.assignPermissionsCalls, 1);
    expect(api.lastSavedRoleId, 'ADMIN');
    expect(api.lastSavedPermissions, containsAll(const ['Roles.View', 'Roles.Update']));
    expect(api.lastSavedPermissions, isNot(contains('PurchaseOrders.View')));

    // Drawer "người dùng sở hữu" uses getRoleUsers (Roles.View), not getUsers
    await tester.tap(find.textContaining('người dùng sở hữu'));
    await tester.pumpAndSettle();
    expect(api.getRoleUsersCalls, 1);
    expect(api.getUsersCalls, 0);
  });

  testWidgets('ReviewDataTable shows delete icon only when Reviews.Delete is granted', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleReview = ReviewItem(
      reviewId: 7,
      userId: 5,
      username: 'khachhang01',
      fullName: 'Nguyễn Văn Khách',
      email: 'khachhang01@gmail.com',
      productId: 1,
      productName: 'ASUS Zenbook 14 OLED',
      orderItemId: 10,
      orderId: 1,
      orderCode: 'ORD-001',
      variantId: 1,
      variantName: 'Ultra 5 / 16GB',
      rating: 4.0,
      comment: 'Ổn',
      isHidden: false,
      createdAt: DateTime(2026, 11, 1),
    );

    ReviewItem? deletedTarget;
    final api = _FakeStrictApiService();

    // Without Reviews.Delete -> no delete icon
    await tester.pumpWidget(
      _wrap(
        authProvider: _StrictAuthProvider(permissions: const {'Reviews.View', 'Reviews.Reply'}),
        apiService: api,
        child: ReviewDataTable(
          reviewsFuture: Future.value(ReviewPagedResult(items: [sampleReview], totalCount: 1, page: 1, pageSize: 10)),
          reviewsError: null,
          isActionBusy: false,
          currentPage: 1,
          itemsPerPage: 10,
          formatError: (_) => '',
          onRetry: () {},
          onPageChanged: (_) {},
          onItemsPerPageChanged: (_) {},
          onOpenReplyDialog: (_, {required canReply}) {},
          onToggleHideReview: (_) async {},
          onDeleteReview: (r) async => deletedTarget = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // With Reviews.Delete -> delete icon visible and works
    await tester.pumpWidget(
      _wrap(
        authProvider: _StrictAuthProvider(permissions: const {'Reviews.View', 'Reviews.Delete'}),
        apiService: api,
        child: ReviewDataTable(
          reviewsFuture: Future.value(ReviewPagedResult(items: [sampleReview], totalCount: 1, page: 1, pageSize: 10)),
          reviewsError: null,
          isActionBusy: false,
          currentPage: 1,
          itemsPerPage: 10,
          formatError: (_) => '',
          onRetry: () {},
          onPageChanged: (_) {},
          onItemsPerPageChanged: (_) {},
          onOpenReplyDialog: (_, {required canReply}) {},
          onToggleHideReview: (_) async {},
          onDeleteReview: (r) async => deletedTarget = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(deletedTarget?.reviewId, 7);
  });
}
