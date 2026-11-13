import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_tokens.dart';
import '../providers/theme_provider.dart';
import 'app_text_field.dart';

/// Mô tả một mức giá chọn nhanh trong bộ lọc nâng cao
class AmountPresetOption {
  final String label;
  final double? min;
  final double? max;

  const AmountPresetOption(this.label, this.min, this.max);
}

/// Nút bật/tắt bảng lọc nâng cao kèm badge đếm số điều kiện đang áp dụng
class FilterToggleButton extends StatelessWidget {
  final bool isOpen;
  final int activeCount;
  final VoidCallback onPressed;

  const FilterToggleButton({
    super.key,
    required this.isOpen,
    required this.activeCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isHighlighted = isOpen || activeCount > 0;

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.tune_rounded,
          size: 16,
          color: isHighlighted ? Colors.white : textPrimary,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeCount > 0 ? 'Lọc ($activeCount)' : 'Bộ lọc',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isHighlighted ? Colors.white : textSecondary,
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isHighlighted ? AppColors.primary : null,
          side: BorderSide(color: isHighlighted ? AppColors.primary : borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        ),
      ),
    );
  }
}

/// Nút icon đặt lại toàn bộ bộ lọc (chỉ hiển thị khi có bộ lọc đang hoạt động)
class FilterResetIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const FilterResetIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Đặt lại toàn bộ lọc',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppColors.danger),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Khung chứa chuẩn cho Panel lọc nâng cao (gồm tiêu đề, badge đếm điều kiện và nút đóng)
class AdvancedFilterContainer extends StatelessWidget {
  final int activeCount;
  final VoidCallback onClose;
  final Widget child;
  final String title;

  const AdvancedFilterContainer({
    super.key,
    required this.activeCount,
    required this.onClose,
    required this.child,
    this.title = 'Bộ lọc',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: textPrimary,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount điều kiện đang áp dụng',
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
          child,
        ],
      ),
    );
  }
}

/// Chip chọn điều kiện chuẩn dùng trong các panel lọc
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Khối lọc theo khoảng tiền (Min - Max) kèm danh sách chip mức giá chọn nhanh
class AmountRangeFilterSection extends StatelessWidget {
  final String title;
  final TextEditingController minAmountCtrl;
  final TextEditingController maxAmountCtrl;
  final double? minAmount;
  final double? maxAmount;
  final VoidCallback onAmountChanged;
  final VoidCallback onAmountSubmitted;
  final void Function(double? min, double? max) onPricePresetSelected;
  final List<AmountPresetOption> presets;

  static const List<AmountPresetOption> defaultPresets = [
    AmountPresetOption('Tất cả giá', null, null),
    AmountPresetOption('< 1 triệu', null, 1000000),
    AmountPresetOption('1tr - 5tr', 1000000, 5000000),
    AmountPresetOption('5tr - 20tr', 5000000, 20000000),
    AmountPresetOption('> 20 triệu', 20000000, null),
  ];

  const AmountRangeFilterSection({
    super.key,
    required this.title,
    required this.minAmountCtrl,
    required this.maxAmountCtrl,
    required this.minAmount,
    required this.maxAmount,
    required this.onAmountChanged,
    required this.onAmountSubmitted,
    required this.onPricePresetSelected,
    this.presets = defaultPresets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAmountInput(
                controller: minAmountCtrl,
                hintText: 'Từ giá ₫',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('—', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _buildAmountInput(
                controller: maxAmountCtrl,
                hintText: 'Đến giá ₫',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.map((preset) {
            final isSelected = minAmount == preset.min && maxAmount == preset.max;
            return AppFilterChip(
              label: preset.label,
              isSelected: isSelected,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              fontSize: 11,
              onTap: () => onPricePresetSelected(preset.min, preset.max),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountInput({
    required TextEditingController controller,
    required String hintText,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [CurrencyInputFormatter()],
        style: TextStyle(fontSize: 12.5, color: textPrimary),
        onChanged: (_) => onAmountChanged(),
        onSubmitted: (_) => onAmountSubmitted(),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
        ),
      ),
    );
  }
}

/// Dòng hiển thị khoảng ngày đang áp dụng kèm nút xóa nhanh
class SelectedDateRangeTag extends StatelessWidget {
  final DateTimeRange dateRange;
  final VoidCallback onClear;

  const SelectedDateRangeTag({
    super.key,
    required this.dateRange,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Row(
      children: [
        const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          'Thời gian: ${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onClear,
          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
        ),
      ],
    );
  }
}

