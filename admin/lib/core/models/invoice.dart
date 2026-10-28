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
  final String receiverPhone;
  final String shippingAddress;
  final double subtotalAmount;
  final double voucherDiscountAmount;
  final String? voucherCode;
  final List<InvoiceItem> items;

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
    this.receiverPhone = '',
    this.shippingAddress = '',
    this.subtotalAmount = 0.0,
    this.voucherDiscountAmount = 0.0,
    this.voucherCode,
    this.items = const [],
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
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      voucherDiscountAmount: (json['voucherDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      voucherCode: json['voucherCode']?.toString(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'subtotalAmount': subtotalAmount,
      'voucherDiscountAmount': voucherDiscountAmount,
      'voucherCode': voucherCode,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

/// Dòng mặt hàng trong Hóa đơn
class InvoiceItem {
  final int orderItemId;
  final String productName;
  final String variantName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  const InvoiceItem({
    required this.orderItemId,
    required this.productName,
    required this.variantName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      orderItemId: (json['orderItemId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderItemId': orderItemId,
      'productName': productName,
      'variantName': variantName,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}

/// Số liệu thống kê và đối soát tài chính của Hóa đơn

class InvoiceStatistics {
  final int totalInvoices;
  final int paidCount;
  final int unpaidCount;
  final int cancelledCount;
  final double paidAmount;
  final double unpaidAmount;
  final Map<String, int> statusCounts;

  const InvoiceStatistics({
    this.totalInvoices = 0,
    this.paidCount = 0,
    this.unpaidCount = 0,
    this.cancelledCount = 0,
    this.paidAmount = 0.0,
    this.unpaidAmount = 0.0,
    this.statusCounts = const {},
  });

  factory InvoiceStatistics.fromJson(Map<String, dynamic> json) {
    final statusCountsRaw = json['statusCounts'];
    final Map<String, int> counts = {};
    if (statusCountsRaw is Map) {
      statusCountsRaw.forEach((k, v) {
        counts[k.toString().toUpperCase()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return InvoiceStatistics(
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      paidCount: (json['paidCount'] as num?)?.toInt() ?? 0,
      unpaidCount: (json['unpaidCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      unpaidAmount: (json['unpaidAmount'] as num?)?.toDouble() ?? 0.0,
      statusCounts: counts,
    );
  }
}

