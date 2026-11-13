import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    bool throwOnError = false,
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
      final response = await httpGet(uri, token: token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
          lastErrorMessage = '';
          final data = jsonRes['data'];
          if (data is Map<String, dynamic>) {
            final List itemsJson = data['items'] ?? [];
            final items = itemsJson.map((item) => SurveyAdminList.fromJson(item as Map<String, dynamic>)).toList();
            final meta = data['meta'] is Map<String, dynamic>
                ? data['meta'] as Map<String, dynamic>
                : data;
            final parsedPageSize = (meta['pageSize'] as num?)?.toInt() ?? pageSize;
            final parsedTotalItems = (meta['totalItems'] as num?)?.toInt() ?? items.length;
            final parsedTotalPages = (meta['totalPages'] as num?)?.toInt() ??
                (parsedPageSize > 0 ? (parsedTotalItems / parsedPageSize).ceil() : 1);
            return SurveyPagedResult(
              items: items,
              totalItems: parsedTotalItems,
              page: (meta['page'] as num?)?.toInt() ?? page,
              pageSize: parsedPageSize,
              totalPages: parsedTotalPages,
            );
          }
        }
      }
      extractErrorMessage(response);
      if (throwOnError) {
        throw Exception(
          lastErrorMessage.isNotEmpty
              ? lastErrorMessage
              : 'Không thể tải danh sách khảo sát (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('API Error getSurveys: $e');
      if (throwOnError) rethrow;
    }

    return SurveyPagedResult(
      items: [],
      totalItems: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
    );
  }

  Future<SurveyAdminDetail?> getSurveyById(int id, {String? token, bool throwOnError = false}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/surveys/$id'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true && jsonRes['data'] != null) {
          lastErrorMessage = '';
          return SurveyAdminDetail.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
      }
      if (response.statusCode == 404 && !throwOnError) {
        extractErrorMessage(response);
        return null;
      }
      extractErrorMessage(response);
      if (response.statusCode != 404 && throwOnError) {
        throw Exception(
          lastErrorMessage.isNotEmpty
              ? lastErrorMessage
              : 'Không thể tải chi tiết bài khảo sát (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('API Error getSurveyById: $e');
      if (lastErrorMessage.isEmpty) {
        lastErrorMessage = 'Lỗi kết nối khi tải chi tiết bài khảo sát: $e';
      }
      if (throwOnError) rethrow;
    }
    return null;
  }

  Future<ApiResult> createSurvey(CreateSurveyRequest req, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/surveys'),
        token: token,
        body: json.encode(req.toJson()),
        timeout: const Duration(seconds: 6),
      );

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
      final response = await httpPatch(
        Uri.parse('$baseUrl/surveys/$id'),
        token: token,
        body: json.encode(req.toJson()),
        timeout: const Duration(seconds: 6),
      );

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
      final response = await httpPatch(
        Uri.parse('$baseUrl/surveys/$id/toggle-active'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        lastErrorMessage = '';
        notifyListeners();
        return true;
      }
      extractErrorMessage(response);
    } catch (e) {
      debugPrint('API Error toggleSurveyActive: $e');
    }
    return false;
  }

  Future<ApiResult> deleteSurvey(int id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/surveys/$id'),
        token: token,
      );

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
      final response = await httpPost(
        Uri.parse('$baseUrl/surveys/$id/assign'),
        token: token,
        body: json.encode(req.toJson()),
        timeout: const Duration(seconds: 6),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        int count = 0;
        if (jsonRes is Map<String, dynamic> && jsonRes['data'] != null) {
          count = (jsonRes['data'] as num).toInt();
        }
        final serverMessage = jsonRes is Map<String, dynamic> ? jsonRes['message']?.toString() : null;
        return ApiResult(
          success: true,
          message: serverMessage ?? 'Đã phát bài khảo sát thành công tới $count khách hàng.',
          data: count,
        );
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error assignSurvey: $e');
      return ApiResult(success: false, message: 'Lỗi khi phát bài khảo sát: $e');
    }
  }

  Future<SurveyStatistics?> getSurveyStatistics(int id, {String? token, bool throwOnError = false}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/surveys/$id/statistics'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true && jsonRes['data'] != null) {
          lastErrorMessage = '';
          return SurveyStatistics.fromJson(jsonRes['data'] as Map<String, dynamic>);
        }
      }
      extractErrorMessage(response);
      if (throwOnError) {
        throw Exception(
          lastErrorMessage.isNotEmpty
              ? lastErrorMessage
              : 'Không thể tải dữ liệu thống kê khảo sát (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('API Error getSurveyStatistics: $e');
      if (lastErrorMessage.isEmpty) {
        lastErrorMessage = 'Lỗi kết nối khi tải thống kê khảo sát: $e';
      }
      if (throwOnError) rethrow;
    }
    return null;
  }

  Future<ApiResult> cloneSurvey(int id, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/surveys/$id/clone'),
        token: token,
        timeout: const Duration(seconds: 6),
      );

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

  Future<(Uint8List?, String)> exportSurveyCsv(int id, {String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/surveys/$id/export-csv'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String fileName = 'KhaoSat_${id}_KetQua.csv';
        final disp = response.headers['content-disposition'];
        if (disp != null) {
          final starMatch = RegExp(r"filename\*=UTF-8''([^;\r\n]+)").firstMatch(disp);
          if (starMatch != null) {
            try {
              fileName = Uri.decodeComponent(starMatch.group(1)!);
            } catch (_) {
              fileName = starMatch.group(1)!;
            }
          } else {
            final match = RegExp(r'filename="?([^";\r\n]+)"?').firstMatch(disp);
            if (match != null) {
              fileName = match.group(1)!.trim();
            }
          }
        }
        // Sanitize fileName to strictly remove illegal Win32 characters: < > : " / \ | ? *
        fileName = fileName.replaceAll(RegExp(r'[<>:/\\|?*"]'), '_').trim();
        if (!fileName.toLowerCase().endsWith('.csv')) {
          fileName = '$fileName.csv';
        }
        lastErrorMessage = '';
        return (response.bodyBytes, fileName);
      }
      extractErrorMessage(response);
    } catch (e) {
      debugPrint('API Error exportSurveyCsv: $e');
      lastErrorMessage = 'Lỗi kết nối khi xuất báo cáo khảo sát: $e';
    }
    return (null, '');
  }
}
