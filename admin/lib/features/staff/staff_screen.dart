import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/role.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<AppUser>> _staffFuture;
  List<RoleModel> _availableRoles = [];

  static const Map<String, String> roleLabels = {
    'ADMIN': 'Quản trị viên',
    'WAREHOUSE_STAFF': 'Thủ kho',
    'SALES_STAFF': 'Nhân viên bán hàng',
    'SURVEY_STAFF': 'Nhân viên khảo sát & CRM',
  };

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _staffFuture = apiService.getUsers(token: token, isStaffOnly: true);
    apiService.getRoles(token: token).then((roles) {
      if (mounted && roles.isNotEmpty) {
        setState(() => _availableRoles = roles);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isStaff(AppUser u) {
    return u.role.toUpperCase() != 'USER' || u.roles.any((r) => r.toUpperCase() != 'USER');
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<AppUser>>(
      future: _staffFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var allUsers = snapshot.data ?? [];
        // Lọc chắc chắn chỉ lấy nhân viên nội bộ
        var staffList = allUsers.where(_isStaff).toList();

        // Lọc tìm kiếm
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          staffList = staffList.where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.userName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.contains(q) ||
            u.role.toLowerCase().contains(q) ||
            u.roles.any((r) => r.toLowerCase().contains(q))
          ).toList();
        }

        // Lọc vai trò
        if (_selectedRole != 'Tất cả') {
          staffList = staffList.where((u) =>
            u.role.toUpperCase() == _selectedRole.toUpperCase() ||
            u.roles.contains(_selectedRole.toUpperCase())
          ).toList();
        }

        // Lọc trạng thái khóa
        if (_selectedStatus != 'Tất cả') {
          if (_selectedStatus == 'active') {
            staffList = staffList.where((u) => !u.isLocked).toList();
          } else if (_selectedStatus == 'locked') {
            staffList = staffList.where((u) => u.isLocked).toList();
          }
        }

        final totalItems = staffList.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedStaff = totalItems == 0
            ? <AppUser>[]
            : staffList.skip(startIndex).take(_itemsPerPage).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản Lý Nhân Viên',
                subtitle: 'Quản lý tài khoản nhân sự nội bộ, phân quyền vai trò (Admin, Sales, Thủ kho, CRM) và bảo mật hệ thống',
                action: authProvider.isAdmin || authProvider.can('Users.Create') ? AppButton(
                  label: 'Thêm nhân viên',
                  icon: Icons.person_add_outlined,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ) : null,
              ),

              FilterBar(
                searchField: AppSearchField<AppUser>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên nhân viên, username, email công vụ...',
                  items: (snapshot.data ?? []).where(_isStaff).toList(),
                  searchFilter: (u, q) {
                    final query = q.toLowerCase();
                    return u.fullName.toLowerCase().contains(query) ||
                        u.userName.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.phone.contains(query);
                  },
                  itemLabel: (u) => '${u.fullName} (@${u.userName})',
                  itemSubtitle: (u) => 'Email: ${u.email} • Vai trò: ${_getRolesDisplay(u)}',
                  onSelected: (u) => setState(() => _searchQuery = u.fullName),
                  onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedRole,
                    labelText: 'Vai trò công tác',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả vai trò')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                      DropdownMenuItem(value: 'WAREHOUSE_STAFF', child: Text('Thủ kho (WAREHOUSE_STAFF)')),
                      DropdownMenuItem(value: 'SALES_STAFF', child: Text('Nhân viên bán hàng (SALES_STAFF)')),
                      DropdownMenuItem(value: 'SURVEY_STAFF', child: Text('Nhân viên khảo sát (SURVEY_STAFF)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRole = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  AppDropdown<String>(
                    value: _selectedStatus,
                    labelText: 'Trạng thái',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'active', child: Text('Đang làm việc / Hoạt động')),
                      DropdownMenuItem(value: 'locked', child: Text('Đã khóa tài khoản')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStatus = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ],
              ),

              Flexible(
                fit: FlexFit.loose,
                child: DataTableContainer(
                  child: staffList.isEmpty
                      ? const EmptyState(
                          icon: Icons.badge_outlined,
                          title: 'Không tìm thấy nhân viên nào',
                          message: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc vai trò công tác.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScrollableTableWrapper(
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 46,
                                dataRowMaxHeight: 46,
                                columnSpacing: 14,
                                horizontalMargin: 14,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                columns: [
                                  DataColumn(label: Text('MÃ NV', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('HỌ TÊN / TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('EMAIL CÔNG VỤ / SĐT', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('VAI TRÒ & PHÂN QUYỀN', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('NGÀY GIA NHẬP', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                ],
                                rows: paginatedStaff.map((u) {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                      if (states.contains(WidgetState.hovered)) {
                                        return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                      }
                                      return null;
                                    }),
                                    cells: [
                                      DataCell(Text('NV#${u.id}', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: u.isLocked ? AppColors.danger.withOpacity(0.15) : _getPrimaryRoleColor(u).withOpacity(0.15),
                                              child: Text(
                                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'S',
                                                style: TextStyle(
                                                  color: u.isLocked ? AppColors.danger : _getPrimaryRoleColor(u),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(u.fullName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                                    if (u.isLocked) ...[
                                                      const SizedBox(width: 4),
                                                      const Tooltip(
                                                        message: 'Tài khoản đang bị khóa',
                                                        child: Icon(Icons.lock_rounded, size: 12, color: AppColors.danger),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text('@${u.userName}', style: TextStyle(color: textSecondary, fontSize: 10)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(u.email, style: TextStyle(color: textPrimary, fontSize: 11)),
                                            if (u.phone.isNotEmpty)
                                              Text(u.phone, style: TextStyle(color: textSecondary, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      DataCell(_buildRolesBadges(u)),
                                      DataCell(
                                        Text('${u.createdAt.day}/${u.createdAt.month}/${u.createdAt.year}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                      ),
                                      DataCell(
                                        StatusBadge(
                                          label: u.isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                                          isSuccess: !u.isLocked,
                                          isDanger: u.isLocked,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.visibility_outlined, size: 15, color: textSecondary),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                              tooltip: 'Xem thông tin nhân viên',
                                              onPressed: () => _showDetailDialog(context, u),
                                            ),
                                            if (authProvider.isAdmin || authProvider.can('Users.AssignRoles') || authProvider.can('Users.Update') || authProvider.can('Users.Edit')) ...[
                                              IconButton(
                                                icon: Icon(Icons.manage_accounts_outlined, size: 15, color: textSecondary),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                tooltip: 'Phân quyền & Sửa thông tin',
                                                onPressed: () => _showFormDialog(context, apiService, authProvider.token, u),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  u.isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                                  size: 15,
                                                  color: u.isLocked ? AppColors.success : AppColors.danger,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                tooltip: u.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản nhân viên',
                                                onPressed: () => _confirmToggleActive(context, apiService, authProvider.token, u),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            if (totalItems > 0)
                              AppPagination(
                                currentPage: safePage,
                                totalPages: totalPages,
                                totalItems: totalItems,
                                itemsPerPage: _itemsPerPage,
                                onPageChanged: (page) => setState(() => _currentPage = page),
                                onItemsPerPageChanged: (items) {
                                  setState(() {
                                    _itemsPerPage = items;
                                    _currentPage = 1;
                                  });
                                },
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPrimaryRoleColor(AppUser u) {
    if (u.roles.contains('ADMIN') || u.role == 'ADMIN') return AppColors.danger;
    if (u.roles.contains('WAREHOUSE_STAFF') || u.role == 'WAREHOUSE_STAFF') return Colors.blue;
    if (u.roles.contains('SALES_STAFF') || u.role == 'SALES_STAFF') return AppColors.success;
    if (u.roles.contains('SURVEY_STAFF') || u.role == 'SURVEY_STAFF') return Colors.purple;
    return AppColors.primary;
  }

  String _getRolesDisplay(AppUser u) {
    final list = u.roles.isNotEmpty ? u.roles : [u.role];
    return list.map((r) {
      final found = _availableRoles.where((ar) => ar.roleId.toUpperCase() == r.toUpperCase()).firstOrNull;
      if (found != null && found.roleName.isNotEmpty) return found.roleName;
      return roleLabels[r] ?? r;
    }).join(', ');
  }

  Widget _buildRolesBadges(AppUser u) {
    final rolesList = u.roles.isNotEmpty ? u.roles : [u.role];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: rolesList.map((r) {
        Color badgeColor = AppColors.primary;
        String label = r;

        switch (r.toUpperCase()) {
          case 'ADMIN':
            badgeColor = AppColors.danger;
            label = 'Quản trị viên';
            break;
          case 'WAREHOUSE_STAFF':
            badgeColor = Colors.blue;
            label = 'Thủ kho';
            break;
          case 'SALES_STAFF':
            badgeColor = AppColors.success;
            label = 'Bán hàng';
            break;
          case 'SURVEY_STAFF':
            badgeColor = Colors.purple;
            label = 'Khảo sát & CRM';
            break;
          default:
            label = r;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  void _showDetailDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _getPrimaryRoleColor(user).withOpacity(0.15),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'S',
                  style: TextStyle(color: _getPrimaryRoleColor(user), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hồ Sơ Nhân Sự: ${user.fullName}',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.badge_outlined, 'Mã nhân viên', 'NV#${user.id}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.account_circle_outlined, 'Tên tài khoản', '@${user.userName}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.email_outlined, 'Email công vụ', user.email, textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.phone_outlined, 'Số điện thoại', user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.admin_panel_settings_outlined,
                  'Vai trò đảm nhiệm',
                  _getRolesDisplay(user),
                  _getPrimaryRoleColor(user),
                  textSecondary,
                  isBoldValue: true,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.calendar_today_outlined, 'Ngày gia nhập', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.shield_outlined, 'Trạng thái', user.isLocked ? 'Đã bị tạm khóa' : 'Đang làm việc', user.isLocked ? AppColors.danger : AppColors.success, textSecondary),
              ],
            ),
          ),
          actions: [
            AppButton(label: 'Đóng', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color valueColor, Color labelColor, {bool isBoldValue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: labelColor),
        const SizedBox(width: 10),
        SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w500))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: valueColor, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showFormDialog(BuildContext context, ApiService apiService, String? token, AppUser? existing) {
    final isEditing = existing != null;
    final fullNameCtrl = TextEditingController(text: isEditing ? existing.fullName : '');
    final userNameCtrl = TextEditingController(text: isEditing ? existing.userName : '');
    final emailCtrl = TextEditingController(text: isEditing ? existing.email : '');
    final phoneCtrl = TextEditingController(text: isEditing ? existing.phone : '');
    final passwordCtrl = TextEditingController();

    final List<String> selectedRoles = isEditing
        ? (existing.roles.isNotEmpty ? List<String>.from(existing.roles) : [existing.role])
        : ['SALES_STAFF'];

    bool isLocked = isEditing ? existing.isLocked : false;

    final Map<String, String> availableStaffRoles = {
      'SALES_STAFF': 'Nhân viên bán hàng (SALES_STAFF)',
      'WAREHOUSE_STAFF': 'Thủ kho (WAREHOUSE_STAFF)',
      'SURVEY_STAFF': 'Nhân viên khảo sát & CRM (SURVEY_STAFF)',
      'ADMIN': 'Quản trị viên toàn hệ thống (ADMIN)',
    };

    for (final r in _availableRoles) {
      if (r.roleId.toUpperCase() != 'USER' && !availableStaffRoles.containsKey(r.roleId)) {
        availableStaffRoles[r.roleId] = '${r.roleName} (${r.roleId})';
      }
    }
    for (final r in selectedRoles) {
      if (!availableStaffRoles.containsKey(r)) {
        availableStaffRoles[r] = r;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(dialogCtx).isDarkMode;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text(
              isEditing ? 'Sửa nhân viên: ${existing.fullName}' : 'Thêm nhân viên mới',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: fullNameCtrl, labelText: 'Họ và tên nhân viên (*)')),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(controller: userNameCtrl, labelText: 'Tên đăng nhập / Username (*)')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: emailCtrl, labelText: 'Email công vụ (*)')),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(controller: phoneCtrl, labelText: 'Số điện thoại liên lạc')),
                      ],
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 12),
                      AppTextField(controller: passwordCtrl, labelText: 'Mật khẩu khởi tạo (*)', obscureText: true),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Phân Quyền Vai Trò (Được chọn nhiều vai trò):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: availableStaffRoles.entries.map((e) {
                          final isChecked = selectedRoles.contains(e.key);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: e.key == 'ADMIN' ? FontWeight.bold : FontWeight.normal,
                                color: e.key == 'ADMIN' ? AppColors.danger : textPrimary,
                              ),
                            ),
                            value: isChecked,
                            activeColor: e.key == 'ADMIN' ? AppColors.danger : AppColors.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedRoles.add(e.key);
                                } else {
                                  if (selectedRoles.length > 1) {
                                    selectedRoles.remove(e.key);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Nhân viên phải có ít nhất 1 vai trò')),
                                    );
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('Khóa tài khoản này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Nhân viên bị khóa sẽ không thể đăng nhập trang quản trị', style: TextStyle(fontSize: 11)),
                        value: isLocked,
                        activeColor: AppColors.danger,
                        onChanged: (val) => setDialogState(() => isLocked = val),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: isEditing ? 'Lưu Phân Quyền' : 'Tạo Nhân Viên',
                onPressed: () async {
                  if (fullNameCtrl.text.trim().isEmpty || userNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ Họ tên, Username và Email (*)')),
                    );
                    return;
                  }
                  if (!isEditing && passwordCtrl.text.trim().length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu khởi tạo phải từ 6 ký tự trở lên (*)')),
                    );
                    return;
                  }

                  final user = AppUser(
                    id: isEditing ? existing.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    userName: userNameCtrl.text.trim(),
                    fullName: fullNameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: selectedRoles.first,
                    roles: selectedRoles,
                    status: isLocked ? 'Tạm khóa' : 'Hoạt động',
                    isLocked: isLocked,
                    phone: phoneCtrl.text.trim(),
                    createdAt: isEditing ? existing.createdAt : DateTime.now(),
                  );

                  Navigator.pop(ctx);
                  if (isEditing) {
                    final res = await apiService.updateUser(user, token: token);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                      setState(() => _loadStaff());
                    }
                  } else {
                    final res = await apiService.createUser(user, passwordCtrl.text.trim(), token: token);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                      setState(() => _loadStaff());
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmToggleActive(BuildContext context, ApiService apiService, String? token, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isLocked ? 'Mở Khóa Tài Khoản Nhân Viên' : 'Khóa Tài Khoản Nhân Viên'),
        content: Text('Bạn có chắc chắn muốn ${user.isLocked ? 'mở khóa' : 'khóa'} tài khoản nhân viên "${user.fullName}" không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: user.isLocked ? 'Mở Khóa' : 'Khóa Ngay',
            variant: user.isLocked ? AppButtonVariant.primary : AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final willLock = !user.isLocked;
              final success = await apiService.toggleUserLock(user.id, isLocked: willLock, token: token);
              if (mounted) {
                final msg = willLock ? 'Đã khóa tài khoản nhân viên thành công!' : 'Đã mở khóa tài khoản nhân viên thành công!';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? msg : 'Thao tác thất bại!')),
                );
                setState(() => _loadStaff());
              }
            },
          ),
        ],
      ),
    );
  }
}
