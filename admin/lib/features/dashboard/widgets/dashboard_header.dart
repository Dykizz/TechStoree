import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class DashboardHeader extends StatelessWidget {
  final String adminName;
  final DashboardTimeRangeType selectedRangeType;
  final DateTimeRange? customDateRange;
  final ValueChanged<DashboardTimeRangeType> onRangeTypeChanged;
  final ValueChanged<DateTimeRange> onCustomDateRangeSelected;
  final VoidCallback onRefresh;
  final bool isLoading;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color borderColor;

  const DashboardHeader({
    super.key,
    required this.adminName,
    required this.selectedRangeType,
    this.customDateRange,
    required this.onRangeTypeChanged,
    required this.onCustomDateRangeSelected,
    required this.onRefresh,
    required this.isLoading,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText = _getRangeDisplayText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Tổng quan kinh doanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '• Chào $adminName 👋  Hiệu suất doanh thu, tồn kho biến thể và chỉ số kinh doanh TechStoree.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Date Range Dropdown
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DashboardTimeRangeType>(
                value: selectedRangeType,
                icon: const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                isDense: true,
                onChanged: (type) async {
                  if (type == null) return;
                  if (type == DashboardTimeRangeType.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      initialDateRange: customDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      onCustomDateRangeSelected(picked);
                    }
                  } else {
                    onRangeTypeChanged(type);
                  }
                },
                items: DashboardTimeRangeType.values.map((type) {
                  return DropdownMenuItem<DashboardTimeRangeType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
              ),
            ),
          ),

          if (selectedRangeType == DashboardTimeRangeType.custom && customDateRange != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rangeText,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],

          const SizedBox(width: 6),

          // Refresh Button
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: isLoading ? null : onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : Icon(Icons.refresh_rounded, size: 16, color: textSecondary),
              tooltip: 'Làm mới dữ liệu',
            ),
          ),
        ],
      ),
    );
  }

  String _getRangeDisplayText() {
    if (selectedRangeType == DashboardTimeRangeType.custom && customDateRange != null) {
      final start = DateFormat('dd/MM').format(customDateRange!.start);
      final end = DateFormat('dd/MM/yyyy').format(customDateRange!.end);
      return '$start - $end';
    }
    return selectedRangeType.displayName;
  }
}
