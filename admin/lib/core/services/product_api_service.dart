import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'base_api_service.dart';

mixin ProductApiService on BaseApiService {
  Future<List<Product>> getProducts({String? token}) {
    return _fetchPagedProducts(path: '$baseUrl/products', token: token, logLabel: 'getProducts');
  }

  Future<List<Product>> getAdminProducts({String? token}) {
    return _fetchPagedProducts(path: '$baseUrl/products/admin', token: token, logLabel: 'getAdminProducts');
  }

  Future<List<Product>> _fetchPagedProducts({
    required String path,
    String? token,
    required String logLabel,
  }) async {
    try {
      final List<Product> allProducts = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await httpGet(
          Uri.parse('$path?page=$page&pageSize=100'),
          token: token,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final jsonRes = json.decode(utf8.decode(response.bodyBytes));
          if (jsonRes is Map<String, dynamic> && jsonRes['success'] == true) {
            final data = jsonRes['data'];
            if (data is Map<String, dynamic>) {
              final items = data['items'] as List?;
              if (items != null) {
                allProducts.addAll(items.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList());
              }
              final meta = data['meta'] as Map<String, dynamic>?;
              hasMore = meta?['hasNextPage'] == true;
              page++;
            } else if (data is List) {
              allProducts.addAll(data.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList());
              hasMore = false;
            } else {
              hasMore = false;
            }
          } else {
            hasMore = false;
          }
        } else {
          if (response.statusCode == 401 || response.statusCode == 403) {
            debugPrint('[ProductApiService] HTTP ${response.statusCode}: Không có quyền truy cập');
            return <Product>[];
          }
          hasMore = false;
        }

        if (page > 50) break;
      }

      isConnected = true;
      return allProducts;
    } catch (e) {
      debugPrint('API Error $logLabel: $e');
      isConnected = false;
      return <Product>[];
    }
  }

  Future<List<Product>> getProductsWithVariants({String? token}) async {
    final products = await getProducts(token: token);
    return _hydrateProductVariants(products, useAdminEndpoint: false, token: token);
  }

  Future<List<Product>> getAdminProductsWithVariants({String? token}) async {
    final products = await getAdminProducts(token: token);
    return _hydrateProductVariants(products, useAdminEndpoint: true, token: token);
  }

  Future<List<Product>> _hydrateProductVariants(
    List<Product> products, {
    required bool useAdminEndpoint,
    String? token,
  }) async {
    if (products.isEmpty) {
      return products;
    }
    return Future.wait(products.map((p) async {
      if (p.variants.isEmpty && p.id.isNotEmpty && int.tryParse(p.id) != null) {
        final detail = useAdminEndpoint
            ? await getAdminProductById(p.id, token: token)
            : await getProductById(p.id, token: token);
        if (detail != null && detail.variants.isNotEmpty) {
          return detail;
        }
      }
      return p;
    }));
  }

  Future<Product?> getProductById(String id, {String? token}) {
    return _fetchProductDetail('$baseUrl/products/$id', token: token, logLabel: 'getProductById');
  }

  Future<Product?> getAdminProductById(String id, {String? token}) {
    return _fetchProductDetail('$baseUrl/products/admin/$id', token: token, logLabel: 'getAdminProductById');
  }

  Future<Product?> _fetchProductDetail(String url, {String? token, required String logLabel}) async {
    try {
      final response = await httpGet(
        Uri.parse(url),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return Product.fromJson(data);
      }
    } catch (e) {
      debugPrint('API Error $logLabel: $e');
    }
    return null;
  }

  Future<ApiResult> createProduct(Product product, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/products'),
        token: token,
        body: json.encode(product.toCreateJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo sản phẩm thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error createProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> updateProduct(Product product, {String? token}) async {
    try {
      final response = await httpPut(
        Uri.parse('$baseUrl/products/${product.id}'),
        token: token,
        body: json.encode(product.toUpdateJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật sản phẩm thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error updateProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> toggleProductStatus(String id, {String? token}) async {
    try {
      final response = await httpPatch(
        Uri.parse('$baseUrl/products/$id/status'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật trạng thái thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error toggleProductStatus: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> deleteProduct(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/products/$id'),
        token: token,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa sản phẩm thành công!');
      }
      return ApiResult(success: false, message: extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error deleteProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }
}
