import '../utils/json_parse_helper.dart';

class AppUser {
  final String id;
  final String userName; // Username đăng nhập
  final String fullName; // Họ và tên
  final String email;
  final String role; // Primary role (e.g., 'ADMIN', 'USER', 'WAREHOUSE_STAFF')
  final List<String> roles; // All roles
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
    this.roles = const [],
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
    final locked = JsonParseHelper.parseBool(json['isLocked']) || (json['status'] == 'Tạm khóa');
    final rawUsername = (json['username'] ?? json['userName'] ?? json['fullName'] ?? json['hoTen'])?.toString() ?? '';
    final rawFullName = (json['fullName'] ?? json['hoTen'] ?? json['userName'] ?? json['username'])?.toString() ?? '';
    final rawEmail = json['email']?.toString() ?? '';

    final rawRoles = json['roles'] is List ? json['roles'] : json['vaiTro'];
    List<String> parsedRoles = JsonParseHelper.parseStringList(rawRoles);

    final rawRole = json['primaryRole']?.toString() ?? json['role']?.toString() ?? (parsedRoles.isNotEmpty ? parsedRoles.first : 'USER');
    if (parsedRoles.isEmpty && rawRole.isNotEmpty) {
      parsedRoles = [rawRole];
    }

    final rawPhone = (json['phone'] ?? json['soDienThoai'] ?? '')?.toString() ?? '';
    final rawTechInterest = json['techInterest']?.toString();
    final rawAddress = json['address']?.toString();

    final uName = rawUsername.isNotEmpty ? rawUsername : rawFullName;
    final fName = rawFullName.isNotEmpty ? rawFullName : uName;

    return AppUser(
      id: (json['userId'] ?? json['id'])?.toString() ?? '0',
      userName: uName,
      fullName: fName,
      email: rawEmail,
      role: rawRole,
      roles: parsedRoles,
      status: locked ? 'Tạm khóa' : 'Hoạt động',
      isLocked: locked,
      phone: rawPhone,
      techInterest: rawTechInterest,
      dateOfBirth: JsonParseHelper.parseNullableDateOnly(json['dateOfBirth']),
      address: rawAddress,
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'role': role,
      'roles': roles,
      'status': status,
      'isLocked': isLocked,
      'phone': phone,
      'techInterest': techInterest,
      'dateOfBirth': dateOfBirth != null
          ? JsonParseHelper.toUtcDateOnlyIsoString(dateOfBirth!)
          : null,
      'address': address,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}



