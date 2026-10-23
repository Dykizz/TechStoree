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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.6 : 0.8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF64748B).withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Icon + Title + (Optional arrow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9.5,
                  color: textSecondary.withValues(alpha: 0.35),
                ),
            ],
          ),

          // Value
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Footer: Pill Badge for trend or Subtitle
          if (kpi != null && kpi!.percentageChange != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isNeutralTrend
                        ? textSecondary.withValues(alpha: 0.10)
                        : (kpi!.isPositiveTrend
                            ? AppColors.success.withValues(alpha: isDark ? 0.20 : 0.12)
                            : AppColors.danger.withValues(alpha: isDark ? 0.20 : 0.12)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNeutralTrend
                          ? textSecondary.withValues(alpha: 0.20)
                          : (kpi!.isPositiveTrend
                              ? AppColors.success.withValues(alpha: 0.35)
                              : AppColors.danger.withValues(alpha: 0.35)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kpi!.isPositiveTrend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 9.5,
                        color: isNeutralTrend
                            ? textSecondary
                            : (kpi!.isPositiveTrend ? AppColors.success : AppColors.danger),
                      ),
                      const SizedBox(width: 1.5),
                      Text(
                        '${kpi!.percentageChange!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isNeutralTrend
                              ? textSecondary
                              : (kpi!.isPositiveTrend ? AppColors.success : AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'kỳ trước',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (subtitle != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: subtitle!.contains('Cần kiểm tra') ? AppColors.warning : AppColors.success,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '— kỳ trước',
              style: TextStyle(fontSize: 10, color: textSecondary),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.primary.withValues(alpha: 0.04),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
