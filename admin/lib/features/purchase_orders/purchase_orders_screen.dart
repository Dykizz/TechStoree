import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/purchase_order.dart';
import '../../core/models/supplier.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_pagination.dart';

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

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Controls
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Search box
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 240, maxWidth: 380),
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm mã phiếu nhập, nhà cung cấp, ghi chú...',
                              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: backgroundColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Supplier Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedSupplierId,
                            dropdownColor: backgroundColor,
                            style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                            items: [
                              const DropdownMenuItem(value: 0, child: Text('Tất cả nhà cung cấp')),
                              ...suppliers.map((s) {
                                final sId = int.tryParse(s.id) ?? 0;
                                return DropdownMenuItem(value: sId, child: Text(s.name));
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedSupplierId = val ?? 0),
                          ),
                        ),
                      ),

                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            dropdownColor: backgroundColor,
                            style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                            items: ['Tất cả', 'DRAFT', 'COMPLETED', 'CANCELLED']
                                .map((st) => DropdownMenuItem(
                                      value: st,
                                      child: Text(st == 'DRAFT' ? 'DRAFT (Nháp)' : (st == 'COMPLETED' ? 'COMPLETED (Nhập kho)' : st)),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val ?? 'Tất cả'),
                          ),
                        ),
                      ),

                      // Add Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Tạo phiếu nhập hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Data Table Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: orders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: textSecondary),
                                    const SizedBox(height: 12),
                                    Text('Chưa có phiếu nhập hàng nào', style: TextStyle(color: textSecondary, fontSize: 14)),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                  ),
                                  dataRowMinHeight: 65,
                                  dataRowMaxHeight: 65,
                                  columns: const [
                                    DataColumn(label: Text('Mã phiếu', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Số mặt hàng', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Tổng tiền nhập', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: paginatedOrders.map((po) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            po.poCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(po.supplierName, style: TextStyle(color: textPrimary, fontSize: 13)),
                                        ),
                                        DataCell(
                                          Text(dateFormat.format(po.createdAt), style: TextStyle(color: textSecondary, fontSize: 12)),
                                        ),
                                        DataCell(
                                          Text('${po.totalItems} dòng', style: TextStyle(color: textPrimary, fontSize: 12)),
                                        ),
                                        DataCell(
                                          Text(
                                            currencyFormat.format(po.totalCost),
                                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        DataCell(_buildStatusChip(po.status)),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.info),
                                                tooltip: 'Xem chi tiết',
                                                onPressed: () => _showDetailDialog(context, apiService, authProvider.token, po.purchaseOrderId),
                                              ),
                                              if (po.isDraft) ...[
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                                  tooltip: 'Sửa phiếu nháp',
                                                  onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, suppliers: suppliers, existingPoId: po.purchaseOrderId),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                                  tooltip: 'Xóa phiếu nháp',
                                                  onPressed: () => _showDeleteConfirm(context, apiService, authProvider.token, po),
                                                ),
                                              ] else ...[
                                                const Tooltip(
                                                  message: 'Phiếu đã hoàn thành (COMPLETED) - Không thể sửa/xóa',
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status;

    if (status == 'COMPLETED' || status == '1') {
      bg = AppColors.successBg;
      fg = AppColors.success;
      label = 'ĐÃ NHẬP KHO';
    } else if (status == 'DRAFT' || status == '0') {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
      label = 'BẢN NHÁP';
    } else {
      bg = AppColors.dangerBg;
      fg = AppColors.danger;
      label = 'ĐÃ HỦY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // --- Show Detail Dialog ---
  void _showDetailDialog(BuildContext context, ApiService apiService, String? token, int poId) async {
    final po = await apiService.getPurchaseOrderById(poId, token: token);
    if (!context.mounted || po == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Chi Tiết Phiếu Nhập: ${po.poCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildStatusChip(po.status),
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
                  const SizedBox(height: 8),
                  _buildInfoItem('Ghi chú', po.note),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('DANH SÁCH MẶT HÀNG NHẬP KHO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 8),

                DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Sản phẩm / Biến thể', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Đơn giá nhập', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: po.items.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                      DataCell(Text(currencyFormat.format(item.importPrice), style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataCell(Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    ]);
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tổng tiền hàng: ${currencyFormat.format(po.totalCost)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (po.isDraft)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              label: const Text('Chốt phiếu & Nhập kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

    // Build selectable variant options from products list
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
            title: Text(isEditing ? 'Sửa Phiếu Nhập Hàng (${existingPo?.poCode})' : 'Tạo Phiếu Nhập Hàng Mới', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier Select & Status Select
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: suppliers.any((s) => int.tryParse(s.id) == selectedSupplierId)
                                ? selectedSupplierId
                                : (int.tryParse(suppliers.first.id) ?? 1),
                            decoration: const InputDecoration(labelText: 'Nhà cung cấp (*)', border: OutlineInputBorder()),
                            items: suppliers.map((s) {
                              final sId = int.tryParse(s.id) ?? 1;
                              return DropdownMenuItem<int>(
                                value: sId,
                                child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedSupplierId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Trạng thái (*)', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Nháp)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedStatus = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Ghi chú phiếu nhập (Mã lô, hóa đơn, chứng từ...)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DANH SÁCH SẢN PHẨM NHẬP KHO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              itemRows.add(_POItemRowInput(
                                variantId: variantOptions.first.variantId,
                                importPrice: variantOptions.first.defaultPrice,
                                quantity: 1,
                              ));
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Thêm mặt hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...itemRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 8),

                            // Variant Autocomplete Suggestion Select
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
                                  return TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      labelText: 'Gõ tên SP / biến thể (*)',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
                                    ),
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(8),
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
                                              title: Text(option.label, style: const TextStyle(fontSize: 12)),
                                              subtitle: Text('Giá niêm yết: ${currencyFormat.format(option.defaultPrice)} | Tồn kho: ${option.stockQuantity}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                            const SizedBox(width: 8),

                            // Price input
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row.importPriceCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(labelText: 'Giá nhập (VNĐ)', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Quantity input
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: row.quantityCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(labelText: 'SL', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Subtotal
                            SizedBox(
                              width: 100,
                              child: Text(
                                currencyFormat.format(row.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                                textAlign: TextAlign.right,
                              ),
                            ),

                            if (itemRows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
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

                    const SizedBox(height: 12),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TỔNG TIỀN PHIẾU NHẬP: ${currencyFormat.format(totalCalc)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  for (var r in itemRows) { r.dispose(); }
                  noteCtrl.dispose();
                  Navigator.pop(ctx);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  // Check duplicate variants
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
                child: Text(isEditing ? 'Cập Nhật Phiếu' : 'Lưu Phiếu Nhập', style: const TextStyle(color: Colors.white)),
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
        title: const Text('Xác nhận xóa phiếu nhập hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa phiếu nháp "${po.poCode}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
