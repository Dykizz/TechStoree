class Supplier {
  final String id;
  final String name;
  final String code;
  final String phone;
  final String email;
  final String address;
  final String description;
  final DateTime? deletedAt;
  final bool isActive;

  bool get isDeleted => deletedAt != null;

  Supplier({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.email,
    required this.address,
    this.description = '',
    this.deletedAt,
    this.isActive = true,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: (json['supplierId'] ?? json['id'])?.toString() ?? '',
      name: json['supplierName'] ?? json['name'] ?? json['tenNhaCungCap'] ?? '',
      code: json['code'] ?? json['maNhaCungCap'] ?? 'SUP-${json['supplierId'] ?? json['id']}',
      phone: json['phone'] ?? json['soDienThoai'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? json['diaChi'] ?? '',
      description: json['description'] ?? json['moTa'] ?? '',
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'phone': phone,
      'email': email,
      'address': address,
      'description': description,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'supplierName': name,
      'phone': phone.isNotEmpty ? phone : '0900000000',
      'email': email.isNotEmpty ? email : null,
      'address': address.isNotEmpty ? address : null,
      'isActive': isActive,
    };
  }
}
