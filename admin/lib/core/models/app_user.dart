class AppUser {
  final String id;
  final String userName; // Username đăng nhập
  final String fullName; // Họ và tên
  final String email;
  final String role; // 'ADMIN', 'USER', 'STAFF'
  final String status; // 'Hoạt động', 'Tạm khóa'
  final bool isLocked;
  final String phone;
  final String? techInterest;
  final DateTime? dateOfBirth;
  final String? address;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.userName,
    String? fullName,
    required this.email,
    required this.role,
    required this.status,
    this.isLocked = false,
    this.phone = '',
    this.techInterest,
    this.dateOfBirth,
    this.address,
    required this.createdAt,
  }) : fullName = (fullName != null && fullName.isNotEmpty) ? fullName : userName;

  int get age => dateOfBirth != null ? DateTime.now().year - dateOfBirth!.year : 0;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final locked = json['isLocked'] == true || (json['status'] == 'Tạm khóa');
    final rawUsername = (json['username'] ?? json['userName'] ?? json['fullName'] ?? json['hoTen'])?.toString() ?? '';
    final rawFullName = (json['fullName'] ?? json['hoTen'] ?? json['userName'] ?? json['username'])?.toString() ?? '';
    final rawEmail = json['email']?.toString() ?? '';
    final rawRole = (json['role'] ?? json['vaiTro'] ?? 'USER')?.toString() ?? 'USER';
    final rawPhone = (json['phone'] ?? json['soDienThoai'] ?? '')?.toString() ?? '';
    final rawTechInterest = json['techInterest']?.toString();
    final rawAddress = json['address']?.toString();

    DateTime? dob;
    if (json['dateOfBirth'] != null) {
      dob = DateTime.tryParse(json['dateOfBirth'].toString());
    }

    DateTime created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final uName = rawUsername.isNotEmpty ? rawUsername : rawFullName;
    final fName = rawFullName.isNotEmpty ? rawFullName : uName;

    return AppUser(
      id: (json['userId'] ?? json['id'])?.toString() ?? '0',
      userName: uName,
      fullName: fName,
      email: rawEmail,
      role: rawRole,
      status: locked ? 'Tạm khóa' : 'Hoạt động',
      isLocked: locked,
      phone: rawPhone,
      techInterest: rawTechInterest,
      dateOfBirth: dob,
      address: rawAddress,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'role': role,
      'status': status,
      'isLocked': isLocked,
      'phone': phone,
      'techInterest': techInterest,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}



