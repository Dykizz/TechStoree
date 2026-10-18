import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class InventoryAlertsWidget extends StatelessWidget {
  final List<VariantInventoryAlert> variantAlerts;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const InventoryAlertsWidget({
    super.key,
    required this.variantAlerts,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cảnh báo tồn kho theo biến thể',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('Biến thể sản phẩm dưới ngưỡng an toàn (≤ 10 sản phẩm)', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: variantAlerts.isNotEmpty ? AppColors.warning.withValues(alpha: 0.10) : AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${variantAlerts.length} biến thể cần chú ý',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: variantAlerts.isNotEmpty ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (variantAlerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Tất cả biến thể sản phẩm đang có tồn kho ổn định.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: variantAlerts.take(6).map((alert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alert.isOutOfStock ? Icons.report_problem_rounded : Icons.inventory_2_outlined,
                        size: 15,
                        color: alert.isOutOfStock ? AppColors.danger : AppColors.warning,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.fullName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Số lượng còn lại: ${alert.stockQuantity}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: alert.isOutOfStock ? AppColors.danger : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: alert.isOutOfStock ? AppColors.danger : AppColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert.statusLabel,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
