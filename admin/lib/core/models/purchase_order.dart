class PurchaseOrderItem {
  final int? poItemId;
  final int variantId;
  final int? productId;
  final String productName;
  final String variantName;
  final double importPrice;
  final int quantity;

  PurchaseOrderItem({
    this.poItemId,
    required this.variantId,
    this.productId,
    this.productName = '',
    this.variantName = '',
    required this.importPrice,
    required this.quantity,
  });

  double get totalPrice => importPrice * quantity;

  String get fullName {
    if (productName.isEmpty) return variantName;
    if (variantName.isEmpty || variantName.toLowerCase() == 'phiên bản tiêu chuẩn' || variantName.toLowerCase() == 'biến thể mặc định') {
      return productName;
    }
    return '$productName ($variantName)';
  }

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      poItemId: json['poItemId'] as int?,
      variantId: (json['variantId'] ?? 0) as int,
      productId: json['productId'] as int?,
      productName: (json['productName'] ?? '').toString(),
      variantName: (json['variantName'] ?? '').toString(),
      importPrice: (json['importPrice'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'variantId': variantId,
      'importPrice': importPrice,
      'quantity': quantity,
    };
  }
}

class PurchaseOrder {
  final int purchaseOrderId;
  final String poCode;
  final int supplierId;
  final String supplierName;
  final int createdByUserId;
  final String createdByName;
  final double totalCost;
  final int totalItems;
  final String status; // 'DRAFT' or 'COMPLETED' or 'CANCELLED'
  final String note;
  final DateTime createdAt;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    required this.purchaseOrderId,
    required this.poCode,
    required this.supplierId,
    this.supplierName = '',
    this.createdByUserId = 0,
    this.createdByName = '',
    required this.totalCost,
    required this.totalItems,
    required this.status,
    this.note = '',
    required this.createdAt,
    List<PurchaseOrderItem>? items,
  }) : items = items ?? [];

  bool get isDraft => status == 'DRAFT' || status == '0';
  bool get isCompleted => status == 'COMPLETED' || status == '1';

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    List<PurchaseOrderItem> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((i) => PurchaseOrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    String parsedStatus = 'DRAFT';
    if (json['status'] != null) {
      final s = json['status'].toString();
      if (s == 'COMPLETED' || s == '1') {
        parsedStatus = 'COMPLETED';
      } else if (s == 'CANCELLED' || s == '2') {
        parsedStatus = 'CANCELLED';
      } else {
        parsedStatus = 'DRAFT';
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return PurchaseOrder(
      purchaseOrderId: (json['purchaseOrderId'] ?? json['id'] ?? 0) as int,
      poCode: (json['poCode'] ?? json['code'] ?? '').toString(),
      supplierId: (json['supplierId'] ?? 0) as int,
      supplierName: (json['supplierName'] ?? 'Chưa xác định').toString(),
      createdByUserId: (json['createdByUserId'] ?? 0) as int,
      createdByName: (json['createdByName'] ?? 'Admin').toString(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      totalItems: (json['totalItems'] ?? parsedItems.length) as int,
      status: parsedStatus,
      note: (json['note'] ?? '').toString(),
      createdAt: parsedDate,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'supplierId': supplierId,
      'status': status,
      'note': note.isNotEmpty ? note : null,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
  }
}
