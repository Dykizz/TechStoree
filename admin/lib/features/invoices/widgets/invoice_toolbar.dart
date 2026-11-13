import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/invoice.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/date_preset_helper.dart';
import '../../../core/widgets/advanced_filter_widgets.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_search_field.dart';

/// Thanh công cụ phía trên bảng hóa đơn: Tìm kiếm, Chọn thời gian, Sắp xếp, Nút mở Bộ lọc và Nút Đặt lại
class InvoiceToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Invoice> invoices;
  final String selectedDatePreset;
  final DateTimeRange? selectedDateRange;
  final String selectedSort;
  final bool isAdvancedFilterOpen;
  final int advancedFilterCount;
  final bool hasActiveFilters;

  final ValueChanged<String> onSearchSelected;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onDatePresetChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onToggleAdvancedFilter;
  final VoidCallback onResetFilters;

  const InvoiceToolbar({
    super.key,
    required this.searchCtrl,
    required this.invoices,
    required this.selectedDatePreset,
    required this.selectedDateRange,
    required this.selectedSort,
    required this.isAdvancedFilterOpen,
    required this.advancedFilterCount,
    required this.hasActiveFilters,
    required this.onSearchSelected,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onDatePresetChanged,
    required this.onSortChanged,
    required this.onToggleAdvancedFilter,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // 1. Omni Search Field
          Expanded(
            child: AppSearchField<Invoice>(
              controller: searchCtrl,
              hintText: 'Tìm theo Mã HĐ, Đơn hàng, Tên khách hàng...',
              items: invoices,
              searchFilter: (inv, q) =>
                  inv.invoiceCode.toLowerCase().contains(q.toLowerCase()) ||
                  inv.orderCode.toLowerCase().contains(q.toLowerCase()) ||
                  inv.customerName.toLowerCase().contains(q.toLowerCase()),
              itemLabel: (inv) => '${inv.invoiceCode} - ${inv.customerName}',
              itemSubtitle: (inv) => '${currencyFormat.format(inv.totalAmount)} • ${inv.statusLabel}',
              onSelected: (inv) => onSearchSelected(inv.invoiceCode),
              onSubmitted: onSearchSubmitted,
              onCleared: onSearchCleared,
            ),
          ),

          const SizedBox(width: 8),

          // 2. Quick Date Preset Dropdown
          SizedBox(
            width: 175,
            child: AppDropdown<String>(
              value: selectedDatePreset,
              items: DatePresetHelper.buildDropdownItems(
                selectedDateRange: selectedDateRange,
                selectedDatePreset: selectedDatePreset,
              ),
              onChanged: (val) {
                if (val != null) {
                  onDatePresetChanged(val);
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // 3. Sort Dropdown
          SizedBox(
            width: 195,
            child: AppDropdown<String>(
              value: selectedSort,
              items: const [
                DropdownMenuItem(value: 'createdAt_desc', child: Text('Sắp xếp: Mới nhất')),
                DropdownMenuItem(value: 'createdAt_asc', child: Text('Sắp xếp: Cũ nhất')),
                DropdownMenuItem(value: 'totalAmount_desc', child: Text('Tổng tiền: Cao → Thấp')),
                DropdownMenuItem(value: 'totalAmount_asc', child: Text('Tổng tiền: Thấp → Cao')),
                DropdownMenuItem(value: 'invoiceCode_asc', child: Text('Mã HĐ: A → Z')),
              ],
              onChanged: (val) {
                if (val != null) {
                  onSortChanged(val);
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // 4. Nút "Bộ lọc"
          FilterToggleButton(
            isOpen: isAdvancedFilterOpen,
            activeCount: advancedFilterCount,
            onPressed: onToggleAdvancedFilter,
          ),

          // 5. Nút Đặt lại bộ lọc (nếu có active filter)
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            FilterResetIconButton(onPressed: onResetFilters),
          ],
        ],
      ),
    );
  }
}

