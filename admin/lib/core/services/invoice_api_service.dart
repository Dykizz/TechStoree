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
    String? advancedQuery,
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
      if (paymentMethod != null &&
          paymentMethod.isNotEmpty &&
          paymentMethod != 'ALL' &&
          paymentMethod != 'Tất cả') {
        queryParams['paymentMethod'] = paymentMethod;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (advancedQuery != null && advancedQuery.trim().isNotEmpty) {
        queryParams['advancedQuery'] = advancedQuery.trim();
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

    return (
      items: <Invoice>[],
      page: page,
      pageSize: pageSize,
      totalItems: 0,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  /// Lấy chi tiết một hóa đơn theo ID: GET /api/invoices/{id}
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

    return null;
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

    return null;
  }

  /// Lấy thống kê số lượng và doanh thu hóa đơn: GET /api/invoices/admin/statistics
  Future<InvoiceStatistics?> getInvoiceStatistics({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/invoices/admin/statistics'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        final data = jsonRes is Map<String, dynamic> ? jsonRes['data'] : null;
        if (data is Map<String, dynamic>) {
          return InvoiceStatistics.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[InvoiceApiService] Lỗi getInvoiceStatistics: $e');
    }

    return null;
  }
}
