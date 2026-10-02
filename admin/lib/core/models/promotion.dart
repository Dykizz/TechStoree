import 'package:intl/intl.dart';

class PromotionVariantItem {
  final int variantId;
  final int productId;
  final String productName;
  final String variantName;
  final double originalPrice;
  final double promotionalPrice;
  final double discountAmount;
  final int stockQuantity;
  final String? imageUrl;
  final Map<String, String> attributes;

  PromotionVariantItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.originalPrice,
    required this.promotionalPrice,
    required this.discountAmount,
    required this.stockQuantity,
    this.imageUrl,
    Map<String, String>? attributes,
  }) : attributes = attributes ?? {};

  String get fullName {
    if (productName.isEmpty) return variantName;
    if (variantName.isEmpty || variantName.toLowerCase() == 'biến thể mặc định') {
      return productName;
    }
    return '$productName ($variantName)';
  }

  factory PromotionVariantItem.fromJson(Map<String, dynamic> json) {
    Map<String, String> attrs = {};
    if (json['attributes'] != null && json['attributes'] is Map) {
      (json['attributes'] as Map).forEach((k, v) {
        attrs[k.toString()] = v.toString();
      });
    }

    return PromotionVariantItem(
      variantId: (json['variantId'] ?? json['variant_id'] ?? 0) as int,
      productId: (json['productId'] ?? json['product_id'] ?? 0) as int,
      productName: (json['productName'] ?? '').toString(),
      variantName: (json['variantName'] ?? '').toString(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      promotionalPrice: (json['promotionalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? 0) as int,
      imageUrl: json['imageUrl'] as String?,
      attributes: attrs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'productId': productId,
      'productName': productName,
      'variantName': variantName,
      'originalPrice': originalPrice,
      'promotionalPrice': promotionalPrice,
      'discountAmount': discountAmount,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'attributes': attributes,
    };
  }
}

class Promotion {
  final int promotionId;
  final String name;
  final String description;
  final String discountType; // 'PERCENTAGE' or 'FIXED_AMOUNT'
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final String status; // 'UPCOMING', 'ACTIVE', 'EXPIRED'
  final int variantCount;
  final List<PromotionVariantItem> variants;
  final List<int> variantIds;

  Promotion({
    required this.promotionId,
    required this.name,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.status = 'ACTIVE',
    this.variantCount = 0,
    List<PromotionVariantItem>? variants,
    List<int>? variantIds,
  })  : variants = variants ?? [],
        variantIds = variantIds ?? [];

  bool get isPercentage => discountType == 'PERCENTAGE';
  bool get isFixedAmount => discountType == 'FIXED_AMOUNT';

  String formattedDiscountValue(NumberFormat currencyFormat) {
    if (isPercentage) {
      return '${discountValue.toInt()}%';
    }
    return currencyFormat.format(discountValue);
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    List<PromotionVariantItem> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => PromotionVariantItem.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    List<int> parsedVariantIds = [];
    if (json['variantIds'] != null && json['variantIds'] is List) {
      parsedVariantIds = (json['variantIds'] as List).map((id) => (id as num).toInt()).toList();
    } else if (parsedVariants.isNotEmpty) {
      parsedVariantIds = parsedVariants.map((v) => v.variantId).toList();
    }

    DateTime parsedStart;
    try {
      parsedStart = json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedStart = DateTime.now();
    }

    DateTime parsedEnd;
    try {
      parsedEnd = json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString()).toLocal()
          : DateTime.now().add(const Duration(days: 7));
    } catch (_) {
      parsedEnd = DateTime.now().add(const Duration(days: 7));
    }

    DateTime parsedCreated;
    try {
      parsedCreated = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    String parsedStatus = (json['status'] ?? 'ACTIVE').toString();

    return Promotion(
      promotionId: (json['promotionId'] ?? json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discountType: (json['discountType'] ?? 'PERCENTAGE').toString(),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      startDate: parsedStart,
      endDate: parsedEnd,
      isActive: (json['isActive'] ?? true) as bool,
      createdAt: parsedCreated,
      status: parsedStatus,
      variantCount: (json['variantCount'] ?? parsedVariants.length) as int,
      variants: parsedVariants,
      variantIds: parsedVariantIds,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'name': name,
      'description': description.isNotEmpty ? description : null,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'isActive': isActive,
      'variantIds': variantIds,
    };
  }
}
