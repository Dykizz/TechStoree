class AppUser {
  final String id;
  final String userName;
  final String email;
  final String role; // 'ADMIN', 'USER'
  final String status; // 'Hoạt động', 'Tạm khóa'
  final bool isLocked;
  final String phone;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    required this.status,
    this.isLocked = false,
    this.phone = '',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final locked = json['isLocked'] ?? (json['status'] == 'Tạm khóa');
    return AppUser(
      id: (json['userId'] ?? json['id'])?.toString() ?? '',
      userName: json['fullName'] ?? json['username'] ?? json['userName'] ?? json['hoTen'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['vaiTro'] ?? 'USER',
      status: locked ? 'Tạm khóa' : 'Hoạt động',
      isLocked: locked,
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
      'isLocked': isLocked,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

