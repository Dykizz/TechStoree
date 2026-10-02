class ProductVariant {
  final int? variantId;
  final int? productId;
  final String? variantNameAttr;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final Map<String, String> attributes;
  final bool isActive;

  ProductVariant({
    this.variantId,
    this.productId,
    this.variantNameAttr,
    required this.price,
    this.stockQuantity = 0,
    this.imageUrl,
    Map<String, String>? attributes,
    this.isActive = true,
  }) : attributes = attributes ?? {};

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    Map<String, String> attrs = {};
    if (json['attributes'] != null && json['attributes'] is Map) {
      (json['attributes'] as Map).forEach((k, v) {
        attrs[k.toString()] = v.toString();
      });
    }
    return ProductVariant(
      variantId: (json['variantId'] ?? json['variant_id']) as int?,
      productId: (json['productId'] ?? json['product_id']) as int?,
      variantNameAttr: (json['variantName'] ?? json['variant_name'])?.toString(),
      price: (json['price'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? json['stock_quantity'] ?? 0).toInt(),
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      attributes: attrs,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (variantId != null && variantId! > 0) 'variantId': variantId,
      if (productId != null && productId! > 0) 'productId': productId,
      if (variantNameAttr != null) 'variantName': variantNameAttr,
      'price': price,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl?.isNotEmpty == true ? imageUrl : null,
      'attributes': attributes,
      'isActive': isActive,
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
  final double price;
  final int stock;
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock', 'Ngừng bán'
  final bool isActive;
  final String imageUrl;
  final String description;
  final List<String> variantAttributes;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.categoryId = 1,
    required this.price,
    required this.stock,
    required this.status,
    this.isActive = true,
    required this.imageUrl,
    this.description = '',
    List<String>? variantAttributes,
    List<ProductVariant>? variants,
  })  : variantAttributes = variantAttributes ?? [],
        variants = variants ?? [];

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawStock = (json['totalStock'] ?? json['stock'] ?? json['soLuongTon'] ?? 0).toInt();
    final active = (json['isActive'] ?? true) as bool;
    final minP = (json['minPrice'] ?? json['price'] ?? json['giaBan'] ?? 0).toDouble();

    String currentStatus;
    if (!active) {
      currentStatus = 'Ngừng bán';
    } else if (rawStock > 10) {
      currentStatus = 'In Stock';
    } else if (rawStock > 0) {
      currentStatus = 'Low Stock';
    } else {
      currentStatus = 'Out of Stock';
    }

    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
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

    return Product(
      id: (json['productId'] ?? json['id'])?.toString() ?? '',
      name: json['productName'] ?? json['name'] ?? json['tenSanPham'] ?? '',
      sku: json['sku'] ?? json['maSKU'] ?? 'TS-PROD-${json['productId'] ?? json['id']}',
      category: json['categoryName'] ?? json['category'] ?? json['tenDanhMuc'] ?? 'Công nghệ',
      categoryId: (json['categoryId'] ?? 1).toInt(),
      price: minP,
      stock: rawStock,
      status: currentStatus,
      isActive: active,
      imageUrl: json['imageUrl'] ?? json['hinhAnh'] ?? 'https://picsum.photos/200',
      description: json['description'] ?? json['moTa'] ?? '',
      variantAttributes: parsedVarAttrs,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'status': status,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'description': description,
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
