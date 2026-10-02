class Supplier {
  final String id;
  final String name;
  final String code;
  final String contactName;
  final String phone;
  final String email;
  final String address;
  final String description;

  Supplier({
    required this.id,
    required this.name,
    required this.code,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    this.description = '',
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: (json['supplierId'] ?? json['id'])?.toString() ?? '',
      name: json['supplierName'] ?? json['name'] ?? json['tenNhaCungCap'] ?? '',
      code: json['code'] ?? json['maNhaCungCap'] ?? 'SUP-${json['supplierId'] ?? json['id']}',
      contactName: json['contactName'] ?? json['nguoiLienHe'] ?? 'N/A',
      phone: json['phone'] ?? json['soDienThoai'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? json['diaChi'] ?? '',
      description: json['description'] ?? json['moTa'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'address': address,
      'description': description,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'supplierName': name,
      'phone': phone.isNotEmpty ? phone : '0900000000',
      'email': email.isNotEmpty ? email : null,
      'address': address.isNotEmpty ? address : null,
    };
  }
}

