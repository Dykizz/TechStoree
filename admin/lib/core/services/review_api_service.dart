import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/dashboard/models/dashboard_data.dart';
import '../models/review.dart';
import 'base_api_service.dart';

mixin ReviewApiService on BaseApiService {
  Future<CustomerReviewOverviewMetric> getReviewStatistics({int? productId, String? token}) async {
    try {
      final queryParams = <String, String>{};
      if (productId != null) {
        queryParams['productId'] = productId.toString();
      }

      final uri = Uri.parse('$baseUrl/Reviews/admin/statistics').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await httpGet(uri, token: token);

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return CustomerReviewOverviewMetric.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) print('API Error getReviewStatistics: $e');
    }
    return CustomerReviewOverviewMetric.empty();
  }

  Future<ReviewStatistics?> getDetailedReviewStatistics({int? productId, String? token}) async {
    try {
      final queryParams = <String, String>{};
      if (productId != null) {
        queryParams['productId'] = productId.toString();
      }

      final uri = Uri.parse('$baseUrl/Reviews/admin/statistics').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (data is Map<String, dynamic>) {
            return ReviewStatistics.fromJson(data);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('API Error getDetailedReviewStatistics: $e');
    }
    return null;
  }

  Future<ReviewPagedResult> getAdminReviews({
    int page = 1,
    int pageSize = 10,
    int? productId,
    int? userId,
    double? rating,
    double? minRating,
    double? maxRating,
    bool? hasReply,
    bool? isHidden,
    bool? hasImages,
    String? search,
    String? sortBy,
    bool isAscending = false,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'isAscending': isAscending.toString(),
      };

      if (productId != null) queryParams['productId'] = productId.toString();
      if (userId != null) queryParams['userId'] = userId.toString();
      if (rating != null) queryParams['rating'] = rating.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxRating != null) queryParams['maxRating'] = maxRating.toString();
      if (hasReply != null) queryParams['hasReply'] = hasReply.toString();
      if (isHidden != null) queryParams['isHidden'] = isHidden.toString();
      if (hasImages != null) queryParams['hasImages'] = hasImages.toString();
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      if (sortBy != null && sortBy.trim().isNotEmpty) queryParams['sortBy'] = sortBy.trim();

      final uri = Uri.parse('$baseUrl/Reviews/admin').replace(queryParameters: queryParams);
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

          final items = itemsData.map((e) => ReviewItem.fromJson(e as Map<String, dynamic>)).toList();
          int p = page;
          int ps = pageSize;
          int totItems = items.length;

          if (metaData != null) {
            p = (metaData['page'] as num?)?.toInt() ?? page;
            ps = (metaData['pageSize'] as num?)?.toInt() ?? pageSize;
            totItems = (metaData['totalItems'] as num?)?.toInt() ?? items.length;
          }

          return ReviewPagedResult(items: items, totalCount: totItems, page: p, pageSize: ps);
        }
      } else {
        if (kDebugMode) print('getAdminReviews HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('API Error getAdminReviews: $e');
    }
    return ReviewPagedResult(items: [], totalCount: 0, page: page, pageSize: pageSize);
  }

  Future<ApiResult> replyReview(int reviewId, String replyContent, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Reviews/$reviewId/reply');
      final response = await httpPost(
        uri,
        token: token,
        body: json.encode({'replyContent': replyContent.trim()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Phản hồi đánh giá thành công!');
      }
      final errorMsg = extractErrorMessage(response);
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      if (kDebugMode) print('API Error replyReview: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  Future<ApiResult> deleteReply(int reviewId, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Reviews/$reviewId/reply');
      final response = await httpDelete(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa phản hồi thành công!');
      }
      final errorMsg = extractErrorMessage(response);
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      if (kDebugMode) print('API Error deleteReply: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  Future<ApiResult> toggleHideReview(int reviewId, bool isHidden, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Reviews/$reviewId/visibility').replace(
        queryParameters: {'isHidden': isHidden.toString()},
      );
      final response = await httpPatch(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(
          success: true,
          message: isHidden ? 'Đã ẩn đánh giá khỏi giao diện người dùng!' : 'Đã hiện lại đánh giá công khai!',
        );
      }
      final errorMsg = extractErrorMessage(response);
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      if (kDebugMode) print('API Error toggleHideReview: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối: $e');
    }
  }
}
