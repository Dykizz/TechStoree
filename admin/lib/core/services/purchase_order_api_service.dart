import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';
import 'base_api_service.dart';

mixin PurchaseOrderApiService on BaseApiService {
  String? _normalizePurchaseOrderFilterStatus(String? status) {
    if (status == null) return null;
    final trimmed = status.trim().toUpperCase();
    if (trimmed.isEmpty || trimmed == 'TẤT CẢ') return null;
    if (trimmed == 'COMPLETE' || trimmed == 'COMPLETED') return 'COMPLETED';
    return trimmed;
  }

  /// Lấy danh sách phiếu nhập hàng có phân trang & bộ lọc phía server.
  Future<PurchaseOrderPagedResult> getPurchaseOrdersPaged({
    int page = 1,
    int pageSize = 10,
    String? token,
    String? status,
    int? supplierId,
    String? search,
    String sortBy = 'createdAt',
    bool isAscending = false,
    bool throwOnError = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'sortBy': sortBy,
        'isAscending': isAscending.toString(),
      };
      final normalizedStatus = _normalizePurchaseOrderFilterStatus(status);
      if (normalizedStatus != null) {
        queryParams['status'] = normalizedStatus;
      }
      if (supplierId != null && supplierId > 0) {
        queryParams['supplierId'] = supplierId.toString();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/purchase-orders')
          .replace(queryParameters: queryParams);
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map<String, dynamic> && body['success'] == true) {
          lastErrorMessage = '';
          final data = body['data'];
          List<dynamic> itemsData = const [];
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

          final items = itemsData
              .whereType<Map>()
              .map(
                (json) => PurchaseOrder.fromJson(
                  json is Map<String, dynamic>
                      ? json
                      : Map<String, dynamic>.from(json),
                ),
              )
              .toList();

          var currentPage = page;
          var currentPageSize = pageSize;
          var totalItems = items.length;
          if (metaData != null) {
            currentPage = (metaData['page'] as num?)?.toInt() ?? page;
            currentPageSize =
                (metaData['pageSize'] as num?)?.toInt() ?? pageSize;
            totalItems =
                (metaData['totalItems'] as num?)?.toInt() ?? items.length;
          }

          return PurchaseOrderPagedResult(
            items: items,
            totalCount: totalItems,
            page: currentPage,
            pageSize: currentPageSize,
          );
        }
      }

      final errMsg = extractErrorMessage(response);
      if (throwOnError) {
        throw Exception(
          errMsg.isNotEmpty
              ? errMsg
              : 'Không thể tải danh sách phiếu nhập hàng (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching paged purchase orders: $e');
      if (throwOnError) rethrow;
    }
    return PurchaseOrderPagedResult(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Lấy toàn bộ phiếu nhập hàng qua vòng lặp phân trang (dùng cho Dashboard/Thống kê).
  Future<List<PurchaseOrder>> getPurchaseOrders({
    String? token,
    String? status,
    int? supplierId,
    String? search,
  }) async {
    const maxPages = 100;
    const pageSize = 100;
    final all = <PurchaseOrder>[];

    for (var page = 1; page <= maxPages; page++) {
      final result = await getPurchaseOrdersPaged(
        page: page,
        pageSize: pageSize,
        token: token,
        status: status,
        supplierId: supplierId,
        search: search,
      );
      all.addAll(result.items);
      if (result.items.isEmpty ||
          all.length >= result.totalCount ||
          result.items.length < pageSize) {
        break;
      }
    }

    return all;
  }

  Future<PurchaseOrder?> getPurchaseOrderById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await httpGet(uri, token: token);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return PurchaseOrder.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching PO detail: $e');
    }
    return null;
  }

  Future<ApiResult> createPurchaseOrder(PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders');
      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(po.toCreateJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi tạo phiếu nhập hàng: $e');
    }
  }

  Future<ApiResult> updatePurchaseOrder(int id, PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await httpPut(
        uri,
        token: token,
        body: jsonEncode(po.toCreateJson()),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi cập nhật phiếu nhập hàng: $e');
    }
  }

  Future<ApiResult> deletePurchaseOrder(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await httpDelete(uri, token: token);

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa phiếu nhập hàng thành công.');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối server: $e');
    }
  }
}
