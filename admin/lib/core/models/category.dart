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
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['tenDanhMuc'] ?? '',
      code: json['code'] ?? json['maDanhMuc'] ?? '',
      productCount: (json['productCount'] ?? json['soLuongSanPham'] ?? 0).toInt(),
      description: json['description'] ?? json['moTa'] ?? '',
      iconName: json['iconName'] ?? 'devices',
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
}
