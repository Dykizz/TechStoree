class Category {
  final String id;
  final String name;
  final String code;
  final int productCount;
  final String description;
  final String iconName;

  Category({
    required this.id,
    required this.name,
    required this.code,
    required this.productCount,
    required this.description,
    required this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    int count = 0;
    final rawCount = json['productCount'] ?? json['soLuongSanPham'];
    if (rawCount != null) {
      if (rawCount is num) {
        count = rawCount.toInt();
      } else if (rawCount is String) {
        count = int.tryParse(rawCount) ?? 0;
      }
    }
    return Category(
      id: (json['categoryId'] ?? json['id'])?.toString() ?? '',
      name: json['categoryName']?.toString() ?? json['name']?.toString() ?? json['tenDanhMuc']?.toString() ?? '',
      code: json['code']?.toString() ?? json['maDanhMuc']?.toString() ?? 'CAT-${json['categoryId'] ?? json['id']}',
      productCount: count,
      description: json['description']?.toString() ?? json['moTa']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? 'devices',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'productCount': productCount,
      'description': description,
      'iconName': iconName,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'categoryName': name,
    };
  }
}

