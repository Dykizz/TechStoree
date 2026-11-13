import 'package:intl/intl.dart';
import '../utils/json_parse_helper.dart';

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
    return PromotionVariantItem(
      variantId: JsonParseHelper.parseInt(json['variantId'] ?? json['variant_id']),
      productId: JsonParseHelper.parseInt(json['productId'] ?? json['product_id']),
      productName: (json['productName'] ?? '').toString(),
      variantName: (json['variantName'] ?? '').toString(),
      originalPrice: JsonParseHelper.parseDouble(json['originalPrice']),
      promotionalPrice: JsonParseHelper.parseDouble(json['promotionalPrice']),
      discountAmount: JsonParseHelper.parseDouble(json['discountAmount']),
      stockQuantity: JsonParseHelper.parseInt(json['stockQuantity']),
      imageUrl: json['imageUrl'] as String?,
      attributes: JsonParseHelper.parseStringMap(json['attributes']),
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
      final valStr = discountValue == discountValue.roundToDouble()
          ? discountValue.toInt().toString()
          : discountValue.toString();
      return '$valStr%';
    }
    return currencyFormat.format(discountValue);
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final parsedVariants = JsonParseHelper.parseJsonList(
      json['variants'],
      PromotionVariantItem.fromJson,
    );

    final parsedVariantIds = json['variantIds'] is List
        ? JsonParseHelper.parseIntList(json['variantIds'])
        : parsedVariants.map((v) => v.variantId).toList();

    return Promotion(
      promotionId: JsonParseHelper.parseInt(json['promotionId'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discountType: (json['discountType'] ?? 'PERCENTAGE').toString(),
      discountValue: JsonParseHelper.parseDouble(json['discountValue']),
      startDate: JsonParseHelper.parseDate(json['startDate']),
      endDate: JsonParseHelper.parseDate(
        json['endDate'],
        fallback: DateTime.now().add(const Duration(days: 7)),
      ),
      isActive: JsonParseHelper.parseBool(json['isActive'], fallback: true),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      status: (json['status'] ?? 'ACTIVE').toString(),
      variantCount: JsonParseHelper.parseInt(json['variantCount'], parsedVariants.length),
      variants: parsedVariants,
      variantIds: parsedVariantIds,
    );
  }

  Promotion copyWith({
    int? promotionId,
    String? name,
    String? description,
    String? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    String? status,
    int? variantCount,
    List<PromotionVariantItem>? variants,
    List<int>? variantIds,
  }) {
    return Promotion(
      promotionId: promotionId ?? this.promotionId,
      name: name ?? this.name,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      variantCount: variantCount ?? this.variantCount,
      variants: variants ?? this.variants,
      variantIds: variantIds ?? this.variantIds,
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
