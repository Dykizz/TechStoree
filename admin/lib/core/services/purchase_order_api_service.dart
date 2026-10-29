import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';
import 'base_api_service.dart';

mixin PurchaseOrderApiService on BaseApiService {
  Future<List<PurchaseOrder>> getPurchaseOrders({String? token, String? status, int? supplierId, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (supplierId != null && supplierId > 0) {
        queryParams['supplierId'] = supplierId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/purchase-orders').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await httpGet(uri, token: token);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final items = body['data']['items'] as List?;
          if (items != null) {
            return items.map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>)).toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching purchase orders: $e');
    }
    return [];
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

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Tạo phiếu nhập hàng thất bại.');
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

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật phiếu nhập hàng thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi cập nhật phiếu nhập hàng: $e');
    }
  }

  Future<ApiResult> deletePurchaseOrder(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await httpDelete(uri, token: token);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa phiếu nhập hàng thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Xóa phiếu nhập hàng thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối server: $e');
    }
  }
}
