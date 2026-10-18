import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import 'base_api_service.dart';

mixin CategoryApiService on BaseApiService {
  final List<Category> mockCategories = [
    Category(id: '1', name: 'Laptop & Máy tính', code: 'LAPTOP', productCount: 42, description: 'MacBook, Dell XPS, ThinkPad, Asus ROG', iconName: 'laptop'),
    Category(id: '2', name: 'Điện thoại thông minh', code: 'SMARTPHONE', productCount: 58, description: 'iPhone, Samsung Galaxy, Xiaomi, Pixel', iconName: 'phone_android'),
    Category(id: '3', name: 'Máy tính bảng', code: 'TABLET', productCount: 19, description: 'iPad, Samsung Galaxy Tab, Xiaomi Pad', iconName: 'tablet'),
    Category(id: '4', name: 'Phụ kiện & Âm thanh', code: 'ACCESSORIES', productCount: 120, description: 'Tai nghe, Sạc, Cáp, Bàn phím, Chuột, Ba lô', iconName: 'headphones'),
  ];

  Future<List<Category>> getCategories({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/categories'),
        token: token,
      );

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

  Future<bool> deleteCategory(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/categories/$id'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error deleteCategory: $e');
    }
    mockCategories.removeWhere((c) => c.id == id);
    notifyListeners();
    return true;
  }
}
