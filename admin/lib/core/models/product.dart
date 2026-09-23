class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock'
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.status,
    required this.imageUrl,
    this.description = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['tenSanPham'] ?? '',
      sku: json['sku'] ?? json['maSKU'] ?? 'TS-${json['id']}',
      category: json['category'] ?? json['tenDanhMuc'] ?? 'Thiết bị công nghệ',
      price: (json['price'] ?? json['giaBan'] ?? 0).toDouble(),
      stock: (json['stock'] ?? json['soLuongTon'] ?? 0).toInt(),
      status: json['status'] ?? (json['soLuongTon'] != null && (json['soLuongTon'] as int) > 10
          ? 'In Stock'
          : (json['soLuongTon'] != null && (json['soLuongTon'] as int) > 0 ? 'Low Stock' : 'Out of Stock')),
      imageUrl: json['imageUrl'] ?? json['hinhAnh'] ?? 'https://picsum.photos/200',
      description: json['description'] ?? json['moTa'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'price': price,
      'stock': stock,
      'status': status,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}
