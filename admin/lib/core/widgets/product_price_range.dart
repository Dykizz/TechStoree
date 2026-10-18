import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../constants/app_colors.dart';

class ProductPriceRange extends StatelessWidget {
  final Product product;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final bool compact;

  const ProductPriceRange({
    super.key,
    required this.product,
    this.primaryStyle,
    this.secondaryStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseTextPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final baseTextSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final defaultPrimary = primaryStyle ?? TextStyle(
      color: baseTextPrimary,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 12.5 : 14,
    );

    final defaultSecondary = secondaryStyle ?? TextStyle(
      color: baseTextSecondary.withOpacity(0.7),
      fontSize: compact ? 10.5 : 12,
      decoration: TextDecoration.lineThrough,
    );

    final minP = product.minPrice;
    final maxP = product.maxPrice;

    String originalRangeStr = (minP == maxP)
        ? currencyFormat.format(minP)
        : '${currencyFormat.format(minP)} – ${currencyFormat.format(maxP)}';

    if (product.hasPromotion && product.promotion != null && product.promotion!.hasPromotion) {
      final promo = product.promotion!;
      final promoMinP = promo.promotionalMinPrice;
      final promoMaxP = promo.promotionalMaxPrice;

      String promoRangeStr = (promoMinP == promoMaxP)
          ? currencyFormat.format(promoMinP)
          : '${currencyFormat.format(promoMinP)} – ${currencyFormat.format(promoMaxP)}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            promoRangeStr,
            style: defaultPrimary.copyWith(color: const Color(0xFFDC2626)),
          ),
          const SizedBox(height: 2),
          Text(
            originalRangeStr,
            style: defaultSecondary,
          ),
        ],
      );
    }

    return Text(
      originalRangeStr,
      style: defaultPrimary,
    );
  }
}
