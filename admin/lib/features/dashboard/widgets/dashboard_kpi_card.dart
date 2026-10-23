import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

class DashboardKpiCard extends StatefulWidget {
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
  State<DashboardKpiCard> createState() => _DashboardKpiCardState();
}

class _DashboardKpiCardState extends State<DashboardKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.kpi?.isPositiveTrend ?? true;
    final hasTrend = widget.kpi != null && widget.kpi!.percentageChange != null;
    final trendPct = widget.kpi?.percentageChange?.abs().toStringAsFixed(1) ?? '0.0';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: 0.55)
                  : widget.borderColor.withValues(alpha: widget.isDark ? 0.6 : 0.8),
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.iconColor.withValues(alpha: widget.isDark ? 0.20 : 0.12)
                    : (widget.isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.05)),
                blurRadius: _isHovered ? 14 : 7,
                offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Faint decorative watermark icon in bottom-right corner
              Positioned(
                right: -6,
                bottom: -8,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.isDark ? 0.06 : 0.045,
                    child: Icon(
                      widget.icon,
                      size: 58,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),

              // Card Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Icon badge + Title + Action indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.iconColor.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.iconColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(widget.icon, size: 15, color: widget.iconColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: widget.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onTap != null)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isHovered ? 0.9 : 0.35,
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: _isHovered ? widget.iconColor : widget.textSecondary,
                          ),
                        ),
                    ],
                  ),

                  // Middle Row: Formatted Value
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      widget.formattedValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: widget.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Bottom Row: Trend pill badge or subtitle
                  if (hasTrend)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isNeutralTrend
                                ? widget.textSecondary.withValues(alpha: 0.10)
                                : (isPositive
                                    ? AppColors.success.withValues(alpha: widget.isDark ? 0.20 : 0.12)
                                    : AppColors.danger.withValues(alpha: widget.isDark ? 0.20 : 0.12)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.isNeutralTrend
                                  ? widget.textSecondary.withValues(alpha: 0.25)
                                  : (isPositive
                                      ? AppColors.success.withValues(alpha: 0.35)
                                      : AppColors.danger.withValues(alpha: 0.35)),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 10,
                                color: widget.isNeutralTrend
                                    ? widget.textSecondary
                                    : (isPositive ? AppColors.success : AppColors.danger),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$trendPct%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isNeutralTrend
                                      ? widget.textSecondary
                                      : (isPositive ? AppColors.success : AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'so với kỳ trước',
                            style: TextStyle(fontSize: 10.5, color: widget.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else if (widget.subtitle != null)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.subtitle!.contains('Cần kiểm tra') ? AppColors.warning : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: widget.subtitle!.contains('Cần kiểm tra') ? AppColors.warning : AppColors.success,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '— so với kỳ trước',
                      style: TextStyle(fontSize: 10.5, color: widget.textSecondary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
