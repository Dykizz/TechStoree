import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import 'base_api_service.dart';

mixin PromotionApiService on BaseApiService {
  Future<List<Promotion>> getPromotions({String? token, String? status, bool? isActive, String? search}) async {
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

      final uri = Uri.parse('$baseUrl/promotions').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await httpGet(uri, token: token);

      if (response.statusCode == 401 || response.statusCode == 403) {
        if (kDebugMode) print('[PromotionApiService] HTTP ${response.statusCode}: Không có quyền truy cập');
        return <Promotion>[];
      }

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Promotion.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('API Error getPromotions: $e');
    }
    return <Promotion>[];
  }

  Future<Promotion?> getPromotionById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/promotions/$id');
      final response = await httpGet(uri, token: token);

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return Promotion.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) print('API Error getPromotionById: $e');
    }
    return null;
  }

  Future<ApiResult> createPromotion(Promotion promo, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/promotions');
      final response = await httpPost(
        uri,
        token: token,
        body: jsonEncode(promo.toUpsertJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo khuyến mãi thành công.',
          data: body['data'] != null ? Promotion.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Tạo khuyến mãi thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi tạo khuyến mãi: $e');
    }
  }

  Future<ApiResult> updatePromotion(int id, Promotion promo, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/promotions/$id');
      final response = await httpPut(
        uri,
        token: token,
        body: jsonEncode(promo.toUpsertJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật khuyến mãi thành công.',
          data: body['data'] != null ? Promotion.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật khuyến mãi thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi cập nhật khuyến mãi: $e');
    }
  }

  Future<ApiResult> deletePromotion(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/promotions/$id');
      final response = await httpDelete(uri, token: token);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa khuyến mãi thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Xóa khuyến mãi thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi xóa khuyến mãi: $e');
    }
  }

  Future<ApiResult> togglePromotionActive(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/promotions/$id/toggle-active');
      final response = await httpPatch(uri, token: token);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Cập nhật trạng thái khuyến mãi thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật trạng thái thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối khi cập nhật trạng thái: $e');
    }
  }
}
