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
    int parseInt(dynamic val) => val is int ? val : (int.tryParse(val?.toString() ?? '') ?? 0);
    double parseDouble(dynamic val) => val is num ? val.toDouble() : (double.tryParse(val?.toString() ?? '') ?? 0.0);

    final pName = json['productName']?.toString() ?? '';
    final vName = json['variantName']?.toString() ?? '';
    final uPrice = parseDouble(json['unitPrice'] ?? json['price']);
    final qty = parseInt(json['quantity'] ?? 1);
    final totPrice = json['totalPrice'] != null ? parseDouble(json['totalPrice']) : (uPrice * qty);

    return OrderItem(
      orderItemId: parseInt(json['orderItemId']),
      orderId: parseInt(json['orderId']),
      variantId: parseInt(json['variantId'] ?? json['productId']),
      productName: pName,
      variantName: vName,
      imageUrl: json['imageUrl']?.toString(),
      originalPrice: parseDouble(json['originalPrice'] ?? uPrice),
      unitPrice: uPrice,
      promotionId: json['promotionId'] != null ? parseInt(json['promotionId']) : null,
      promotionName: json['promotionName']?.toString(),
      promotionDiscount: parseDouble(json['promotionDiscount']),
      quantity: qty,
      totalPrice: totPrice,
      hasPromotion: json['hasPromotion'] == true || json['promotionId'] != null || parseDouble(json['promotionDiscount']) > 0,
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
    this.createdByName,
    this.updatedByName,
    this.items = const [],
  });

  // Backward compatibility getters
  String get id => orderId.toString();
  String get orderNumber => orderCode.isNotEmpty ? orderCode : 'ORD-$orderId';
  String get customerName => receiverName.isNotEmpty ? receiverName : 'Khách hàng';
  String get customerEmail => user?['email']?.toString() ?? 'N/A';
  String get status => orderStatus;

  // Business Rule: Can cancel only when orderStatus is PENDING or CONFIRMED
  bool get canCancel => orderStatus == 'PENDING' || orderStatus == 'CONFIRMED';

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
    int parseInt(dynamic val) => val is int ? val : (int.tryParse(val?.toString() ?? '') ?? 0);
    double parseDouble(dynamic val) => val is num ? val.toDouble() : (double.tryParse(val?.toString() ?? '') ?? 0.0);
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    final rawItems = json['items'];
    List<OrderItem> parsedItems = [];
    if (rawItems != null && rawItems is List) {
      parsedItems = rawItems.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList();
    }

    return Order(
      orderId: parseInt(json['orderId'] ?? json['id']),
      orderCode: json['orderCode']?.toString() ?? json['orderNumber'] ?? '',
      userId: parseInt(json['userId']),
      receiverName: json['receiverName']?.toString() ?? json['customerName'] ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? json['phone'] ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? json['address'] ?? '',
      notes: json['notes']?.toString(),
      orderStatus: json['orderStatus']?.toString() ?? json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      subtotalAmount: parseDouble(json['subtotalAmount'] ?? json['totalAmount']),
      voucherId: json['voucherId'] != null ? parseInt(json['voucherId']) : null,
      voucherCode: json['voucherCode']?.toString(),
      voucherTitle: json['voucherTitle']?.toString(),
      voucherDiscountAmount: parseDouble(json['voucherDiscountAmount']),
      totalAmount: parseDouble(json['totalAmount']),
      totalItems: json['totalItems'] != null ? parseInt(json['totalItems']) : parsedItems.length,
      totalQuantity: json['totalQuantity'] != null ? parseInt(json['totalQuantity']) : parsedItems.fold(0, (sum, item) => sum + item.quantity),
      totalSavings: parseDouble(json['totalSavings']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      paidAt: parseDate(json['paidAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason']?.toString(),
      user: json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null,
      createdByName: json['createdByName']?.toString(),
      updatedByName: json['updatedByName']?.toString(),
      items: parsedItems,
    );
  }

  /// Dữ liệu mẫu đơn hàng phong phú dành cho ứng dụng Admin TechStoree
  static List<Order> getSampleOrders() {
    final now = DateTime.now();
    return [
      Order(
        orderId: 101,
        orderCode: 'ORD-20261001-A1B2',
        userId: 1,
        receiverName: 'Nguyễn Văn An',
        receiverPhone: '0901234567',
        shippingAddress: '123 Đường Nguyễn Trãi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
        notes: 'Giao giờ hành chính, gọi trước khi giao 15 phút',
        orderStatus: 'PENDING',
        paymentMethod: 'COD',
        paymentStatus: 'PENDING',
        subtotalAmount: 24990000,
        voucherId: null,
        voucherCode: null,
        voucherTitle: null,
        voucherDiscountAmount: 0,
        totalAmount: 24990000,
        totalItems: 1,
        totalQuantity: 1,
        totalSavings: 2000000,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        user: {
          'id': 1,
          'fullName': 'Nguyễn Văn An',
          'email': 'an.nguyen@gmail.com',
          'phone': '0901234567',
        },
        items: [
          OrderItem(
            orderItemId: 201,
            orderId: 101,
            variantId: 1,
            productName: 'Laptop ASUS Zenbook 14 OLED UX3405',
            variantName: '16GB RAM / 512GB SSD - Xanh',
            imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/l/a/laptop-asus-zenbook.png',
            originalPrice: 26990000,
            unitPrice: 24990000,
            promotionId: 1,
            promotionName: 'Ưu đãi Mùa Thu 2026',
            promotionDiscount: 2000000,
            quantity: 1,
            totalPrice: 24990000,
            hasPromotion: true,
          ),
        ],
      ),
      Order(
        orderId: 102,
        orderCode: 'ORD-20261002-C3D4',
        userId: 2,
        receiverName: 'Trần Thị Bình',
        receiverPhone: '0988776655',
        shippingAddress: '45 Đường Lê Lợi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
        notes: 'Hàng bọc quà tặng cẩn thận giúp shop',
        orderStatus: 'CONFIRMED',
        paymentMethod: 'VNPAY',
        paymentStatus: 'PAID',
        subtotalAmount: 16980000,
        voucherId: 5,
        voucherCode: 'TECHSTORE100K',
        voucherTitle: 'Giảm 100K cho đơn hàng từ 2 triệu',
        voucherDiscountAmount: 100000,
        totalAmount: 16880000,
        totalItems: 1,
        totalQuantity: 2,
        totalSavings: 1100000,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        paidAt: now.subtract(const Duration(days: 1)),
        user: {
          'id': 2,
          'fullName': 'Trần Thị Bình',
          'email': 'binhtran@gmail.com',
          'phone': '0988776655',
        },
        items: [
          OrderItem(
            orderItemId: 202,
            orderId: 102,
            variantId: 4,
            productName: 'Tai nghe chụp tai Sony WH-1000XM5',
            variantName: 'Màu Đen (Black)',
            imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png',
            originalPrice: 8990000,
            unitPrice: 8490000,
            promotionId: 2,
            promotionName: 'Sony Audio Festival',
            promotionDiscount: 500000,
            quantity: 2,
            totalPrice: 16980000,
            hasPromotion: true,
          ),
        ],
      ),
      Order(
        orderId: 103,
        orderCode: 'ORD-20261003-E5F6',
        userId: 3,
        receiverName: 'Phạm Minh Cường',
        receiverPhone: '0912345678',
        shippingAddress: '789 Đường Võ Văn Kiệt, Phường 1, Quận 5, TP. Hồ Chí Minh',
        notes: 'Giao buổi chiều sau 14h',
        orderStatus: 'SHIPPING',
        paymentMethod: 'BANK_TRANSFER',
        paymentStatus: 'PAID',
        subtotalAmount: 42990000,
        voucherId: null,
        voucherCode: null,
        voucherTitle: null,
        voucherDiscountAmount: 0,
        totalAmount: 42990000,
        totalItems: 1,
        totalQuantity: 1,
        totalSavings: 3000000,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        paidAt: now.subtract(const Duration(hours: 10)),
        user: {
          'id': 3,
          'fullName': 'Phạm Minh Cường',
          'email': 'cuong.pham@gmail.com',
          'phone': '0912345678',
        },
        items: [
          OrderItem(
            orderItemId: 203,
            orderId: 103,
            variantId: 2,
            productName: 'Laptop Gaming ASUS ROG Zephyrus G16',
            variantName: '32GB RAM / 1TB SSD - Eclipse Gray',
            imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/a/s/asus-rog-zephyrus.png',
            originalPrice: 45990000,
            unitPrice: 42990000,
            promotionId: 3,
            promotionName: 'ROG Gaming Month',
            promotionDiscount: 3000000,
            quantity: 1,
            totalPrice: 42990000,
            hasPromotion: true,
          ),
        ],
      ),
      Order(
        orderId: 104,
        orderCode: 'ORD-20261003-G7H8',
        userId: 4,
        receiverName: 'Lê Hoàng Dung',
        receiverPhone: '0977123456',
        shippingAddress: '12 Đường Số 7, Phường Linh Trung, TP. Thủ Đức, TP. Hồ Chí Minh',
        notes: 'Vui lòng gọi trước khi giao 10 phút',
        orderStatus: 'DELIVERED',
        paymentMethod: 'COD',
        paymentStatus: 'PAID',
        subtotalAmount: 11980000,
        voucherId: null,
        voucherCode: null,
        voucherTitle: null,
        voucherDiscountAmount: 0,
        totalAmount: 11980000,
        totalItems: 1,
        totalQuantity: 2,
        totalSavings: 1000000,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        paidAt: now.subtract(const Duration(hours: 2)),
        user: {
          'id': 4,
          'fullName': 'Lê Hoàng Dung',
          'email': 'dung.le@gmail.com',
          'phone': '0977123456',
        },
        items: [
          OrderItem(
            orderItemId: 204,
            orderId: 104,
            variantId: 5,
            productName: 'Tai nghe Bluetooth True Wireless Sony WF-1000XM5',
            variantName: 'Màu Bạc (Silver)',
            imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wf-1000xm5.png',
            originalPrice: 6490000,
            unitPrice: 5990000,
            promotionId: 2,
            promotionName: 'Sony Audio Festival',
            promotionDiscount: 500000,
            quantity: 2,
            totalPrice: 11980000,
            hasPromotion: true,
          ),
        ],
      ),
      Order(
        orderId: 105,
        orderCode: 'ORD-20261003-K9L0',
        userId: 5,
        receiverName: 'Hoàng Quốc Em',
        receiverPhone: '0933998877',
        shippingAddress: '456 Đường Hoàng Diệu, Phường 6, Quận 4, TP. Hồ Chí Minh',
        notes: null,
        orderStatus: 'CANCELLED',
        paymentMethod: 'COD',
        paymentStatus: 'PENDING',
        subtotalAmount: 8490000,
        voucherId: null,
        voucherCode: null,
        voucherTitle: null,
        voucherDiscountAmount: 0,
        totalAmount: 8490000,
        totalItems: 1,
        totalQuantity: 1,
        totalSavings: 500000,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        cancelledAt: now.subtract(const Duration(hours: 1)),
        cancellationReason: 'Khách hàng thông báo muốn đổi sang dòng tai nghe chống ồn khác',
        user: {
          'id': 5,
          'fullName': 'Hoàng Quốc Em',
          'email': 'em.hoang@gmail.com',
          'phone': '0933998877',
        },
        items: [
          OrderItem(
            orderItemId: 205,
            orderId: 105,
            variantId: 4,
            productName: 'Tai nghe chụp tai Sony WH-1000XM5',
            variantName: 'Màu Đen (Black)',
            imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png',
            originalPrice: 8990000,
            unitPrice: 8490000,
            promotionId: 2,
            promotionName: 'Sony Audio Festival',
            promotionDiscount: 500000,
            quantity: 1,
            totalPrice: 8490000,
            hasPromotion: true,
          ),
        ],
      ),
    ];
  }
}
