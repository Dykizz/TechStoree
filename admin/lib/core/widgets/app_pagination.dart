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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          // Info & Items per page Dropdown
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hiển thị ',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                '$startItem-$endItem',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                ' trong số ',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                '$totalItems',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                ' kết quả',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              if (onItemsPerPageChanged != null) ...[
                const SizedBox(width: 16),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPageOptions.contains(itemsPerPage) ? itemsPerPage : itemsPerPageOptions.first,
                      dropdownColor: backgroundColor,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary, size: 20),
                      style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
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
              ],
            ],
          ),

          // Pagination Controls (First, Prev, Page Numbers, Next, Last)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Page
              _buildPageButton(
                context,
                icon: Icons.first_page_rounded,
                isEnabled: currentPage > 1,
                onTap: () => onPageChanged(1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              // Prev Page
              _buildPageButton(
                context,
                icon: Icons.chevron_left_rounded,
                isEnabled: currentPage > 1,
                onTap: () => onPageChanged(currentPage - 1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 6),

              // Page Number Chips
              ..._generatePageNumbers().map((pageNumber) {
                if (pageNumber == -1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('...', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                  );
                }

                final isSelected = pageNumber == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => onPageChanged(pageNumber),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.primary : borderColor),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(width: 6),

              // Next Page
              _buildPageButton(
                context,
                icon: Icons.chevron_right_rounded,
                isEnabled: currentPage < totalPages,
                onTap: () => onPageChanged(currentPage + 1),
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              // Last Page
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : Colors.grey.withOpacity(0.4),
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
      if (currentPage > 3) {
        pages.add(-1); // Ellipsis
      }

      int start = (currentPage - 1).clamp(2, totalPages - 1);
      int end = (currentPage + 1).clamp(2, totalPages - 1);

      for (int i = start; i <= end; i++) {
        if (!pages.contains(i)) {
          pages.add(i);
        }
      }

      if (currentPage < totalPages - 2) {
        pages.add(-1); // Ellipsis
      }
      if (!pages.contains(totalPages)) {
        pages.add(totalPages);
      }
    }
    return pages;
  }
}
