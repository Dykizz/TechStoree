import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/json_parse_helper.dart';

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
      invoiceId: JsonParseHelper.parseInt(json['invoiceId']),
      invoiceCode: json['invoiceCode']?.toString() ?? '',
      orderId: JsonParseHelper.parseInt(json['orderId']),
      orderCode: json['orderCode']?.toString() ?? '',
      userId: JsonParseHelper.parseInt(json['userId']),
      customerName: json['customerName']?.toString() ?? '',
      totalAmount: JsonParseHelper.parseDouble(json['totalAmount']),
      status: json['status']?.toString() ?? 'UNPAID',
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paidAt: JsonParseHelper.parseNullableDate(json['paidAt']),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      note: json['note']?.toString(),
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      subtotalAmount: JsonParseHelper.parseDouble(
        json['subtotalAmount'] ?? json['totalAmount'],
      ),
      voucherDiscountAmount: JsonParseHelper.parseDouble(json['voucherDiscountAmount']),
      voucherCode: json['voucherCode']?.toString(),
      items: JsonParseHelper.parseJsonList(json['items'], InvoiceItem.fromJson),
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
      'paidAt': paidAt?.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
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
      orderItemId: JsonParseHelper.parseInt(json['orderItemId']),
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      unitPrice: JsonParseHelper.parseDouble(json['unitPrice']),
      quantity: JsonParseHelper.parseInt(json['quantity']),
      totalPrice: JsonParseHelper.parseDouble(json['totalPrice']),
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
    return InvoiceStatistics(
      totalInvoices: JsonParseHelper.parseInt(json['totalInvoices']),
      paidCount: JsonParseHelper.parseInt(json['paidCount']),
      unpaidCount: JsonParseHelper.parseInt(json['unpaidCount']),
      cancelledCount: JsonParseHelper.parseInt(json['cancelledCount']),
      paidAmount: JsonParseHelper.parseDouble(json['paidAmount']),
      unpaidAmount: JsonParseHelper.parseDouble(json['unpaidAmount']),
      statusCounts: JsonParseHelper.parseIntMap(
        json['statusCounts'],
        uppercaseKeys: true,
      ),
    );
  }
}

