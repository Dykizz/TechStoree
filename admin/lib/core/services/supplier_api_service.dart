import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import 'base_api_service.dart';

mixin SupplierApiService on BaseApiService {
  Future<List<Supplier>> getSuppliers({String? token, String? status = 'all'}) async {
    try {
      final queryParams = <String, String>{'pageSize': '100'};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final uri = Uri.parse('$baseUrl/suppliers').replace(queryParameters: queryParams);
      final response = await httpGet(
        uri,
        token: token,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[SupplierApiService] HTTP ${response.statusCode}: Không có quyền truy cập');
        return <Supplier>[];
      }

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Supplier.fromJson(json as Map<String, dynamic>)).toList();
      }
      debugPrint('[SupplierApiService] getSuppliers: data không hợp lệ: $data');
    } catch (e) {
      debugPrint('[SupplierApiService] Error getSuppliers: $e');
    }
    return <Supplier>[];
  }

  Future<bool> createSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/suppliers'),
        token: token,
        body: json.encode(supplier.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
      debugPrint('[SupplierApiService] createSupplier thất bại: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[SupplierApiService] Error createSupplier: $e');
    }
    return false;
  }

  Future<bool> updateSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await httpPut(
        Uri.parse('$baseUrl/suppliers/${supplier.id}'),
        token: token,
        body: json.encode(supplier.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
      debugPrint('[SupplierApiService] updateSupplier thất bại: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[SupplierApiService] Error updateSupplier: $e');
    }
    return false;
  }

  Future<ApiResult> deleteSupplier(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/suppliers/$id'),
        token: token,
      );

      if (response.statusCode == 204 || parseApiResponse(response) != null) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa nhà cung cấp thành công!');
      }
      final errorMsg = extractErrorMessage(response);
      debugPrint('[SupplierApiService] deleteSupplier thất bại: ${response.statusCode} $errorMsg');
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('[SupplierApiService] Error deleteSupplier: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  Future<ApiResult> toggleActiveSupplier(String id, {String? token}) async {
    try {
      final response = await httpPatch(
        Uri.parse('$baseUrl/suppliers/$id/toggle-active'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật trạng thái hợp tác thành công!');
      }
      final errorMsg = extractErrorMessage(response);
      debugPrint('[SupplierApiService] toggleActiveSupplier thất bại: ${response.statusCode} $errorMsg');
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('[SupplierApiService] Error toggleActiveSupplier: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  Future<bool> restoreSupplier(String id, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/suppliers/$id/restore'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
      debugPrint('[SupplierApiService] restoreSupplier thất bại: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[SupplierApiService] Error restoreSupplier: $e');
    }
    return false;
  }
}
