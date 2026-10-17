import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/role.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import 'role_form_dialog.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  bool _initialized = false;
  bool _isLoadingRoles = false;
  bool _isLoadingCatalog = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;

  List<RoleModel> _roles = [];
  List<ModulePermissionsModel> _permissionModules = [];
  String? _selectedRoleId;
  RoleDetailModel? _currentRoleDetail;

  // Selected permission IDs for the currently active role
  final Set<String> _selectedPermissions = {};
  // Saved original snapshot to detect dirty state and support Undo
  final Set<String> _originalPermissions = {};

  final TextEditingController _searchRoleController = TextEditingController();
  final TextEditingController _searchPermController = TextEditingController();
  String _roleSearchQuery = '';
  String _permSearchQuery = '';

  // Track expanded state for each module accordion
  final Map<String, bool> _expandedModules = {};

  @override
  void initState() {
    super.initState();
    _searchRoleController.addListener(() {
      setState(() {
        _roleSearchQuery = _searchRoleController.text.trim().toLowerCase();
      });
    });
    _searchPermController.addListener(() {
      setState(() {
        _permSearchQuery = _searchPermController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lazy load: Chỉ gọi API khi tab được chọn lần đầu tiên để tránh eager load thừa từ IndexedStack
    final navProvider = Provider.of<NavigationProvider>(context);
    if (!_initialized && navProvider.currentIndex == 10) {
      _initialized = true;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchRoleController.dispose();
    _searchPermController.dispose();
    super.dispose();
  }

  /// Các vai trò hệ thống không hiển thị trong màn hình phân quyền:
  /// - ADMIN: Toàn quyền tối cao trong hệ thống, không cần/không thể sửa phân quyền.
  /// - USER / CUSTOMER: Khách hàng mua sắm, không có quyền quản lý hệ thống.
  static bool _isManageableRole(RoleModel r) {
    final id = r.roleId.trim().toUpperCase();
    return id != 'ADMIN' && id != 'USER' && id != 'CUSTOMER';
  }

  /// Tải danh mục quyền hạn và danh sách vai trò từ backend
  Future<void> _loadInitialData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    setState(() {
      _isLoadingRoles = true;
      _isLoadingCatalog = true;
    });

    final futures = await Future.wait([
      apiService.getRoles(token: token),
      apiService.getPermissionCatalog(token: token),
    ]);

    if (!mounted) return;

    final rolesList = futures[0] as List<RoleModel>;
    final catalogList = futures[1] as List<ModulePermissionsModel>;

    // Lọc bỏ vai trò ADMIN (toàn quyền) và USER/CUSTOMER (khách hàng không có quyền quản lý)
    final manageableRoles = rolesList.where(_isManageableRole).toList();

    setState(() {
      _roles = manageableRoles;
      _permissionModules = catalogList;
      _isLoadingRoles = false;
      _isLoadingCatalog = false;

      // Mặc định mở tất cả các module accordion
      for (var m in _permissionModules) {
        _expandedModules[m.module] = true;
      }
    });

    // Tự động chọn vai trò đầu tiên nếu có
    if (_roles.isNotEmpty) {
      final defaultRole = _roles.firstWhere(
        (r) => r.roleId.toUpperCase() == 'SALES_STAFF',
        orElse: () => _roles.first,
      );
      _selectRole(defaultRole.roleId);
    }
  }

  /// Tải lại danh sách vai trò
  Future<void> _refreshRoles({String? selectRoleId}) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    setState(() => _isLoadingRoles = true);
    final rolesList = await apiService.getRoles(token: token);

    if (!mounted) return;

    final manageableRoles = rolesList.where(_isManageableRole).toList();

    setState(() {
      _roles = manageableRoles;
      _isLoadingRoles = false;
    });

    final targetId = selectRoleId ?? _selectedRoleId;
    if (targetId != null && _roles.any((r) => r.roleId == targetId)) {
      _selectRole(targetId, force: true);
    } else if (_roles.isNotEmpty) {
      _selectRole(_roles.first.roleId, force: true);
    } else {
      setState(() {
        _selectedRoleId = null;
        _selectedPermissions.clear();
        _originalPermissions.clear();
      });
    }
  }

  /// Kiểm tra xem vai trò hiện tại có thay đổi chưa lưu hay không
  bool get _isCurrentRoleDirty {
    if (_selectedPermissions.length != _originalPermissions.length) return true;
    return !_selectedPermissions.containsAll(_originalPermissions);
  }

  RoleModel? get _currentRole {
    if (_selectedRoleId == null) return null;
    try {
      return _roles.firstWhere(
        (r) => r.roleId.toUpperCase() == _selectedRoleId!.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get _isCurrentRoleAdmin {
    return _selectedRoleId?.toUpperCase() == 'ADMIN';
  }

  int get _totalAllPermissionsCount {
    int total = 0;
    for (var m in _permissionModules) {
      total += m.permissions.length;
    }
    return total;
  }

  /// Chọn một vai trò để xem chi tiết
  Future<void> _selectRole(String roleId, {bool force = false}) async {
    if (!force && roleId == _selectedRoleId) return;

    // Kiểm tra dirty state trước khi chuyển vai trò
    if (!force && _isCurrentRoleDirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thay đổi chưa được lưu'),
          content: Text(
            'Bạn có các phân quyền chưa lưu cho vai trò "${_currentRole?.roleName ?? _selectedRoleId}". '
            'Bạn có chắc chắn muốn bỏ qua các thay đổi này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Ở lại lưu'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Bỏ qua thay đổi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }

    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    setState(() {
      _selectedRoleId = roleId;
      _isLoadingDetail = true;
    });

    final detail = await apiService.getRoleById(roleId, token: token);

    if (!mounted) return;
    setState(() {
      _currentRoleDetail = detail;
      _selectedPermissions.clear();
      _originalPermissions.clear();

      if (detail != null) {
        _selectedPermissions.addAll(detail.permissions);
        _originalPermissions.addAll(detail.permissions);
      } else {
        // Fallback đọc permissions từ RoleModel nếu endpoint roleId gặp lỗi tạm thời
        final role = _currentRole;
        if (role != null) {
          _selectedPermissions.addAll(role.permissions);
          _originalPermissions.addAll(role.permissions);
        }
      }
      _isLoadingDetail = false;
    });
  }

  /// Hoàn tác các thay đổi trên vai trò hiện tại
  void _revertChanges() {
    setState(() {
      _selectedPermissions.clear();
      _selectedPermissions.addAll(_originalPermissions);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã hoàn tác các thay đổi phân quyền!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Lưu thay đổi quyền hạn xuống backend: PUT /roles/{id}/permissions
  Future<void> _savePermissions() async {
    if (_selectedRoleId == null || !_isCurrentRoleDirty || _isCurrentRoleAdmin) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang ở chế độ Offline — không thể quản lý phân quyền!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = authProvider.token;

    setState(() => _isSaving = true);

    final result = await apiService.assignPermissions(
      _selectedRoleId!,
      _selectedPermissions.toList(),
      token: token,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      setState(() {
        _originalPermissions.clear();
        _originalPermissions.addAll(_selectedPermissions);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message.isNotEmpty ? result.message : 'Lưu phân quyền thành công!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Cập nhật lại danh sách role bên trái để đồng bộ số quyền hiển thị
      _refreshRoles(selectRoleId: _selectedRoleId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Mở dialog tạo vai trò mới
  void _openCreateRoleDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.can('Roles.Create') || authProvider.isOfflineMode) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoleFormDialog(
        apiService: apiService,
        token: authProvider.token,
        permissionModules: _permissionModules,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo vai trò mới thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          _refreshRoles();
        },
      ),
    );
  }

  /// Mở dialog sửa vai trò hiện tại
  void _openEditRoleDialog() {
    final role = _currentRole;
    if (role == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.can('Roles.Update') || authProvider.isOfflineMode) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoleFormDialog(
        apiService: apiService,
        token: authProvider.token,
        existingRole: role,
        permissionModules: _permissionModules,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin vai trò thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          _refreshRoles(selectRoleId: role.roleId);
        },
      ),
    );
  }

  /// Xóa vai trò (chỉ mở cho vai trò tùy chỉnh isSystem = false)
  Future<void> _confirmDeleteRole() async {
    final role = _currentRole;
    if (role == null || role.isSystem) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.can('Roles.Delete') || authProvider.isOfflineMode) return;

    final nameConfirmController = TextEditingController();
    bool isMatch = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                const SizedBox(width: 8),
                Text('Xác nhận xóa vai trò: ${role.roleName}'),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thao tác này sẽ xóa hoàn toàn vai trò này khỏi hệ thống và không thể hoàn tác.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Vui lòng nhập chính xác tên vai trò "'),
                        TextSpan(
                          text: role.roleName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                        const TextSpan(text: '" để xác nhận:'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameConfirmController,
                    onChanged: (val) {
                      setDialogState(() {
                        isMatch = val.trim() == role.roleName.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: role.roleName,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy bỏ'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: isMatch ? () => Navigator.of(ctx).pop(true) : null,
                child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.deleteRole(role.roleId, token: authProvider.token);

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa vai trò thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshRoles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Lọc danh sách vai trò theo search (chỉ giữ vai trò quản lý có thể phân quyền)
    final filteredRoles = _roles.where((r) {
      if (!_isManageableRole(r)) return false;
      if (_roleSearchQuery.isEmpty) return true;
      return r.roleName.toLowerCase().contains(_roleSearchQuery) ||
          r.roleId.toLowerCase().contains(_roleSearchQuery);
    }).toList();

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vai Trò & Phân Quyền (RBAC)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Quản lý vai trò nhân viên & thiết lập ma trận phân quyền chi tiết theo từng module hệ thống',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                // Nút [+ Thêm vai trò] (chỉ bật khi có quyền Roles.Create và không offline)
                AppButton(
                  label: 'Thêm vai trò',
                  icon: Icons.add_moderator_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: (authProvider.can('Roles.Create') && !authProvider.isOfflineMode)
                      ? _openCreateRoleDialog
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tải lại dữ liệu',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => _refreshRoles(),
                ),
              ],
            ),
          ),

          // Offline Warning Banner (nếu đang ở chế độ mock JWT)
          if (authProvider.isOfflineMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.warningBg,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Đang ở chế độ Offline (Mock Token) — Mọi chức năng lưu phân quyền tạm thời bị khóa.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Master-Detail Workspace
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // PANEL TRÁI: DANH SÁCH VAI TRÒ (310px)
                // ==========================================
                Container(
                  width: 310,
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    children: [
                      // Role list search input
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchRoleController,
                          style: TextStyle(fontSize: 12.5, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc mã vai trò...',
                            hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                      Divider(color: borderColor, height: 1),

                      // Role list items
                      Expanded(
                        child: _isLoadingRoles
                            ? const Center(child: CircularProgressIndicator())
                            : filteredRoles.isEmpty
                                ? Center(
                                    child: Text(
                                      'Không tìm thấy vai trò nào',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filteredRoles.length,
                                    separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                                    itemBuilder: (context, index) {
                                      final role = filteredRoles[index];
                                      final isSelected = role.roleId.toUpperCase() ==
                                          _selectedRoleId?.toUpperCase();
                                      final isDirty = isSelected && _isCurrentRoleDirty;

                                      return InkWell(
                                        onTap: () => _selectRole(role.roleId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isDark
                                                    ? AppColors.primary.withValues(alpha: 0.15)
                                                    : const Color(0xFFEFF6FF))
                                                : Colors.transparent,
                                            border: Border(
                                              left: BorderSide(
                                                color: isSelected ? AppColors.primary : Colors.transparent,
                                                width: 3.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Status icon / radio
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Icon(
                                                  isSelected
                                                      ? Icons.radio_button_checked_rounded
                                                      : Icons.radio_button_off_rounded,
                                                  size: 17,
                                                  color: isSelected ? AppColors.primary : textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            role.roleName,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                              color: isSelected ? AppColors.primary : textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isDirty)
                                                          Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration: const BoxDecoration(
                                                              color: AppColors.warning,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    // Role ID and badge
                                                    Row(
                                                      children: [
                                                        Text(
                                                          role.roleId,
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            fontFamily: 'monospace',
                                                            color: textSecondary,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        // Badge Hệ thống / Tùy chỉnh
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: role.isSystem
                                                                ? (isDark
                                                                    ? const Color(0xFF1E293B)
                                                                    : const Color(0xFFF1F5F9))
                                                                : AppColors.successBg,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(
                                                              color: role.isSystem
                                                                  ? borderColor
                                                                  : AppColors.successBorder,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            role.isSystem ? 'Hệ thống' : 'Tùy chỉnh',
                                                            style: TextStyle(
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: role.isSystem
                                                                  ? textSecondary
                                                                  : AppColors.success,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    // Numbers
                                                    Text(
                                                      '${isSelected ? _selectedPermissions.length : role.permissions.length} quyền · ${role.userCount} người dùng',
                                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // PANEL PHẢI: MA TRẬN PHÂN QUYỀN (CHI TIẾT)
                // ==========================================
                Expanded(
                  child: _selectedRoleId == null
                      ? Center(
                          child: Text(
                            'Chọn một vai trò ở danh sách bên trái để xem và thiết lập phân quyền',
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        )
                      : _isLoadingCatalog || _isLoadingDetail
                          ? const Center(child: CircularProgressIndicator())
                          : _buildPermissionMatrixWorkspace(
                              context,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Render không gian làm việc chi tiết của vai trò được chọn
  Widget _buildPermissionMatrixWorkspace(
    BuildContext context, {
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final role = _currentRole;
    if (role == null) return const SizedBox.shrink();
    final displayDesc = _currentRoleDetail?.description ?? role.description;

    final authProvider = Provider.of<AuthProvider>(context);
    final isAdminRole = _isCurrentRoleAdmin;
    final isOffline = authProvider.isOfflineMode;

    // Lọc quyền theo query
    final filteredModules = _permissionModules.map((m) {
      if (_permSearchQuery.isEmpty) return m;
      final matchingPerms = m.permissions.where((p) {
        return p.permissionName.toLowerCase().contains(_permSearchQuery) ||
            p.permissionId.toLowerCase().contains(_permSearchQuery) ||
            (p.description != null && p.description!.toLowerCase().contains(_permSearchQuery)) ||
            m.module.toLowerCase().contains(_permSearchQuery);
      }).toList();
      return ModulePermissionsModel(module: m.module, permissions: matchingPerms);
    }).where((m) => m.permissions.isNotEmpty).toList();

    return Column(
      children: [
        // Role Detail Header & Actions Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          role.roleName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            role.roleId,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: role.isSystem
                                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
                                : AppColors.successBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: role.isSystem ? borderColor : AppColors.successBorder,
                            ),
                          ),
                          child: Text(
                            role.isSystem ? 'Hệ thống' : 'Tùy chỉnh',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: role.isSystem ? textSecondary : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${role.userCount} người dùng sở hữu',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Nút sửa thông tin
                  AppButton(
                    label: 'Sửa thông tin',
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: (authProvider.can('Roles.Update') && !isOffline)
                        ? _openEditRoleDialog
                        : null,
                  ),
                  const SizedBox(width: 8),

                  // Nút xóa vai trò (chỉ enable khi isSystem == false)
                  Tooltip(
                    message: role.isSystem
                        ? 'Không thể xóa vai trò mặc định của hệ thống'
                        : 'Xóa vĩnh viễn vai trò này',
                    child: AppButton(
                      label: 'Xóa vai trò',
                      icon: Icons.delete_outline_rounded,
                      variant: AppButtonVariant.danger,
                      onPressed: (!role.isSystem && authProvider.can('Roles.Delete') && !isOffline)
                          ? _confirmDeleteRole
                          : null,
                    ),
                  ),
                ],
              ),
              if (displayDesc != null && displayDesc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  displayDesc,
                  style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),

        // Banner Cảnh báo nếu là vai trò ADMIN
        if (isAdminRole)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🔒 Quản trị viên tối cao luôn có toàn quyền và không thể chỉnh sửa danh sách quyền hạn.',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Ghi chú thời hạn hiệu lực JWT (60 phút)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ℹ️ Thay đổi quyền có hiệu lực với phiên đăng nhập mới. Người dùng đang hoạt động cần đăng nhập lại (tối đa 60 phút).',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ),
            ],
          ),
        ),
        Divider(color: borderColor, height: 1),

        // Toolbar tìm kiếm quyền và chọn tất cả
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchPermController,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên quyền, mã quyền, hoặc tên module...',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Đếm số quyền đã chọn
              Text(
                'Tổng: ${_selectedPermissions.length} / $_totalAllPermissionsCount quyền',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 12),

              // Chọn tất cả
              TextButton(
                onPressed: (isAdminRole || isOffline)
                    ? null
                    : () {
                        setState(() {
                          for (var m in _permissionModules) {
                            for (var p in m.permissions) {
                              _selectedPermissions.add(p.permissionId);
                            }
                          }
                        });
                      },
                child: const Text('Chọn tất cả', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),

              // Bỏ chọn tất cả
              TextButton(
                onPressed: (isAdminRole || isOffline)
                    ? null
                    : () {
                        setState(() {
                          _selectedPermissions.clear();
                        });
                      },
                child: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        // Accordion danh mục 10 Module
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredModules.length,
            itemBuilder: (context, index) {
              final module = filteredModules[index];
              final isExpanded = _expandedModules[module.module] ?? true;
              final selectedInModule = module.permissions
                  .where((p) => _selectedPermissions.contains(p.permissionId))
                  .length;
              final totalInModule = module.permissions.length;
              final isAllModuleSelected = selectedInModule == totalInModule && totalInModule > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Header của Module
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedModules[module.module] = !isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_right_rounded,
                              size: 20,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                module.module,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            // Badge đếm số quyền trong module (vd 2/3)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: selectedInModule > 0
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$selectedInModule / $totalInModule ☑',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: selectedInModule > 0 ? AppColors.primary : textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Quick toggle toàn bộ module
                            Checkbox(
                              value: isAllModuleSelected,
                              tristate: selectedInModule > 0 && !isAllModuleSelected,
                              onChanged: (isAdminRole || isOffline)
                                  ? null
                                  : (val) {
                                      setState(() {
                                        if (val == true) {
                                          for (var p in module.permissions) {
                                            _selectedPermissions.add(p.permissionId);
                                          }
                                        } else {
                                          for (var p in module.permissions) {
                                            _selectedPermissions.remove(p.permissionId);
                                          }
                                        }
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Children permissions
                    if (isExpanded) ...[
                      Divider(color: borderColor, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: module.permissions.map((perm) {
                            final isChecked = _selectedPermissions.contains(perm.permissionId);
                            final canToggle = !isAdminRole && !isOffline;

                            return Container(
                              width: 380,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? (isDark
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : const Color(0xFFF8FAFC))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : borderColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: isChecked,
                                        onChanged: canToggle
                                            ? (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedPermissions.add(perm.permissionId);
                                                  } else {
                                                    _selectedPermissions.remove(perm.permissionId);
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                perm.permissionName,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                            // Reserved warning badge (Chưa áp dụng)
                                            if (perm.isReserved)
                                              Tooltip(
                                                message:
                                                    'Quyền đã khai báo nhưng chưa gắn vào API nào — gán được nhưng hiện chưa có tác dụng.',
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warningBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppColors.warningBorder),
                                                  ),
                                                  child: const Text(
                                                    'Chưa áp dụng',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.warning,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              perm.permissionId,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontFamily: 'monospace',
                                                color: textSecondary,
                                              ),
                                            ),
                                            if (perm.endpointCount > 0) ...[
                                              const SizedBox(width: 6),
                                              Tooltip(
                                                message:
                                                    'Bảo vệ: ${perm.endpoints.join(', ')}',
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color(0xFF1E293B)
                                                        : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    '${perm.endpointCount} endpoint',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (perm.description != null && perm.description!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            perm.description!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Sticky Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              if (_isCurrentRoleDirty)
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Có thay đổi phân quyền chưa được lưu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Đã đồng bộ với máy chủ',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              const Spacer(),

              // Nút Hoàn tác
              AppButton(
                label: 'Hoàn tác',
                icon: Icons.undo_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: (_isCurrentRoleDirty && !isAdminRole && !isOffline && !_isSaving)
                    ? _revertChanges
                    : null,
              ),
              const SizedBox(width: 10),

              // Nút Lưu thay đổi
              AppButton(
                label: 'Lưu thay đổi',
                icon: Icons.save_rounded,
                variant: AppButtonVariant.primary,
                isLoading: _isSaving,
                onPressed: (_isCurrentRoleDirty && !isAdminRole && !isOffline && !_isSaving)
                    ? _savePermissions
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
