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
import '../../core/widgets/status_badge.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<Supplier>> _suppliersFuture;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _suppliersFuture = apiService.getSuppliers(token: token);
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

        var suppliers = snapshot.data ?? [];
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

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản Lý Nhà Cung Cấp',
                subtitle: 'Quản lý thông tin các nhà đối tác phân phối thiết bị và linh kiện',
                action: AppButton(
                  label: 'Tạo Nhà Cung Cấp Mới',
                  icon: Icons.add_rounded,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ),
              ),

              FilterBar(
                searchField: AppSearchField<Supplier>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên nhà cung cấp, sđt, email...',
                  items: snapshot.data ?? [],
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

              Flexible(
                fit: FlexFit.loose,
                child: DataTableContainer(
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
                                        DataColumn(label: Text('MÃ NCC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TÊN NHÀ CUNG CẤP', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('NGƯỜI LIÊN HỆ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('SỐ ĐIỆN THOẠI / EMAIL', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('ĐỊA CHỈ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                      ],
                                      rows: paginatedSuppliers.map((sup) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(Text(sup.code, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.domain_rounded, size: 15, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(sup.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            DataCell(Text(sup.contactName, style: TextStyle(color: textPrimary, fontSize: 12))),
                                            DataCell(
                                              Text('${sup.phone.isNotEmpty ? sup.phone : '—'} / ${sup.email.isNotEmpty ? sup.email : '—'}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                            ),
                                            DataCell(
                                              Text(
                                                sup.address.isNotEmpty ? sup.address : '—',
                                                style: TextStyle(color: textSecondary, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DataCell(
                                              const StatusBadge(
                                                label: 'ĐANG ĐỐI TÁC',
                                                isSuccess: true,
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
                                                    tooltip: 'Chỉnh sửa',
                                                    onPressed: () => _showFormDialog(context, apiService, authProvider.token, sup),
                                                  ),
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

  void _showFormDialog(BuildContext context, ApiService apiService, String? token, Supplier? existing) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: isEditing ? existing.name : '');
    final contactCtrl = TextEditingController(text: isEditing ? existing.contactName : '');
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
            isEditing ? 'Sửa Nhà Cung Cấp: ${existing.name}' : 'Tạo Nhà Cung Cấp Mới',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, labelText: 'Tên nhà cung cấp (*)'),
                const SizedBox(height: 10),
                AppTextField(controller: contactCtrl, labelText: 'Tên người đại diện / liên hệ'),
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
                  contactName: contactCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
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

  void _confirmDelete(BuildContext context, ApiService apiService, String? token, Supplier sup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Xác nhận xóa nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn xóa nhà cung cấp "${sup.name}" không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Xóa Nhà Cung Cấp',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteSupplier(sup.id, token: token);
              if (context.mounted) {
                setState(() => _loadSuppliers());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res ? 'Xóa thành công!' : 'Xóa thất bại!'), backgroundColor: res ? AppColors.success : AppColors.danger),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
