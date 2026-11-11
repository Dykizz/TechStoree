import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_text_field.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dateFormatDate = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: textPrimary,
                    ),
                  ),
                  if (advancedFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$advancedFilterCount điều kiện đang áp dụng',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),

          // 2 Cột: Khoảng tiền (Min-Max) & Trạng thái / Phương thức thanh toán
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột 1: Khoảng tiền đơn hàng (VNĐ)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khoảng tiền đơn hàng (VNĐ)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: minAmountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              style: TextStyle(fontSize: 12.5, color: textPrimary),
                              onChanged: (_) => onAmountChanged(),
                              onSubmitted: (_) => onAmountSubmitted(),
                              decoration: InputDecoration(
                                hintText: 'Từ giá ₫',
                                hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: maxAmountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              style: TextStyle(fontSize: 12.5, color: textPrimary),
                              onChanged: (_) => onAmountChanged(),
                              onSubmitted: (_) => onAmountSubmitted(),
                              decoration: InputDecoration(
                                hintText: 'Đến giá ₫',
                                hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick Price Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPriceChip('Tất cả giá', null, null, isDark, borderColor),
                        _buildPriceChip('< 1 triệu', null, 1000000, isDark, borderColor),
                        _buildPriceChip('1tr - 5tr', 1000000, 5000000, isDark, borderColor),
                        _buildPriceChip('5tr - 20tr', 5000000, 20000000, isDark, borderColor),
                        _buildPriceChip('> 20 triệu', 20000000, null, isDark, borderColor),
                      ],
                    ),
                  ],
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
                      children: [
                        _buildPaymentStatusChip('Tất cả', 'ALL', isDark, borderColor),
                        _buildPaymentStatusChip('PENDING - Chờ TT', 'PENDING', isDark, borderColor),
                        _buildPaymentStatusChip('PAID - Đã thanh toán', 'PAID', isDark, borderColor),
                        _buildPaymentStatusChip('FAILED - Thất bại', 'FAILED', isDark, borderColor),
                        _buildPaymentStatusChip('REFUNDED - Hoàn tiền', 'REFUNDED', isDark, borderColor),
                      ],
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
                      children: [
                        _buildPaymentMethodChip('Tất cả', 'ALL', isDark, borderColor),
                        _buildPaymentMethodChip('COD (Khi nhận hàng)', 'COD', isDark, borderColor),
                        _buildPaymentMethodChip('Cổng VNPay', 'VNPAY', isDark, borderColor),
                        _buildPaymentMethodChip('Chuyển khoản NH', 'BANK_TRANSFER', isDark, borderColor),
                      ],
                    ),
                    if (selectedDateRange != null && selectedDatePreset == 'CUSTOM') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Thời gian: ${dateFormatDate.format(selectedDateRange!.start)} - ${dateFormatDate.format(selectedDateRange!.end)}',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: onClearDateRange,
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, double? min, double? max, bool isDark, Color borderColor) {
    final isSelected = minAmount == min && maxAmount == max;
    return InkWell(
      onTap: () => onPricePresetSelected(min, max),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String label, String value, bool isDark, Color borderColor) {
    final isSelected = selectedPaymentStatus == value;
    return InkWell(
      onTap: () => onPaymentStatusSelected(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String label, String value, bool isDark, Color borderColor) {
    final isSelected = selectedPaymentMethod == value;
    return InkWell(
      onTap: () => onPaymentMethodSelected(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

