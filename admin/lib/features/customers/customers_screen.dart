import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/tech_interests.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/smooth_loading_wrapper.dart';
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
  int _itemsPerPage = 10;
  late Future<List<AppUser>> _customersFuture;
  List<TechInterestOption> _techInterests = TechInterestCatalog.defaults;
  bool _showDemographics = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadTechInterests();
  }

  Future<void> _loadTechInterests() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final options = await apiService.getTechInterests(token: token);
    if (mounted && options.isNotEmpty) {
      setState(() => _techInterests = options);
    }
  }

  void _loadCustomers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _customersFuture = apiService.getUsers(token: token, isStaffOnly: false);
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  bool _matchesCustomerQuery(AppUser u, String rawQuery) {
    final q = rawQuery.toLowerCase();
    final interestLabel = u.techInterest != null && u.techInterest!.trim().isNotEmpty
        ? TechInterestCatalog.displayLabel(u.techInterest, options: _techInterests).toLowerCase()
        : '';
    return u.fullName.toLowerCase().contains(q) ||
        u.userName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.toLowerCase().contains(q) ||
        (u.address != null && u.address!.toLowerCase().contains(q)) ||
        (u.techInterest != null && u.techInterest!.toLowerCase().contains(q)) ||
        interestLabel.contains(q);
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
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final canUpdate = authProvider.can('Customers.Update');
    final canLock = authProvider.can('Customers.Lock');
    final hasRowActions = canUpdate || canLock;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_showDemographics) {
      return DemographicsReportView(
        showBackHeader: true,
        onBack: () => setState(() => _showDemographics = false),
      );
    }

    return CachedFutureBuilder<List<AppUser>>(
      future: _customersFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasData = snapshot.hasData;

        var allUsers = snapshot.data ?? [];
        // Lọc chắc chắn chỉ lấy khách hàng
        var customers = allUsers.where(_isCustomer).toList();

        // Lọc tìm kiếm
        if (_searchQuery.isNotEmpty) {
          customers = customers.where((u) => _matchesCustomerQuery(u, _searchQuery)).toList();
        }

        // Lọc sở thích công nghệ
        if (_selectedTechInterest != 'Tất cả') {
          customers = customers
              .where((u) => TechInterestCatalog.matchesFilter(
                    u.techInterest,
                    _selectedTechInterest,
                    options: _techInterests,
                  ))
              .toList();
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
                title: 'Quản lý khách hàng',
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
                    if (authProvider.can('Customers.Create')) ...[
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Thêm khách hàng',
                        icon: Icons.person_add_outlined,
                        onPressed: () => _showFormDialog(apiService, authProvider.token, null, canLock: false),
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
                  searchFilter: _matchesCustomerQuery,
                  itemLabel: (u) => '${u.fullName} (@${u.userName})',
                  itemSubtitle: (u) =>
                      'Email: ${u.email} • Sở thích: ${TechInterestCatalog.displayLabel(u.techInterest, options: _techInterests)}',
                  onSelected: (u) => _applySearch(u.fullName),
                  onSubmitted: (val) => _applySearch(val.trim()),
                  onCleared: () => _applySearch(''),
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedTechInterest,
                    labelText: 'Sở thích công nghệ',
                    items: [
                      const DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả sở thích')),
                      ..._techInterests.map((t) => DropdownMenuItem(value: t.key, child: Text(t.displayName))),
                      const DropdownMenuItem(
                        value: TechInterestCatalog.unsetLabel,
                        child: Text(TechInterestCatalog.unsetLabel),
                      ),
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
                child: SmoothLoadingWrapper(
                  isLoading: isLoading,
                  hasData: hasData,
                  initialMinHeight: 380,
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
                                showCheckboxColumn: false,
                                headingRowHeight: 40,
                                dataRowMinHeight: 46,
                                dataRowMaxHeight: 46,
                                columnSpacing: 14,
                                horizontalMargin: 14,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                columns: [
                                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Khách hàng / Tài khoản', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Email / Số điện thoại', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Sở thích công nghệ', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  if (hasRowActions)
                                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                ],
                                rows: paginatedCustomers.map((u) {
                                  return DataRow(
                                    onSelectChanged: (_) => _showDetailDialog(context, u),
                                    mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
                                    color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
                                      }
                                      if (states.contains(WidgetState.hovered)) {
                                        return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
                                      }
                                      return null;
                                    }),
                                    cells: [
                                      DataCell(Text('#${u.id}', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      DataCell(
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
                                        StatusBadge(
                                          label: u.isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                                          isSuccess: !u.isLocked,
                                          isDanger: u.isLocked,
                                        ),
                                      ),
                                      if (hasRowActions)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (canUpdate)
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                  tooltip: 'Chỉnh sửa thông tin',
                                                  onPressed: () => _showFormDialog(
                                                    apiService,
                                                    authProvider.token,
                                                    u,
                                                    canLock: canLock,
                                                  ),
                                                ),
                                              if (canLock)
                                                IconButton(
                                                  icon: Icon(
                                                    !u.isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                                                    size: 15,
                                                    color: !u.isLocked ? AppColors.danger : AppColors.success,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                  tooltip: !u.isLocked ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                                                  onPressed: () => _confirmToggleActive(apiService, authProvider.token, u),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechInterestBadge(String? interest, bool isDark) {
    final trimmed = interest?.trim() ?? '';
    if (trimmed.isEmpty) {
      return Text(
        TechInterestCatalog.unsetLabel,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final badgeColor = TechInterestCatalog.badgeColor(trimmed, options: _techInterests);
    final label = TechInterestCatalog.displayLabel(trimmed, options: _techInterests);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
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
                  'Hồ sơ khách hàng: ${user.fullName}',
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
                  TechInterestCatalog.displayLabel(user.techInterest, options: _techInterests),
                  (user.techInterest?.trim().isNotEmpty ?? false)
                      ? AppColors.primary
                      : textSecondary,
                  textSecondary,
                  isBoldValue: user.techInterest?.trim().isNotEmpty ?? false,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.cake_outlined,
                  'Ngày sinh / Tuổi',
                  user.dateOfBirth != null
                      ? '${AppDateFormatter.formatDate(user.dateOfBirth!)} (${user.age} tuổi)'
                      : 'Chưa cập nhật',
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on_outlined, 'Địa chỉ nhận hàng', user.address ?? 'Chưa cập nhật', textPrimary, textSecondary),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.calendar_today_outlined, 'Ngày mở tài khoản', AppDateFormatter.formatDate(user.createdAt), textPrimary, textSecondary),
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

  Future<void> _showFormDialog(
    ApiService apiService,
    String? token,
    AppUser? existing, {
    required bool canLock,
  }) async {
    final successMsg = await showDialog<String>(
      context: context,
      builder: (ctx) => _CustomerFormDialog(
        apiService: apiService,
        token: token,
        existing: existing,
        canLock: canLock,
        techInterests: _techInterests,
        onPartialSaved: () {
          if (mounted) {
            setState(() => _loadCustomers());
          }
        },
      ),
    );

    if (successMsg != null && mounted) {
      setState(() => _loadCustomers());
      AppToast.success(context, successMsg);
    }
  }

  Future<void> _confirmToggleActive(ApiService apiService, String? token, AppUser user) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ToggleCustomerLockDialog(
        apiService: apiService,
        token: token,
        user: user,
      ),
    );

    if (success == null || !mounted) return;

    final willLock = !user.isLocked;
    if (success) {
      final msg = willLock ? 'Đã khóa tài khoản thành công!' : 'Đã mở khóa tài khoản thành công!';
      AppToast.success(context, msg);
      setState(() => _loadCustomers());
    } else {
      final errMsg = apiService.lastErrorMessage.isNotEmpty ? apiService.lastErrorMessage : 'Thao tác thất bại!';
      AppToast.error(context, errMsg);
    }
  }
}

/// Dialog tạo/sửa khách hàng để quản lý vòng đời controller, chặn submit trùng và kiểm tra quyền khóa.
class _CustomerFormDialog extends StatefulWidget {
  final ApiService apiService;
  final String? token;
  final AppUser? existing;
  final bool canLock;
  final List<TechInterestOption> techInterests;
  final VoidCallback onPartialSaved;

  const _CustomerFormDialog({
    required this.apiService,
    required this.token,
    this.existing,
    required this.canLock,
    required this.techInterests,
    required this.onPartialSaved,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phoneRegex = RegExp(r'^[0-9+\-\s()]{8,15}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _userNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _passwordCtrl;

  DateTime? _selectedDob;
  late String _selectedTechInterest;
  String? _customTechInterest;
  late bool _isLocked;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _fullNameCtrl = TextEditingController(text: existing?.fullName ?? '');
    _userNameCtrl = TextEditingController(text: existing?.userName ?? '');
    _emailCtrl = TextEditingController(text: existing?.email ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _addressCtrl = TextEditingController(text: existing?.address ?? '');
    _passwordCtrl = TextEditingController();

    _selectedDob = existing?.dateOfBirth;
    final rawInterest = existing?.techInterest?.trim() ?? '';
    if (rawInterest.isNotEmpty) {
      final normalizedKey = TechInterestCatalog.tryNormalizeKey(
        rawInterest,
        options: widget.techInterests,
      );
      if (normalizedKey != null && widget.techInterests.any((o) => o.key == normalizedKey)) {
        _selectedTechInterest = normalizedKey;
      } else {
        _selectedTechInterest = rawInterest;
        _customTechInterest = rawInterest;
      }
    } else {
      _selectedTechInterest = 'Chưa chọn';
    }
    _isLocked = existing?.isLocked ?? false;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _userNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final existing = widget.existing;
    final isEditing = existing != null;

    final user = AppUser(
      id: isEditing ? existing.id : DateTime.now().millisecondsSinceEpoch.toString(),
      userName: _userNameCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: 'USER',
      roles: const ['USER'],
      status: _isLocked ? 'Tạm khóa' : 'Hoạt động',
      isLocked: _isLocked,
      phone: _phoneCtrl.text.trim(),
      techInterest: _selectedTechInterest != 'Chưa chọn' ? _selectedTechInterest : null,
      dateOfBirth: _selectedDob,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      createdAt: isEditing ? existing.createdAt : DateTime.now(),
    );

    final res = isEditing
        ? await widget.apiService.updateUser(user, token: widget.token)
        : await widget.apiService.createUser(user, _passwordCtrl.text.trim(), token: widget.token);

    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context, res.message.isNotEmpty ? res.message : 'Thao tác thành công!');
    } else {
      if (res.message.startsWith('Đã lưu hồ sơ')) {
        widget.onPartialSaved();
      }
      setState(() => _isSubmitting = false);
      final errMsg = res.message.isNotEmpty
          ? res.message
          : (widget.apiService.lastErrorMessage.isNotEmpty
              ? widget.apiService.lastErrorMessage
              : 'Thao tác thất bại!');
      AppToast.error(context, errMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final isEditing = existing != null;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          isEditing ? 'Sửa khách hàng: ${existing.fullName}' : 'Thêm khách hàng mới',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _fullNameCtrl,
                          labelText: 'Họ và tên (*)',
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if (v.isEmpty) return 'Họ và tên không được để trống.';
                            if (v.length > 100) return 'Họ và tên tối đa 100 ký tự.';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _userNameCtrl,
                          labelText: 'Tên đăng nhập (*)',
                          readOnly: isEditing,
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if (v.isEmpty) return 'Tên đăng nhập không được để trống.';
                            if (v.length < 3 || v.length > 50) return 'Tên đăng nhập từ 3 đến 50 ký tự.';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _emailCtrl,
                          labelText: 'Địa chỉ Email (*)',
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if (v.isEmpty) return 'Email không được để trống.';
                            if (v.length > 100) return 'Email tối đa 100 ký tự.';
                            if (!_emailRegex.hasMatch(v)) return 'Định dạng email không hợp lệ.';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _phoneCtrl,
                          labelText: 'Số điện thoại',
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if (v.isEmpty) return null;
                            if (v.length > 15) return 'Số điện thoại tối đa 15 ký tự.';
                            if (!_phoneRegex.hasMatch(v)) return 'Số điện thoại không đúng định dạng.';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _passwordCtrl,
                      labelText: 'Mật khẩu khởi tạo (*)',
                      obscureText: true,
                      validator: (val) {
                        final v = val?.trim() ?? '';
                        if (v.isEmpty) return 'Mật khẩu không được để trống.';
                        if (v.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên.';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _isSubmitting ? null : _pickDateOfBirth,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ngày sinh',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                            child: Text(
                              _selectedDob != null
                                  ? AppDateFormatter.formatDate(_selectedDob!)
                                  : 'Chọn ngày sinh',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDropdown<String>(
                          value: _selectedTechInterest,
                          labelText: 'Sở thích công nghệ',
                          items: [
                            const DropdownMenuItem(value: 'Chưa chọn', child: Text('Chưa chọn')),
                            if (_customTechInterest != null)
                              DropdownMenuItem(value: _customTechInterest!, child: Text(_customTechInterest!)),
                            ...widget.techInterests.map(
                              (t) => DropdownMenuItem(value: t.key, child: Text(t.displayName)),
                            ),
                          ],
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _selectedTechInterest = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _addressCtrl,
                    labelText: 'Địa chỉ cư trú / giao hàng',
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.length > 255) return 'Địa chỉ tối đa 255 ký tự.';
                      return null;
                    },
                  ),
                  if (isEditing && widget.canLock) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Khóa tài khoản này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Khách hàng bị khóa sẽ không thể đăng nhập đặt hàng', style: TextStyle(fontSize: 11)),
                      value: _isLocked,
                      activeThumbColor: AppColors.danger,
                      onChanged: _isSubmitting ? null : (val) => setState(() => _isLocked = val),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.outline,
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
          AppButton(
            label: isEditing ? 'Lưu thay đổi' : 'Tạo khách hàng',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Dialog xác nhận khóa/mở khóa khách hàng, giữ trạng thái loading cho tới khi API phản hồi.
class _ToggleCustomerLockDialog extends StatefulWidget {
  final ApiService apiService;
  final String? token;
  final AppUser user;

  const _ToggleCustomerLockDialog({
    required this.apiService,
    required this.token,
    required this.user,
  });

  @override
  State<_ToggleCustomerLockDialog> createState() => _ToggleCustomerLockDialogState();
}

class _ToggleCustomerLockDialogState extends State<_ToggleCustomerLockDialog> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final willLock = !widget.user.isLocked;
    final success = await widget.apiService.toggleUserLock(
      widget.user.id,
      isLocked: willLock,
      token: widget.token,
    );

    if (!mounted) return;
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text(user.isLocked ? 'Mở khóa khách hàng' : 'Khóa tài khoản khách hàng'),
        content: Text(
          'Bạn có chắc chắn muốn ${user.isLocked ? 'mở khóa' : 'khóa'} tài khoản khách hàng "${user.fullName}" không?',
        ),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.outline,
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
          AppButton(
            label: user.isLocked ? 'Mở khóa' : 'Khóa ngay',
            variant: user.isLocked ? AppButtonVariant.primary : AppButtonVariant.danger,
            isLoading: _isSubmitting,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
