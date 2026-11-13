import 'package:intl/intl.dart';
import '../utils/json_parse_helper.dart';

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
    return Voucher(
      voucherId: JsonParseHelper.parseInt(json['voucherId'] ?? json['id']),
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      discountType: (json['discountType'] ?? 'PERCENTAGE').toString(),
      discountValue: JsonParseHelper.parseDouble(json['discountValue']),
      minOrderValue: JsonParseHelper.parseDouble(json['minOrderValue']),
      maxDiscountAmount: JsonParseHelper.parseNullableDouble(json['maxDiscountAmount']),
      usageLimit: JsonParseHelper.parseNullableInt(json['usageLimit']),
      usedCount: JsonParseHelper.parseInt(json['usedCount']),
      limitPerUser: JsonParseHelper.parseInt(json['limitPerUser'], 1),
      startDate: JsonParseHelper.parseDate(json['startDate']),
      endDate: JsonParseHelper.parseDate(
        json['endDate'],
        fallback: DateTime.now().add(const Duration(days: 7)),
      ),
      isActive: JsonParseHelper.parseBool(json['isActive'], fallback: true),
      isPublic: JsonParseHelper.parseBool(json['isPublic'], fallback: true),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      status: (json['status'] ?? 'ACTIVE').toString(),
      totalClaimedCount: JsonParseHelper.parseInt(json['totalClaimedCount']),
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
