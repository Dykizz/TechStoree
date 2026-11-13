import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/review.dart';
import '../../../core/providers/theme_provider.dart';

/// Thanh tab lọc trạng thái đánh giá kèm badge số lượng chính xác.
class ReviewStatusTabBar extends StatelessWidget {
  final ReviewStatistics? stats;
  final String selectedStatusTab;
  final ValueChanged<String> onTabSelected;

  const ReviewStatusTabBar({
    super.key,
    required this.stats,
    required this.selectedStatusTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final stats = this.stats;
    final int? allCount = stats?.totalReviews;
    // Backend ReviewStatistics đếm totalReviews và totalReplied gồm cả đánh giá đã ẩn,
    // trong khi tab Chờ phản hồi / Đã phản hồi lọc isHidden = false nên chỉ hiển thị số chính xác khi không có bài ẩn.
    final bool exactVisibleCounts = stats != null && stats.totalHidden == 0;
    final int? repliedCount = exactVisibleCounts ? stats.totalReplied : null;
    final int? pendingCount = exactVisibleCounts
        ? (stats.totalReviews - stats.totalReplied).clamp(0, stats.totalReviews)
        : null;
    final int? hiddenCount = stats?.totalHidden;

    final tabs = [
      (key: 'all', label: 'Tất cả', count: allCount, color: AppColors.primary),
      (key: 'pending', label: 'Chờ phản hồi', count: pendingCount, color: AppColors.warning),
      (key: 'replied', label: 'Đã phản hồi', count: repliedCount, color: AppColors.success),
      (key: 'negative', label: 'Đánh giá thấp (1-2★)', count: null, color: AppColors.danger),
      (key: 'hidden', label: 'Đã ẩn', count: hiddenCount, color: textSecondary),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = selectedStatusTab == tab.key;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  if (selectedStatusTab != tab.key) {
                    onTabSelected(tab.key);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? tab.color.withValues(alpha: 0.2) : tab.color.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? tab.color : Colors.transparent, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? (isDark ? Colors.white : tab.color) : textSecondary,
                        ),
                      ),
                      if (tab.count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? tab.color : (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${tab.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

