import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/advanced_filter_widgets.dart';

/// Panel lọc nâng cao cho màn hình Quản lý đơn hàng (Khoảng tiền, PTTT, TT Thanh toán, Thời gian)
class OrderFilterPanel extends StatelessWidget {
  final TextEditingController minAmountCtrl;
  final TextEditingController maxAmountCtrl;
  final double? minAmount;
  final double? maxAmount;
  final String selectedPaymentStatus;
  final String selectedPaymentMethod;
  final DateTimeRange? selectedDateRange;
  final String selectedDatePreset;
  final int advancedFilterCount;

  final VoidCallback onClose;
  final VoidCallback onAmountChanged;
  final VoidCallback onAmountSubmitted;
  final void Function(double? min, double? max) onPricePresetSelected;
  final ValueChanged<String> onPaymentStatusSelected;
  final ValueChanged<String> onPaymentMethodSelected;
  final VoidCallback onClearDateRange;

  const OrderFilterPanel({
    super.key,
    required this.minAmountCtrl,
    required this.maxAmountCtrl,
    required this.minAmount,
    required this.maxAmount,
    required this.selectedPaymentStatus,
    required this.selectedPaymentMethod,
    required this.selectedDateRange,
    required this.selectedDatePreset,
    required this.advancedFilterCount,
    required this.onClose,
    required this.onAmountChanged,
    required this.onAmountSubmitted,
    required this.onPricePresetSelected,
    required this.onPaymentStatusSelected,
    required this.onPaymentMethodSelected,
    required this.onClearDateRange,
  });

  static const List<Map<String, String>> _paymentStatuses = [
    {'label': 'Tất cả', 'value': 'ALL'},
    {'label': 'PENDING - Chờ TT', 'value': 'PENDING'},
    {'label': 'PAID - Đã thanh toán', 'value': 'PAID'},
    {'label': 'FAILED - Thất bại', 'value': 'FAILED'},
    {'label': 'REFUNDED - Hoàn tiền', 'value': 'REFUNDED'},
  ];

  static const List<Map<String, String>> _paymentMethods = [
    {'label': 'Tất cả', 'value': 'ALL'},
    {'label': 'COD (Khi nhận hàng)', 'value': 'COD'},
    {'label': 'Cổng VNPay', 'value': 'VNPAY'},
    {'label': 'Chuyển khoản NH', 'value': 'BANK_TRANSFER'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return AdvancedFilterContainer(
      activeCount: advancedFilterCount,
      onClose: onClose,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột 1: Khoảng tiền đơn hàng (VNĐ)
          Expanded(
            flex: 6,
            child: AmountRangeFilterSection(
              title: 'Khoảng tiền đơn hàng (VNĐ)',
              minAmountCtrl: minAmountCtrl,
              maxAmountCtrl: maxAmountCtrl,
              minAmount: minAmount,
              maxAmount: maxAmount,
              onAmountChanged: onAmountChanged,
              onAmountSubmitted: onAmountSubmitted,
              onPricePresetSelected: onPricePresetSelected,
            ),
          ),

          const SizedBox(width: 24),

          // Cột 2: Trạng thái thanh toán & Phương thức thanh toán
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái thanh toán',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _paymentStatuses.map((item) {
                    final value = item['value']!;
                    return AppFilterChip(
                      label: item['label']!,
                      isSelected: selectedPaymentStatus == value,
                      onTap: () => onPaymentStatusSelected(value),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _paymentMethods.map((item) {
                    final value = item['value']!;
                    return AppFilterChip(
                      label: item['label']!,
                      isSelected: selectedPaymentMethod == value,
                      onTap: () => onPaymentMethodSelected(value),
                    );
                  }).toList(),
                ),

                if (selectedDateRange != null && selectedDatePreset == 'CUSTOM') ...[
                  const SizedBox(height: 12),
                  SelectedDateRangeTag(
                    dateRange: selectedDateRange!,
                    onClear: onClearDateRange,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
