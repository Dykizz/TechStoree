import 'package:intl/intl.dart';

class Voucher {
  final int voucherId;
  final String code;
  final String title;
  final String? description;
  final String discountType; // 'PERCENTAGE' or 'FIXED_AMOUNT'
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final int limitPerUser;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isPublic;
  final DateTime createdAt;
  final String status; // 'UPCOMING', 'ACTIVE', 'EXPIRED'
  final int totalClaimedCount;

  Voucher({
    required this.voucherId,
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.limitPerUser = 1,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.isPublic = true,
    required this.createdAt,
    this.status = 'ACTIVE',
    this.totalClaimedCount = 0,
  });

  bool get isPercentage => discountType == 'PERCENTAGE';
  bool get isFixedAmount => discountType == 'FIXED_AMOUNT';

  String formattedDiscountValue(NumberFormat currencyFormat) {
    if (isPercentage) {
      return '${discountValue.toInt()}%';
    }
    return currencyFormat.format(discountValue);
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      try {
        return DateTime.parse(val.toString()).toLocal();
      } catch (_) {
        return fallback;
      }
    }

    return Voucher(
      voucherId: (json['voucherId'] ?? json['id'] ?? 0) as int,
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      discountType: (json['discountType'] ?? 'PERCENTAGE').toString(),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      maxDiscountAmount: json['maxDiscountAmount'] != null ? (json['maxDiscountAmount'] as num).toDouble() : null,
      usageLimit: json['usageLimit'] != null ? (json['usageLimit'] as num).toInt() : null,
      usedCount: (json['usedCount'] ?? 0) as int,
      limitPerUser: (json['limitPerUser'] ?? 1) as int,
      startDate: parseDate(json['startDate'], DateTime.now()),
      endDate: parseDate(json['endDate'], DateTime.now().add(const Duration(days: 7))),
      isActive: (json['isActive'] ?? true) as bool,
      isPublic: (json['isPublic'] ?? true) as bool,
      createdAt: parseDate(json['createdAt'], DateTime.now()),
      status: (json['status'] ?? 'ACTIVE').toString(),
      totalClaimedCount: (json['totalClaimedCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'code': code.toUpperCase().trim(),
      'title': title.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxDiscountAmount': isPercentage ? maxDiscountAmount : null,
      'usageLimit': usageLimit,
      'limitPerUser': limitPerUser,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'isActive': isActive,
      'isPublic': isPublic,
    };
  }
}
