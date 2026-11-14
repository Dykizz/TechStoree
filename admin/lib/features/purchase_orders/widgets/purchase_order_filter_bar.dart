import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/filter_bar.dart';

/// Thanh tìm kiếm và bộ lọc nhà cung cấp, trạng thái cho màn hình phiếu nhập hàng.
class PurchaseOrderFilterBar extends StatelessWidget {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final TextEditingController searchController;
  final List<PurchaseOrder> searchItems;
  final List<Supplier> suppliers;
  final int selectedSupplierId;
  final String selectedStatus;
  final ValueChanged<PurchaseOrder> onSearchSelected;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final ValueChanged<int?> onSupplierChanged;
  final ValueChanged<String?> onStatusChanged;

  const PurchaseOrderFilterBar({
    super.key,
    required this.searchController,
    required this.searchItems,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.selectedStatus,
    required this.onSearchSelected,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onSupplierChanged,
    required this.onStatusChanged,
  });

  static const List<String> _validStatuses = ['Tất cả', 'DRAFT', 'COMPLETED'];

  @override
  Widget build(BuildContext context) {
    final hasSelectedSupplier = selectedSupplierId == 0 ||
        suppliers.any((s) => (int.tryParse(s.id) ?? 0) == selectedSupplierId);
    final normalizedStatus = selectedStatus.toUpperCase() == 'COMPLETE'
        ? 'COMPLETED'
        : selectedStatus;
    final effectiveStatus =
        _validStatuses.contains(normalizedStatus) ? normalizedStatus : 'Tất cả';

    return FilterBar(
      searchField: AppSearchField<PurchaseOrder>(
        controller: searchController,
        hintText: 'Tìm kiếm mã PO, nhà cung cấp, ghi chú...',
        items: searchItems,
        searchFilter: (po, q) {
          final query = q.toLowerCase();
          return po.poCode.toLowerCase().contains(query) ||
              po.supplierName.toLowerCase().contains(query) ||
              po.note.toLowerCase().contains(query);
        },
        itemLabel: (po) => '${po.poCode} - ${po.supplierName}',
        itemSubtitle: (po) =>
            '${_currencyFormat.format(po.totalCost)} • ${po.status}',
        onSelected: onSearchSelected,
        onSubmitted: onSearchSubmitted,
        onCleared: onSearchCleared,
      ),
      filters: [
        AppDropdown<int>(
          value: hasSelectedSupplier ? selectedSupplierId : 0,
          items: [
            const DropdownMenuItem(
              value: 0,
              child: Text('Tất cả nhà cung cấp'),
            ),
            ...suppliers.map((s) {
              final sId = int.tryParse(s.id) ?? 0;
              final label = !s.isActive ? '${s.name} [Ngừng HT]' : s.name;
              return DropdownMenuItem(
                value: sId,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: onSupplierChanged,
        ),
        AppDropdown<String>(
          value: effectiveStatus,
          items: const [
            DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
            DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Bản nháp)')),
            DropdownMenuItem(
              value: 'COMPLETED',
              child: Text('COMPLETED (Đã hoàn thành)'),
            ),
          ],
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

