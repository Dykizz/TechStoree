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
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['tenNhaCungCap'] ?? '',
      code: json['code'] ?? json['maNhaCungCap'] ?? 'SUP-${json['id']}',
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
}
