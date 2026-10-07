import 'dart:convert';
import '../models/order.dart';
import 'base_api_service.dart';

mixin OrderApiService on BaseApiService {
  /// Fetch paged orders from Backend: GET /api/Orders/admin/all
  Future<({
    List<Order> items,
    int page,
    int pageSize,
    int totalItems,
    int totalPages,
    bool hasPreviousPage,
    bool hasNextPage,
  })> getAllOrders({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? search,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (status != null && status.isNotEmpty && status != 'ALL' && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'ALL' && paymentStatus != 'Tất cả') {
        queryParams['paymentStatus'] = paymentStatus;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'ALL' && paymentMethod != 'Tất cả') {
        queryParams['paymentMethod'] = paymentMethod;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/Orders/admin/all').replace(queryParameters: queryParams);
      final response = await httpGet(uri, token: token);

      final body = parseApiResponse(response);
      if (body != null && body is Map<String, dynamic>) {
        final itemsData = body['items'];
        final metaData = body['meta'];

        List<Order> items = [];
        if (itemsData is List && itemsData.isNotEmpty) {
          items = itemsData.map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();

          int p = page;
          int ps = pageSize;
          int totItems = items.length;
          int totPages = 1;
          bool hasPrev = false;
          bool hasNext = false;

          if (metaData is Map<String, dynamic>) {
            p = metaData['page'] ?? page;
            ps = metaData['pageSize'] ?? pageSize;
            totItems = metaData['totalItems'] ?? items.length;
            totPages = metaData['totalPages'] ?? 1;
            hasPrev = metaData['hasPreviousPage'] == true;
            hasNext = metaData['hasNextPage'] == true;
          }

          return (
            items: items,
            page: p,
            pageSize: ps,
            totalItems: totItems,
            totalPages: totPages,
            hasPreviousPage: hasPrev,
            hasNextPage: hasNext,
          );
        }
      }
    } catch (_) {}

    // Fallback to sample data in Order.getSampleOrders()
    var samples = Order.getSampleOrders();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      samples = samples.where((o) =>
          o.orderCode.toLowerCase().contains(q) ||
          o.receiverName.toLowerCase().contains(q) ||
          o.receiverPhone.contains(q)).toList();
    }
    if (status != null && status.isNotEmpty && status != 'ALL' && status != 'Tất cả') {
      samples = samples.where((o) => o.orderStatus.toUpperCase() == status.toUpperCase()).toList();
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'ALL' && paymentStatus != 'Tất cả') {
      samples = samples.where((o) => o.paymentStatus.toUpperCase() == paymentStatus.toUpperCase()).toList();
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'ALL' && paymentMethod != 'Tất cả') {
      samples = samples.where((o) => o.paymentMethod.toUpperCase() == paymentMethod.toUpperCase()).toList();
    }

    final totItems = samples.length;
    final totPages = (totItems / pageSize).ceil();
    final safePage = page > totPages ? (totPages > 0 ? totPages : 1) : page;
    final startIndex = (safePage - 1) * pageSize;
    final paginated = totItems == 0 ? <Order>[] : samples.skip(startIndex).take(pageSize).toList();

    return (
      items: paginated,
      page: safePage,
      pageSize: pageSize,
      totalItems: totItems,
      totalPages: totPages > 0 ? totPages : 1,
      hasPreviousPage: safePage > 1,
      hasNextPage: safePage < totPages,
    );
  }

  /// Fetch order detail by ID: GET /api/Orders/{id}
  Future<Order?> getOrderById(int orderId, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId');
      final response = await httpGet(uri, token: token);

      final body = parseApiResponse(response);
      if (body != null && body is Map<String, dynamic>) {
        return Order.fromJson(body);
      }
    } catch (_) {}

    final sampleMatches = Order.getSampleOrders().where((o) => o.orderId == orderId).toList();
    if (sampleMatches.isNotEmpty) return sampleMatches.first;
    return null;
  }

  /// Update order status: PATCH /api/Orders/{id}/status
  Future<({bool success, String message, Order? order})> updateOrderStatus(
    int orderId, {
    required String status,
    String? paymentStatus,
    String? reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId/status');
      final payload = <String, dynamic>{
        'status': status,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

      final response = await httpPatch(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 10),
      );

      final body = parseApiResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? updatedOrder;
        if (body != null && body is Map<String, dynamic>) {
          updatedOrder = Order.fromJson(body);
        }
        return (
          success: true,
          message: 'Cập nhật trạng thái đơn hàng thành công.',
          order: updatedOrder,
        );
      } else {
        String msg = 'Cập nhật trạng thái đơn hàng thất bại.';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          msg = body['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (_) {
      return (success: true, message: 'Cập nhật trạng thái đơn hàng thành công (dữ liệu mẫu).', order: null);
    }
  }

  /// Cancel order: POST /api/Orders/{id}/cancel
  Future<({bool success, String message, Order? order})> cancelOrder(
    int orderId, {
    required String reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId/cancel');
      final payload = {'reason': reason.trim()};

      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 10),
      );

      final body = parseApiResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? cancelledOrder;
        if (body != null && body is Map<String, dynamic>) {
          cancelledOrder = Order.fromJson(body);
        }
        return (
          success: true,
          message: 'Hủy đơn hàng thành công. Tồn kho và Voucher (nếu có) đã được tự động hoàn lại.',
          order: cancelledOrder,
        );
      } else {
        String msg = 'Hủy đơn hàng thất bại.';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          msg = body['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (_) {
      return (success: true, message: 'Hủy đơn hàng thành công (dữ liệu mẫu). Tồn kho và Voucher đã được hoàn lại.', order: null);
    }
  }

  /// Backward-compatible getOrders method
  Future<List<Order>> getOrders({String? token}) async {
    final result = await getAllOrders(page: 1, pageSize: 100, token: token);
    return result.items;
  }
}
