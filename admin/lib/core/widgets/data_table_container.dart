import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'scrollable_table_wrapper.dart';

class DataTableContainer extends StatelessWidget {
  final Widget child;
  final bool isScrollableTable;

  const DataTableContainer({
    super.key,
    required this.child,
    this.isScrollableTable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            dataTableTheme: DataTableThemeData(
              dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
                }
                if (states.contains(WidgetState.hovered)) {
                  return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
                }
                return null;
              }),
            ),
          ),
          child: isScrollableTable
              ? ScrollableTableWrapper(child: child)
              : child,
        ),
      ),
    );
  }
}
