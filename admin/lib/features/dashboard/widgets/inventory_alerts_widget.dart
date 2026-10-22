import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class InventoryAlertsWidget extends StatelessWidget {
  final List<VariantInventoryAlert> variantAlerts;
  final VoidCallback? onViewAll;
  final VoidCallback? onImportPO;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const InventoryAlertsWidget({
    super.key,
    required this.variantAlerts,
    this.onViewAll,
    this.onImportPO,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.6 : 0.8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF64748B).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.20) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh báo tồn kho theo biến thể',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biến thể sản phẩm dưới ngưỡng an toàn (≤ 20 sản phẩm)',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: variantAlerts.isEmpty
                          ? AppColors.success.withValues(alpha: 0.10)
                          : (variantAlerts.any((a) => a.isOutOfStock || a.stockQuantity == 0)
                              ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                              : (variantAlerts.any((a) => a.stockQuantity <= 10)
                                  ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                                  : const Color(0xFFEAB308).withValues(alpha: 0.20))),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${variantAlerts.length} cần chú ý',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: variantAlerts.isEmpty
                            ? AppColors.success
                            : (variantAlerts.any((a) => a.isOutOfStock || a.stockQuantity == 0)
                                ? const Color(0xFFDC2626)
                                : (variantAlerts.any((a) => a.stockQuantity <= 10)
                                    ? const Color(0xFFEA580C)
                                    : (isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309)))),
                      ),
                    ),
                  ),
                  if (onImportPO != null && variantAlerts.isNotEmpty)
                    InkWell(
                      onTap: onImportPO,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_shopping_cart_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Nhập hàng',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
          else ...[
            Column(
              children: variantAlerts.take(6).map((alert) {
                final visual = _getAlertVisual(alert, isDark);

                return InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
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
                          visual.iconData,
                          size: 15,
                          color: visual.iconColor,
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
                                  color: visual.qtyColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: visual.badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: visual.badgeTextColor,
                            ),
                          ),
                        ),
                        if (onViewAll != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, size: 15, color: textSecondary.withValues(alpha: 0.6)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (variantAlerts.length > 6 && onViewAll != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Text(
                      'Xem thêm ${variantAlerts.length - 6} biến thể khác →',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  ({Color badgeBg, Color badgeTextColor, Color iconColor, Color qtyColor, IconData iconData}) _getAlertVisual(
    VariantInventoryAlert alert,
    bool isDark,
  ) {
    if (alert.isOutOfStock || alert.stockQuantity == 0) {
      // 1. Hết hàng (stock == 0) -> ĐỎ (Red)
      return (
        badgeBg: const Color(0xFFDC2626),
        badgeTextColor: Colors.white,
        iconColor: const Color(0xFFDC2626),
        qtyColor: const Color(0xFFDC2626),
        iconData: Icons.cancel_rounded,
      );
    } else if (alert.stockQuantity <= 10) {
      // 2. Sắp hết (stock <= 10) -> CAM (Orange)
      return (
        badgeBg: const Color(0xFFEA580C),
        badgeTextColor: Colors.white,
        iconColor: const Color(0xFFEA580C),
        qtyColor: const Color(0xFFEA580C),
        iconData: Icons.report_problem_rounded,
      );
    } else {
      // 3. Tồn kho thấp (11 <= stock <= 20) -> VÀNG (Yellow)
      return (
        badgeBg: const Color(0xFFEAB308),
        badgeTextColor: const Color(0xFF713F12), // Nâu sẫm tương phản nổi bật trên nền vàng tươi
        iconColor: const Color(0xFFD97706),
        qtyColor: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
        iconData: Icons.inventory_2_outlined,
      );
    }
  }
}
