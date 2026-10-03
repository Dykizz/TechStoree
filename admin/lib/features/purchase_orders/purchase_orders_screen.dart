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
                o.note.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
            }

            if (_selectedStatus != 'Tất cả') {
              orders = orders.where((o) => o.status == _selectedStatus).toList();
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
                    title: 'Quản lý Phiếu nhập hàng',
                    subtitle: 'Theo dõi các đợt nhập hàng từ nhà cung cấp và nhập kho sản phẩm',
                    action: AppButton(
                      label: 'Tạo phiếu nhập hàng',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers),
                    ),
                  ),

                  // Filter Controls
                  FilterBar(
                    searchField: AppSearchField<PurchaseOrder>(
                      controller: _searchCtrl,
                      hintText: 'Tìm kiếm mã phiếu nhập, nhà cung cấp, ghi chú...',
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
                          DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Nháp)')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED (Nhập kho)')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
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
                                    message: 'Không tìm thấy thông tin phiếu nhập khớp với bộ lọc.',
                                    icon: Icons.inventory_2_outlined,
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SizedBox(
                                          width: constraints.maxWidth,
                                          child: DataTable(
                                            headingRowHeight: 38,
                                            dataRowMinHeight: 44,
                                            dataRowMaxHeight: 48,
                                            columnSpacing: 16,
                                            horizontalMargin: 16,
                                            headingRowColor: WidgetStateProperty.all(
                                              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            ),
                                            columns: const [
                                              DataColumn(label: Text('Mã phiếu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Số mặt hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Tổng tiền nhập', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                              DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                            ],
                                            rows: paginatedOrders.map((po) {
                                              return DataRow(
                                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                                  if (states.contains(WidgetState.hovered)) {
                                                    return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
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
                                                    Text(dateFormat.format(po.createdAt), style: TextStyle(color: textSecondary, fontSize: 11)),
                                                  ),
                                                  DataCell(
                                                    Text('${po.totalItems} dòng', style: TextStyle(color: textPrimary, fontSize: 12)),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      currencyFormat.format(po.totalCost),
                                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                                    ),
                                                  ),
                                                  DataCell(_renderStatusBadge(po.status)),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.visibility_outlined, size: 15, color: AppColors.primary),
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                          tooltip: 'Xem chi tiết',
                                                          onPressed: () => _showDetailDialog(context, apiService, authProvider.token, po.purchaseOrderId),
                                                        ),
                                                        if (po.isDraft) ...[
                                                          IconButton(
                                                            icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                            tooltip: 'Sửa phiếu nháp',
                                                            onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers, existingPoId: po.purchaseOrderId),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                            tooltip: 'Xóa phiếu nháp',
                                                            onPressed: () => _showDeleteConfirm(context, apiService, authProvider.token, po),
                                                          ),
                                                        ] else ...[
                                                          Tooltip(
                                                            message: 'Phiếu đã hoàn thành (COMPLETED) - Không thể sửa/xóa',
                                                            child: Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                                              child: Icon(Icons.lock_outline_rounded, size: 14, color: textSecondary),
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
    if (status == 'COMPLETED' || status == '1') {
      return const StatusBadge(label: 'ĐÃ NHẬP KHO', isSuccess: true);
    } else if (status == 'DRAFT' || status == '0') {
      return const StatusBadge(label: 'BẢN NHÁP', isWarning: true);
    } else {
      return const StatusBadge(label: 'ĐÃ HỦY', isDanger: true);
    }
  }

  // --- Show Detail Dialog ---
  void _showDetailDialog(BuildContext context, ApiService apiService, String? token, int poId) async {
    final po = await apiService.getPurchaseOrderById(poId, token: token);
    if (!context.mounted || po == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('Nhà cung cấp', po.supplierName)),
                    Expanded(child: _buildInfoItem('Người tạo', po.createdByName)),
                    Expanded(child: _buildInfoItem('Ngày tạo', dateFormat.format(po.createdAt))),
                  ],
                ),
                if (po.note.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space8),
                  _buildInfoItem('Ghi chú', po.note),
                ],
                const SizedBox(height: AppTokens.space12),
                const Divider(),
                const SizedBox(height: AppTokens.space8),
                const Text('DANH SÁCH MẶT HÀNG NHẬP KHO', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: AppTokens.space8),

                DataTableContainer(
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 36,
                    dataRowMinHeight: 38,
                    dataRowMaxHeight: 38,
                    columns: const [
                      DataColumn(label: Text('Sản phẩm / Biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Đơn giá nhập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                      DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                    ],
                    rows: po.items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.fullName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                        DataCell(Text(currencyFormat.format(item.importPrice), style: const TextStyle(fontSize: 11))),
                        DataCell(Text('${item.quantity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        DataCell(Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
                      ]);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppTokens.space12),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tổng tiền hàng: ${currencyFormat.format(po.totalCost)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (po.isDraft)
            AppButton(
              label: 'Chốt phiếu & Nhập kho',
              icon: Icons.check_circle_outline,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.pop(ctx);
                final updatedPo = PurchaseOrder(
                  purchaseOrderId: po.purchaseOrderId,
                  poCode: po.poCode,
                  supplierId: po.supplierId,
                  status: 'COMPLETED',
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
          AppButton(
            label: 'Đóng',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
            final vLabel = '${p.name} - $vName';
            variantOptions.add(_VariantSelectOption(
              variantId: vId,
              label: vLabel,
              defaultPrice: v.price > 0 ? v.price : p.price,
              stockQuantity: v.stockQuantity,
            ));
          }
        }
      } else {
        final pId = int.tryParse(p.id) ?? 0;
        if (pId > 0) {
          variantOptions.add(_VariantSelectOption(
            variantId: pId,
            label: '${p.name} - Mặc định',
            defaultPrice: p.price,
            stockQuantity: p.stock,
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
        itemRows.add(_POItemRowInput(
          variantId: item.variantId,
          importPrice: item.importPrice,
          quantity: item.quantity,
        ));
      }
    } else {
      itemRows.add(_POItemRowInput(
        variantId: variantOptions.first.variantId,
        importPrice: variantOptions.first.defaultPrice,
        quantity: 1,
      ));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalCalc = 0;
          for (var r in itemRows) {
            totalCalc += r.totalPrice;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text(isEditing ? 'Sửa Phiếu Nhập Hàng (${existingPo?.poCode})' : 'Tạo Phiếu Nhập Hàng Mới', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppDropdown<int>(
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
                        ),
                        const SizedBox(width: AppTokens.space8),
                        Expanded(
                          flex: 1,
                          child: AppDropdown<String>(
                            value: selectedStatus,
                            items: const [
                              DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Nháp)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedStatus = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),

                    AppTextField(
                      controller: noteCtrl,
                      labelText: 'Ghi chú phiếu nhập (Mã lô, hóa đơn, chứng từ...)',
                    ),
                    const SizedBox(height: AppTokens.space12),
                    const Divider(),
                    const SizedBox(height: AppTokens.space4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DANH SÁCH SẢN PHẨM NHẬP KHO', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.primary)),
                        AppButton(
                          label: 'Thêm mặt hàng',
                          icon: Icons.add_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            setDialogState(() {
                              itemRows.add(_POItemRowInput(
                                variantId: variantOptions.first.variantId,
                                importPrice: variantOptions.first.defaultPrice,
                                quantity: 1,
                              ));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),

                    ...itemRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTokens.space8),
                        padding: const EdgeInsets.all(AppTokens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                            const SizedBox(width: AppTokens.space8),

                            Expanded(
                              flex: 3,
                              child: RawAutocomplete<_VariantSelectOption>(
                                initialValue: TextEditingValue(
                                  text: variantOptions.firstWhere(
                                    (opt) => opt.variantId == row.variantId,
                                    orElse: () => variantOptions.first,
                                  ).label,
                                ),
                                displayStringForOption: (option) => option.label,
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return variantOptions;
                                  }
                                  return variantOptions.where((opt) =>
                                      opt.label.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (option) {
                                  setDialogState(() {
                                    row.variantId = option.variantId;
                                    row.importPriceCtrl.text = option.defaultPrice.toInt().toString();
                                  });
                                },
                                fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                  return AppTextField(
                                    controller: textController,
                                    labelText: 'SP / Biến thể (*)',
                                    suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        width: 360,
                                        height: options.length > 5 ? 200 : options.length * 45.0,
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final option = options.elementAt(index);
                                            return ListTile(
                                              dense: true,
                                              title: Text(option.label, style: const TextStyle(fontSize: 11)),
                                              subtitle: Text('Giá niêm yết: ${currencyFormat.format(option.defaultPrice)} | Tồn: ${option.stockQuantity}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: AppTokens.space8),

                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                controller: row.importPriceCtrl,
                                labelText: 'Giá nhập',
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space8),

                            SizedBox(
                              width: 75,
                              child: AppTextField(
                                controller: row.quantityCtrl,
                                labelText: 'SL',
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space8),

                            SizedBox(
                              width: 95,
                              child: Text(
                                currencyFormat.format(row.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.primary),
                                textAlign: TextAlign.right,
                              ),
                            ),

                            if (itemRows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 15),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () {
                                  setDialogState(() {
                                    row.dispose();
                                    itemRows.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppTokens.space8),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TỔNG TIỀN PHIẾU NHẬP: ${currencyFormat.format(totalCalc)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
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
                label: isEditing ? 'Cập Nhật Phiếu' : 'Lưu Phiếu Nhập',
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  final seenVariantIds = <int>{};
                  for (var r in itemRows) {
                    if (seenVariantIds.contains(r.variantId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phát hiện biến thể bị chọn trùng lặp. Vui lòng gộp số lượng vào 1 dòng.'), backgroundColor: AppColors.warning),
                      );
                      return;
                    }
                    seenVariantIds.add(r.variantId);
                  }

                  List<PurchaseOrderItem> poItems = [];
                  for (var r in itemRows) {
                    poItems.add(PurchaseOrderItem(
                      variantId: r.variantId,
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

  // --- Delete Confirm ---
  void _showDeleteConfirm(BuildContext context, ApiService apiService, String? token, PurchaseOrder po) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Xác nhận xóa phiếu nhập hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn xóa phiếu nháp "${po.poCode}" không?'),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Xóa',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              final result = await apiService.deletePurchaseOrder(po.purchaseOrderId, token: token);
              if (context.mounted) {
                Navigator.pop(ctx);
                if (result.success) {
                  setState(() => _loadData());
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppColors.success : AppColors.danger,
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

class _VariantSelectOption {
  final int variantId;
  final String label;
  final double defaultPrice;
  final int stockQuantity;

  _VariantSelectOption({
    required this.variantId,
    required this.label,
    required this.defaultPrice,
    this.stockQuantity = 0,
  });
}

class _POItemRowInput {
  int variantId;
  final TextEditingController importPriceCtrl;
  final TextEditingController quantityCtrl;

  _POItemRowInput({
    required this.variantId,
    double importPrice = 0,
    int quantity = 1,
  })  : importPriceCtrl = TextEditingController(text: importPrice > 0 ? importPrice.toInt().toString() : '0'),
        quantityCtrl = TextEditingController(text: quantity > 0 ? quantity.toString() : '1');

  double get importPrice => double.tryParse(importPriceCtrl.text) ?? 0;
  int get quantity => int.tryParse(quantityCtrl.text) ?? 1;
  double get totalPrice => importPrice * quantity;

  void dispose() {
    importPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}
