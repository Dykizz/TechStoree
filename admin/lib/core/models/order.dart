import '../utils/json_parse_helper.dart';

class OrderItem {
  final int orderItemId;
  final int orderId;
  final int variantId;
  final String productName;
  final String variantName;
  final String? imageUrl;
  final double originalPrice;
  final double unitPrice;
  final int? promotionId;
  final String? promotionName;
  final double promotionDiscount;
  final int quantity;
  final double totalPrice;
  final bool hasPromotion;

  // Backward compatibility getter for productId
  String get productId => variantId.toString();

  OrderItem({
    this.orderItemId = 0,
    this.orderId = 0,
    required this.variantId,
    required this.productName,
    this.variantName = '',
    this.imageUrl,
    required this.originalPrice,
    required this.unitPrice,
    this.promotionId,
    this.promotionName,
    this.promotionDiscount = 0.0,
    required this.quantity,
    required this.totalPrice,
    this.hasPromotion = false,
  });

  String get fullName {
    if (productName.isEmpty) return variantName;
    if (variantName.isEmpty || variantName.toLowerCase() == 'phiên bản tiêu chuẩn') {
      return productName;
    }
    return '$productName ($variantName)';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final pName = json['productName']?.toString() ?? '';
    final vName = json['variantName']?.toString() ?? '';
    final uPrice = JsonParseHelper.parseDouble(json['unitPrice'] ?? json['price']);
    final qty = JsonParseHelper.parseInt(json['quantity'] ?? 1);
    final totPrice = json['totalPrice'] != null
        ? JsonParseHelper.parseDouble(json['totalPrice'])
        : (uPrice * qty);

    return OrderItem(
      orderItemId: JsonParseHelper.parseInt(json['orderItemId']),
      orderId: JsonParseHelper.parseInt(json['orderId']),
      variantId: JsonParseHelper.parseInt(json['variantId'] ?? json['productId']),
      productName: pName,
      variantName: vName,
      imageUrl: json['imageUrl']?.toString(),
      originalPrice: JsonParseHelper.parseDouble(json['originalPrice'] ?? uPrice),
      unitPrice: uPrice,
      promotionId: JsonParseHelper.parseNullableInt(json['promotionId']),
      promotionName: json['promotionName']?.toString(),
      promotionDiscount: JsonParseHelper.parseDouble(json['promotionDiscount']),
      quantity: qty,
      totalPrice: totPrice,
      hasPromotion: JsonParseHelper.parseBool(json['hasPromotion']) ||
          json['promotionId'] != null ||
          JsonParseHelper.parseDouble(json['promotionDiscount']) > 0,
    );
  }
}

class Order {
  final int orderId;
  final String orderCode;
  final int userId;
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final String? notes;
  final String orderStatus; // PENDING, CONFIRMED, SHIPPING, DELIVERED, CANCELLED
  final String paymentMethod; // COD, VNPAY, BANK_TRANSFER
  final String paymentStatus; // PENDING, PAID, FAILED, REFUNDED
  final double subtotalAmount;
  final int? voucherId;
  final String? voucherCode;
  final String? voucherTitle;
  final double voucherDiscountAmount;
  final double totalAmount;
  final int totalItems;
  final int totalQuantity;
  final double totalSavings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final Map<String, dynamic>? user;
  final int? updatedByUserId;
  final String? createdByName;
  final String? updatedByName;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.orderCode,
    required this.userId,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    this.notes,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotalAmount,
    this.voucherId,
    this.voucherCode,
    this.voucherTitle,
    this.voucherDiscountAmount = 0.0,
    required this.totalAmount,
    this.totalItems = 0,
    this.totalQuantity = 0,
    this.totalSavings = 0.0,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.cancelledAt,
    this.cancellationReason,
    this.user,
    this.updatedByUserId,
    this.createdByName,
    this.updatedByName,
    this.items = const [],
  });

  // Backward compatibility getters
  String get id => orderId.toString();
  String get orderNumber => orderCode.isNotEmpty ? orderCode : 'ORD-$orderId';
  String get customerName => receiverName.isNotEmpty ? receiverName : 'Khách hàng';
  String get status => orderStatus;

  // Business Rule: Can cancel/return when orderStatus is PENDING, CONFIRMED, or SHIPPING
  bool get canCancel => orderStatus == 'PENDING' || orderStatus == 'CONFIRMED' || orderStatus == 'SHIPPING';

  String get orderStatusDisplay {
    switch (orderStatus.toUpperCase()) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'SHIPPING':
        return 'Đang vận chuyển';
      case 'DELIVERED':
        return 'Đã giao hàng';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'RETURNED':
        return 'Hoàn hàng / Giao thất bại';
      default:
        return orderStatus;
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'FAILED':
        return 'Thanh toán thất bại';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return paymentStatus;
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod.toUpperCase()) {
      case 'COD':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'VNPAY':
        return 'Cổng VNPAY';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      default:
        return paymentMethod;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final parsedItems = JsonParseHelper.parseJsonList(
      json['items'],
      OrderItem.fromJson,
    );

    return Order(
      orderId: JsonParseHelper.parseInt(json['orderId'] ?? json['id']),
      orderCode: json['orderCode']?.toString() ?? json['orderNumber'] ?? '',
      userId: JsonParseHelper.parseInt(json['userId']),
      receiverName: json['receiverName']?.toString() ?? json['customerName'] ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? json['phone'] ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? json['address'] ?? '',
      notes: json['notes']?.toString(),
      orderStatus: json['orderStatus']?.toString() ?? json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      subtotalAmount: JsonParseHelper.parseDouble(json['subtotalAmount'] ?? json['totalAmount']),
      voucherId: JsonParseHelper.parseNullableInt(json['voucherId']),
      voucherCode: json['voucherCode']?.toString(),
      voucherTitle: json['voucherTitle']?.toString(),
      voucherDiscountAmount: JsonParseHelper.parseDouble(json['voucherDiscountAmount']),
      totalAmount: JsonParseHelper.parseDouble(json['totalAmount']),
      totalItems: JsonParseHelper.parseInt(json['totalItems'], parsedItems.length),
      totalQuantity: JsonParseHelper.parseInt(
        json['totalQuantity'],
        parsedItems.fold(0, (sum, item) => sum + item.quantity),
      ),
      totalSavings: JsonParseHelper.parseDouble(json['totalSavings']),
      createdAt: JsonParseHelper.parseNullableDate(json['createdAt']),
      updatedAt: JsonParseHelper.parseNullableDate(json['updatedAt']),
      paidAt: JsonParseHelper.parseNullableDate(json['paidAt']),
      cancelledAt: JsonParseHelper.parseNullableDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason']?.toString(),
      user: json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null,
      updatedByUserId: JsonParseHelper.parseNullableInt(json['updatedByUserId']),
      createdByName: json['createdByName']?.toString() ??
          (json['user'] is Map
              ? ((json['user']['fullName'] ?? json['user']['username'])?.toString())
              : null),
      updatedByName: json['updatedByUsername']?.toString() ?? json['updatedByName']?.toString(),
      items: parsedItems,
    );
  }
}
