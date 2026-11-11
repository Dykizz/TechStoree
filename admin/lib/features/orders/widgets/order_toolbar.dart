import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_search_field.dart';

/// Thanh công cụ phía trên bảng đơn hàng: Tìm kiếm, Chọn thời gian, Sắp xếp, Nút mở Bộ lọc và Nút Đặt lại
class OrderToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Order> orders;
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

  const OrderToolbar({
    super.key,
    required this.searchCtrl,
    required this.orders,
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

  String _currentOrderCode(Order order) =>
      order.orderCode.isNotEmpty ? order.orderCode : '#${order.orderId}';

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatDate = DateFormat('dd/MM/yyyy');

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
            child: AppSearchField<Order>(
              controller: searchCtrl,
              hintText: 'Tìm theo Mã đơn, Người nhận, SĐT...',
              items: orders,
              searchFilter: (o, q) =>
                  o.orderCode.toLowerCase().contains(q.toLowerCase()) ||
                  o.receiverName.toLowerCase().contains(q.toLowerCase()) ||
                  o.receiverPhone.contains(q),
              itemLabel: (o) => '${_currentOrderCode(o)} - ${o.receiverName}',
              itemSubtitle: (o) => '${currencyFormat.format(o.totalAmount)} • ${o.orderStatusDisplay}',
              onSelected: (o) => onSearchSelected(o.orderCode),
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
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('Thời gian: Tất cả')),
                const DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                const DropdownMenuItem(value: 'YESTERDAY', child: Text('Hôm qua')),
                const DropdownMenuItem(value: 'LAST_7_DAYS', child: Text('7 ngày qua')),
                const DropdownMenuItem(value: 'THIS_MONTH', child: Text('Tháng này')),
                DropdownMenuItem(
                  value: 'CUSTOM',
                  child: Text(
                    selectedDateRange != null && selectedDatePreset == 'CUSTOM'
                        ? '${dateFormatDate.format(selectedDateRange!.start)} - ${dateFormatDate.format(selectedDateRange!.end)}'
                        : 'Tùy chọn ngày...',
                  ),
                ),
              ],
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
                DropdownMenuItem(value: 'orderCode_asc', child: Text('Mã đơn: A → Z')),
                DropdownMenuItem(value: 'orderCode_desc', child: Text('Mã đơn: Z → A')),
                DropdownMenuItem(value: 'orderStatus_asc', child: Text('Trạng thái: A → Z')),
              ],
              onChanged: (val) {
                if (val != null) {
                  onSortChanged(val);
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // 4. Nút "Bộ lọc" (40px chuẩn)
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onToggleAdvancedFilter,
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: (isAdvancedFilterOpen || advancedFilterCount > 0) ? Colors.white : textPrimary,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    advancedFilterCount > 0 ? 'Lọc ($advancedFilterCount)' : 'Bộ lọc',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: (isAdvancedFilterOpen || advancedFilterCount > 0) ? Colors.white : textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isAdvancedFilterOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: (isAdvancedFilterOpen || advancedFilterCount > 0) ? Colors.white : textSecondary,
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: (isAdvancedFilterOpen || advancedFilterCount > 0) ? AppColors.primary : null,
                side: BorderSide(
                  color: (isAdvancedFilterOpen || advancedFilterCount > 0) ? AppColors.primary : borderColor,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
              ),
            ),
          ),

          // 5. Nút Đặt lại bộ lọc (chỉ hiện khi có active filter)
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                tooltip: 'Đặt lại toàn bộ lọc',
                onPressed: onResetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppColors.danger),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

