import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/advanced_filter_widgets.dart';

/// Panel lọc nâng cao cho màn hình Quản lý hóa đơn (Khoảng tiền, PTTT, Khoảng thời gian)
class InvoiceFilterPanel extends StatelessWidget {
  final TextEditingController minAmountCtrl;
  final TextEditingController maxAmountCtrl;
  final double? minAmount;
  final double? maxAmount;
  final String selectedPaymentMethod;
  final DateTimeRange? selectedDateRange;
  final int advancedFilterCount;

  final VoidCallback onClose;
  final VoidCallback onAmountChanged;
  final VoidCallback onAmountSubmitted;
  final void Function(double? min, double? max) onPricePresetSelected;
  final ValueChanged<String> onPaymentMethodSelected;
  final VoidCallback onClearDateRange;

  const InvoiceFilterPanel({
    super.key,
    required this.minAmountCtrl,
    required this.maxAmountCtrl,
    required this.minAmount,
    required this.maxAmount,
    required this.selectedPaymentMethod,
    required this.selectedDateRange,
    required this.advancedFilterCount,
    required this.onClose,
    required this.onAmountChanged,
    required this.onAmountSubmitted,
    required this.onPricePresetSelected,
    required this.onPaymentMethodSelected,
    required this.onClearDateRange,
  });

  static const List<Map<String, String>> _paymentMethods = [
    {'label': 'Tất cả', 'value': 'ALL'},
    {'label': 'COD (Tiền mặt)', 'value': 'COD'},
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
          // Cột 1: Khoảng tiền hóa đơn
          Expanded(
            flex: 6,
            child: AmountRangeFilterSection(
              title: 'Khoảng tiền hóa đơn (VNĐ)',
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

          // Cột 2: Phương thức thanh toán & Tag khoảng ngày
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (selectedDateRange != null) ...[
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

