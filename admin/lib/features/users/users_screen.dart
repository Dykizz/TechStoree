import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _usersFuture = apiService.getUsers(token: token);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<AppUser>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var users = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) =>
            u.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.phone.contains(_searchQuery)
          ).toList();
        }

        if (_selectedRole != 'Tất cả') {
          users = users.where((u) => u.role.toUpperCase() == _selectedRole.toUpperCase()).toList();
        }

        final totalItems = users.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedUsers = totalItems == 0
            ? <AppUser>[]
            : users.skip(startIndex).take(_itemsPerPage).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản Lý Người Dùng & Khách Hàng',
                subtitle: 'Quản lý tài khoản, phân quyền và trạng thái khách hàng trên hệ thống',
                action: AppButton(
                  label: 'Tạo Tài Khoản Mới',
                  icon: Icons.person_add_outlined,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ),
              ),

              FilterBar(
                searchField: AppSearchField<AppUser>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên, email, sđt...',
                  items: snapshot.data ?? [],
                  searchFilter: (u, q) => u.userName.toLowerCase().contains(q.toLowerCase()) ||
                      u.email.toLowerCase().contains(q.toLowerCase()) ||
                      u.phone.contains(q),
                  itemLabel: (u) => u.userName,
                  itemSubtitle: (u) => 'Email: ${u.email} • Vai trò: ${u.role}',
                  onSelected: (u) => setState(() => _searchQuery = u.userName),
                  onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedRole,
                    labelText: 'Vai trò (Role)',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả vai trò')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                      DropdownMenuItem(value: 'STAFF', child: Text('Nhân viên (STAFF)')),
                      DropdownMenuItem(value: 'USER', child: Text('Khách hàng (USER)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() {
                        _selectedRole = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ],
              ),

              Flexible(
                fit: FlexFit.loose,
                child: DataTableContainer(
                  child: users.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Không tìm thấy người dùng nào',
                          message: 'Thử thay đổi từ khóa tìm kiếm hoặc vai trò chọn lọc.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: DataTable(
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 42,
                                      dataRowMaxHeight: 42,
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('HỌ TÊN / USERNAME', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('EMAIL / SỐ ĐIỆN THOẠI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('VAI TRÒ (ROLE)', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                      ],
                                      rows: paginatedUsers.map((u) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(Text('#${u.id}', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 11,
                                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                                    child: Text(
                                                      u.userName.isNotEmpty ? u.userName[0].toUpperCase() : 'U',
                                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 10),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(u.userName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text('${u.email}${u.phone.isNotEmpty ? " • ${u.phone}" : ""}', style: TextStyle(color: textPrimary, fontSize: 11)),
                                            ),
                                            DataCell(_buildRoleBadge(u.role)),
                                            DataCell(
                                              StatusBadge(
                                                label: u.isLocked ? 'KHOÁ' : 'HOẠT ĐỘNG',
                                                isSuccess: !u.isLocked,
                                                isDanger: u.isLocked,
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                    tooltip: 'Chỉnh sửa tài khoản',
                                                    onPressed: () => _showFormDialog(context, apiService, authProvider.token, u),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      !u.isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                                                      size: 15,
                                                      color: !u.isLocked ? AppColors.danger : AppColors.success,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                    tooltip: !u.isLocked ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                                                    onPressed: () => _confirmToggleActive(context, apiService, authProvider.token, u),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildRoleBadge(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const StatusBadge(label: 'ADMIN', isDanger: true);
      case 'STAFF':
        return const StatusBadge(label: 'STAFF', isInfo: true);
      default:
        return const StatusBadge(label: 'USER', isSuccess: true);
    }
  }

  void _showFormDialog(BuildContext context, ApiService apiService, String? token, AppUser? existing) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: isEditing ? existing.userName : '');
    final emailCtrl = TextEditingController(text: isEditing ? existing.email : '');
    final phoneCtrl = TextEditingController(text: isEditing ? existing.phone : '');
    String role = isEditing ? existing.role : 'USER';
    bool isLocked = isEditing ? existing.isLocked : false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text(
              isEditing ? 'Sửa Người Dùng: ${existing.userName}' : 'Tạo Tài Khoản Mới',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: nameCtrl, labelText: 'Họ và tên / Username (*)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: emailCtrl, labelText: 'Địa chỉ Email (*)', readOnly: isEditing)),
                      const SizedBox(width: 8),
                      Expanded(child: AppTextField(controller: phoneCtrl, labelText: 'Số điện thoại')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppDropdown<String>(
                    value: role,
                    labelText: 'Phân quyền vai trò (Role)*',
                    items: const [
                      DropdownMenuItem(value: 'USER', child: Text('Khách hàng (USER)')),
                      DropdownMenuItem(value: 'STAFF', child: Text('Nhân viên (STAFF)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => role = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Khóa tài khoản', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    value: isLocked,
                    onChanged: (val) => setDialogState(() => isLocked = val),
                  ),
                ],
              ),
            ),
            actions: [
              AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                  final u = AppUser(
                    id: isEditing ? existing.id : '0',
                    userName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: role,
                    status: isLocked ? 'Tạm khóa' : 'Hoạt động',
                    isLocked: isLocked,
                    createdAt: isEditing ? existing.createdAt : DateTime.now(),
                  );

                  bool success = true;
                  String msg = 'Cập nhật thành công!';
                  if (!isEditing) {
                    final ApiResult res = await apiService.createUser(u, '123456', token: token);
                    success = res.success;
                    msg = res.message;
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    setState(() => _loadUsers());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: success ? AppColors.success : AppColors.danger),
                    );
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
    final actionText = !user.isLocked ? 'khóa' : 'mở khóa';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Xác nhận $actionText tài khoản', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn $actionText tài khoản "${user.email}" (${user.userName}) không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Xác Nhận',
            variant: !user.isLocked ? AppButtonVariant.danger : AppButtonVariant.primary,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.toggleUserLock(user.id, token: token);
              if (context.mounted) {
                setState(() => _loadUsers());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res ? 'Thao tác thành công!' : 'Thao tác thất bại!'), backgroundColor: res ? AppColors.success : AppColors.danger),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
