import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class EngagementSummaryWidget extends StatelessWidget {
  final SurveyOverviewMetric surveyMetric;
  final PromotionVoucherOverviewMetric promoMetric;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const EngagementSummaryWidget({
    super.key,
    required this.surveyMetric,
    required this.promoMetric,
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
                    'Khảo sát & Khuyến mãi - Voucher',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('Tương tác khách hàng và tỷ lệ dùng ưu đãi', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              const Icon(Icons.poll_rounded, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-Section A: Survey Performance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khảo sát thị trường (${surveyMetric.activeSurveysCount} đang hoạt động)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    Text(
                      'Tỷ lệ: ${surveyMetric.averageResponseRate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: surveyMetric.averageResponseRate > 0 ? (surveyMetric.averageResponseRate / 100) : 0,
                    backgroundColor: borderColor.withValues(alpha: 0.4),
                    color: AppColors.primary,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đã giao: ${surveyMetric.totalAssigned}', style: TextStyle(fontSize: 11, color: textSecondary)),
                    Text('Đã hoàn thành: ${surveyMetric.totalCompleted}', style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sub-Section B: Voucher / Promotion Activity
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sử dụng Mã Voucher (${promoMetric.activeVouchersCount} mã phát hành)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    Text(
                      '${promoMetric.totalVouchersUsed} / ${promoMetric.totalVouchersLimit}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: promoMetric.voucherUsageRate > 0 ? (promoMetric.voucherUsageRate / 100).clamp(0.0, 1.0) : 0,
                    backgroundColor: borderColor.withValues(alpha: 0.4),
                    color: AppColors.success,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Khuyến mãi đang chạy: ${promoMetric.activePromotionsCount}', style: TextStyle(fontSize: 11, color: textSecondary)),
                    Text('Tỷ lệ dùng: ${promoMetric.voucherUsageRate.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
