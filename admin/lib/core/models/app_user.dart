class AppUser {
  final String id;
  final String userName;
  final String email;
  final String role; // 'Admin', 'Manager', 'Staff', 'Customer'
  final String status; // 'Hoạt động', 'Tạm khóa'
  final String phone;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    required this.status,
    this.phone = '',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      userName: json['userName'] ?? json['name'] ?? json['hoTen'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['vaiTro'] ?? 'Customer',
      status: json['status'] ?? json['trangThai'] ?? 'Hoạt động',
      phone: json['phone'] ?? json['soDienThoai'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'role': role,
      'status': status,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
