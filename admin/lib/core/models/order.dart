class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] ?? 1).toInt(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final double totalAmount;
  final String status; // 'Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled'
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? json['maDonHang'] ?? 'ORD-${json['id']}',
      customerName: json['customerName'] ?? json['tenKhachHang'] ?? 'Khách hàng',
      customerEmail: json['customerEmail'] ?? json['email'] ?? 'khach@techstoree.vn',
      totalAmount: (json['totalAmount'] ?? json['tongTien'] ?? 0).toDouble(),
      status: json['status'] ?? json['trangThai'] ?? 'Pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : [],
    );
  }
}
