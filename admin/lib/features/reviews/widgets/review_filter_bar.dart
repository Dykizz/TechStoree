import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/filter_bar.dart';

/// Thanh tìm kiếm và bộ lọc số sao, ảnh đính kèm và sản phẩm đang lọc cho màn hình đánh giá.
class ReviewFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final double? selectedRating;
  final bool onlyWithImages;
  final int? filteredProductId;
  final String? filteredProductName;
  final VoidCallback onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<double?> onRatingChanged;
  final ValueChanged<bool> onOnlyWithImagesChanged;
  final VoidCallback onClearProductFilter;

  const ReviewFilterBar({
    super.key,
    required this.searchController,
    required this.selectedRating,
    required this.onlyWithImages,
    required this.filteredProductId,
    required this.filteredProductName,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSearchSubmitted,
    required this.onRatingChanged,
    required this.onOnlyWithImagesChanged,
    required this.onClearProductFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterBar(
          searchField: AppTextField(
            controller: searchController,
            hintText: 'Tìm theo tên khách, sản phẩm, nhận xét...',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => onSearchChanged(),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    tooltip: 'Xóa từ khóa tìm kiếm',
                    onPressed: onClearSearch,
                  )
                : null,
            onFieldSubmitted: (_) => onSearchSubmitted(),
          ),
          filters: [
            // Dropdown lọc số sao
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double?>(
                  value: selectedRating,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500),
                  dropdownColor: cardBg,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả số sao')),
                    DropdownMenuItem(value: 5.0, child: Text('⭐⭐⭐⭐⭐ (5 sao)')),
                    DropdownMenuItem(value: 4.0, child: Text('⭐⭐⭐⭐ (4 sao)')),
                    DropdownMenuItem(value: 3.0, child: Text('⭐⭐⭐ (3 sao)')),
                    DropdownMenuItem(value: 2.0, child: Text('⭐⭐ (2 sao)')),
                    DropdownMenuItem(value: 1.0, child: Text('⭐ (1 sao)')),
                  ],
                  onChanged: onRatingChanged,
                ),
              ),
            ),

            // Filter Có ảnh đính kèm
            FilterChip(
              label: const Text('Có ảnh đính kèm', style: TextStyle(fontSize: 11.5)),
              selected: onlyWithImages,
              onSelected: onOnlyWithImagesChanged,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: onlyWithImages ? AppColors.primary : cardBorder),
              ),
            ),
          ],
        ),

        // Hiển thị Chip đang lọc theo sản phẩm cụ thể (nếu có)
        if (filteredProductId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Text('Đang lọc đánh giá của: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Flexible(
                  child: Chip(
                    label: Text(
                      filteredProductName ?? 'Sản phẩm #$filteredProductId',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: onClearProductFilter,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

