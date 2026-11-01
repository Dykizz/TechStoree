import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import 'base_api_service.dart';

mixin CategoryApiService on BaseApiService {
  Future<List<Category>> getCategories({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/categories'),
        token: token,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[CategoryApiService] HTTP ${response.statusCode}: Không có quyền truy cập');
        return <Category>[];
      }

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[CategoryApiService] Lỗi getCategories: $e');
    }
    // Hoàn toàn không dùng mock fallback - trả về danh sách rỗng nếu lỗi kết nối
    return <Category>[];
  }

  Future<bool> createCategory(Category category, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/categories'),
        token: token,
        body: json.encode(category.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[CategoryApiService] Lỗi createCategory: $e');
    }
    return false;
  }

  Future<bool> updateCategory(Category category, {String? token}) async {
    try {
      final response = await httpPut(
        Uri.parse('$baseUrl/categories/${category.id}'),
        token: token,
        body: json.encode(category.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[CategoryApiService] Lỗi updateCategory: $e');
    }
    return false;
  }

  Future<ApiResult> deleteCategory(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/categories/$id'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa loại sản phẩm thành công!');
      }

      final errorMsg = extractErrorMessage(response);
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('[CategoryApiService] Lỗi deleteCategory: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }
}
