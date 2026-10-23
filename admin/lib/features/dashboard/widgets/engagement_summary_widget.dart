import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class EngagementSummaryWidget extends StatelessWidget {
  final SurveyOverviewMetric surveyMetric;
  final PromotionVoucherOverviewMetric promoMetric;
  final CustomerReviewOverviewMetric? reviewMetric;
  final VoidCallback? onSurveyTap;
  final VoidCallback? onVoucherTap;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool showSurveys;
  final bool showPromotions;
  final bool showReviews;

  const EngagementSummaryWidget({
    super.key,
    required this.surveyMetric,
    required this.promoMetric,
    this.reviewMetric,
    this.onSurveyTap,
    this.onVoucherTap,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.showSurveys = true,
    this.showPromotions = true,
    this.showReviews = true,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    // Sub-Section A: Survey Performance
    if (showSurveys) {
      sections.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSurveyTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Khảo sát thị trường (${surveyMetric.activeSurveysCount} hoạt động)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        'Tỷ lệ: ${surveyMetric.averageResponseRate.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
          ),
        ),
      );
    }

    // Sub-Section B: Voucher / Promotion Activity
    if (showPromotions) {
      sections.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onVoucherTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            'Sử dụng voucher (${promoMetric.activeVouchersCount} mã)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '${promoMetric.totalVouchersUsed} / ${promoMetric.totalVouchersLimit}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
          ),
        ),
      );
    }

    // Sub-Section C: Customer Review / CSAT (If available)
    if (showReviews && reviewMetric != null && reviewMetric!.totalReviews > 0) {
      sections.add(
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Đánh giá khách hàng (CSAT)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    '${reviewMetric!.averageRating.toStringAsFixed(1)} / 5.0 ⭐',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (reviewMetric!.averageRating / 5.0).clamp(0.0, 1.0),
                  backgroundColor: borderColor.withValues(alpha: 0.4),
                  color: Colors.amber,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${reviewMetric!.totalReviews} lượt đánh giá', style: TextStyle(fontSize: 11, color: textSecondary)),
                  Text('${reviewMetric!.totalReplied} đã phản hồi', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
                      'Khảo sát & Tương tác khách hàng',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mức độ hài lòng, khảo sát và tỷ lệ dùng ưu đãi',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.poll_rounded, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < sections.length; i++) ...[
            sections[i],
            if (i < sections.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
