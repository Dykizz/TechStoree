import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/review.dart';
import '../../../core/providers/theme_provider.dart';

/// Hiển thị 2 card xếp hạng Top 5 sản phẩm đánh giá tốt nhất và Top 5 sản phẩm cần lưu ý.
class ReviewRankingsCards extends StatelessWidget {
  final ReviewStatistics? stats;
  final void Function(int productId, String productName) onSelectProduct;

  const ReviewRankingsCards({
    super.key,
    required this.stats,
    required this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final topProducts = stats?.topRatedProducts ?? [];
    final lowestProducts = stats?.lowestRatedProducts ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final children = [
          // Card 1: Top 5 Đánh giá Tốt nhất
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _RankingCard(
              icon: Icons.emoji_events_rounded,
              iconColor: Colors.amber,
              title: 'Top 5 sản phẩm đánh giá tốt nhất',
              subtitle: 'Được khách hàng yêu thích và đánh giá sao cao nhất',
              emptyMessage: 'Chưa có dữ liệu xếp hạng đánh giá',
              items: topProducts,
              isPositive: true,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
              onSelectProduct: onSelectProduct,
            ),
          ),

          if (!isMobile) const SizedBox(width: 14) else const SizedBox(height: 14),

          // Card 2: Top 5 Cần Lưu Ý (Đánh giá thấp / Tiêu cực)
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _RankingCard(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.danger,
              title: 'Top 5 sản phẩm cần lưu ý (đánh giá thấp)',
              subtitle: 'Sản phẩm có nhiều phản ánh tiêu cực (1-2★) cần kiểm tra',
              emptyMessage: 'Chưa có sản phẩm nào bị đánh giá tiêu cực',
              items: lowestProducts,
              isPositive: false,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
              onSelectProduct: onSelectProduct,
            ),
          ),
        ];

        return isMobile
            ? Column(children: children)
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }
}

class _RankingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<ProductRatingRanking> items;
  final bool isPositive;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final void Function(int productId, String productName) onSelectProduct;

  const _RankingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.items,
    required this.isPositive,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(emptyMessage, style: TextStyle(fontSize: 11.5, color: textSecondary)),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              return _RankingItemTile(
                rank: entry.key + 1,
                item: entry.value,
                isPositive: isPositive,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => onSelectProduct(entry.value.productId, entry.value.productName),
              );
            }),
        ],
      ),
    );
  }
}

class _RankingItemTile extends StatelessWidget {
  final int rank;
  final ProductRatingRanking item;
  final bool isPositive;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _RankingItemTile({
    required this.rank,
    required this.item,
    required this.isPositive,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color rankBadgeColor;
    if (rank == 1) {
      rankBadgeColor = Colors.amber;
    } else if (rank == 2) {
      rankBadgeColor = const Color(0xFF94A3B8); // Bạc
    } else if (rank == 3) {
      rankBadgeColor = const Color(0xFFCD7F32); // Đồng
    } else {
      rankBadgeColor = Colors.grey.shade400;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          children: [
            // Huy hiệu Rank #1, #2, #3
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankBadgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: rankBadgeColor),
              ),
            ),
            const SizedBox(width: 8),

            // Ảnh thumbnail SP
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 30,
                height: 30,
                color: Colors.grey.withValues(alpha: 0.1),
                child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
                    ? Image.network(
                        item.productImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 16),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 16),
              ),
            ),
            const SizedBox(width: 8),

            // Tên SP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isPositive
                        ? '${item.totalReviews} đánh giá (${item.positiveReviewCount} khen)'
                        : '${item.totalReviews} đánh giá • ${item.negativeReviewCount} khách chê (1-2★)',
                    style: TextStyle(fontSize: 10.5, color: isPositive ? textSecondary : AppColors.danger),
                  ),
                ],
              ),
            ),

            // Badge Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: isPositive ? Colors.amber.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 13, color: isPositive ? Colors.amber.shade700 : AppColors.danger),
                  const SizedBox(width: 3),
                  Text(
                    item.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? Colors.amber.shade800 : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

