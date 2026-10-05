import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/purchase_order.dart';
import 'base_api_service.dart';
import 'product_api_service.dart';

mixin PurchaseOrderApiService on BaseApiService, ProductApiService {
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
      final response = await http.get(uri, headers: headers(token));

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
      final response = await http.get(uri, headers: headers(token));

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

  void applyPoStockToMock(PurchaseOrder po) {
    if (po.isCompleted) {
      for (var item in po.items) {
        for (int i = 0; i < mockProducts.length; i++) {
          var p = mockProducts[i];
          bool updated = false;
          List<ProductVariant> newVariants = [];
          int newTotalStock = 0;
          for (var v in p.variants) {
            if (v.variantId == item.variantId) {
              updated = true;
              final int newStock = (v.stockQuantity + item.quantity).toInt();
              newTotalStock += newStock;
              newVariants.add(ProductVariant(
                variantId: v.variantId,
                productId: v.productId,
                variantNameAttr: v.variantNameAttr,
                price: v.price,
                stockQuantity: newStock,
                imageUrl: v.imageUrl,
                attributes: v.attributes,
                isActive: v.isActive,
              ));
            } else {
              newTotalStock += v.stockQuantity.toInt();
              newVariants.add(v);
            }
          }
          if (updated) {
            mockProducts[i] = Product(
              id: p.id,
              name: p.name,
              sku: p.sku,
              category: p.category,
              categoryId: p.categoryId,
              price: p.price,
              stock: newTotalStock,
              status: p.status,
              isActive: p.isActive,
              imageUrl: p.imageUrl,
              description: p.description,
              variantAttributes: p.variantAttributes,
              variants: newVariants,
            );
          }
        }
      }
    }
  }

  Future<ApiResult> createPurchaseOrder(PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders');
      final response = await http.post(
        uri,
        headers: headers(token),
        body: jsonEncode(po.toCreateJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        applyPoStockToMock(po);
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Tạo phiếu nhập hàng thất bại.');
    } catch (e) {
      applyPoStockToMock(po);
      notifyListeners();
      return ApiResult(success: true, message: 'Tạo phiếu nhập hàng thành công (Offline Mode).');
    }
  }

  Future<ApiResult> updatePurchaseOrder(int id, PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await http.put(
        uri,
        headers: headers(token),
        body: jsonEncode(po.toCreateJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        applyPoStockToMock(po);
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật phiếu nhập hàng thất bại.');
    } catch (e) {
      applyPoStockToMock(po);
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật phiếu nhập hàng thành công (Offline Mode).');
    }
  }

  Future<ApiResult> deletePurchaseOrder(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-orders/$id');
      final response = await http.delete(uri, headers: headers(token));
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
