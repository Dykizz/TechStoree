int _parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? defaultValue;
  }
  return defaultValue;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) {
    final parsed = int.tryParse(val);
    if (parsed != null) return parsed;
    final d = double.tryParse(val);
    return d?.toInt();
  }
  return null;
}

double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? defaultValue;
  }
  return defaultValue;
}

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
    if (productName.isEmpty) return variantName.isNotEmpty ? variantName : 'Biến thể #$variantId';
    if (variantName.isEmpty || variantName.toLowerCase() == 'phiên bản tiêu chuẩn' || variantName.toLowerCase() == 'biến thể mặc định') {
      return productName;
    }
    return '$productName ($variantName)';
  }

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      poItemId: _parseNullableInt(json['poItemId'] ?? json['id']),
      variantId: _parseInt(json['variantId'] ?? json['variant_id'], 0),
      productId: _parseNullableInt(json['productId'] ?? json['product_id']),
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      importPrice: _parseDouble(json['importPrice'] ?? json['price']),
      quantity: _parseInt(json['quantity'], 1),
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
  final String status; // 'DRAFT', 'COMPLETE', 'CANCLE'
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

  bool get isDraft => status.toUpperCase() == 'DRAFT' || status == '0';
  bool get isComplete => status.toUpperCase() == 'COMPLETE' || status.toUpperCase() == 'COMPLETED' || status == '1';
  bool get isCompleted => isComplete;
  bool get isCancle => status.toUpperCase() == 'CANCLE' || status.toUpperCase() == 'CANCELLED' || status == '2';

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    List<PurchaseOrderItem> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .where((i) => i != null && i is Map)
          .map((i) => PurchaseOrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    String parsedStatus = 'DRAFT';
    if (json['status'] != null) {
      final s = json['status'].toString().toUpperCase();
      if (s == 'COMPLETE' || s == 'COMPLETED' || s == '1') {
        parsedStatus = 'COMPLETE';
      } else if (s == 'CANCLE' || s == 'CANCELLED' || s == '2') {
        parsedStatus = 'CANCLE';
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
      purchaseOrderId: _parseInt(json['purchaseOrderId'] ?? json['id'], 0),
      poCode: (json['poCode'] ?? json['code'] ?? '').toString(),
      supplierId: _parseInt(json['supplierId'], 0),
      supplierName: (json['supplierName'] ?? 'Chưa xác định').toString(),
      createdByUserId: _parseInt(json['createdByUserId'], 0),
      createdByName: (json['createdByName'] ?? 'Admin').toString(),
      totalCost: _parseDouble(json['totalCost']),
      totalItems: _parseInt(json['totalItems'], parsedItems.length),
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
