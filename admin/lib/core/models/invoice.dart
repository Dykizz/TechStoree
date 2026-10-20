import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Invoice {
  final int invoiceId;
  final String invoiceCode;
  final int orderId;
  final String orderCode;
  final int userId;
  final String customerName;
  final double totalAmount;
  final String status; // 'UNPAID', 'PAID', 'CANCELLED'
  final String paymentMethod; // 'COD', 'VNPAY', 'BANK_TRANSFER'
  final DateTime? paidAt;
  final DateTime createdAt;
  final String? note;

  const Invoice({
    required this.invoiceId,
    required this.invoiceCode,
    required this.orderId,
    required this.orderCode,
    required this.userId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paidAt,
    required this.createdAt,
    this.note,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isUnpaid => status.toUpperCase() == 'UNPAID';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'UNPAID':
        return 'Chờ thanh toán';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'UNPAID':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.secondary;
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod.toUpperCase()) {
      case 'COD':
        return 'Thanh toán COD';
      case 'VNPAY':
        return 'Cổng VNPay';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản NH';
      default:
        return paymentMethod;
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'] is int
          ? json['invoiceId'] as int
          : int.tryParse(json['invoiceId']?.toString() ?? '0') ?? 0,
      invoiceCode: json['invoiceCode']?.toString() ?? '',
      orderId: json['orderId'] is int
          ? json['orderId'] as int
          : int.tryParse(json['orderId']?.toString() ?? '0') ?? 0,
      orderCode: json['orderCode']?.toString() ?? '',
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'UNPAID',
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceCode': invoiceCode,
      'orderId': orderId,
      'orderCode': orderCode,
      'userId': userId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  /// Danh sách hóa đơn mẫu phục vụ chế độ Offline Resilience
  static List<Invoice> getSampleInvoices() {
    final now = DateTime.now();
    return [
      Invoice(
        invoiceId: 1,
        invoiceCode: 'INV-ORD-20261002-C3D4',
        orderId: 2,
        orderCode: 'ORD-20261002-C3D4',
        userId: 3,
        customerName: 'Trần Thị Bình',
        totalAmount: 57880000.0,
        status: 'PAID',
        paymentMethod: 'VNPAY',
        paidAt: now.subtract(const Duration(days: 2, hours: 4)),
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        note: 'Đã thanh toán thành công qua cổng VNPay QR',
      ),
      Invoice(
        invoiceId: 2,
        invoiceCode: 'INV-ORD-20261003-E5F6',
        orderId: 3,
        orderCode: 'ORD-20261003-E5F6',
        userId: 3,
        customerName: 'Phạm Minh Cường',
        totalAmount: 20000000.0,
        status: 'PAID',
        paymentMethod: 'BANK_TRANSFER',
        paidAt: now.subtract(const Duration(days: 1, hours: 8)),
        createdAt: now.subtract(const Duration(days: 1, hours: 10)),
        note: 'Chuyển khoản Vietcombank xác nhận bởi kế toán',
      ),
      Invoice(
        invoiceId: 3,
        invoiceCode: 'INV-ORD-20261003-G7H8',
        orderId: 4,
        orderCode: 'ORD-20261003-G7H8',
        userId: 3,
        customerName: 'Lê Hoàng Dung',
        totalAmount: 53980000.0,
        status: 'PAID',
        paymentMethod: 'COD',
        paidAt: now.subtract(const Duration(days: 1, hours: 2)),
        createdAt: now.subtract(const Duration(days: 2, hours: 12)),
        note: 'Shipper đã đối soát tiền mặt COD thành công',
      ),
      Invoice(
        invoiceId: 4,
        invoiceCode: 'INV-ORD-20261001-A1B2',
        orderId: 1,
        orderCode: 'ORD-20261001-A1B2',
        userId: 3,
        customerName: 'Nguyễn Văn An',
        totalAmount: 24990000.0,
        status: 'UNPAID',
        paymentMethod: 'COD',
        paidAt: null,
        createdAt: now.subtract(const Duration(hours: 15)),
        note: 'Đơn hàng đang chờ giao và thu tiền COD tận nơi',
      ),
      Invoice(
        invoiceId: 5,
        invoiceCode: 'INV-ORD-20261003-K9L0',
        orderId: 5,
        orderCode: 'ORD-20261003-K9L0',
        userId: 3,
        customerName: 'Hoàng Quốc Em',
        totalAmount: 28990000.0,
        status: 'CANCELLED',
        paymentMethod: 'COD',
        paidAt: null,
        createdAt: now.subtract(const Duration(hours: 3)),
        note: 'Hóa đơn tự động hủy do khách hàng hủy đơn hàng',
      ),
    ];
  }
}
