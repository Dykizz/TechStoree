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
  String _selectedTechInterest = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<AppUser>> _usersFuture;

  static const List<String> techInterestOptions = [
    'Gaming',
    'Văn phòng & Học tập',
    'Lập trình & AI',
    'Âm thanh & Studio',
    'Smartwatch & Sức khỏe',
    'Nhiếp ảnh & Quay phim',
    'SmartHome & Đồ gia dụng',
  ];

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

        // Lọc tìm kiếm
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          users = users.where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.userName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.contains(q) ||
            (u.address != null && u.address!.toLowerCase().contains(q)) ||
            (u.techInterest != null && u.techInterest!.toLowerCase().contains(q))
          ).toList();
        }

        // Lọc vai trò
        if (_selectedRole != 'Tất cả') {
          users = users.where((u) => u.role.toUpperCase() == _selectedRole.toUpperCase()).toList();
        }

        // Lọc sở thích công nghệ
        if (_selectedTechInterest != 'Tất cả') {
          users = users.where((u) {
            if (_selectedTechInterest == 'Chưa cập nhật') {
              return u.techInterest == null || u.techInterest!.isEmpty;
            }
            return u.techInterest != null && u.techInterest!.toLowerCase().contains(_selectedTechInterest.toLowerCase());
          }).toList();
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
                subtitle: 'Quản lý tài khoản, thông tin cá nhân, sở thích công nghệ và phân quyền hệ thống',
                action: AppButton(
                  label: 'Tạo Tài Khoản Mới',
                  icon: Icons.person_add_outlined,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ),
              ),

              FilterBar(
                searchField: AppSearchField<AppUser>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên, username, email, sđt, địa chỉ...',
                  items: snapshot.data ?? [],
                  searchFilter: (u, q) {
                    final query = q.toLowerCase();
                    return u.fullName.toLowerCase().contains(query) ||
                        u.userName.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.phone.contains(query) ||
                        (u.address != null && u.address!.toLowerCase().contains(query));
                  },
                  itemLabel: (u) => '${u.fullName} (@${u.userName})',
                  itemSubtitle: (u) => 'Email: ${u.email} • Sở thích: ${u.techInterest ?? "Chưa rõ"}',
                  onSelected: (u) => setState(() => _searchQuery = u.fullName),
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
                    value: _selectedTechInterest,
                    labelText: 'Sở thích công nghệ',
                    items: [
                      const DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả sở thích')),
                      ...techInterestOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                      const DropdownMenuItem(value: 'Chưa cập nhật', child: Text('Chưa cập nhật')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTechInterest = val;
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
                  child: users.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Không tìm thấy người dùng nào',
                          message: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc vai trò, sở thích.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('HỌ TÊN / USERNAME', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('EMAIL / SỐ ĐIỆN THOẠI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('SỞ THÍCH CÔNG NGHỆ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('NGÀY SINH / TUỔI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('ĐỊA CHỈ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('VAI TRÒ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
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
                                                    radius: 12,
                                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                                    child: Text(
                                                      u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(u.fullName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
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
                                            DataCell(_buildTechInterestBadge(u.techInterest, isDark)),
                                            DataCell(
                                              u.dateOfBirth != null
                                                  ? Text(
                                                      '${u.dateOfBirth!.day}/${u.dateOfBirth!.month}/${u.dateOfBirth!.year} (${u.age} tuổi)',
                                                      style: TextStyle(color: textPrimary, fontSize: 11),
                                                    )
                                                  : Text('Chưa cập nhật', style: TextStyle(color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 140,
                                                child: Text(
                                                  u.address != null && u.address!.isNotEmpty ? u.address! : 'Chưa cập nhật',
                                                  style: TextStyle(color: u.address != null && u.address!.isNotEmpty ? textPrimary : textSecondary, fontSize: 11, fontStyle: u.address == null || u.address!.isEmpty ? FontStyle.italic : FontStyle.normal),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
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
                                                    icon: Icon(Icons.visibility_outlined, size: 15, color: textSecondary),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    tooltip: 'Xem chi tiết',
                                                    onPressed: () => _showDetailDialog(context, u),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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

  Widget _buildTechInterestBadge(String? interest, bool isDark) {
    if (interest == null || interest.trim().isEmpty) {
      return Text('Chưa chọn', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11, fontStyle: FontStyle.italic));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            interest,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
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

  void _showDetailDialog(BuildContext context, AppUser user) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                  Text('@${user.userName} • ID #${user.id}', style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
            _buildRoleBadge(user.role),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.email_outlined, 'Email', user.email, textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.phone_outlined, 'Số điện thoại', user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật', textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.stars_outlined,
                'Sở thích công nghệ',
                user.techInterest ?? 'Chưa cập nhật',
                user.techInterest != null ? AppColors.primary : textSecondary,
                textSecondary,
                isBoldValue: user.techInterest != null,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.cake_outlined,
                'Ngày sinh / Tuổi',
                user.dateOfBirth != null
                    ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year} (${user.age} tuổi)'
                    : 'Chưa cập nhật',
                textPrimary,
                textSecondary,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.location_on_outlined, 'Địa chỉ cư trú', user.address ?? 'Chưa cập nhật', textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.calendar_today_outlined, 'Ngày tham gia', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}', textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.shield_outlined, 'Trạng thái tài khoản', user.isLocked ? 'Đã bị tạm khóa' : 'Hoạt động bình thường', user.isLocked ? AppColors.danger : AppColors.success, textSecondary),
            ],
          ),
        ),
        actions: [
          AppButton(label: 'Đóng', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
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
    final addressCtrl = TextEditingController(text: isEditing ? (existing.address ?? '') : '');
    
    DateTime? selectedDob = isEditing ? existing.dateOfBirth : null;
    String selectedTechInterest = isEditing && existing.techInterest != null && existing.techInterest!.isNotEmpty
        ? (techInterestOptions.contains(existing.techInterest) ? existing.techInterest! : 'Chưa chọn')
        : 'Chưa chọn';
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text(
              isEditing ? 'Sửa Người Dùng: ${existing.fullName}' : 'Tạo Tài Khoản Mới',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: fullNameCtrl, labelText: 'Họ và tên (*)')),
                        const SizedBox(width: 8),
                        Expanded(child: AppTextField(controller: userNameCtrl, labelText: 'Username (*)', readOnly: isEditing)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: emailCtrl, labelText: 'Địa chỉ Email (*)', readOnly: isEditing)),
                        const SizedBox(width: 8),
                        Expanded(child: AppTextField(controller: phoneCtrl, labelText: 'Số điện thoại')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDob ?? DateTime(2000, 1, 1),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDob = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                suffixIcon: const Icon(Icons.calendar_today, size: 16),
                              ),
                              child: Text(
                                selectedDob != null
                                    ? '${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}'
                                    : 'Chọn ngày sinh',
                                style: TextStyle(fontSize: 12, color: textPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppDropdown<String>(
                            value: selectedTechInterest,
                            labelText: 'Sở thích công nghệ',
                            items: [
                              const DropdownMenuItem(value: 'Chưa chọn', child: Text('Chưa chọn / Không rõ')),
                              ...techInterestOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedTechInterest = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(controller: addressCtrl, labelText: 'Địa chỉ cư trú'),
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
            ),
            actions: [
              AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
                onPressed: () async {
                  if (fullNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                  final u = AppUser(
                    id: isEditing ? existing.id : '0',
                    userName: userNameCtrl.text.trim().isNotEmpty ? userNameCtrl.text.trim() : fullNameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                    fullName: fullNameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: role,
                    status: isLocked ? 'Tạm khóa' : 'Hoạt động',
                    isLocked: isLocked,
                    techInterest: selectedTechInterest != 'Chưa chọn' ? selectedTechInterest : null,
                    dateOfBirth: selectedDob,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                    createdAt: isEditing ? existing.createdAt : DateTime.now(),
                  );

                  bool success = true;
                  String msg = 'Cập nhật thông tin thành công!';
                  if (!isEditing) {
                    final ApiResult res = await apiService.createUser(u, '123456', token: token);
                    success = res.success;
                    msg = res.message;
                  } else {
                    final ApiResult res = await apiService.updateUser(u, token: token);
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
        content: Text('Bạn có chắc muốn $actionText tài khoản "${user.email}" (${user.fullName}) không?'),
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

