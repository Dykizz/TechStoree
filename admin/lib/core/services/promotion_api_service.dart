import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import 'base_api_service.dart';

mixin PromotionApiService on BaseApiService {
  late final List<Promotion> mockPromotions = [
    Promotion(
      promotionId: 1,
      name: 'Flash Sale Laptop Cuối Tuần',
      description: 'Giảm 10% cho tất cả các phiên bản laptop ASUS Zenbook',
      discountType: 'PERCENTAGE',
      discountValue: 10,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'ACTIVE',
      variantCount: 2,
      variantIds: [1, 2],
      variants: [
        PromotionVariantItem(
          variantId: 1,
          productId: 1,
          productName: 'Laptop ASUS Zenbook 14 OLED UX3405',
          variantName: '16GB RAM / 512GB SSD - Xanh',
          originalPrice: 24990000,
          promotionalPrice: 22491000,
          discountAmount: 2499000,
          stockQuantity: 15,
        ),
        PromotionVariantItem(
          variantId: 2,
          productId: 1,
          productName: 'Laptop ASUS Zenbook 14 OLED UX3405',
          variantName: '32GB RAM / 1TB SSD - Xanh',
          originalPrice: 29990000,
          promotionalPrice: 26991000,
          discountAmount: 2999000,
          stockQuantity: 10,
        ),
      ],
    ),
    Promotion(
      promotionId: 2,
      name: 'Tri Ân Khách Hàng Tai Nghe Sony',
      description: 'Giảm trực tiếp 500.000 VNĐ cho tai nghe chống ồn Sony WH-1000XM5',
      discountType: 'FIXED_AMOUNT',
      discountValue: 500000,
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'UPCOMING',
      variantCount: 2,
      variantIds: [4, 5],
      variants: [
        PromotionVariantItem(
          variantId: 4,
          productId: 3,
          productName: 'Tai nghe chụp tai Sony WH-1000XM5',
          variantName: 'Màu Đen (Midnight Black)',
          originalPrice: 7490000,
          promotionalPrice: 6990000,
          discountAmount: 500000,
          stockQuantity: 25,
        ),
      ],
    ),
  ];

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

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Promotion.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('API Error getPromotions: $e');
    }
    return mockPromotions;
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
    final idx = mockPromotions.indexWhere((p) => p.promotionId == id);
    if (idx != -1) return mockPromotions[idx];
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
      mockPromotions.add(promo);
      notifyListeners();
      return ApiResult(success: true, message: 'Tạo khuyến mãi thành công (Offline Mode).');
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
      final idx = mockPromotions.indexWhere((p) => p.promotionId == id);
      if (idx != -1) mockPromotions[idx] = promo;
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật khuyến mãi thành công (Offline Mode).');
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
      mockPromotions.removeWhere((p) => p.promotionId == id);
      notifyListeners();
      return ApiResult(success: true, message: 'Xóa khuyến mãi thành công (Offline Mode).');
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
      final idx = mockPromotions.indexWhere((p) => p.promotionId == id);
      if (idx != -1) {
        final old = mockPromotions[idx];
        mockPromotions[idx] = Promotion(
          promotionId: old.promotionId,
          name: old.name,
          description: old.description,
          discountType: old.discountType,
          discountValue: old.discountValue,
          startDate: old.startDate,
          endDate: old.endDate,
          isActive: !old.isActive,
          createdAt: old.createdAt,
          status: old.status,
          variantCount: old.variantCount,
          variants: old.variants,
          variantIds: old.variantIds,
        );
      }
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật trạng thái khuyến mãi thành công (Offline Mode).');
    }
  }
}
