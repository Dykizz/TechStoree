import 'package:flutter/material.dart';
import '../models/product.dart';

class PromotionBadge extends StatelessWidget {
  final ProductPromotionSummary? productPromotion;
  final VariantPromotionSummary? variantPromotion;
  final bool isVariant;

  const PromotionBadge({
    super.key,
    this.productPromotion,
    this.variantPromotion,
    this.isVariant = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPromo = isVariant
        ? (variantPromotion != null && variantPromotion!.hasPromotion)
        : (productPromotion != null && productPromotion!.hasPromotion);

    if (!hasPromo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Không có KM',
          style: TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      );
    }

    final String name = isVariant
        ? (variantPromotion?.promotionName ?? 'Khuyến mãi')
        : (productPromotion?.promotionName ?? 'Khuyến mãi');

    final String? type = isVariant ? variantPromotion?.discountType : productPromotion?.discountType;
    final double? val = isVariant ? variantPromotion?.discountValue : productPromotion?.discountValue;

    String valStr = '';
    if (val != null && val > 0) {
      valStr = (type == 'PERCENTAGE') ? ' -${val.toInt()}%' : ' -${val.toInt()}đ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded, size: 12, color: Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$name$valStr',
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
