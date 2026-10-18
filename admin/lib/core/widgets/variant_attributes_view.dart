import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class VariantAttributesView extends StatelessWidget {
  final Map<String, String> attributes;
  final String? fallbackText;
  final bool isChipStyle;

  const VariantAttributesView({
    super.key,
    required this.attributes,
    this.fallbackText,
    this.isChipStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (attributes.isEmpty) {
      return Text(
        fallbackText ?? 'Mặc định',
        style: TextStyle(color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
      );
    }

    if (!isChipStyle) {
      final inlineText = attributes.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
      return Text(
        inlineText,
        style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: attributes.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${e.key}: ',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: e.value,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
