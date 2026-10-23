import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import 'base_api_service.dart';

mixin CategoryApiService on BaseApiService {
  final List<Category> mockCategories = [
    Category(id: '1', name: 'Laptop & Máy tính', code: 'LAPTOP', productCount: 42, description: '', iconName: ''),
    Category(id: '2', name: 'Điện thoại thông minh', code: 'SMARTPHONE', productCount: 58, description: '', iconName: ''),
    Category(id: '3', name: 'Máy tính bảng', code: 'TABLET', productCount: 19, description: '', iconName: ''),
    Category(id: '4', name: 'Phụ kiện & Âm thanh', code: 'ACCESSORIES', productCount: 120, description: '', iconName: ''),
  ];

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
      debugPrint('API Error getCategories: $e');
    }
    return mockCategories;
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
      debugPrint('API Error createCategory: $e');
    }
    mockCategories.add(category);
    notifyListeners();
    return true;
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
      debugPrint('API Error updateCategory: $e');
    }
    final idx = mockCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) mockCategories[idx] = category;
    notifyListeners();
    return true;
  }

  Future<ApiResult> deleteCategory(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/categories/$id'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        mockCategories.removeWhere((c) => c.id == id);
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa loại sản phẩm thành công!');
      }

      final errorMsg = extractErrorMessage(response);
      return ApiResult(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('API Error deleteCategory: $e');
      return ApiResult(success: false, message: 'Lỗi kết nối máy chủ: $e');
    }
  }
}
