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
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';
import '../users/demographics_report_view.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedTechInterest = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<AppUser>> _customersFuture;
  bool _showDemographics = false;

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
    _loadCustomers();
  }

  void _loadCustomers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _customersFuture = apiService.getUsers(token: token, isStaffOnly: false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isCustomer(AppUser u) {
    return u.role.toUpperCase() == 'USER' && (u.roles.isEmpty || u.roles.every((r) => r.toUpperCase() == 'USER'));
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_showDemographics) {
      return DemographicsReportView(
        showBackHeader: true,
        onBack: () => setState(() => _showDemographics = false),
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: _customersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var allUsers = snapshot.data ?? [];
        // Lọc chắc chắn chỉ lấy khách hàng
        var customers = allUsers.where(_isCustomer).toList();

        // Lọc tìm kiếm
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          customers = customers.where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.userName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.contains(q) ||
            (u.address != null && u.address!.toLowerCase().contains(q)) ||
            (u.techInterest != null && u.techInterest!.toLowerCase().contains(q))
          ).toList();
        }

        // Lọc sở thích công nghệ
        if (_selectedTechInterest != 'Tất cả') {
          customers = customers.where((u) {
            if (_selectedTechInterest == 'Chưa cập nhật') {
              return u.techInterest == null || u.techInterest!.isEmpty;
            }
            return u.techInterest != null && u.techInterest!.toLowerCase().contains(_selectedTechInterest.toLowerCase());
          }).toList();
        }

        // Lọc trạng thái khóa
        if (_selectedStatus != 'Tất cả') {
          if (_selectedStatus == 'active') {
            customers = customers.where((u) => !u.isLocked).toList();
          } else if (_selectedStatus == 'locked') {
            customers = customers.where((u) => u.isLocked).toList();
          }
        }

        final totalItems = customers.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedCustomers = totalItems == 0
            ? <AppUser>[]
            : customers.skip(startIndex).take(_itemsPerPage).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản Lý Khách Hàng',
                subtitle: 'Theo dõi hồ sơ khách hàng, phân khúc sở thích công nghệ và nhân khẩu học CRM',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Báo cáo nhân khẩu học',
                      icon: Icons.insights_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => setState(() => _showDemographics = true),
                    ),
                    if (authProvider.can('Customers.Create') || authProvider.can('Users.Create')) ...[
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Thêm khách hàng',
                        icon: Icons.person_add_outlined,
                        onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                      ),
                    ],
                  ],
                ),
              ),

              FilterBar(
                searchField: AppSearchField<AppUser>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên khách hàng, email, sđt, địa chỉ...',
                  items: (snapshot.data ?? []).where(_isCustomer).toList(),
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
                  const SizedBox(width: 8),
                  AppDropdown<String>(
                    value: _selectedStatus,
                    labelText: 'Trạng thái',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                      DropdownMenuItem(value: 'locked', child: Text('Đã bị khóa')),
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
                  child: customers.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Không tìm thấy khách hàng nào',
                          message: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc sở thích công nghệ.',
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
                                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('KHÁCH HÀNG / TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('EMAIL / SĐT', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('SỞ THÍCH CÔNG NGHỆ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('NGÀY SINH / TUỔI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('ĐỊA CHỈ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('NGÀY THAM GIA', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                  DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                ],
                                rows: paginatedCustomers.map((u) {
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
                                              backgroundColor: u.isLocked ? AppColors.danger.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                                              child: Text(
                                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'K',
                                                style: TextStyle(
                                                  color: u.isLocked ? AppColors.danger : AppColors.primary,
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
                                          width: 130,
                                          child: Text(
                                            u.address != null && u.address!.isNotEmpty ? u.address! : 'Chưa cập nhật',
                                            style: TextStyle(
                                              color: u.address != null && u.address!.isNotEmpty ? textPrimary : textSecondary,
                                              fontSize: 11,
                                              fontStyle: u.address == null || u.address!.isEmpty ? FontStyle.italic : FontStyle.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
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
                                              tooltip: 'Xem hồ sơ khách hàng',
                                              onPressed: () => _showDetailDialog(context, u),
                                            ),                                            if (authProvider.can('Customers.Update') || authProvider.can('Users.Update'))
                                              IconButton(
                                                icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                tooltip: 'Chỉnh sửa thông tin',
                                                onPressed: () => _showFormDialog(context, apiService, authProvider.token, u),
                                              ),
                                            if (authProvider.can('Customers.Lock') || authProvider.can('Users.Lock'))
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
    if (interest == null || interest.isEmpty) {
      return Text('Chưa cập nhật', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11, fontStyle: FontStyle.italic));
    }

    Color badgeColor = AppColors.primary;
    if (interest.contains('Gaming')) badgeColor = Colors.purple;
    if (interest.contains('AI') || interest.contains('Lập trình')) badgeColor = Colors.indigo;
    if (interest.contains('Âm thanh')) badgeColor = Colors.teal;
    if (interest.contains('Smartwatch')) badgeColor = Colors.orange;
    if (interest.contains('Nhiếp ảnh')) badgeColor = Colors.pink;
    if (interest.contains('SmartHome')) badgeColor = Colors.cyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        interest,
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
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
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'K',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hồ Sơ Khách Hàng: ${user.fullName}',
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
                _buildDetailRow(Icons.tag_rounded, 'Mã khách hàng', '#${user.id}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.account_circle_outlined, 'Tên đăng nhập', '@${user.userName}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.email_outlined, 'Địa chỉ Email', user.email, textPrimary, textSecondary),
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
                _buildDetailRow(Icons.location_on_outlined, 'Địa chỉ nhận hàng', user.address ?? 'Chưa cập nhật', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.calendar_today_outlined, 'Ngày mở tài khoản', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.shield_outlined, 'Trạng thái', user.isLocked ? 'Đã bị khóa' : 'Đang hoạt động', user.isLocked ? AppColors.danger : AppColors.success, textSecondary),
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
    final addressCtrl = TextEditingController(text: isEditing ? (existing.address ?? '') : '');
    final passwordCtrl = TextEditingController();

    DateTime? selectedDob = isEditing ? existing.dateOfBirth : null;
    String selectedTechInterest = isEditing && existing.techInterest != null && existing.techInterest!.isNotEmpty
        ? (techInterestOptions.contains(existing.techInterest) ? existing.techInterest! : 'Chưa chọn')
        : 'Chưa chọn';

    bool isLocked = isEditing ? existing.isLocked : false;

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
              isEditing ? 'Sửa khách hàng: ${existing.fullName}' : 'Thêm khách hàng mới',
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
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(controller: userNameCtrl, labelText: 'Tên đăng nhập (*)')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: emailCtrl, labelText: 'Địa chỉ Email (*)')),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(controller: phoneCtrl, labelText: 'Số điện thoại')),
                      ],
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 12),
                      AppTextField(controller: passwordCtrl, labelText: 'Mật khẩu khởi tạo (*)', obscureText: true),
                    ],
                    const SizedBox(height: 12),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                              ),
                              child: Text(
                                selectedDob != null ? '${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}' : 'Chọn ngày sinh',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppDropdown<String>(
                            value: selectedTechInterest,
                            labelText: 'Sở thích công nghệ',
                            items: [
                              const DropdownMenuItem(value: 'Chưa chọn', child: Text('Chưa chọn')),
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
                    const SizedBox(height: 12),
                    AppTextField(controller: addressCtrl, labelText: 'Địa chỉ cư trú / giao hàng'),
                    if (isEditing) ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('Khóa tài khoản này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Khách hàng bị khóa sẽ không thể đăng nhập đặt hàng', style: TextStyle(fontSize: 11)),
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
                label: isEditing ? 'Lưu Thay Đổi' : 'Tạo Khách Hàng',
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
                    role: 'USER',
                    roles: const ['USER'],
                    status: isLocked ? 'Tạm khóa' : 'Hoạt động',
                    isLocked: isLocked,
                    phone: phoneCtrl.text.trim(),
                    techInterest: selectedTechInterest != 'Chưa chọn' ? selectedTechInterest : null,
                    dateOfBirth: selectedDob,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                    createdAt: isEditing ? existing.createdAt : DateTime.now(),
                  );

                  Navigator.pop(ctx);
                  if (isEditing) {
                    final res = await apiService.updateUser(user, token: token);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                      setState(() => _loadCustomers());
                    }
                  } else {
                    final res = await apiService.createUser(user, passwordCtrl.text.trim(), token: token);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                      setState(() => _loadCustomers());
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
        title: Text(user.isLocked ? 'Mở Khóa Khách Hàng' : 'Khóa Tài Khoản Khách Hàng'),
        content: Text('Bạn có chắc chắn muốn ${user.isLocked ? 'mở khóa' : 'khóa'} tài khoản khách hàng "${user.fullName}" không?'),
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
                final msg = willLock ? 'Đã khóa tài khoản thành công!' : 'Đã mở khóa tài khoản thành công!';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? msg : 'Thao tác thất bại!')),
                );
                setState(() => _loadCustomers());
              }
            },
          ),
        ],
      ),
    );
  }
}
