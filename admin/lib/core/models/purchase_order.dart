import '../utils/json_parse_helper.dart';

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
      poItemId: JsonParseHelper.parseNullableInt(json['poItemId'] ?? json['id']),
      variantId: JsonParseHelper.parseInt(json['variantId'] ?? json['variant_id'], 0),
      productId: JsonParseHelper.parseNullableInt(json['productId'] ?? json['product_id']),
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      importPrice: JsonParseHelper.parseDouble(json['importPrice'] ?? json['price']),
      quantity: JsonParseHelper.parseInt(json['quantity'], 1),
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
  final String status; // 'DRAFT', 'COMPLETE'
  final String note;
  final DateTime createdAt;
  final String? approvedByName;
  final String? receivedByName;
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
    this.approvedByName,
    this.receivedByName,
    List<PurchaseOrderItem>? items,
  }) : items = items ?? [];

  bool get isDraft => status.toUpperCase() == 'DRAFT' || status == '0';
  bool get isComplete => status.toUpperCase() == 'COMPLETE' || status.toUpperCase() == 'COMPLETED' || status == '1';
  bool get isCompleted => isComplete;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final parsedItems = JsonParseHelper.parseJsonList(
      json['items'],
      PurchaseOrderItem.fromJson,
    );

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

    return PurchaseOrder(
      purchaseOrderId: JsonParseHelper.parseInt(json['purchaseOrderId'] ?? json['id'], 0),
      poCode: (json['poCode'] ?? json['code'] ?? '').toString(),
      supplierId: JsonParseHelper.parseInt(json['supplierId'], 0),
      supplierName: (json['supplierName'] ?? 'Chưa xác định').toString(),
      createdByUserId: JsonParseHelper.parseInt(json['createdByUserId'], 0),
      createdByName: (json['createdByName'] ?? 'Admin').toString(),
      totalCost: JsonParseHelper.parseDouble(json['totalCost']),
      totalItems: JsonParseHelper.parseInt(json['totalItems'], parsedItems.length),
      status: parsedStatus,
      note: (json['note'] ?? '').toString(),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      approvedByName: json['approvedByName']?.toString(),
      receivedByName: json['receivedByName']?.toString(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toCreateJson() {
    String apiStatus = 'DRAFT';
    final upper = status.toUpperCase();
    if (upper == 'COMPLETE' || upper == 'COMPLETED') {
      apiStatus = 'COMPLETED';
    }
    return {
      'supplierId': supplierId,
      'status': apiStatus,
      'note': note.isNotEmpty ? note : null,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
  }
}

/// Kết quả phân trang danh sách phiếu nhập hàng trả về từ API.
class PurchaseOrderPagedResult {
  final List<PurchaseOrder> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PurchaseOrderPagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages =>
      pageSize > 0 ? (totalCount / pageSize).ceil() : (totalCount > 0 ? 1 : 0);
}
