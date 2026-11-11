import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';

/// Thanh Tab trạng thái đơn hàng nằm ngang kèm bộ đếm số lượng theo thời gian thực
class OrderStatusTabs extends StatelessWidget {
  final List<Map<String, String>> tabs;
  final String selectedStatus;
  final Map<String, int> statusCounts;
  final ValueChanged<String> onStatusSelected;

  const OrderStatusTabs({
    super.key,
    required this.tabs,
    required this.selectedStatus,
    required this.statusCounts,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final key = tab['key']!;
            final label = tab['label']!;
            final isSelected = selectedStatus == key;
            final count = statusCounts[key] ?? 0;

            Color tabAccent = AppColors.primary;
            if (key == 'PENDING') tabAccent = AppColors.warning;
            if (key == 'CONFIRMED') tabAccent = const Color(0xFF0284C7);
            if (key == 'SHIPPING') tabAccent = const Color(0xFF6366F1);
            if (key == 'DELIVERED') tabAccent = AppColors.success;
            if (key == 'RETURNED') tabAccent = const Color(0xFFF97316);
            if (key == 'CANCELLED') tabAccent = AppColors.danger;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  if (selectedStatus != key) {
                    onStatusSelected(key);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? tabAccent.withAlpha(50) : tabAccent.withAlpha(25))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? tabAccent : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? tabAccent : textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tabAccent
                              : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

