import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class TopProductsWidget extends StatelessWidget {
  final List<TopProductItem> topProducts;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const TopProductsWidget({
    super.key,
    required this.topProducts,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

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
                    'Top sản phẩm bán chạy',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('Xếp hạng theo doanh số trong kỳ', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              Text(
                '${topProducts.length} sản phẩm',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu bán hàng trong khoảng thời gian này.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            )
          else
            Column(
              children: topProducts.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: idx == 0
                              ? AppColors.primary
                              : idx == 1
                                  ? AppColors.info
                                  : idx == 2
                                      ? AppColors.warning
                                      : textSecondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: idx < 3 ? Colors.white : textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fullName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Đã bán: ${item.quantitySold} sản phẩm',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Revenue
                      Text(
                        currencyFormat.format(item.revenue),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
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
