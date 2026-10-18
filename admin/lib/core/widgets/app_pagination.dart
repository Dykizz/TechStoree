import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class AppPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [5, 10, 20, 50],
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage) > totalItems ? totalItems : (currentPage * itemsPerPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Result Count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hiển thị ', style: TextStyle(color: textSecondary, fontSize: 12)),
              Text('$startItem-$endItem', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              Text(' trong số ', style: TextStyle(color: textSecondary, fontSize: 12)),
              Text('$totalItems', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              Text(' kết quả', style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),

          // Right: Page size selector + Page navigation buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onItemsPerPageChanged != null) ...[
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPageOptions.contains(itemsPerPage) ? itemsPerPage : itemsPerPageOptions.first,
                      dropdownColor: backgroundColor,
                      icon: Icon(Icons.arrow_drop_down, color: textSecondary, size: 16),
                      style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                      items: itemsPerPageOptions
                          .map((val) => DropdownMenuItem<int>(
                                value: val,
                                child: Text('$val / trang'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null && onItemsPerPageChanged != null) {
                          onItemsPerPageChanged!(val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              _buildPageButton(
                context,
                icon: Icons.first_page_rounded,
                isEnabled: currentPage > 1,
                onTap: () => onPageChanged(1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                context,
                icon: Icons.chevron_left_rounded,
                isEnabled: currentPage > 1,
                onTap: () => onPageChanged(currentPage - 1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              ..._generatePageNumbers().map((pageNumber) {
                if (pageNumber == -1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text('...', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                  );
                }

                final isSelected = pageNumber == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => onPageChanged(pageNumber),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF)),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isSelected ? AppColors.primary : borderColor),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(width: 4),
              _buildPageButton(
                context,
                icon: Icons.chevron_right_rounded,
                isEnabled: currentPage < totalPages,
                onTap: () => onPageChanged(currentPage + 1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                context,
                icon: Icons.last_page_rounded,
                isEnabled: currentPage < totalPages,
                onTap: () => onPageChanged(totalPages),
                borderColor: borderColor,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
    BuildContext context, {
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    required Color borderColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isEnabled ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.lightTextSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  List<int> _generatePageNumbers() {
    List<int> pages = [];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(-1);

      int start = (currentPage - 1).clamp(2, totalPages - 1);
      int end = (currentPage + 1).clamp(2, totalPages - 1);

      for (int i = start; i <= end; i++) {
        if (!pages.contains(i)) pages.add(i);
      }

      if (currentPage < totalPages - 2) pages.add(-1);
      if (!pages.contains(totalPages)) pages.add(totalPages);
    }
    return pages;
  }
}
