import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class FilterBar extends StatelessWidget {
  final Widget searchField;
  final List<Widget> filters;

  const FilterBar({
    super.key,
    required this.searchField,
    this.filters = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final realFilters = filters.where((f) => f is! SizedBox).toList();
          
          if (constraints.maxWidth < 800) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: constraints.maxWidth,
                  child: searchField,
                ),
                for (final filter in realFilters)
                  SizedBox(
                    width: constraints.maxWidth > 500 ? (constraints.maxWidth / 2) - 4 : constraints.maxWidth,
                    child: filter,
                  ),
              ],
            );
          }
          
          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              for (final filter in realFilters) ...[
                const SizedBox(width: 8),
                Expanded(flex: 2, child: filter),
              ],
            ],
          );
        },
      ),
    );
  }
}
