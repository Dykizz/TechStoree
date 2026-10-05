import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final bool isSuccess;
  final bool isWarning;
  final bool isDanger;
  final bool isInfo;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.isSuccess = false,
    this.isWarning = false,
    this.isDanger = false,
    this.isInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = color ?? AppColors.lightTextSecondary;
    Color bgColor = backgroundColor ?? const Color(0xFFF1F5F9);
    Color borderColor = const Color(0xFFE2E8F0);

    if (isSuccess) {
      textColor = AppColors.success;
      bgColor = AppColors.successBg;
      borderColor = AppColors.successBorder;
    } else if (isWarning) {
      textColor = AppColors.warning;
      bgColor = AppColors.warningBg;
      borderColor = AppColors.warningBorder;
    } else if (isDanger) {
      textColor = AppColors.danger;
      bgColor = AppColors.dangerBg;
      borderColor = AppColors.dangerBorder;
    } else if (isInfo) {
      textColor = AppColors.info;
      bgColor = AppColors.infoBg;
      borderColor = AppColors.infoBorder;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
