import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import 'base_api_service.dart';

mixin InvoiceApiService on BaseApiService {
  /// Lấy danh sách hóa đơn phân trang từ Backend: GET /api/invoices/admin/all
  Future<({
    List<Invoice> items,
    int page,
    int pageSize,
    int totalItems,
    int totalPages,
    bool hasPreviousPage,
    bool hasNextPage,
  })> getAllInvoices({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
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
      if (paymentMethod != null &&
          paymentMethod.isNotEmpty &&
          paymentMethod != 'ALL' &&
          paymentMethod != 'Tất cả') {
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
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
        queryParams['isAscending'] = isAscending.toString();
      }

      final uri = Uri.parse('$baseUrl/invoices/admin/all').replace(queryParameters: queryParams);
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
          final data = jsonRes['data'];
          List<dynamic> itemsData = [];
          Map<String, dynamic>? metaData;

          if (data is Map<String, dynamic>) {
            if (data['items'] is List) itemsData = data['items'] as List;
            if (data['meta'] is Map<String, dynamic>) metaData = data['meta'] as Map<String, dynamic>;
          } else if (data is List) {
            itemsData = data;
          }

          final items = itemsData
              .map((j) => Invoice.fromJson(j as Map<String, dynamic>))
              .toList();

          int p = page;
          int ps = pageSize;
          int totItems = items.length;
          int totPages = 1;
          bool hasPrev = false;
          bool hasNext = false;

          if (metaData != null) {
            p = (metaData['page'] as num?)?.toInt() ?? p;
            ps = (metaData['pageSize'] as num?)?.toInt() ?? ps;
            totItems = (metaData['totalItems'] as num?)?.toInt() ?? totItems;
            totPages = (metaData['totalPages'] as num?)?.toInt() ?? totPages;
            hasPrev = metaData['hasPreviousPage'] as bool? ?? (p > 1);
            hasNext = metaData['hasNextPage'] as bool? ?? (p < totPages);
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
        debugPrint('[InvoiceApiService] Backend trả về HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[InvoiceApiService] Lỗi getAllInvoices: $e');
    }

    // Fallback sang dữ liệu mẫu khi ngoại tuyến hoặc khi hệ thống chưa có dữ liệu ban đầu
    var samples = Invoice.getSampleInvoices();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      samples = samples.where((inv) =>
          inv.invoiceCode.toLowerCase().contains(q) ||
          inv.orderCode.toLowerCase().contains(q) ||
          inv.customerName.toLowerCase().contains(q) ||
          (inv.note != null && inv.note!.toLowerCase().contains(q))).toList();
    }
    if (status != null && status.isNotEmpty && status != 'ALL' && status != 'Tất cả') {
      samples = samples.where((inv) => inv.status.toUpperCase() == status.toUpperCase()).toList();
    }
    if (paymentMethod != null &&
        paymentMethod.isNotEmpty &&
        paymentMethod != 'ALL' &&
        paymentMethod != 'Tất cả') {
      samples = samples.where((inv) => inv.paymentMethod.toUpperCase() == paymentMethod.toUpperCase()).toList();
    }
    if (fromDate != null) {
      samples = samples.where((inv) => inv.createdAt.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      final nextDay = toDate.add(const Duration(days: 1));
      samples = samples.where((inv) => inv.createdAt.isBefore(nextDay)).toList();
    }

    final totItems = samples.length;
    final totPages = (totItems / pageSize).ceil();
    final safePage = page > totPages ? (totPages > 0 ? totPages : 1) : page;
    final startIndex = (safePage - 1) * pageSize;
    final paginated = totItems == 0 ? <Invoice>[] : samples.skip(startIndex).take(pageSize).toList();

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

  /// Lấy chi tiết hóa đơn theo ID: GET /api/invoices/{id}
  Future<Invoice?> getInvoiceById(int id, {String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/invoices/$id'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        final data = jsonRes is Map<String, dynamic> ? jsonRes['data'] : null;
        if (data is Map<String, dynamic>) {
          return Invoice.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[InvoiceApiService] Lỗi getInvoiceById($id): $e');
    }

    // Fallback
    try {
      return Invoice.getSampleInvoices().firstWhere((i) => i.invoiceId == id);
    } catch (_) {
      return null;
    }
  }

  /// Tra cứu hóa đơn theo OrderId: GET /api/invoices/by-order/{orderId}
  Future<Invoice?> getInvoiceByOrderId(int orderId, {String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/invoices/by-order/$orderId'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        final data = jsonRes is Map<String, dynamic> ? jsonRes['data'] : null;
        if (data is Map<String, dynamic>) {
          return Invoice.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[InvoiceApiService] Lỗi getInvoiceByOrderId($orderId): $e');
    }

    // Fallback
    try {
      return Invoice.getSampleInvoices().firstWhere((i) => i.orderId == orderId);
    } catch (_) {
      return null;
    }
  }
}
