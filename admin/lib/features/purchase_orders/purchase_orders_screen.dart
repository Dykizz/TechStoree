import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/purchase_order.dart';
import '../../core/models/supplier.dart';
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
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/status_badge.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'Tất cả';
  int _selectedSupplierId = 0;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  late Future<List<PurchaseOrder>> _ordersFuture;
  late Future<List<Supplier>> _suppliersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _ordersFuture = apiService.getPurchaseOrders(token: token);
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
      builder: (context, supplierSnap) {
        final suppliers = supplierSnap.data ?? [];

        return FutureBuilder<List<PurchaseOrder>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            var orders = snapshot.data ?? [];

            // Filters
            if (_searchQuery.isNotEmpty) {
              orders = orders.where((o) =>
                o.poCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                o.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                o.createdByName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                o.note.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
            }

            if (_selectedStatus != 'Tất cả') {
              orders = orders.where((o) => o.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
            }

            if (_selectedSupplierId > 0) {
              orders = orders.where((o) => o.supplierId == _selectedSupplierId).toList();
            }

            final totalItems = orders.length;
            final totalPages = (totalItems / _itemsPerPage).ceil();
            final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
            final startIndex = (safePage - 1) * _itemsPerPage;
            final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
            final paginatedOrders = orders.sublist(startIndex, endIndex);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Quản lý Phiếu nhập hàng (Purchase Orders)',
                    subtitle: 'Theo dõi đợt nhập hàng từ nhà cung cấp theo từng biến thể sản phẩm',
                    action: authProvider.can('PurchaseOrders.Create')
                        ? AppButton(
                            label: 'Tạo phiếu nhập hàng mới',
                            icon: Icons.add_rounded,
                            variant: AppButtonVariant.primary,
                            onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers),
                          )
                        : null,
                  ),

                  // Filter Controls
                  FilterBar(
                    searchField: AppSearchField<PurchaseOrder>(
                      controller: _searchCtrl,
                      hintText: 'Tìm kiếm mã PO, nhà cung cấp, người tạo...',
                      items: orders,
                      searchFilter: (po, q) => po.poCode.toLowerCase().contains(q.toLowerCase()) ||
                          po.supplierName.toLowerCase().contains(q.toLowerCase()) ||
                          po.note.toLowerCase().contains(q.toLowerCase()),
                      itemLabel: (po) => '${po.poCode} - ${po.supplierName}',
                      itemSubtitle: (po) => '${currencyFormat.format(po.totalCost)} • ${po.status}',
                      onSelected: (po) => setState(() => _searchQuery = po.poCode),
                      onSubmitted: (val) => setState(() => _searchQuery = val),
                      onCleared: () => setState(() => _searchQuery = ''),
                    ),
                    filters: [
                      AppDropdown<int>(
                        value: _selectedSupplierId,
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('Tất cả nhà cung cấp')),
                          ...suppliers.map((s) {
                            final sId = int.tryParse(s.id) ?? 0;
                            final label = !s.isActive ? '${s.name} [Ngừng HT]' : s.name;
                            return DropdownMenuItem(value: sId, child: Text(label, overflow: TextOverflow.ellipsis));
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedSupplierId = val ?? 0),
                      ),
                      AppDropdown<String>(
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                          DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Bản nháp)')),
                          DropdownMenuItem(value: 'COMPLETE', child: Text('COMPLETE (Đã hoàn thành)')),
                          DropdownMenuItem(value: 'CANCLE', child: Text('CANCLE (Đã hủy)')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val ?? 'Tất cả'),
                      ),
                    ],
                  ),

                  // Table Container
                  DataTableContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        orders.isEmpty
                                ? const EmptyState(
                                    title: 'Chưa có phiếu nhập hàng nào',
                                    message: 'Không tìm thấy phiếu nhập khớp với bộ lọc.',
                                    icon: Icons.inventory_2_outlined,
                                  )
                                : ScrollableTableWrapper(
                                    child: DataTable(
                                              headingRowHeight: 40,
                                              dataRowMinHeight: 50,
                                              dataRowMaxHeight: 54,
                                              columnSpacing: 14,
                                              horizontalMargin: 12,
                                              headingRowColor: WidgetStateProperty.all(
                                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                              ),
                                              columns: [
                                                DataColumn(label: Text('Mã PO', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Người tạo', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Số dòng hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Tổng chi phí', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                              ],
                                              rows: paginatedOrders.map((po) {
                                                return DataRow(
                                                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                                                    if (states.contains(WidgetState.hovered)) {
                                                      return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                                                    }
                                                    return null;
                                                  }),
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        po.poCode,
                                                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(po.supplierName, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                                                    ),
                                                    DataCell(
                                                      Text(po.createdByName.isNotEmpty ? po.createdByName : 'Admin', style: TextStyle(color: textSecondary, fontSize: 11.5)),
                                                    ),
                                                    DataCell(
                                                      Text('${po.totalItems} sản phẩm', style: TextStyle(color: textPrimary, fontSize: 12)),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        currencyFormat.format(po.totalCost),
                                                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                                      ),
                                                    ),
                                                    DataCell(_renderStatusBadge(po.status)),
                                                    DataCell(
                                                      Text(dateFormat.format(po.createdAt), style: TextStyle(color: textSecondary, fontSize: 11)),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Tooltip(
                                                            message: 'Xem chi tiết phiếu nhập',
                                                            child: IconButton(
                                                              icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                              onPressed: () => _showDetailDialog(context, apiService, authProvider.token, po.purchaseOrderId),
                                                            ),
                                                          ),
                                                          if (po.isDraft && authProvider.can('PurchaseOrders.Update')) ...[
                                                            const SizedBox(width: 4),
                                                            Tooltip(
                                                              message: 'Chỉnh sửa phiếu nháp',
                                                              child: IconButton(
                                                                icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                                                                padding: EdgeInsets.zero,
                                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                                onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers, existingPoId: po.purchaseOrderId),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Tooltip(
                                                              message: 'Hoàn thành phiếu (COMPLETE)',
                                                              child: IconButton(
                                                                icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                                                padding: EdgeInsets.zero,
                                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                                onPressed: () => _confirmStatusChange(context, apiService, authProvider.token, po, 'COMPLETE'),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Tooltip(
                                                              message: 'Hủy phiếu nhập (CANCLE)',
                                                              child: IconButton(
                                                                icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                                                                padding: EdgeInsets.zero,
                                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                                onPressed: () => _confirmStatusChange(context, apiService, authProvider.token, po, 'CANCLE'),
                                                              ),
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
                              onItemsPerPageChanged: (size) => setState(() {
                                _itemsPerPage = size;
                                _currentPage = 1;
                              }),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _renderStatusBadge(String status) {
    final s = status.toUpperCase();
    if (s == 'COMPLETE' || s == 'COMPLETED') {
      return const StatusBadge(label: 'COMPLETE', isSuccess: true);
    } else if (s == 'CANCLE' || s == 'CANCELLED') {
      return const StatusBadge(label: 'CANCLE', isDanger: true);
    } else {
      return const StatusBadge(label: 'DRAFT', isWarning: true);
    }
  }

  // --- Confirm Status Change ---
  void _confirmStatusChange(BuildContext context, ApiService apiService, String? token, PurchaseOrder po, String targetStatus) {
    final isCompleting = targetStatus == 'COMPLETE';
    final actionLabel = isCompleting ? 'Hoàn thành (COMPLETE)' : 'Hủy phiếu (CANCLE)';
    final message = isCompleting
        ? 'Chốt phiếu nhập "${po.poCode}"? Sau khi hoàn thành, số lượng tồn kho của các biến thể sẽ được cộng vào hệ thống.'
        : 'Bạn có chắc muốn hủy phiếu nhập "${po.poCode}"? Phiếu nhập sẽ chuyển sang trạng thái CANCLE và tồn kho giữ nguyên.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: Row(
          children: [
            Icon(isCompleting ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: isCompleting ? AppColors.success : AppColors.danger, size: 20),
            const SizedBox(width: AppTokens.space8),
            Text('Xác nhận $actionLabel', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          AppButton(
            label: 'Hủy bỏ',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: isCompleting ? 'Hoàn thành' : 'Hủy phiếu',
            variant: isCompleting ? AppButtonVariant.primary : AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedPo = PurchaseOrder(
                purchaseOrderId: po.purchaseOrderId,
                poCode: po.poCode,
                supplierId: po.supplierId,
                supplierName: po.supplierName,
                createdByUserId: po.createdByUserId,
                createdByName: po.createdByName,
                status: targetStatus,
                note: po.note,
                createdAt: po.createdAt,
                totalCost: po.totalCost,
                totalItems: po.totalItems,
                items: po.items,
              );
              final res = (targetStatus == 'CANCLE' || targetStatus == 'CANCEL')
                  ? await apiService.deletePurchaseOrder(po.purchaseOrderId, token: token)
                  : await apiService.updatePurchaseOrder(po.purchaseOrderId, updatedPo, token: token);
              if (context.mounted) {
                if (res.success) {
                  setState(() => _loadData());
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
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

  // --- Show Detail Dialog ---
  void _showDetailDialog(BuildContext context, ApiService apiService, String? token, int poId) async {
    final po = await apiService.getPurchaseOrderById(poId, token: token);
    if (!context.mounted || po == null) return;

    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: AppTokens.space8),
            Text('Chi Tiết Phiếu Nhập: ${po.poCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            _renderStatusBadge(po.status),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoItem('Nhà cung cấp', po.supplierName, textPrimary, textSecondary)),
                    Expanded(child: _buildInfoItem('Ngày tạo', dateFormat.format(po.createdAt), textPrimary, textSecondary)),
                    const Spacer(), // Balance layout
                  ],
                ),
                const SizedBox(height: AppTokens.space12),
                
                // Thông tin người tạo phiếu
                Container(
                  padding: const EdgeInsets.all(AppTokens.space12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTokens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                        child: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppTokens.space12),
                      _buildInfoItem(
                        'Người tạo phiếu (Yêu cầu)',
                        po.createdByName.isNotEmpty ? po.createdByName : 'Thủ kho',
                        textPrimary,
                        textSecondary,
                      ),
                    ],
                  ),
                ),
                if (po.note.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space8),
                  _buildInfoItem('Ghi chú phiếu nhập', po.note, textPrimary, textSecondary),
                ],
                const SizedBox(height: AppTokens.space12),
                const Divider(),
                const SizedBox(height: AppTokens.space8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DANH SÁCH CHI TIẾT CÁC BIẾN THỂ NHẬP KHO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                    Text('Tổng dòng hàng: ${po.items.length}', style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: AppTokens.space8),

                DataTableContainer(
                  isScrollableTable: true,
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 12,
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Đơn giá nhập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                    ],
                    rows: po.items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.productName.isNotEmpty ? item.productName : item.fullName, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.variantName.isNotEmpty ? item.variantName : 'Biến thể #${item.variantId}', style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        DataCell(Text(currencyFormat.format(item.importPrice), style: TextStyle(fontSize: 11.5, color: textPrimary))),
                        DataCell(Text('${item.quantity}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary))),
                        DataCell(Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                      ]);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppTokens.space12),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TỔNG CHI PHÍ PHIẾU NHẬP: ${currencyFormat.format(po.totalCost)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (po.isDraft) ...[
            AppButton(
              label: 'Hủy phiếu (CANCLE)',
              variant: AppButtonVariant.danger,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmStatusChange(context, apiService, token, po, 'CANCLE');
              },
            ),
            AppButton(
              label: 'Hoàn thành & Nhập kho (COMPLETE)',
              variant: AppButtonVariant.primary,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmStatusChange(context, apiService, token, po, 'COMPLETE');
              },
            ),
          ],
          AppButton(
            label: 'Đóng',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary)),
      ],
    );
  }

  // --- Create / Edit Dialog ---
  void _showCreateOrEditDialog(
    BuildContext context,
    ApiService apiService,
    String? token, {
    required List<Supplier> suppliers,
    int? existingPoId,
  }) async {
    final products = await apiService.getProductsWithVariants(token: token);
    PurchaseOrder? existingPo;
    if (existingPoId != null && existingPoId > 0) {
      existingPo = await apiService.getPurchaseOrderById(existingPoId, token: token);
    }

    if (!context.mounted) return;

    final isEditing = existingPoId != null && existingPoId > 0;
    final availableSuppliers = isEditing
        ? suppliers.where((s) => s.isActive || int.tryParse(s.id) == existingPo?.supplierId).toList()
        : suppliers.where((s) => s.isActive).toList();
    if (availableSuppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có Nhà cung cấp nào đang hợp tác để lập phiếu nhập hàng.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    List<_VariantSelectOption> variantOptions = [];
    for (var p in products) {
      if (p.variants.isNotEmpty) {
        for (var v in p.variants) {
          final vId = v.variantId ?? 0;
          if (vId > 0) {
            final vName = v.variantName;
            variantOptions.add(_VariantSelectOption(
              variantId: vId,
              productId: int.tryParse(p.id) ?? 0,
              productName: p.name,
              variantName: vName,
              fullName: '${p.name} ($vName)',
              defaultPrice: v.price > 0 ? v.price : p.price,
              stockQuantity: v.stockQuantity,
              imageUrl: v.imageUrl?.isNotEmpty == true ? v.imageUrl : p.imageUrl,
            ));
          }
        }
      } else {
        final pId = int.tryParse(p.id) ?? 0;
        if (pId > 0) {
          variantOptions.add(_VariantSelectOption(
            variantId: pId,
            productId: pId,
            productName: p.name,
            variantName: 'Biến thể mặc định',
            fullName: p.name,
            defaultPrice: p.price,
            stockQuantity: p.stock,
            imageUrl: p.imageUrl,
          ));
        }
      }
    }

    if (variantOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh sách biến thể sản phẩm hợp lệ trong hệ thống.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PurchaseOrderFormDialog(
        existingPo: existingPo,
        suppliers: availableSuppliers,
        variantOptions: variantOptions,
        apiService: apiService,
        token: token,
        onSaved: () {
          setState(() => _loadData());
        },
      ),
    );
  }
}

class _VariantSelectOption {
  final int variantId;
  final int productId;
  final String productName;
  final String variantName;
  final String fullName;
  final double defaultPrice;
  final int stockQuantity;
  final String? imageUrl;

  _VariantSelectOption({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.fullName,
    required this.defaultPrice,
    required this.stockQuantity,
    this.imageUrl,
  });
}

class _POItemRowInput {
  _VariantSelectOption selectedVariant;
  final TextEditingController importPriceCtrl;
  final TextEditingController quantityCtrl;

  _POItemRowInput({
    required this.selectedVariant,
    double importPrice = 0,
    int quantity = 1,
  })  : importPriceCtrl = TextEditingController(
          text: importPrice > 0
              ? NumberFormat('#,###', 'en_US').format(importPrice.toInt())
              : (selectedVariant.defaultPrice > 0
                  ? NumberFormat('#,###', 'en_US').format(selectedVariant.defaultPrice.toInt())
                  : ''),
        ),
        quantityCtrl = TextEditingController(text: quantity > 0 ? quantity.toString() : '1');

  double get importPrice {
    final clean = importPriceCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    return double.tryParse(clean) ?? 0;
  }

  int get quantity {
    final clean = quantityCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    return int.tryParse(clean) ?? 1;
  }

  double get totalPrice => importPrice * quantity;

  void dispose() {
    importPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}

class _PurchaseOrderFormDialog extends StatefulWidget {
  final PurchaseOrder? existingPo;
  final List<Supplier> suppliers;
  final List<_VariantSelectOption> variantOptions;
  final ApiService apiService;
  final String? token;
  final VoidCallback onSaved;

  const _PurchaseOrderFormDialog({
    required this.existingPo,
    required this.suppliers,
    required this.variantOptions,
    required this.apiService,
    required this.token,
    required this.onSaved,
  });

  @override
  State<_PurchaseOrderFormDialog> createState() => _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState extends State<_PurchaseOrderFormDialog> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  late int _selectedSupplierId;
  late String _selectedStatus;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;

  final List<_POItemRowInput> _itemRows = [];
  String _searchQuery = '';
  bool _showDropdown = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.existingPo != null;
    final po = widget.existingPo;

    _selectedSupplierId = isEditing
        ? po!.supplierId
        : (int.tryParse(widget.suppliers.first.id) ?? 1);

    // Khi tạo mới: Mặc định là DRAFT (chỉ có DRAFT hoặc COMPLETE)
    _selectedStatus = isEditing ? po!.status : 'DRAFT';

    _noteCtrl = TextEditingController(text: isEditing ? po!.note : '');
    _searchCtrl = TextEditingController();
    _searchFocusNode = FocusNode();

    // Khởi tạo mặt hàng: Nếu chỉnh sửa thì nạp items cũ, nếu tạo mới thì ban đầu để RỖNG
    if (isEditing && po!.items.isNotEmpty) {
      for (var item in po.items) {
        final opt = widget.variantOptions.firstWhere(
          (o) => o.variantId == item.variantId,
          orElse: () => _VariantSelectOption(
            variantId: item.variantId,
            productId: item.productId ?? 0,
            productName: item.productName,
            variantName: item.variantName,
            fullName: item.fullName,
            defaultPrice: item.importPrice,
            stockQuantity: 0,
          ),
        );
        _itemRows.add(_POItemRowInput(
          selectedVariant: opt,
          importPrice: item.importPrice,
          quantity: item.quantity,
        ));
      }
    }

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
          _showDropdown = q.isNotEmpty;
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchCtrl.text.trim().isNotEmpty) {
        setState(() {
          _showDropdown = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    for (var r in _itemRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addVariantToPo(_VariantSelectOption variant) {
    final existingIdx = _itemRows.indexWhere((r) => r.selectedVariant.variantId == variant.variantId);
    setState(() {
      if (existingIdx != -1) {
        final row = _itemRows[existingIdx];
        final currentQty = row.quantity;
        row.quantityCtrl.text = (currentQty + 1).toString();
      } else {
        _itemRows.add(_POItemRowInput(
          selectedVariant: variant,
          importPrice: variant.defaultPrice,
          quantity: 1,
        ));
      }
      _searchCtrl.clear();
      _searchQuery = '';
      _showDropdown = false;
    });
  }

  double get _totalCalc {
    double total = 0;
    for (var r in _itemRows) {
      total += r.totalPrice;
    }
    return total;
  }

  int get _totalQuantity {
    int qty = 0;
    for (var r in _itemRows) {
      qty += r.quantity;
    }
    return qty;
  }

  Future<void> _handleSave() async {
    if (_itemRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 mặt hàng vào phiếu nhập.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Kiểm tra trùng lặp và tính hợp lệ của đơn giá & số lượng
    final seenVariantIds = <int>{};
    for (var r in _itemRows) {
      if (seenVariantIds.contains(r.selectedVariant.variantId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phát hiện biến thể "${r.selectedVariant.fullName}" bị chọn trùng lặp. Vui lòng gộp số lượng vào 1 dòng.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      seenVariantIds.add(r.selectedVariant.variantId);

      if (r.importPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đơn giá nhập của "${r.selectedVariant.fullName}" phải lớn hơn 0.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (r.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số lượng nhập của "${r.selectedVariant.fullName}" phải lớn hơn 0.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final isEditing = widget.existingPo != null;
    List<PurchaseOrderItem> poItems = _itemRows.map((r) => PurchaseOrderItem(
      variantId: r.selectedVariant.variantId,
      productId: r.selectedVariant.productId,
      productName: r.selectedVariant.productName,
      variantName: r.selectedVariant.variantName,
      importPrice: r.importPrice,
      quantity: r.quantity,
    )).toList();

    final po = PurchaseOrder(
      purchaseOrderId: isEditing ? widget.existingPo!.purchaseOrderId : 0,
      poCode: isEditing ? widget.existingPo!.poCode : '',
      supplierId: _selectedSupplierId,
      status: _selectedStatus,
      note: _noteCtrl.text.trim(),
      createdAt: isEditing ? widget.existingPo!.createdAt : DateTime.now(),
      totalCost: _totalCalc,
      totalItems: poItems.length,
      items: poItems,
    );

    ApiResult result;
    if (isEditing) {
      if (_selectedStatus == 'CANCLE' || _selectedStatus == 'CANCEL') {
        result = await widget.apiService.deletePurchaseOrder(widget.existingPo!.purchaseOrderId, token: widget.token);
      } else {
        result = await widget.apiService.updatePurchaseOrder(widget.existingPo!.purchaseOrderId, po, token: widget.token);
      }
    } else {
      result = await widget.apiService.createPurchaseOrder(po, token: widget.token);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final isEditing = widget.existingPo != null;

    final matchingVariants = _searchQuery.isEmpty
        ? <_VariantSelectOption>[]
        : widget.variantOptions.where((v) {
            final q = _searchQuery.toLowerCase();
            return v.productName.toLowerCase().contains(q) ||
                v.variantName.toLowerCase().contains(q) ||
                v.fullName.toLowerCase().contains(q) ||
                v.variantId.toString().contains(q);
          }).toList();

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppTokens.space8),
              Text(
                isEditing ? 'Sửa Phiếu Nhập Hàng (${widget.existingPo?.poCode})' : 'Tạo Phiếu Nhập Hàng Mới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
      content: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thông tin chung: Nhà cung cấp & Trạng thái
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nhà cung cấp (*)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 6),
                        AppDropdown<int>(
                          value: widget.suppliers.any((s) => int.tryParse(s.id) == _selectedSupplierId)
                              ? _selectedSupplierId
                              : (int.tryParse(widget.suppliers.first.id) ?? 1),
                          items: widget.suppliers.map((s) {
                            final sId = int.tryParse(s.id) ?? 1;
                            final label = !s.isActive ? '${s.name} [Ngừng HT]' : s.name;
                            return DropdownMenuItem<int>(
                              value: sId,
                              child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSupplierId = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trạng thái (*)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 6),
                        AppDropdown<String>(
                          value: _selectedStatus,
                          items: isEditing
                              ? const [
                                  DropdownMenuItem(
                                    value: 'DRAFT',
                                    child: Text('DRAFT (Bản nháp)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COMPLETE',
                                    child: Text('COMPLETE (Nhập kho)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CANCLE',
                                    child: Text('CANCLE (Hủy phiếu)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppColors.danger)),
                                  ),
                                ]
                              : const [
                                  // Khi tạo mới: CHỈ CÓ DRAFT hoặc COMPLETE
                                  DropdownMenuItem(
                                    value: 'DRAFT',
                                    child: Text('DRAFT (Bản nháp - Lưu tạm)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COMPLETE',
                                    child: Text('COMPLETE (Hoàn thành & Nhập kho ngay)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5)),
                                  ),
                                ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Ghi chú
              AppTextField(
                controller: _noteCtrl,
                labelText: 'Ghi chú phiếu nhập (Số hóa đơn, đợt nhập, người phụ trách...)',
                hintText: 'Nhập thông tin chứng từ lô hàng...',
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 14),

              // 3. Tìm kiếm sản phẩm theo biến thể có dropdown gợi ý
              Text(
                'Tìm kiếm sản phẩm & biến thể để thêm vào phiếu nhập (*)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                labelText: 'Tìm kiếm sản phẩm hoặc biến thể...',
                hintText: 'Gõ tên sản phẩm, biến thể (ASUS, Sony, RAM, Màu...), mã ID...',
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                            _showDropdown = false;
                          });
                        },
                      )
                    : null,
              ),

              // Dropdown gợi ý biến thể sản phẩm
              if (_showDropdown && _searchQuery.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  constraints: const BoxConstraints(maxHeight: 230),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: matchingVariants.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Không tìm thấy biến thể sản phẩm khớp với "$_searchQuery"',
                                  style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Gợi ý sản phẩm & biến thể (${matchingVariants.length}):',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() => _showDropdown = false),
                                    child: Icon(Icons.close, size: 14, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: matchingVariants.length,
                                separatorBuilder: (ctx, index) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                                itemBuilder: (ctx, idx) {
                                  final item = matchingVariants[idx];
                                  final existingRow = _itemRows.where((r) => r.selectedVariant.variantId == item.variantId).firstOrNull;
                                  final isAdded = existingRow != null;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 36,
                                                height: 36,
                                                color: Colors.black12,
                                                child: const Icon(Icons.devices, size: 16),
                                              ),
                                            )
                                          : Container(
                                              width: 36,
                                              height: 36,
                                              color: Colors.black12,
                                              child: const Icon(Icons.devices, size: 16),
                                            ),
                                    ),
                                    title: Text(
                                      item.fullName,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text('Giá niêm yết: ${currencyFormat.format(item.defaultPrice)}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                        const SizedBox(width: 8),
                                        Text('| Tồn kho hiện tại: ${item.stockQuantity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                                      ],
                                    ),
                                    trailing: isAdded
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Chip(
                                                label: Text('Đã thêm (${existingRow.quantity})', style: const TextStyle(fontSize: 10.5, color: AppColors.success, fontWeight: FontWeight.bold)),
                                                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                                                side: BorderSide.none,
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                                avatar: const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle, size: 18, color: AppColors.primary),
                                                tooltip: 'Thêm +1 số lượng',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                onPressed: () => _addVariantToPo(item),
                                              ),
                                            ],
                                          )
                                        : ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              visualDensity: VisualDensity.compact,
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.add_rounded, size: 13),
                                            label: const Text('Thêm vào phiếu', style: TextStyle(fontSize: 11)),
                                            onPressed: () => _addVariantToPo(item),
                                          ),
                                    onTap: () => _addVariantToPo(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              const SizedBox(height: 12),

              // 4. Danh sách các mặt hàng nhập kho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DANH SÁCH MẶT HÀNG NHẬP KHO (${_itemRows.length}):',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                  ),
                  if (_itemRows.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          for (var r in _itemRows) {
                            r.dispose();
                          }
                          _itemRows.clear();
                        });
                      },
                      child: const Text('Bỏ tất cả mặt hàng', style: TextStyle(fontSize: 11.5, color: AppColors.danger)),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Bảng hoặc danh sách các dòng mặt hàng
              if (_itemRows.isEmpty)
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 30, color: textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(height: 6),
                        Text(
                          'Chưa có mặt hàng nào trong phiếu nhập',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gõ từ khóa vào ô tìm kiếm ở trên để chọn và thêm sản phẩm vào phiếu nhập',
                          style: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._itemRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        // STT
                        Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: textSecondary)),
                        const SizedBox(width: 8),

                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: row.selectedVariant.imageUrl != null && row.selectedVariant.imageUrl!.isNotEmpty
                              ? Image.network(
                                  row.selectedVariant.imageUrl!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.black12,
                                    child: const Icon(Icons.devices, size: 16),
                                  ),
                                )
                              : Container(
                                  width: 36,
                                  height: 36,
                                  color: Colors.black12,
                                  child: const Icon(Icons.devices, size: 16),
                                ),
                        ),
                        const SizedBox(width: 10),

                        // Tên sản phẩm & biến thể
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.selectedVariant.fullName,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Giá niêm yết: ${currencyFormat.format(row.selectedVariant.defaultPrice)}',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Badge Tồn kho hiện tại
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Tồn hiện tại', style: TextStyle(fontSize: 9.5, color: textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                '${row.selectedVariant.stockQuantity}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Đơn giá nhập với CurrencyInputFormatter (TỰ ĐỘNG THÊM DẤU PHẨY)
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            controller: row.importPriceCtrl,
                            labelText: 'Đơn giá nhập (*)',
                            hintText: 'VD: 15,000,000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            suffixIcon: Container(
                              padding: const EdgeInsets.only(right: 8),
                              alignment: Alignment.centerRight,
                              width: 20,
                              child: Text('₫', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Số lượng nhập với nút - và +
                        SizedBox(
                          width: 110,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: row.quantity > 1
                                    ? () {
                                        setState(() {
                                          row.quantityCtrl.text = (row.quantity - 1).toString();
                                        });
                                      }
                                    : null,
                              ),
                              Expanded(
                                child: AppTextField(
                                  controller: row.quantityCtrl,
                                  keyboardType: TextInputType.number,
                                  labelText: 'SL',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: () {
                                  setState(() {
                                    row.quantityCtrl.text = (row.quantity + 1).toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Thành tiền của dòng
                        SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Thành tiền', style: TextStyle(fontSize: 9.5, color: textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(row.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Nút xóa dòng
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Xóa khỏi phiếu',
                          onPressed: () {
                            setState(() {
                              row.dispose();
                              _itemRows.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 10),

              // 5. Tổng kết chi phí & mặt hàng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng mặt hàng: ${_itemRows.length} biến thể | Tổng số lượng: $_totalQuantity sản phẩm',
                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'TỔNG TIỀN NHẬP: ${currencyFormat.format(_totalCalc)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy bỏ',
          variant: AppButtonVariant.outline,
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        AppButton(
          label: isEditing ? 'Cập nhật phiếu nhập' : 'Tạo phiếu nhập hàng',
          variant: AppButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _handleSave,
        ),
      ],
    );
  }
}

