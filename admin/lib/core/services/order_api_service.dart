import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    bool isAscending = false,
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
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }
      if (minAmount != null) {
        queryParams['minAmount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['maxAmount'] = maxAmount.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
        queryParams['isAscending'] = isAscending.toString();
      }

      final uri = Uri.parse('$baseUrl/Orders/admin/all').replace(queryParameters: queryParams);
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
          final data = jsonRes['data'];
          List<dynamic> itemsData = [];
          Map<String, dynamic>? metaData;

          if (data is Map<String, dynamic>) {
            if (data['items'] is List) {
              itemsData = data['items'] as List;
            }
            if (data['meta'] is Map<String, dynamic>) {
              metaData = data['meta'] as Map<String, dynamic>;
            }
          } else if (data is List) {
            itemsData = data;
          }

          final items = itemsData.map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();

          int p = page;
          int ps = pageSize;
          int totItems = items.length;
          int totPages = 1;
          bool hasPrev = false;
          bool hasNext = false;

          if (metaData != null) {
            p = (metaData['page'] as num?)?.toInt() ?? page;
            ps = (metaData['pageSize'] as num?)?.toInt() ?? pageSize;
            totItems = (metaData['totalItems'] as num?)?.toInt() ?? items.length;
            totPages = (metaData['totalPages'] as num?)?.toInt() ?? 1;
            hasPrev = metaData['hasPreviousPage'] == true || p > 1;
            hasNext = metaData['hasNextPage'] == true || (totPages > 0 && p < totPages);
          } else {
            totPages = ps > 0 ? (totItems / ps).ceil() : 1;
            if (totPages == 0) totPages = 1;
            hasPrev = p > 1;
            hasNext = p < totPages;
          }

          isConnected = true;
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
      } else {
        debugPrint('[OrderApiService] Backend trả về HTTP ${response.statusCode}: ${response.body}');
        if (response.statusCode == 401 || response.statusCode == 403) {
          return (
            items: <Order>[],
            page: 1,
            pageSize: pageSize,
            totalItems: 0,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi khi lấy danh sách đơn hàng: $e');
    }

    return (
      items: <Order>[],
      page: page,
      pageSize: pageSize,
      totalItems: 0,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  /// Fetch order detail by ID: GET /api/Orders/{id}
  Future<Order?> getOrderById(int orderId, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId');
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        final data = jsonRes is Map<String, dynamic> ? jsonRes['data'] : null;
        if (data is Map<String, dynamic>) {
          return Order.fromJson(data);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return null;
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi getOrderById($orderId): $e');
    }

    return null;
  }

  /// Update order status: PATCH /api/Orders/{id}/status
  Future<({bool success, String message, Order? order})> updateOrderStatus(
    int orderId, {
    required String status,
    String? reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId/status');
      final payload = <String, dynamic>{
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

      final response = await httpPatch(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 10),
      );

      final jsonRes = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? updatedOrder;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] is Map<String, dynamic>) {
          updatedOrder = Order.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return (
          success: true,
          message: jsonRes is Map<String, dynamic> && jsonRes['message'] != null
              ? jsonRes['message'].toString()
              : 'Cập nhật trạng thái đơn hàng thành công.',
          order: updatedOrder,
        );
      } else {
        String msg = 'Cập nhật trạng thái đơn hàng thất bại.';
        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('message')) {
          msg = jsonRes['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi updateOrderStatus: $e');
      return (success: false, message: 'Lỗi kết nối máy chủ: $e', order: null);
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

      final jsonRes = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? cancelledOrder;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] is Map<String, dynamic>) {
          cancelledOrder = Order.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return (
          success: true,
          message: jsonRes is Map<String, dynamic> && jsonRes['message'] != null
              ? jsonRes['message'].toString()
              : 'Hủy đơn hàng thành công. Tồn kho và Voucher (nếu có) đã được tự động hoàn lại.',
          order: cancelledOrder,
        );
      } else {
        String msg = 'Hủy đơn hàng thất bại.';
        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('message')) {
          msg = jsonRes['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi cancelOrder: $e');
      return (success: false, message: 'Lỗi kết nối máy chủ: $e', order: null);
    }
  }

  /// Fetch order status counts: GET /api/Orders/admin/status-counts
  Future<Map<String, int>> getOrderStatusCounts({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/admin/status-counts');
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true && jsonRes['data'] is Map<String, dynamic>) {
          final data = jsonRes['data'] as Map<String, dynamic>;
          return data.map((k, v) => MapEntry(k.toUpperCase(), (v as num).toInt()));
        }
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi getOrderStatusCounts: $e');
    }

    // Return empty map on failure so caller can sync dynamically with real loaded items
    return <String, int>{};
  }

  /// Return order: POST /api/Orders/{id}/return
  Future<({bool success, String message, Order? order})> returnOrder(
    int orderId, {
    required String reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId/return');
      final payload = {'reason': reason.trim()};

      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 10),
      );

      final jsonRes = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? returnedOrder;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] is Map<String, dynamic>) {
          returnedOrder = Order.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return (
          success: true,
          message: jsonRes is Map<String, dynamic> && jsonRes['message'] != null
              ? jsonRes['message'].toString()
              : 'Xác nhận hoàn hàng thành công. Tồn kho và voucher đã được hoàn lại.',
          order: returnedOrder,
        );
      } else {
        String msg = 'Xác nhận hoàn hàng thất bại.';
        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('message')) {
          msg = jsonRes['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi returnOrder: $e');
      return (success: false, message: 'Lỗi kết nối máy chủ: $e', order: null);
    }
  }

  /// Update payment status (COD reconciliation): PATCH /api/Orders/{id}/payment-status
  Future<({bool success, String message, Order? order})> updateOrderPaymentStatus(
    int orderId, {
    required String paymentStatus,
    String? note,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/$orderId/payment-status');
      final payload = {
        'paymentStatus': paymentStatus,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await httpPatch(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 10),
      );

      final jsonRes = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Order? updatedOrder;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] is Map<String, dynamic>) {
          updatedOrder = Order.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return (
          success: true,
          message: jsonRes is Map<String, dynamic> && jsonRes['message'] != null
              ? jsonRes['message'].toString()
              : 'Cập nhật trạng thái thanh toán thành công.',
          order: updatedOrder,
        );
      } else {
        String msg = 'Cập nhật trạng thái thanh toán thất bại.';
        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('message')) {
          msg = jsonRes['message'].toString();
        }
        return (success: false, message: msg, order: null);
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi updateOrderPaymentStatus: $e');
      return (success: false, message: 'Lỗi kết nối máy chủ: $e', order: null);
    }
  }

  /// Batch update order status: POST /api/Orders/admin/batch-status
  Future<({bool success, String message, int successCount, int failedCount})> batchUpdateOrderStatus({
    required List<int> orderIds,
    required String status,
    String? reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/admin/batch-status');
      final payload = {
        'orderIds': orderIds,
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );

      final jsonRes = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        int sCount = orderIds.length;
        int fCount = 0;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] is Map<String, dynamic>) {
          final data = jsonRes['data'] as Map<String, dynamic>;
          sCount = (data['successCount'] as num?)?.toInt() ?? orderIds.length;
          fCount = (data['failedCount'] as num?)?.toInt() ?? 0;
        }
        return (
          success: true,
          message: jsonRes is Map<String, dynamic> && jsonRes['message'] != null
              ? jsonRes['message'].toString()
              : 'Thực hiện thao tác hàng loạt thành công $sCount đơn.',
          successCount: sCount,
          failedCount: fCount,
        );
      } else {
        String msg = 'Thao tác hàng loạt thất bại.';
        if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('message')) {
          msg = jsonRes['message'].toString();
        }
        return (success: false, message: msg, successCount: 0, failedCount: orderIds.length);
      }
    } catch (e) {
      debugPrint('[OrderApiService] Lỗi batchUpdateOrderStatus: $e');
      return (success: false, message: 'Lỗi kết nối máy chủ: $e', successCount: 0, failedCount: orderIds.length);
    }
  }

  /// Backward-compatible getOrders method
  Future<List<Order>> getOrders({String? token}) async {
    final result = await getAllOrders(page: 1, pageSize: 100, token: token);
    return result.items;
  }
}
