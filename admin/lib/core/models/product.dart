import 'dart:math' as math;

int _parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? defaultValue;
  }
  return defaultValue;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) {
    final parsed = int.tryParse(val);
    if (parsed != null) return parsed;
    final d = double.tryParse(val);
    return d?.toInt();
  }
  return null;
}

double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? defaultValue;
  }
  return defaultValue;
}

double? _parseNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val);
  }
  return null;
}

bool _parseBool(dynamic val, [bool defaultValue = true]) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is num) return val != 0;
  if (val is String) {
    final lower = val.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

class VariantPromotionSummary {
  final bool hasPromotion;
  final int? promotionId;
  final String promotionName;
  final String? discountType;
  final double? discountValue;
  final double promotionalPrice;
  final double discountAmount;

  VariantPromotionSummary({
    this.hasPromotion = false,
    this.promotionId,
    this.promotionName = '',
    this.discountType,
    this.discountValue,
    this.promotionalPrice = 0,
    this.discountAmount = 0,
  });

  factory VariantPromotionSummary.fromJson(Map<String, dynamic> json) {
    return VariantPromotionSummary(
      hasPromotion: _parseBool(json['hasPromotion'], true),
      promotionId: _parseNullableInt(json['promotionId']),
      promotionName: json['promotionName']?.toString() ?? '',
      discountType: json['discountType']?.toString(),
      discountValue: _parseNullableDouble(json['discountValue']),
      promotionalPrice: _parseDouble(json['promotionalPrice']),
      discountAmount: _parseDouble(json['discountAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasPromotion': hasPromotion,
      if (promotionId != null) 'promotionId': promotionId,
      'promotionName': promotionName,
      if (discountType != null) 'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      'promotionalPrice': promotionalPrice,
      'discountAmount': discountAmount,
    };
  }
}

class ProductPromotionSummary {
  final bool hasPromotion;
  final int? promotionId;
  final String promotionName;
  final String? discountType; // "PERCENTAGE" or "FIXED_AMOUNT"
  final double? discountValue;
  final double promotionalMinPrice;
  final double promotionalMaxPrice;

  ProductPromotionSummary({
    this.hasPromotion = false,
    this.promotionId,
    this.promotionName = '',
    this.discountType,
    this.discountValue,
    this.promotionalMinPrice = 0,
    this.promotionalMaxPrice = 0,
  });

  factory ProductPromotionSummary.fromJson(Map<String, dynamic> json) {
    return ProductPromotionSummary(
      hasPromotion: _parseBool(json['hasPromotion'], true),
      promotionId: _parseNullableInt(json['promotionId']),
      promotionName: json['promotionName']?.toString() ?? '',
      discountType: json['discountType']?.toString(),
      discountValue: _parseNullableDouble(json['discountValue']),
      promotionalMinPrice: _parseDouble(json['promotionalMinPrice']),
      promotionalMaxPrice: _parseDouble(json['promotionalMaxPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasPromotion': hasPromotion,
      if (promotionId != null) 'promotionId': promotionId,
      'promotionName': promotionName,
      if (discountType != null) 'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      'promotionalMinPrice': promotionalMinPrice,
      'promotionalMaxPrice': promotionalMaxPrice,
    };
  }
}

class ProductVariant {
  final int? variantId;
  final int? productId;
  final String? productName;
  final String? variantNameAttr;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final Map<String, String> attributes;
  final VariantPromotionSummary? promotion;
  final bool hasPromotion;
  final bool isActive;
  final DateTime? createdAt;

  ProductVariant({
    this.variantId,
    this.productId,
    this.productName,
    this.variantNameAttr,
    required this.price,
    this.stockQuantity = 0,
    this.imageUrl,
    Map<String, String>? attributes,
    this.promotion,
    bool? hasPromotion,
    this.isActive = true,
    this.createdAt,
  })  : attributes = attributes ?? {},
        hasPromotion = hasPromotion ?? (promotion != null && promotion.hasPromotion);

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    Map<String, String> attrs = {};
    if (json['attributes'] != null && json['attributes'] is Map) {
      (json['attributes'] as Map).forEach((k, v) {
        attrs[k.toString()] = v.toString();
      });
    }

    VariantPromotionSummary? promo;
    if (json['promotion'] != null && json['promotion'] is Map) {
      promo = VariantPromotionSummary.fromJson(json['promotion'] as Map<String, dynamic>);
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return ProductVariant(
      variantId: _parseNullableInt(json['variantId'] ?? json['variant_id']),
      productId: _parseNullableInt(json['productId'] ?? json['product_id']),
      productName: json['productName']?.toString(),
      variantNameAttr: (json['variantName'] ?? json['variant_name'])?.toString(),
      price: _parseDouble(json['price']),
      stockQuantity: _parseInt(json['stockQuantity'] ?? json['stock_quantity'], 0),
      imageUrl: (json['imageUrl'] ?? json['image_url'])?.toString(),
      attributes: attrs,
      promotion: promo,
      hasPromotion: _parseBool(json['hasPromotion'] ?? (promo != null && promo.hasPromotion), false),
      isActive: _parseBool(json['isActive'] ?? json['is_active'], true),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (variantId != null && variantId! > 0) 'variantId': variantId,
      if (productId != null && productId! > 0) 'productId': productId,
      if (productName != null) 'productName': productName,
      if (variantNameAttr != null) 'variantName': variantNameAttr,
      'price': price,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl?.isNotEmpty == true ? imageUrl : null,
      'attributes': attributes,
      if (promotion != null) 'promotion': promotion!.toJson(),
      'hasPromotion': hasPromotion,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  String get variantName {
    if (variantNameAttr != null && variantNameAttr!.trim().isNotEmpty) {
      return variantNameAttr!.trim();
    }
    if (attributes.containsKey('Phiên bản')) {
      return attributes['Phiên bản']!;
    }
    if (attributes.isEmpty) return 'Biến thể mặc định';
    return attributes.entries.map((e) => e.value).join(' - ');
  }

  String get attributesText {
    if (attributes.isEmpty) {
      return variantNameAttr ?? 'Biến thể mặc định';
    }
    return attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int categoryId;
  final double minPrice;
  final double maxPrice;
  final int totalStock;
  final double price; // Alias for minPrice
  final double? originalPrice;
  final int stock; // Alias for totalStock
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock', 'Ngừng bán'
  final bool isActive;
  final String imageUrl;
  final String description;
  final ProductPromotionSummary? promotion;
  final bool hasPromotion;
  final DateTime? createdAt;
  final List<String> variantAttributes;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.categoryId = 1,
    double? minPrice,
    double? maxPrice,
    int? totalStock,
    double? price,
    this.originalPrice,
    int? stock,
    required this.status,
    this.isActive = true,
    required this.imageUrl,
    this.description = '',
    this.promotion,
    bool? hasPromotion,
    this.createdAt,
    List<String>? variantAttributes,
    List<ProductVariant>? variants,
  })  : variants = variants ?? [],
        variantAttributes = variantAttributes ?? [],
        minPrice = minPrice ?? (price ?? 0),
        maxPrice = maxPrice ?? (price ?? 0),
        totalStock = totalStock ?? (stock ?? 0),
        price = price ?? (minPrice ?? 0),
        stock = stock ?? (totalStock ?? 0),
        hasPromotion = hasPromotion ?? (promotion != null && promotion.hasPromotion);

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawStock = _parseInt(json['totalStock'] ?? json['stock'] ?? json['soLuongTon'], 0);
    final active = _parseBool(json['isActive'] ?? json['is_active'], true);

    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .where((v) => v != null && v is Map)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    double calcMinP = _parseDouble(json['minPrice'] ?? json['price'] ?? json['giaBan'], 0);
    double calcMaxP = _parseDouble(json['maxPrice'] ?? json['price'] ?? json['giaBan'], 0);
    int calcStock = rawStock;

    if (parsedVariants.isNotEmpty) {
      final variantPrices = parsedVariants.map((v) => v.price).toList();
      final variantStocks = parsedVariants.map((v) => v.stockQuantity).toList();
      calcMinP = variantPrices.reduce(math.min);
      calcMaxP = variantPrices.reduce(math.max);
      calcStock = variantStocks.reduce((a, b) => a + b);
    }

    ProductPromotionSummary? promo;
    if (json['promotion'] != null && json['promotion'] is Map) {
      promo = ProductPromotionSummary.fromJson(json['promotion'] as Map<String, dynamic>);
    }

    double? origP;
    if (promo != null && promo.hasPromotion && promo.promotionalMinPrice > 0 && promo.promotionalMinPrice < calcMinP) {
      origP = calcMinP;
    } else {
      final rawOrig = (json['originalPrice'] ?? json['giaGoc'] ?? json['marketPrice']);
      if (rawOrig != null) {
        final val = _parseDouble(rawOrig, 0);
        if (val > calcMinP) {
          origP = val;
        }
      }
    }

    String currentStatus;
    if (!active) {
      currentStatus = 'Ngừng bán';
    } else if (calcStock > 10) {
      currentStatus = 'In Stock';
    } else if (calcStock > 0) {
      currentStatus = 'Low Stock';
    } else {
      currentStatus = 'Out of Stock';
    }

    List<String> parsedVarAttrs = [];
    if (json['variantAttributes'] != null && json['variantAttributes'] is List) {
      parsedVarAttrs = (json['variantAttributes'] as List).map((e) => e.toString()).toList();
    }
    if (parsedVarAttrs.isEmpty && parsedVariants.isNotEmpty) {
      Set<String> keys = {};
      for (var v in parsedVariants) {
        keys.addAll(v.attributes.keys);
      }
      parsedVarAttrs = keys.toList();
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return Product(
      id: (json['productId'] ?? json['id'])?.toString() ?? '',
      name: json['productName']?.toString() ?? json['name']?.toString() ?? json['tenSanPham']?.toString() ?? '',
      sku: json['sku']?.toString() ?? json['maSKU']?.toString() ?? 'TS-PROD-${json['productId'] ?? json['id']}',
      category: json['categoryName']?.toString() ?? json['category']?.toString() ?? json['tenDanhMuc']?.toString() ?? 'Công nghệ',
      categoryId: _parseInt(json['categoryId'], 1),
      minPrice: calcMinP,
      maxPrice: calcMaxP,
      totalStock: calcStock,
      price: calcMinP,
      originalPrice: origP,
      stock: calcStock,
      status: currentStatus,
      isActive: active,
      imageUrl: json['imageUrl']?.toString() ?? json['hinhAnh']?.toString() ?? 'https://picsum.photos/200',
      description: json['description']?.toString() ?? json['moTa']?.toString() ?? '',
      promotion: promo,
      hasPromotion: _parseBool(json['hasPromotion'] ?? (promo != null && promo.hasPromotion), false),
      createdAt: parsedCreatedAt,
      variantAttributes: parsedVarAttrs,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': int.tryParse(id) ?? id,
      'productName': name,
      'sku': sku,
      'categoryName': category,
      'categoryId': categoryId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'totalStock': totalStock,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'description': description,
      if (promotion != null) 'promotion': promotion!.toJson(),
      'hasPromotion': hasPromotion,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'variantAttributes': variantAttributes,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'productName': name,
      'categoryId': categoryId,
      'description': description.isNotEmpty ? description : null,
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
      'isActive': isActive,
      'variantAttributes': variantAttributes.isNotEmpty ? variantAttributes : null,
      'variants': variants.isNotEmpty
          ? variants.map((v) {
              var m = v.toJson();
              m.remove('variantId');
              return m;
            }).toList()
          : [
              {
                'price': price,
                'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
                'attributes': {},
                'isActive': true,
              }
            ],
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'productName': name,
      'categoryId': categoryId,
      'description': description.isNotEmpty ? description : null,
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
      'isActive': isActive,
      'variantAttributes': variantAttributes.isNotEmpty ? variantAttributes : null,
      'variants': variants.isNotEmpty
          ? variants.map((v) {
              var m = v.toJson();
              if (v.variantId == null || v.variantId! <= 0) {
                m.remove('variantId');
              }
              return m;
            }).toList()
          : [
              {
                'price': price,
                'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
                'attributes': {},
                'isActive': true,
              }
            ],
    };
  }
}
