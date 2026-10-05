import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/survey.dart';
import 'base_api_service.dart';

class SurveyPagedResult {
  final List<SurveyAdminList> items;
  final int totalItems;
  final int page;
  final int pageSize;
  final int totalPages;

  SurveyPagedResult({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

mixin SurveyApiService on BaseApiService {
  Future<SurveyPagedResult> getSurveys({
    String? search,
    bool? isActive,
    bool? hasReward,
    int page = 1,
    int pageSize = 10,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (hasReward != null) {
        queryParams['hasReward'] = hasReward.toString();
      }

      final uri = Uri.parse('$baseUrl/surveys/admin').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers(token)).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (data is Map<String, dynamic>) {
            final List itemsJson = data['items'] ?? [];
            final items = itemsJson.map((item) => SurveyAdminList.fromJson(item as Map<String, dynamic>)).toList();
            return SurveyPagedResult(
              items: items,
              totalItems: (data['totalItems'] ?? items.length) as int,
              page: (data['page'] ?? page) as int,
              pageSize: (data['pageSize'] ?? pageSize) as int,
              totalPages: (data['totalPages'] ?? 1) as int,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('API Error getSurveys: $e');
    }

    return SurveyPagedResult(
      items: [],
      totalItems: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
    );
  }

  Future<SurveyAdminDetail?> getSurveyById(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys/$id'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true && jsonRes['data'] != null) {
          return SurveyAdminDetail.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('API Error getSurveyById: $e');
    }
    return null;
  }

  Future<ApiResult> createSurvey(CreateSurveyRequest req, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys'),
        headers: headers(token),
        body: json.encode(req.toJson()),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        SurveyAdminDetail? detail;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] != null) {
          detail = SurveyAdminDetail.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return ApiResult(
          success: true,
          message: 'Khởi tạo bài khảo sát thành công!',
          data: detail,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error createSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối khi khởi tạo khảo sát: $e');
    }
  }

  Future<ApiResult> updateSurvey(int id, UpdateSurveyRequest req, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/surveys/$id'),
        headers: headers(token),
        body: json.encode(req.toJson()),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        SurveyAdminDetail? detail;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] != null) {
          detail = SurveyAdminDetail.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return ApiResult(
          success: true,
          message: 'Cập nhật bài khảo sát thành công!',
          data: detail,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error updateSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi khi cập nhật bài khảo sát: $e');
    }
  }

  Future<bool> toggleSurveyActive(int id, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/surveys/$id/toggle-active'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error toggleSurveyActive: $e');
    }
    return false;
  }

  Future<ApiResult> deleteSurvey(int id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/surveys/$id'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa bài khảo sát thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error deleteSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi khi xóa bài khảo sát: $e');
    }
  }

  Future<ApiResult> assignSurvey(int id, AssignSurveyRequest req, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys/$id/assign'),
        headers: headers(token),
        body: json.encode(req.toJson()),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        int count = 0;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] != null) {
          count = (jsonRes['data'] as num).toInt();
        }
        return ApiResult(
          success: true,
          message: 'Đã phát bài khảo sát thành công tới $count khách hàng.',
          data: count,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error assignSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi khi phát bài khảo sát: $e');
    }
  }

  Future<SurveyStatistics?> getSurveyStatistics(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys/$id/statistics'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true && jsonRes['data'] != null) {
          return SurveyStatistics.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('API Error getSurveyStatistics: $e');
    }
    return null;
  }

  Future<ApiResult> cloneSurvey(int id, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys/$id/clone'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        SurveyAdminDetail? cloned;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] != null) {
          cloned = SurveyAdminDetail.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
        return ApiResult(
          success: true,
          message: 'Nhân bản bài khảo sát thành công!',
          data: cloned,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error cloneSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi khi nhân bản khảo sát: $e');
    }
  }
}
