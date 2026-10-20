import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/voucher.dart';
import 'base_api_service.dart';

mixin VoucherApiService on BaseApiService {
  Future<List<Voucher>> getVouchers({String? token, String? status, bool? isActive, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/vouchers').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await httpGet(uri, token: token);

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Voucher.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('API Error getVouchers: $e');
    }
    return <Voucher>[];
  }

  Future<Voucher?> getVoucherById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/vouchers/$id');
      final response = await httpGet(uri, token: token);

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return Voucher.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) print('API Error getVoucherById: $e');
    }
    return null;
  }

  Future<ApiResult> createVoucher(Voucher voucher, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/vouchers');
      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(voucher.toUpsertJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo voucher thành công.',
          data: body['data'] != null ? Voucher.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }

  Future<ApiResult> updateVoucher(int id, Voucher voucher, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/vouchers/$id');
      final response = await httpPut(
        uri,
        token: token,
        body: jsonEncode(voucher.toUpsertJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật voucher thành công.',
          data: body['data'] != null ? Voucher.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }

  Future<ApiResult> toggleVoucherActive(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/vouchers/$id/toggle-active');
      final response = await httpPatch(uri, token: token);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Cập nhật trạng thái voucher thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }

  Future<ApiResult> deleteVoucher(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/vouchers/$id');
      final response = await httpDelete(uri, token: token);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa voucher thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? extractErrorMessage(response));
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }
}
