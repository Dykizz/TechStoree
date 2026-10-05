import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class DashboardKpiCard extends StatelessWidget {
  final String title;
  final String formattedValue;
  final DashboardMetricKpi? kpi;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isNeutralTrend;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const DashboardKpiCard({
    super.key,
    required this.title,
    required this.formattedValue,
    this.kpi,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isNeutralTrend = false,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          if (kpi != null && kpi!.percentageChange != null) ...[
            Row(
              children: [
                Icon(
                  kpi!.isPositiveTrend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 13,
                  color: isNeutralTrend
                      ? textSecondary
                      : (kpi!.isPositiveTrend ? AppColors.success : AppColors.danger),
                ),
                const SizedBox(width: 2),
                Text(
                  '${kpi!.percentageChange!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNeutralTrend
                        ? textSecondary
                        : (kpi!.isPositiveTrend ? AppColors.success : AppColors.danger),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'so với kỳ trước',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ] else if (subtitle != null) ...[
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Text(
              '— so với kỳ trước',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
