import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_user.dart';
import '../../core/models/role.dart';
import '../../core/providers/auth_provider.dart';
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
  // Chế độ xem: true = Bảng Ma Trận CRUD 2D, false = Dạng Thẻ Chi Tiết
  bool _isMatrixView = true;

  List<RoleModel> _roles = [];
  List<ModulePermissionsModel> _permissionModules = [];
  String? _selectedRoleId;
  RoleDetailModel? _currentRoleDetail;

  // Danh sách quyền đang chọn cho vai trò hiện tại
  final Set<String> _selectedPermissions = {};
  // Bản sao gốc để kiểm tra trạng thái thay đổi (dirty) và hỗ trợ hoàn tác
  final Set<String> _originalPermissions = {};

  final TextEditingController _searchRoleController = TextEditingController();
  final TextEditingController _searchPermController = TextEditingController();
  String _roleSearchQuery = '';
  String _permSearchQuery = '';

  // Trạng thái mở rộng accordion từng module
  final Map<String, bool> _expandedModules = {};

  // Bộ lọc module theo Tab/Chip ('ALL' hoặc tên module cụ thể)
  String _selectedModuleFilter = 'ALL';

  // Bộ lọc trạng thái quyền: 'ALL', 'GRANTED' (đã cấp), 'NOT_GRANTED' (chưa cấp)
  String _statusFilter = 'ALL';

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
    if (!_initialized) {
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

  /// Các vai trò không hiển thị trong màn hình phân quyền:
  /// - USER / CUSTOMER: Khách hàng mua sắm, không có quyền quản lý hệ thống.
  /// (ADMIN hiển thị ở chế độ Toàn quyền Read-Only để quản trị viên đối chiếu).
  static bool _isManageableRole(RoleModel r) {
    final id = r.roleId.trim().toUpperCase();
    return id != 'USER' && id != 'CUSTOMER';
  }

  /// Icon nhận diện cho từng vai trò
  IconData _getRoleIcon(String roleId) {
    final id = roleId.toUpperCase();
    if (id.contains('SALES') || id.contains('BÁN HÀNG')) return Icons.point_of_sale_rounded;
    if (id.contains('SURVEY') || id.contains('CRM') || id.contains('KHẢO SÁT')) return Icons.poll_rounded;
    if (id.contains('WAREHOUSE') || id.contains('KHO')) return Icons.warehouse_rounded;
    if (id.contains('ADMIN')) return Icons.shield_rounded;
    return Icons.badge_rounded;
  }

  /// Màu sắc đại diện cho từng vai trò
  Color _getRoleColor(String roleId) {
    final id = roleId.toUpperCase();
    if (id.contains('SALES') || id.contains('BÁN HÀNG')) return const Color(0xFF0284C7); // Sky Blue
    if (id.contains('SURVEY') || id.contains('CRM') || id.contains('KHẢO SÁT')) return const Color(0xFF7C3AED); // Purple
    if (id.contains('WAREHOUSE') || id.contains('KHO')) return const Color(0xFFD97706); // Amber
    if (id.contains('ADMIN')) return const Color(0xFFDC2626); // Red
    return AppColors.primary;
  }

  /// Icon nhận diện cho từng module hệ thống
  IconData _getModuleIcon(String module) {
    final m = module.toLowerCase();
    if (m.contains('khảo sát') || m.contains('crm')) return Icons.assignment_rounded;
    if (m.contains('phân quyền') || m.contains('vai trò')) return Icons.admin_panel_settings_rounded;
    if (m.contains('voucher') || m.contains('mã giảm')) return Icons.confirmation_number_rounded;
    if (m.contains('sản phẩm')) return Icons.inventory_2_rounded;
    if (m.contains('đơn hàng')) return Icons.shopping_bag_rounded;
    if (m.contains('hóa đơn')) return Icons.receipt_long_rounded;
    if (m.contains('nhà cung cấp')) return Icons.local_shipping_rounded;
    if (m.contains('nhập hàng') || m.contains('phiếu nhập')) return Icons.move_to_inbox_rounded;
    if (m.contains('khuyến mãi') || m.contains('giảm giá')) return Icons.discount_rounded;
    if (m.contains('khách hàng')) return Icons.people_alt_rounded;
    return Icons.folder_open_rounded;
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

    final manageableRoles = rolesList.where(_isManageableRole).toList();

    setState(() {
      _roles = manageableRoles;
      _permissionModules = catalogList;
      _isLoadingRoles = false;
      _isLoadingCatalog = false;

      // Mặc định đóng tất cả các module accordion (chỉ mở khi người dùng click vào)
      for (var m in _permissionModules) {
        _expandedModules[m.module] = false;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Thay đổi chưa được lưu'),
            ],
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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

    // Lọc danh sách vai trò theo search
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
          // ==========================================
          // TOP HEADER BAR (Gọn gàng & Hiện đại)
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      Row(
                        children: [
                          Text(
                            'Vai Trò & Phân Quyền (RBAC)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_roles.length} vai trò',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quản lý vai trò nhân viên & thiết lập ma trận phân quyền hệ thống',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                // Nút [+ Thêm vai trò]
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

          // Offline Warning Banner
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
                      // Header & Search
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchRoleController,
                          style: TextStyle(fontSize: 12.5, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc mã vai trò...',
                            hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            suffixIcon: _roleSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => _searchRoleController.clear(),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                      Divider(color: borderColor, height: 1),

                      // Danh sách vai trò dạng Card hiện đại
                      Expanded(
                        child: _isLoadingRoles
                            ? const Center(child: CircularProgressIndicator())
                            : filteredRoles.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Không tìm thấy vai trò nào',
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: filteredRoles.length,
                                    itemBuilder: (context, index) {
                                      final role = filteredRoles[index];
                                      final isSelected = role.roleId.toUpperCase() ==
                                          _selectedRoleId?.toUpperCase();
                                      final isDirty = isSelected && _isCurrentRoleDirty;
                                      final roleColor = _getRoleColor(role.roleId);
                                      final roleIcon = _getRoleIcon(role.roleId);
                                      final permCount = isSelected
                                          ? _selectedPermissions.length
                                          : role.permissions.length;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () => _selectRole(role.roleId),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? (isDark
                                                        ? AppColors.primary.withValues(alpha: 0.16)
                                                        : const Color(0xFFEFF6FF))
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primary.withValues(alpha: 0.6)
                                                      : Colors.transparent,
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Role Avatar Circle
                                                  CircleAvatar(
                                                    radius: 17,
                                                    backgroundColor: roleColor.withValues(alpha: 0.15),
                                                    child: Icon(roleIcon, size: 18, color: roleColor),
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
                                                                  fontWeight: isSelected
                                                                      ? FontWeight.w700
                                                                      : FontWeight.w600,
                                                                  color: isSelected
                                                                      ? AppColors.primary
                                                                      : textPrimary,
                                                                ),
                                                              ),
                                                            ),
                                                            if (isDirty)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                    horizontal: 5, vertical: 1),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.warningBg,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(color: AppColors.warningBorder),
                                                                ),
                                                                child: const Text(
                                                                  'Chưa lưu',
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: AppColors.warning,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 3),
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
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: role.isSystem
                                                                      ? textSecondary
                                                                      : AppColors.success,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.shield_outlined, size: 12, color: textSecondary),
                                                            const SizedBox(width: 3),
                                                            Text(
                                                              '$permCount / $_totalAllPermissionsCount quyền',
                                                              style: TextStyle(fontSize: 11, color: textSecondary),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            InkWell(
                                                              onTap: () => _showAssignedUsersDrawer(context, role),
                                                              borderRadius: BorderRadius.circular(4),
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.primary),
                                                                    const SizedBox(width: 2),
                                                                    Text(
                                                                      '${role.userCount}',
                                                                      style: const TextStyle(
                                                                        fontSize: 11,
                                                                        color: AppColors.primary,
                                                                        fontWeight: FontWeight.w600,
                                                                        decoration: TextDecoration.underline,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, size: 40, color: textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text(
                                'Chọn một vai trò ở danh sách bên trái để xem và thiết lập phân quyền',
                                style: TextStyle(color: textSecondary, fontSize: 13),
                              ),
                            ],
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
    final roleColor = _getRoleColor(role.roleId);
    final roleIcon = _getRoleIcon(role.roleId);

    // Tính toán tiến độ phân quyền của vai trò hiện tại
    final grantedTotal = _selectedPermissions.length;
    final progressPercent = _totalAllPermissionsCount > 0
        ? (grantedTotal / _totalAllPermissionsCount).clamp(0.0, 1.0)
        : 0.0;

    // Lọc danh sách module theo tab/chip đang chọn
    final targetModules = _selectedModuleFilter == 'ALL'
        ? _permissionModules
        : _permissionModules.where((m) => m.module == _selectedModuleFilter).toList();

    // Lọc quyền theo tìm kiếm và bộ lọc trạng thái (ALL / GRANTED / NOT_GRANTED)
    final filteredModules = targetModules.map((m) {
      final matchingPerms = m.permissions.where((p) {
        // Lọc theo search query
        if (_permSearchQuery.isNotEmpty) {
          final queryMatch = p.permissionName.toLowerCase().contains(_permSearchQuery) ||
              p.permissionId.toLowerCase().contains(_permSearchQuery) ||
              (p.description != null && p.description!.toLowerCase().contains(_permSearchQuery)) ||
              m.module.toLowerCase().contains(_permSearchQuery);
          if (!queryMatch) return false;
        }

        // Lọc theo trạng thái đã cấp / chưa cấp
        final isGranted = _selectedPermissions.contains(p.permissionId);
        if (_statusFilter == 'GRANTED' && !isGranted) return false;
        if (_statusFilter == 'NOT_GRANTED' && isGranted) return false;

        return true;
      }).toList();

      return ModulePermissionsModel(module: m.module, permissions: matchingPerms);
    }).where((m) => m.permissions.isNotEmpty).toList();

    // Tổng số quyền thỏa mãn bộ lọc hiện tại
    int currentFilteredCount = 0;
    for (var m in filteredModules) {
      currentFilteredCount += m.permissions.length;
    }

    // Đếm số quyền đã cấp / chưa cấp trong phạm vi đang xem
    int currentScopeTotal = 0;
    int currentScopeGranted = 0;
    for (var m in targetModules) {
      currentScopeTotal += m.permissions.length;
      currentScopeGranted += m.permissions.where((p) => _selectedPermissions.contains(p.permissionId)).length;
    }
    int currentScopeNotGranted = currentScopeTotal - currentScopeGranted;

    return Column(
      children: [
        // ==========================================
        // 1. HERO ROLE PROFILE CARD (Gọn gàng & Hiện đại)
        // ==========================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Role Icon Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Icon(roleIcon, size: 22, color: roleColor),
              ),
              const SizedBox(width: 12),
              // Role Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.roleName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            role.roleId,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: role.isSystem ? textSecondary : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showAssignedUsersDrawer(context, role),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '· ${role.userCount} người dùng sở hữu',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.open_in_new_rounded, size: 11, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (displayDesc != null && displayDesc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              // Privilege Meter (Thanh tiến độ quyền hạn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cấp quyền: ',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        Text(
                          '$grantedTotal / $_totalAllPermissionsCount',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          ' (${(progressPercent * 100).round()}%)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 140,
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action buttons (Sửa / Xóa)
              AppButton(
                label: 'Sửa thông tin',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.outline,
                onPressed: (authProvider.can('Roles.Update') && !isOffline)
                    ? _openEditRoleDialog
                    : null,
              ),
              if (!role.isSystem) ...[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Xóa vai trò',
                  icon: Icons.delete_outline_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: (authProvider.can('Roles.Delete') && !isOffline)
                      ? _confirmDeleteRole
                      : null,
                ),
              ],
            ],
          ),
        ),

        // Admin Warning Banner
        if (isAdminRole)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 16),
                SizedBox(width: 8),
                Text(
                  'Quản trị viên tối cao luôn có toàn quyền và không thể chỉnh sửa danh sách quyền hạn.',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // ==========================================
        // 2. HORIZONTAL MODULE TABS / FILTER CHIPS
        // Giải quyết triệt để vấn đề "hiển thị quá nhiều thứ trên 1 màn hình"
        // Cho phép admin chọn xem từng module riêng biệt hoặc toàn bộ
        // ==========================================
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D131F) : const Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Chip "Tất cả Module"
                _buildModuleTabChip(
                  label: 'Tất cả module',
                  icon: Icons.dashboard_outlined,
                  isSelected: _selectedModuleFilter == 'ALL',
                  badge: '$_totalAllPermissionsCount',
                  onTap: () => setState(() => _selectedModuleFilter = 'ALL'),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),

                // Chips từng module
                ..._permissionModules.map((m) {
                  final isSelected = _selectedModuleFilter == m.module;
                  final moduleIcon = _getModuleIcon(m.module);
                  final selectedCount = m.permissions
                      .where((p) => _selectedPermissions.contains(p.permissionId))
                      .length;
                  final totalCount = m.permissions.length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildModuleTabChip(
                      label: m.module,
                      icon: moduleIcon,
                      isSelected: isSelected,
                      badge: '$selectedCount/$totalCount',
                      isComplete: selectedCount == totalCount && totalCount > 0,
                      hasGranted: selectedCount > 0,
                      onTap: () => setState(() => _selectedModuleFilter = m.module),
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ==========================================
        // 3. TOOLBAR (Tìm kiếm, Lọc trạng thái & Thao tác nhanh)
        // ==========================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Ô tìm kiếm quyền
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchPermController,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên quyền, mã quyền, hoặc endpoint...',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _permSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => _searchPermController.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Bộ lọc trạng thái quyền (Segmented Filter: Tất cả | Đã cấp | Chưa cấp)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusFilterButton(
                      label: 'Tất cả ($currentScopeTotal)',
                      value: 'ALL',
                      isSelected: _statusFilter == 'ALL',
                    ),
                    _buildStatusFilterButton(
                      label: 'Đã cấp ($currentScopeGranted)',
                      value: 'GRANTED',
                      isSelected: _statusFilter == 'GRANTED',
                      activeColor: AppColors.success,
                    ),
                    _buildStatusFilterButton(
                      label: 'Chưa cấp ($currentScopeNotGranted)',
                      value: 'NOT_GRANTED',
                      isSelected: _statusFilter == 'NOT_GRANTED',
                      activeColor: textSecondary,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Chuyển đổi giao diện: Bảng Ma Trận CRUD 2D vs Thẻ Chi Tiết
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeToggleBtn(
                      icon: Icons.table_chart_rounded,
                      label: 'Bảng Ma trận',
                      isActive: _isMatrixView,
                      onTap: () => setState(() => _isMatrixView = true),
                      isDark: isDark,
                    ),
                    _buildViewModeToggleBtn(
                      icon: Icons.view_agenda_rounded,
                      label: 'Thẻ chi tiết',
                      isActive: !_isMatrixView,
                      onTap: () => setState(() => _isMatrixView = false),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Thao tác nhanh: Chọn tất cả
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.select_all_rounded, size: 16),
                label: const Text('Chọn tất cả', style: TextStyle(fontSize: 12)),
                onPressed: (isAdminRole || isOffline)
                    ? null
                    : () {
                        setState(() {
                          for (var m in targetModules) {
                            for (var p in m.permissions) {
                              _selectedPermissions.add(p.permissionId);
                            }
                          }
                        });
                      },
              ),
              const SizedBox(width: 4),

              // Thao tác nhanh: Bỏ chọn tất cả
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.deselect_rounded, size: 16),
                label: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12)),
                onPressed: (isAdminRole || isOffline)
                    ? null
                    : () {
                        setState(() {
                          for (var m in targetModules) {
                            for (var p in m.permissions) {
                              _selectedPermissions.remove(p.permissionId);
                            }
                          }
                        });
                      },
              ),

              // Mở rộng / Thu gọn tất cả (chỉ hiển thị khi đang xem "Tất cả module")
              if (_selectedModuleFilter == 'ALL') ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Mở rộng / Thu gọn tất cả',
                  icon: const Icon(Icons.unfold_more_rounded, size: 18),
                  onPressed: () {
                    final anyCollapsed = _permissionModules.any((m) => _expandedModules[m.module] != true);
                    setState(() {
                      for (var m in _permissionModules) {
                        _expandedModules[m.module] = anyCollapsed;
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        ),

        // ==========================================
        // 4. DANH SÁCH QUYỀN HẠN (Grid Responsive & Thẻ Tinh Gọn)
        // ==========================================
        Expanded(
          child: filteredModules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        currentFilteredCount == 0 && _permSearchQuery.isNotEmpty
                            ? 'Không tìm thấy quyền hạn nào khớp với "$_permSearchQuery"'
                            : 'Không có quyền nào phù hợp với bộ lọc hiện tại',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                        label: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            _selectedModuleFilter = 'ALL';
                            _statusFilter = 'ALL';
                            _searchPermController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                )
              : (_isMatrixView
                  ? _buildMatrixTableView(
                      context,
                      filteredModules: filteredModules,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      isAdminRole: isAdminRole,
                      isOffline: isOffline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredModules.length,
                      itemBuilder: (context, index) {
                    final module = filteredModules[index];
                    final isExpanded = _expandedModules[module.module] ?? false;
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Module Header Card
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

                                  // Badge đếm số quyền trong module (vd 3/5)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selectedInModule == totalInModule && totalInModule > 0
                                          ? AppColors.successBg
                                          : selectedInModule > 0
                                              ? AppColors.primary.withValues(alpha: 0.12)
                                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: selectedInModule == totalInModule && totalInModule > 0
                                            ? AppColors.successBorder
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      '$selectedInModule / $totalInModule đã cấp',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: selectedInModule == totalInModule && totalInModule > 0
                                            ? AppColors.success
                                            : selectedInModule > 0
                                                ? AppColors.primary
                                                : textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Quick toggle toàn bộ quyền trong module này
                                  Tooltip(
                                    message: isAllModuleSelected
                                        ? 'Bỏ chọn toàn bộ quyền module này'
                                        : 'Chọn toàn bộ quyền module này',
                                    child: Checkbox(
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
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Children permissions in responsive layout grid
                          if (isExpanded) ...[
                            Divider(color: borderColor, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Tính toán số cột responsive: 1, 2, hoặc 3 cột tùy theo độ rộng màn hình
                                  final availableWidth = constraints.maxWidth;
                                  int crossAxisCount = 2;
                                  if (availableWidth >= 1100) {
                                    crossAxisCount = 3;
                                  } else if (availableWidth < 680) {
                                    crossAxisCount = 1;
                                  }

                                  const spacing = 10.0;
                                  final itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: module.permissions.map((perm) {
                                      final isChecked = _selectedPermissions.contains(perm.permissionId);
                                      final canToggle = !isAdminRole && !isOffline;

                                      return SizedBox(
                                        width: itemWidth,
                                        child: _buildPermissionCard(
                                          perm: perm,
                                          isChecked: isChecked,
                                          canToggle: canToggle,
                                          cardBg: cardBg,
                                          borderColor: borderColor,
                                          textPrimary: textPrimary,
                                          textSecondary: textSecondary,
                                          isDark: isDark,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                )),
        ),

        // ==========================================
        // 5. STICKY BOTTOM ACTION BAR (Rõ ràng & Tiện dụng)
        // ==========================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              if (_isCurrentRoleDirty) ...[
                // Trạng thái có thay đổi chưa lưu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        _getDirtySummaryText(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Trạng thái đã đồng bộ
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Đã đồng bộ với máy chủ',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ],

              const SizedBox(width: 12),
              // Tooltip thông báo JWT 60 phút
              Tooltip(
                message: 'Thay đổi quyền có hiệu lực với phiên làm việc mới (tối đa 60 phút theo thời hạn JWT).',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Hiệu lực tối đa 60p',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
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

  /// Bật/tắt quyền kèm ràng buộc phụ thuộc thông minh (Cascading Dependency)
  void _togglePermission(PermissionDetailModel perm, bool willCheck) {
    setState(() {
      final isView = perm.permissionId.endsWith('.View');
      final dotIndex = perm.permissionId.indexOf('.');
      final modulePrefix = dotIndex > 0 ? perm.permissionId.substring(0, dotIndex) : '';

      if (willCheck) {
        _selectedPermissions.add(perm.permissionId);
        // Ràng buộc thông minh: Tự động bật quyền Xem tương ứng nếu chưa có
        if (!isView && modulePrefix.isNotEmpty) {
          final viewPermId = '$modulePrefix.View';
          _selectedPermissions.add(viewPermId);
        }
      } else {
        _selectedPermissions.remove(perm.permissionId);
        // Ràng buộc thông minh: Nếu bỏ quyền Xem, tự động bỏ toàn bộ các quyền thao tác khác trong cùng module
        if (isView) {
          final moduleObj = _permissionModules.where((m) => m.module == perm.module).firstOrNull;
          if (moduleObj != null) {
            for (var p in moduleObj.permissions) {
              _selectedPermissions.remove(p.permissionId);
            }
          }
        }
      }
    });
  }

  /// Thẻ quyền hạn tinh gọn, bấm trực tiếp vào toàn bộ thẻ để bật/tắt
  Widget _buildPermissionCard({
    required PermissionDetailModel perm,
    required bool isChecked,
    required bool canToggle,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canToggle ? () => _togglePermission(perm, !isChecked) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isChecked
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF0F7FF))
                : cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isChecked
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : borderColor,
              width: isChecked ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox nhỏ gọn
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: canToggle ? (val) => _togglePermission(perm, val == true) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nội dung quyền
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
                              fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                              color: isChecked ? AppColors.primary : textPrimary,
                            ),
                          ),
                        ),
                        // Badge Chưa áp dụng
                        if (perm.isReserved)
                          Tooltip(
                            message:
                                'Quyền đã khai báo nhưng chưa gắn vào API nào — gán được nhưng hiện chưa có tác dụng.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.warningBorder),
                              ),
                              child: const Text(
                                'Chưa áp dụng',
                                style: TextStyle(
                                  fontSize: 9,
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
                        // Mã quyền monospace
                        Text(
                          perm.permissionId,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (perm.endpointCount > 0) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Bảo vệ: ${perm.endpoints.join(', ')}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link_rounded, size: 10, color: textSecondary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${perm.endpointCount} endpoint',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nút lọc Module trên thanh cuộn ngang
  Widget _buildModuleTabChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required String badge,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    bool isComplete = false,
    bool hasGranted = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isComplete
                          ? AppColors.successBg
                          : (hasGranted
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isComplete && !isSelected) ...[
                      const Icon(Icons.check_rounded, size: 10, color: AppColors.success),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isComplete
                                ? AppColors.success
                                : (hasGranted ? AppColors.primary : AppColors.secondary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nút chọn trạng thái lọc quyền (Tất cả / Đã cấp / Chưa cấp)
  Widget _buildStatusFilterButton({
    required String label,
    required String value,
    required bool isSelected,
    Color? activeColor,
  }) {
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (activeColor ?? AppColors.primary).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? (activeColor ?? AppColors.primary) : AppColors.secondary,
          ),
        ),
      ),
    );
  }

  /// Tạo chuỗi tóm tắt thay đổi phân quyền
  String _getDirtySummaryText() {
    final added = _selectedPermissions.where((id) => !_originalPermissions.contains(id)).length;
    final removed = _originalPermissions.where((id) => !_selectedPermissions.contains(id)).length;

    if (added > 0 && removed > 0) {
      return 'Có thay đổi chưa lưu: +$added cấp mới, -$removed hủy bỏ';
    } else if (added > 0) {
      return 'Có thay đổi chưa lưu: +$added cấp mới';
    } else if (removed > 0) {
      return 'Có thay đổi chưa lưu: -$removed hủy bỏ';
    }
    return 'Có thay đổi phân quyền chưa lưu';
  }

  /// Nút chuyển đổi chế độ xem (Bảng Ma trận / Thẻ chi tiết)
  Widget _buildViewModeToggleBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// GIAO DIỆN BẢNG MA TRẬN CRUD 2D CHUẨN DOANH NGHIỆP
  Widget _buildMatrixTableView(
    BuildContext context, {
    required List<ModulePermissionsModel> filteredModules,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required bool isAdminRole,
    required bool isOffline,
  }) {
    final canToggle = !isAdminRole && !isOffline;
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1050),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(headerBg),
                headingRowHeight: 44,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 80,
                horizontalMargin: 16,
                columnSpacing: 14,
                dividerThickness: 1,
                columns: [
                  DataColumn(
                    label: Text(
                      'Phân hệ / Module',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Center(
                      child: Text(
                        'Xem (View)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Center(
                      child: Text(
                        'Thêm (Create)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Center(
                      child: Text(
                        'Sửa (Update)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Center(
                      child: Text(
                        'Xóa (Delete)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Tác vụ đặc biệt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Center(
                      child: Text(
                        'Thao tác',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ),
                  ),
                ],
                rows: filteredModules.map((m) {
                  // Phân loại quyền CRUD chuẩn
                  final viewPerm = m.permissions.where((p) => p.permissionId.endsWith('.View')).firstOrNull;
                  final createPerm = m.permissions.where((p) => p.permissionId.endsWith('.Create')).firstOrNull;
                  final updatePerm = m.permissions.where((p) => p.permissionId.endsWith('.Update')).firstOrNull;
                  final deletePerm = m.permissions.where((p) => p.permissionId.endsWith('.Delete')).firstOrNull;

                  // Các quyền đặc thù không thuộc CRUD 4 cột
                  final specialPerms = m.permissions.where((p) {
                    return !p.permissionId.endsWith('.View') &&
                        !p.permissionId.endsWith('.Create') &&
                        !p.permissionId.endsWith('.Update') &&
                        !p.permissionId.endsWith('.Delete');
                  }).toList();

                  final selectedCount = m.permissions.where((p) => _selectedPermissions.contains(p.permissionId)).length;
                  final totalCount = m.permissions.length;
                  final isAllSelected = selectedCount == totalCount && totalCount > 0;

                  return DataRow(
                    cells: [
                      // 1. Phân hệ
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              m.module,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isAllSelected
                                    ? AppColors.successBg
                                    : (selectedCount > 0
                                        ? AppColors.primary.withValues(alpha: 0.12)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isAllSelected
                                      ? AppColors.successBorder
                                      : (selectedCount > 0 ? AppColors.primary.withValues(alpha: 0.3) : borderColor),
                                ),
                              ),
                              child: Text(
                                '$selectedCount / $totalCount quyền',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isAllSelected
                                      ? AppColors.success
                                      : (selectedCount > 0 ? AppColors.primary : textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Xem (View)
                      DataCell(
                        Center(
                          child: viewPerm != null
                              ? _buildMatrixCheckbox(
                                  perm: viewPerm,
                                  isChecked: _selectedPermissions.contains(viewPerm.permissionId),
                                  canToggle: canToggle,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked) {
                                        _selectedPermissions.add(viewPerm.permissionId);
                                      } else {
                                        // Ràng buộc thông minh: Bỏ Xem -> Bỏ toàn bộ quyền thao tác trong module này
                                        for (var p in m.permissions) {
                                          _selectedPermissions.remove(p.permissionId);
                                        }
                                      }
                                    });
                                  },
                                )
                              : Text('—', style: TextStyle(color: textSecondary.withValues(alpha: 0.4))),
                        ),
                      ),

                      // 3. Thêm (Create)
                      DataCell(
                        Center(
                          child: createPerm != null
                              ? _buildMatrixCheckbox(
                                  perm: createPerm,
                                  isChecked: _selectedPermissions.contains(createPerm.permissionId),
                                  canToggle: canToggle,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked) {
                                        _selectedPermissions.add(createPerm.permissionId);
                                        // Ràng buộc thông minh: Tự động bật quyền Xem nếu chưa có
                                        if (viewPerm != null) _selectedPermissions.add(viewPerm.permissionId);
                                      } else {
                                        _selectedPermissions.remove(createPerm.permissionId);
                                      }
                                    });
                                  },
                                )
                              : Text('—', style: TextStyle(color: textSecondary.withValues(alpha: 0.4))),
                        ),
                      ),

                      // 4. Sửa (Update)
                      DataCell(
                        Center(
                          child: updatePerm != null
                              ? _buildMatrixCheckbox(
                                  perm: updatePerm,
                                  isChecked: _selectedPermissions.contains(updatePerm.permissionId),
                                  canToggle: canToggle,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked) {
                                        _selectedPermissions.add(updatePerm.permissionId);
                                        // Ràng buộc thông minh: Tự động bật quyền Xem nếu chưa có
                                        if (viewPerm != null) _selectedPermissions.add(viewPerm.permissionId);
                                      } else {
                                        _selectedPermissions.remove(updatePerm.permissionId);
                                      }
                                    });
                                  },
                                )
                              : Text('—', style: TextStyle(color: textSecondary.withValues(alpha: 0.4))),
                        ),
                      ),

                      // 5. Xóa (Delete)
                      DataCell(
                        Center(
                          child: deletePerm != null
                              ? _buildMatrixCheckbox(
                                  perm: deletePerm,
                                  isChecked: _selectedPermissions.contains(deletePerm.permissionId),
                                  canToggle: canToggle,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked) {
                                        _selectedPermissions.add(deletePerm.permissionId);
                                        // Ràng buộc thông minh: Tự động bật quyền Xem nếu chưa có
                                        if (viewPerm != null) _selectedPermissions.add(viewPerm.permissionId);
                                      } else {
                                        _selectedPermissions.remove(deletePerm.permissionId);
                                      }
                                    });
                                  },
                                )
                              : Text('—', style: TextStyle(color: textSecondary.withValues(alpha: 0.4))),
                        ),
                      ),

                      // 6. Tác vụ đặc biệt (Chips tương tác)
                      DataCell(
                        specialPerms.isEmpty
                            ? Text('—', style: TextStyle(color: textSecondary.withValues(alpha: 0.4)))
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: specialPerms.map((p) {
                                    final isChecked = _selectedPermissions.contains(p.permissionId);
                                    return Tooltip(
                                      message: '${p.permissionName} (${p.permissionId})\n${p.description}',
                                      child: InkWell(
                                        onTap: canToggle
                                            ? () {
                                                setState(() {
                                                  if (isChecked) {
                                                    _selectedPermissions.remove(p.permissionId);
                                                  } else {
                                                    _selectedPermissions.add(p.permissionId);
                                                    if (viewPerm != null) {
                                                      _selectedPermissions.add(viewPerm.permissionId);
                                                    }
                                                  }
                                                });
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isChecked
                                                ? (isDark
                                                    ? AppColors.primary.withValues(alpha: 0.2)
                                                    : const Color(0xFFE0F2FE))
                                                : (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isChecked
                                                  ? AppColors.primary.withValues(alpha: 0.6)
                                                  : borderColor,
                                            ),
                                          ),
                                          child: Text(
                                            p.permissionName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                                              color: isChecked ? AppColors.primary : textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),

                      // 7. Thao tác nhanh
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút Chỉ xem
                            Tooltip(
                              message: 'Chỉ cấp quyền Xem cho module này',
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: canToggle && viewPerm != null
                                    ? () {
                                        setState(() {
                                          for (var p in m.permissions) {
                                            _selectedPermissions.remove(p.permissionId);
                                          }
                                          _selectedPermissions.add(viewPerm.permissionId);
                                        });
                                      }
                                    : null,
                                child: const Text('Chỉ xem', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Nút Toàn quyền
                            Tooltip(
                              message: 'Cấp toàn bộ quyền của module này',
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: canToggle
                                    ? () {
                                        setState(() {
                                          for (var p in m.permissions) {
                                            _selectedPermissions.add(p.permissionId);
                                          }
                                        });
                                      }
                                    : null,
                                child: const Text('Toàn quyền', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Nút Xóa/Bỏ chọn
                            IconButton(
                              tooltip: 'Bỏ chọn toàn bộ quyền của module này',
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              visualDensity: VisualDensity.compact,
                              color: AppColors.danger,
                              onPressed: canToggle && selectedCount > 0
                                  ? () {
                                      setState(() {
                                        for (var p in m.permissions) {
                                          _selectedPermissions.remove(p.permissionId);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ô Checkbox cho bảng ma trận có Tooltip giải thích chi tiết
  Widget _buildMatrixCheckbox({
    required PermissionDetailModel perm,
    required bool isChecked,
    required bool canToggle,
    required ValueChanged<bool> onChanged,
  }) {
    return Tooltip(
      message: '${perm.permissionName} (${perm.permissionId})\n${perm.description}',
      child: SizedBox(
        width: 28,
        height: 28,
        child: Checkbox(
          value: isChecked,
          onChanged: canToggle ? (v) => onChanged(v == true) : null,
        ),
      ),
    );
  }

  /// Hiển thị Drawer trượt từ phải sang xem "Danh sách nhân viên sở hữu vai trò"
  void _showAssignedUsersDrawer(BuildContext context, RoleModel role) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _AssignedUsersDrawerContent(
              role: role,
              roleColor: _getRoleColor(role.roleId),
              roleIcon: _getRoleIcon(role.roleId),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

}


/// Widget nội dung Drawer hiển thị danh sách nhân viên sở hữu vai trò
class _AssignedUsersDrawerContent extends StatefulWidget {
  final RoleModel role;
  final Color roleColor;
  final IconData roleIcon;

  const _AssignedUsersDrawerContent({
    required this.role,
    required this.roleColor,
    required this.roleIcon,
  });

  @override
  State<_AssignedUsersDrawerContent> createState() => _AssignedUsersDrawerContentState();
}

class _AssignedUsersDrawerContentState extends State<_AssignedUsersDrawerContent> {
  bool _isLoading = true;
  String _searchQuery = '';
  List<AppUser> _allUsers = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final users = await apiService.getUsers(token: token, isStaffOnly: true);
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final targetRoleId = widget.role.roleId.toUpperCase();
    final roleUsers = _allUsers.where((u) {
      final inRoles = u.roles.any((r) => r.toUpperCase() == targetRoleId);
      final inPrimary = u.role.toUpperCase() == targetRoleId;
      return inRoles || inPrimary;
    }).toList();

    final filteredUsers = roleUsers.where((u) {
      if (_searchQuery.isEmpty) return true;
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.userName.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.phone.toLowerCase().contains(_searchQuery);
    }).toList();

    final activeCount = roleUsers.where((u) => !u.isLocked).length;
    final lockedCount = roleUsers.where((u) => u.isLocked).length;

    return Container(
      width: 480,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.roleIcon, color: widget.roleColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhân sự thuộc vai trò',
                        style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.role.roleName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã định danh: ${widget.role.roleId}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Box & Stats Banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm nhân sự theo tên, username, email...',
                    hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 16, color: widget.roleColor),
                      const SizedBox(width: 8),
                      Text(
                        'Tổng: ${roleUsers.length} nhân sự',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$activeCount hoạt động',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      if (lockedCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$lockedCount tạm khóa',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_rounded, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              roleUsers.isEmpty
                                  ? 'Chưa có nhân viên nào được gán vai trò này'
                                  : 'Không tìm thấy nhân viên phù hợp với từ khóa',
                              style: TextStyle(fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final user = filteredUsers[idx];
                          final initials = user.fullName.isNotEmpty
                              ? user.fullName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                              : (user.userName.isNotEmpty ? user.userName.substring(0, 1).toUpperCase() : '?');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: widget.roleColor.withValues(alpha: 0.15),
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: widget.roleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.fullName,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: user.isLocked ? AppColors.dangerBg : AppColors.successBg,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: user.isLocked ? AppColors.dangerBorder : AppColors.successBorder,
                                              ),
                                            ),
                                            child: Text(
                                              user.isLocked ? 'Tạm khóa' : 'Hoạt động',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: user.isLocked ? AppColors.danger : AppColors.success,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Username: ${user.userName}',
                                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                                      ),
                                      Text(
                                        'Email: ${user.email}${user.phone.isNotEmpty ? " • SĐT: ${user.phone}" : ""}',
                                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
