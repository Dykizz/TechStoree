import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/supplier.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'active', 'deleted'
  int _currentPage = 1;
  int _itemsPerPage = 10;
  late Future<List<Supplier>> _suppliersFuture;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _suppliersFuture = apiService.getSuppliers(token: token, status: 'all');
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

    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allSuppliers = snapshot.data ?? [];
        final allCount = allSuppliers.length;
        final activeCount = allSuppliers.where((s) => s.isActive).length;
        final inactiveCount = allSuppliers.where((s) => !s.isActive).length;

        var filteredByStatus = allSuppliers;
        if (_selectedStatus == 'active') {
          filteredByStatus = allSuppliers.where((s) => s.isActive).toList();
        } else if (_selectedStatus == 'inactive' || _selectedStatus == 'deleted') {
          filteredByStatus = allSuppliers.where((s) => !s.isActive).toList();
        }

        var suppliers = filteredByStatus;
        if (_searchQuery.isNotEmpty) {
          suppliers = suppliers.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.phone.contains(_searchQuery) ||
            s.email.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        final totalItems = suppliers.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedSuppliers = totalItems == 0
            ? <Supplier>[]
            : suppliers.skip(startIndex).take(_itemsPerPage).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản lý nhà cung cấp',
                subtitle: 'Quản lý thông tin các nhà đối tác phân phối thiết bị và linh kiện',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Tải lại',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => setState(() => _loadSuppliers()),
                    ),
                    if (authProvider.can('Suppliers.Create')) ...[
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Tạo nhà cung cấp mới',
                        icon: Icons.add_rounded,
                        onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                      ),
                    ],
                  ],
                ),
              ),

              // Thanh Tabs lọc trạng thái (Tất cả / Đang hợp tác / Ngừng hợp tác)
              _buildStatusTabBar(allCount, activeCount, inactiveCount, isDark, textPrimary, textSecondary),

              FilterBar(
                searchField: AppSearchField<Supplier>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên nhà cung cấp, sđt, email...',
                  items: filteredByStatus,
                  searchFilter: (s, q) => s.name.toLowerCase().contains(q.toLowerCase()) ||
                      s.phone.contains(q) ||
                      s.email.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (s) => s.name,
                  itemSubtitle: (s) => 'SĐT: ${s.phone} • Email: ${s.email}',
                  onSelected: (s) => setState(() => _searchQuery = s.name),
                  onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
              ),

              // Dòng thống kê nhanh
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                child: Row(
                  children: [
                    Icon(Icons.domain_rounded, size: 13, color: textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      _searchQuery.isNotEmpty
                          ? '$totalItems kết quả tìm kiếm'
                          : (_selectedStatus == 'active'
                              ? 'Tổng $totalItems nhà cung cấp đang hợp tác'
                              : (_selectedStatus == 'inactive' || _selectedStatus == 'deleted'
                                  ? 'Tổng $totalItems nhà cung cấp đã ngừng hợp tác'
                                  : 'Tổng $totalItems nhà cung cấp')),
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),

              DataTableContainer(
                  child: suppliers.isEmpty
                      ? const EmptyState(
                          icon: Icons.domain_outlined,
                          title: 'Không tìm thấy nhà cung cấp nào',
                          message: 'Thử tìm kiếm từ khóa khác hoặc thêm nhà cung cấp mới.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScrollableTableWrapper(
                              child: DataTable(
                                headingRowHeight: 38,
                                dataRowMinHeight: 46,
                                dataRowMaxHeight: 46,
                                columnSpacing: 16,
                                horizontalMargin: 16,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                columns: [
                                  DataColumn(label: Text('Mã NCC', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Tên nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                  DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                ],
                                rows: paginatedSuppliers.map((sup) {
                                  final canUpdate = authProvider.can('Suppliers.Update');
                                  final canDelete = authProvider.can('Suppliers.Delete');
                                  final isActive = sup.isActive;
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                      if (!isActive) {
                                        return isDark
                                            ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                                            : const Color(0xFFFFFBEB).withValues(alpha: 0.6);
                                      }
                                      if (states.contains(WidgetState.hovered)) {
                                        return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                                      }
                                      return null;
                                    }),
                                    cells: [
                                      // Mã NCC
                                      DataCell(Text(sup.code, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      // Tên NCC
                                      DataCell(
                                        Text(
                                          sup.name,
                                          style: TextStyle(
                                            color: !isActive ? textSecondary : textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      // Số điện thoại (tách riêng)
                                      DataCell(
                                        Text(
                                          sup.phone.isNotEmpty ? sup.phone : '—',
                                          style: TextStyle(color: textSecondary, fontSize: 12),
                                        ),
                                      ),
                                      // Email (tách riêng)
                                      DataCell(
                                        Text(
                                          sup.email.isNotEmpty ? sup.email : '—',
                                          style: TextStyle(color: textSecondary, fontSize: 12),
                                        ),
                                      ),
                                      // Địa chỉ (Tooltip để xem đầy đủ khi hover)
                                      DataCell(
                                        Tooltip(
                                          message: sup.address.isNotEmpty ? sup.address : '',
                                          child: Text(
                                            sup.address.isNotEmpty ? sup.address : '—',
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Badge trạng thái
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isActive ? AppColors.successBg : AppColors.warningBg,
                                            border: Border.all(color: isActive ? AppColors.successBorder : AppColors.warningBorder),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isActive ? 'Đang hợp tác' : 'Ngừng hợp tác',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isActive ? AppColors.success : AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Thao tác
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Nút xem chi tiết (luôn hiển thị)
                                            IconButton(
                                              icon: Icon(Icons.visibility_outlined, size: 15, color: AppColors.primary),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              tooltip: 'Xem chi tiết',
                                              onPressed: () => _showDetailDialog(context, sup, textPrimary, textSecondary, isDark),
                                            ),
                                            if (canUpdate)
                                              IconButton(
                                                icon: Icon(
                                                  isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                                  size: 16,
                                                  color: isActive ? AppColors.warning : AppColors.success,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                tooltip: isActive ? 'Ngừng hợp tác' : 'Tiếp tục hợp tác',
                                                onPressed: () => _confirmToggleActive(context, apiService, authProvider.token, sup),
                                              ),
                                            if (canUpdate)
                                              IconButton(
                                                icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                tooltip: 'Chỉnh sửa',
                                                onPressed: () => _showFormDialog(context, apiService, authProvider.token, sup),
                                              ),
                                            if (canDelete)
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                tooltip: 'Xóa nhà cung cấp',
                                                onPressed: () => _confirmDelete(context, apiService, authProvider.token, sup),
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
            ],
          ),
        );
      },
    );
  }

  /// Dialog xem chi tiết đầy đủ thông tin nhà cung cấp
  Widget _buildStatusTabBar(int allCount, int activeCount, int inactiveCount, bool isDark, Color textPrimary, Color textSecondary) {
    final tabs = [
      {'key': 'all', 'label': 'Tất cả', 'count': allCount, 'color': AppColors.primary},
      {'key': 'active', 'label': 'Đang hợp tác', 'count': activeCount, 'color': AppColors.success},
      {'key': 'inactive', 'label': 'Ngừng hợp tác', 'count': inactiveCount, 'color': AppColors.warning},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final key = tab['key'] as String;
            final label = tab['label'] as String;
            final count = tab['count'] as int;
            final color = tab['color'] as Color;
            final isSelected = _selectedStatus == key;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  if (_selectedStatus != key) {
                    setState(() {
                      _selectedStatus = key;
                      _currentPage = 1;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? color.withAlpha(50) : color.withAlpha(25))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? (isDark ? Colors.white : color) : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Supplier sup, Color textPrimary, Color textSecondary, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.domain_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sup.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                  Text(sup.code, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            // Badge trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sup.isDeleted ? AppColors.dangerBg : AppColors.successBg,
                border: Border.all(color: sup.isDeleted ? AppColors.dangerBorder : AppColors.successBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sup.isDeleted ? 'Đã xóa' : 'Hoạt động',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sup.isDeleted ? AppColors.danger : AppColors.success),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildDetailRow(Icons.phone_outlined, 'Số điện thoại', sup.phone.isNotEmpty ? sup.phone : '—', textPrimary, textSecondary, borderColor),
              _buildDetailRow(Icons.email_outlined, 'Email liên hệ', sup.email.isNotEmpty ? sup.email : '—', textPrimary, textSecondary, borderColor),
              _buildDetailRow(Icons.location_on_outlined, 'Địa chỉ trụ sở', sup.address.isNotEmpty ? sup.address : '—', textPrimary, textSecondary, borderColor, isLast: true),
            ],
          ),
        ),
        actions: [
          AppButton(label: 'Đóng', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color textPrimary, Color textSecondary, Color borderColor, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, ApiService apiService, String? token, Supplier? existing) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: isEditing ? existing.name : '');
    final phoneCtrl = TextEditingController(text: isEditing ? existing.phone : '');
    final emailCtrl = TextEditingController(text: isEditing ? existing.email : '');
    final addressCtrl = TextEditingController(text: isEditing ? existing.address : '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: Text(
            isEditing ? 'Sửa Nhà Cung Cấp: ${existing.name}' : 'Tạo nhà cung cấp mới',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, labelText: 'Tên nhà cung cấp (*)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: phoneCtrl, labelText: 'Số điện thoại')),
                    const SizedBox(width: 8),
                    Expanded(child: AppTextField(controller: emailCtrl, labelText: 'Email liên hệ')),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(controller: addressCtrl, maxLines: 2, labelText: 'Địa chỉ trụ sở / kho hàng'),
              ],
            ),
          ),
          actions: [
            AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
            AppButton(
              label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final sup = Supplier(
                  id: isEditing ? existing.id : '0',
                  name: nameCtrl.text.trim(),
                  code: isEditing ? existing.code : 'SUP-${DateTime.now().millisecondsSinceEpoch}',
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  isActive: isEditing ? existing.isActive : true,
                );

                final res = isEditing
                    ? await apiService.updateSupplier(sup, token: token)
                    : await apiService.createSupplier(sup, token: token);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() => _loadSuppliers());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res ? 'Thao tác thành công!' : 'Thao tác thất bại!'), backgroundColor: res ? AppColors.success : AppColors.danger),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmToggleActive(BuildContext context, ApiService apiService, String? token, Supplier sup) {
    final willActive = !sup.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          willActive ? 'Tiếp tục hợp tác' : 'Xác nhận ngừng hợp tác',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        content: Text(
          willActive
              ? 'Bạn có chắc muốn tiếp tục hợp tác với nhà cung cấp "${sup.name}" để cho phép tạo phiếu nhập hàng mới?'
              : 'Bạn có chắc muốn ngừng hợp tác với nhà cung cấp "${sup.name}"? Nhà cung cấp sẽ không thể chọn khi tạo phiếu nhập mới.',
        ),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: willActive ? 'Tiếp Tục Hợp Tác' : 'Ngừng Hợp Tác',
            variant: willActive ? AppButtonVariant.primary : AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.toggleActiveSupplier(sup.id, token: token);
              if (context.mounted) {
                if (res.success) {
                  setState(() => _loadSuppliers());
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Thao tác thành công!' : 'Thao tác thất bại!')),
                    backgroundColor: res.success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ApiService apiService, String? token, Supplier sup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Xác nhận xóa nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn xóa nhà cung cấp "${sup.name}" khỏi danh sách? Dữ liệu lịch sử phiếu nhập trong quá khứ vẫn được bảo toàn.'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Xóa',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteSupplier(sup.id, token: token);
              if (context.mounted) {
                if (res.success) {
                  setState(() => _loadSuppliers());
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Xóa nhà cung cấp thành công!' : 'Thao tác thất bại!')),
                    backgroundColor: res.success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
