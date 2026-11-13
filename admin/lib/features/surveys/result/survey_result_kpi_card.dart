import 'package:flutter/material.dart';

/// Thẻ hiển thị chỉ số KPI tổng quan cho báo cáo thống kê khảo sát.
class SurveyResultKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyResultKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<SurveyResultKpiCard> createState() => _SurveyResultKpiCardState();
}

class _SurveyResultKpiCardState extends State<SurveyResultKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  : (widget.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFF64748B).withValues(alpha: 0.05)),
              blurRadius: _isHovered ? 14 : 7,
              offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, size: 14, color: widget.iconColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: widget.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.subtext.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      widget.subtext,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: widget.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

