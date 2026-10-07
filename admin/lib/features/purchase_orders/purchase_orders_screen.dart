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
  int _itemsPerPage = 12;

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

            return Padding(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Quản lý Phiếu nhập hàng (Purchase Orders)',
                    subtitle: 'Theo dõi đợt nhập hàng từ nhà cung cấp theo từng biến thể sản phẩm',
                    action: AppButton(
                      label: 'Tạo phiếu nhập hàng mới',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers),
                    ),
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
                            return DropdownMenuItem(value: sId, child: Text(s.name, overflow: TextOverflow.ellipsis));
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
                  Flexible(
                    child: DataTableContainer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: orders.isEmpty
                                ? const EmptyState(
                                    title: 'Chưa có phiếu nhập hàng nào',
                                    message: 'Không tìm thấy phiếu nhập khớp với bộ lọc.',
                                    icon: Icons.inventory_2_outlined,
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                            child: DataTable(
                                              headingRowHeight: 40,
                                              dataRowMinHeight: 50,
                                              dataRowMaxHeight: 54,
                                              columnSpacing: 14,
                                              horizontalMargin: 12,
                                              headingRowColor: WidgetStateProperty.all(
                                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                              ),
                                              columns: const [
                                                DataColumn(label: Text('Mã PO', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Người tạo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Số dòng hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Tổng chi phí', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
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
                                                          if (po.isDraft) ...[
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
                                        ),
                                      );
                                    },
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
        ? 'Chốt phiếu nhập "${po.poCode}"? Sau khi hoàn thành, số lượng tồn kho của các biến thể sẽ được Backend tự động cộng vào hệ thống.'
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
              final res = await apiService.updatePurchaseOrder(po.purchaseOrderId, updatedPo, token: token);
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
                
                // Quy trình 3 bước - Audit Trail
                Container(
                  padding: const EdgeInsets.all(AppTokens.space12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Quy trình & Dấu vết kiểm toán kho', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInfoItem('1. Người tạo (Yêu cầu)', po.createdByName.isNotEmpty ? po.createdByName : 'Thủ kho', textPrimary, textSecondary)),
                          Expanded(child: _buildInfoItem('2. Người duyệt (QL/Ngân sách)', po.approvedByName ?? 'Chưa duyệt', textPrimary, textSecondary)),
                          Expanded(child: _buildInfoItem('3. Người nhận (Kiểm đếm)', po.receivedByName ?? 'Chưa nhận hàng', textPrimary, textSecondary)),
                        ],
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

    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo ít nhất 1 Nhà cung cấp trước khi lập phiếu nhập hàng.'), backgroundColor: AppColors.warning),
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

    final isEditing = existingPo != null;
    int selectedSupplierId = isEditing ? existingPo.supplierId : int.tryParse(suppliers.first.id) ?? 1;
    String selectedStatus = isEditing ? existingPo.status : 'DRAFT';
    final noteCtrl = TextEditingController(text: isEditing ? existingPo.note : '');

    List<_POItemRowInput> itemRows = [];
    if (isEditing && existingPo.items.isNotEmpty) {
      for (var item in existingPo.items) {
        final opt = variantOptions.firstWhere(
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
        itemRows.add(_POItemRowInput(
          selectedVariant: opt,
          importPrice: item.importPrice,
          quantity: item.quantity,
        ));
      }
    } else {
      itemRows.add(_POItemRowInput(
        selectedVariant: variantOptions.first,
        importPrice: variantOptions.first.defaultPrice,
        quantity: 1,
      ));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

          double totalCalc = 0;
          for (var r in itemRows) {
            totalCalc += r.totalPrice;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            title: Row(
              children: [
                const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppTokens.space8),
                Text(
                  isEditing ? 'Sửa Phiếu Nhập Hàng (${existingPo?.poCode})' : 'Tạo Phiếu Nhập Hàng Mới',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            content: SizedBox(
              width: 820,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section: Supplier & Status
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nhà cung cấp (*)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 4),
                              AppDropdown<int>(
                                value: suppliers.any((s) => int.tryParse(s.id) == selectedSupplierId)
                                    ? selectedSupplierId
                                    : (int.tryParse(suppliers.first.id) ?? 1),
                                items: suppliers.map((s) {
                                  final sId = int.tryParse(s.id) ?? 1;
                                  return DropdownMenuItem<int>(
                                    value: sId,
                                    child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedSupplierId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Trạng thái (*)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 4),
                              AppDropdown<String>(
                                value: selectedStatus,
                                items: const [
                                  DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Bản nháp)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'COMPLETE', child: Text('COMPLETE (Nhập kho)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'CANCLE', child: Text('CANCLE (Đã hủy)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedStatus = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space12),

                    AppTextField(
                      controller: noteCtrl,
                      labelText: 'Ghi chú phiếu nhập (Mã vận đơn, chứng từ, đợt nhập...)',
                      hintText: 'Nhập thông tin ghi chú lô hàng...',
                    ),
                    const SizedBox(height: AppTokens.space16),
                    const Divider(),
                    const SizedBox(height: AppTokens.space8),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DANH SÁCH BIẾN THỂ NHẬP KHO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                        AppButton(
                          label: 'Thêm dòng sản phẩm',
                          icon: Icons.add_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            setDialogState(() {
                              itemRows.add(_POItemRowInput(
                                selectedVariant: variantOptions.first,
                                importPrice: variantOptions.first.defaultPrice,
                                quantity: 1,
                              ));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),

                    // Items Input List Table
                    ...itemRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTokens.space8),
                        padding: const EdgeInsets.all(AppTokens.space8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: textSecondary)),
                            const SizedBox(width: 8),

                            // Variant Selector
                            Expanded(
                              flex: 4,
                              child: RawAutocomplete<_VariantSelectOption>(
                                initialValue: TextEditingValue(text: row.selectedVariant.fullName),
                                displayStringForOption: (opt) => opt.fullName,
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return variantOptions;
                                  }
                                  return variantOptions.where((opt) =>
                                      opt.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (opt) {
                                  setDialogState(() {
                                    row.selectedVariant = opt;
                                    row.importPriceCtrl.text = opt.defaultPrice.toInt().toString();
                                  });
                                },
                                fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                  return AppTextField(
                                    controller: textController,
                                    labelText: 'Chọn Sản phẩm & Biến thể (*)',
                                    suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 420,
                                        height: options.length > 5 ? 220 : options.length * 48.0,
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int idx) {
                                            final opt = options.elementAt(idx);
                                            return ListTile(
                                              dense: true,
                                              leading: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  opt.imageUrl ?? '',
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Container(width: 32, height: 32, color: Colors.black12, child: const Icon(Icons.devices, size: 16)),
                                                ),
                                              ),
                                              title: Text(opt.fullName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                              subtitle: Text('Giá niêm yết: ${currencyFormat.format(opt.defaultPrice)} | Tồn kho hiện tại: ${opt.stockQuantity}', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                                              onTap: () => onSelected(opt),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // READ-ONLY Current Stock Badge
                            Container(
                              width: 85,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Tồn hiện tại', style: TextStyle(fontSize: 9.5, color: textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${row.selectedVariant.stockQuantity}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Editable Import Price
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                controller: row.importPriceCtrl,
                                labelText: 'Đơn giá nhập',
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Editable Quantity
                            SizedBox(
                              width: 70,
                              child: AppTextField(
                                controller: row.quantityCtrl,
                                labelText: 'Số lượng',
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Read-Only Item Total Price Preview
                            SizedBox(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Thành tiền', style: TextStyle(fontSize: 9.5, color: textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    currencyFormat.format(row.totalPrice),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.primary),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),

                            if (itemRows.length > 1) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: 'Xóa dòng',
                                onPressed: () {
                                  setDialogState(() {
                                    row.dispose();
                                    itemRows.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppTokens.space8),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TỔNG CHI PHÍ PHIẾU NHẬP: ${currencyFormat.format(totalCalc)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              AppButton(
                label: 'Hủy',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  for (var r in itemRows) { r.dispose(); }
                  noteCtrl.dispose();
                  Navigator.pop(ctx);
                },
              ),
              AppButton(
                label: isEditing ? 'Cập nhật phiếu' : 'Lưu phiếu nhập',
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  final seenVariantIds = <int>{};
                  for (var r in itemRows) {
                    if (seenVariantIds.contains(r.selectedVariant.variantId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Phát hiện biến thể "${r.selectedVariant.fullName}" bị chọn trùng lặp. Vui lòng gộp số lượng.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    seenVariantIds.add(r.selectedVariant.variantId);
                  }

                  List<PurchaseOrderItem> poItems = [];
                  for (var r in itemRows) {
                    poItems.add(PurchaseOrderItem(
                      variantId: r.selectedVariant.variantId,
                      productId: r.selectedVariant.productId,
                      productName: r.selectedVariant.productName,
                      variantName: r.selectedVariant.variantName,
                      importPrice: r.importPrice,
                      quantity: r.quantity,
                    ));
                  }

                  final newPo = PurchaseOrder(
                    purchaseOrderId: isEditing ? existingPo!.purchaseOrderId : 0,
                    poCode: isEditing ? existingPo!.poCode : '',
                    supplierId: selectedSupplierId,
                    status: selectedStatus,
                    note: noteCtrl.text.trim(),
                    createdAt: isEditing ? existingPo!.createdAt : DateTime.now(),
                    totalCost: totalCalc,
                    totalItems: poItems.length,
                    items: poItems,
                  );

                  ApiResult result;
                  if (isEditing) {
                    result = await apiService.updatePurchaseOrder(existingPo!.purchaseOrderId, newPo, token: token);
                  } else {
                    result = await apiService.createPurchaseOrder(newPo, token: token);
                  }

                  for (var r in itemRows) { r.dispose(); }
                  noteCtrl.dispose();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    if (result.success) {
                      setState(() => _loadData());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success ? AppColors.success : AppColors.danger,
                        duration: const Duration(seconds: 4),
                      ),
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
          text: importPrice > 0 ? importPrice.toInt().toString() : selectedVariant.defaultPrice.toInt().toString(),
        ),
        quantityCtrl = TextEditingController(text: quantity > 0 ? quantity.toString() : '1');

  double get importPrice => double.tryParse(importPriceCtrl.text) ?? 0;
  int get quantity => int.tryParse(quantityCtrl.text) ?? 1;
  double get totalPrice => importPrice * quantity;

  void dispose() {
    importPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}
