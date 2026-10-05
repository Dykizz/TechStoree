import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'base_api_service.dart';

mixin ProductApiService on BaseApiService {
  late final List<Product> mockProducts = [
    Product(
      id: '1',
      name: 'iPhone 18 Pro Max 256GB',
      sku: 'TS-PROD-1',
      category: 'Điện thoại (Mobile)',
      price: 41990000,
      originalPrice: 45990000,
      stock: 25,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'iPhone 18 Pro Max màn hình Super Retina XDR ProMotion, chip A19 Pro mạnh mẽ.',
      variantAttributes: ['Dung lượng', 'Màu sắc'],
      variants: [
        ProductVariant(variantId: 1, productId: 1, variantNameAttr: '256GB - Titan Tự Nhiên', price: 41990000, stockQuantity: 15, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Dung lượng': '256GB', 'Màu sắc': 'Titan Tự Nhiên'}),
        ProductVariant(variantId: 2, productId: 1, variantNameAttr: '512GB - Titan Đen', price: 47990000, stockQuantity: 10, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Dung lượng': '512GB', 'Màu sắc': 'Titan Đen'}),
      ],
    ),
    Product(
      id: '2',
      name: 'iPhone Duo 256GB',
      sku: 'TS-PROD-2',
      category: 'Điện thoại (Mobile)',
      price: 64990000,
      stock: 20,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'Siêu phẩm điện thoại gập kép đột phá từ Apple.',
      variantAttributes: ['Cấu hình', 'Màu sắc'],
      variants: [
        ProductVariant(variantId: 3, productId: 2, variantNameAttr: '256GB - Trắng Tuyết', price: 64990000, stockQuantity: 20, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Cấu hình': '256GB', 'Màu sắc': 'Trắng Tuyết'}),
      ],
    ),
    Product(
      id: '3',
      name: 'iPhone 18 Pro 256GB',
      sku: 'TS-PROD-3',
      category: 'Điện thoại (Mobile)',
      price: 38790000,
      originalPrice: 38990000,
      stock: 40,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'iPhone 18 Pro mỏng nhẹ viền titan cao cấp.',
      variantAttributes: ['Màu sắc'],
      variants: [
        ProductVariant(variantId: 4, productId: 3, variantNameAttr: 'Titan Đỏ Đô', price: 38790000, stockQuantity: 25, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Titan Đỏ Đô'}),
        ProductVariant(variantId: 5, productId: 3, variantNameAttr: 'Titan Sa Mạc', price: 38790000, stockQuantity: 15, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Titan Sa Mạc'}),
      ],
    ),
    Product(
      id: '4',
      name: 'Laptop ASUS Zenbook 14 OLED UX3405',
      sku: 'TS-PROD-4',
      category: 'Laptop',
      price: 24990000,
      stock: 18,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz sắc nét, vi xử lý Intel Core Ultra.',
      variantAttributes: ['Màu sắc'],
      variants: [
        ProductVariant(variantId: 6, productId: 4, variantNameAttr: 'Xanh Xám', price: 24990000, stockQuantity: 18, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Xanh Xám'}),
      ],
    ),
    Product(
      id: '5',
      name: 'Tai nghe Bluetooth Sony WH-1000XM5',
      sku: 'TS-PROD-5',
      category: 'Tai nghe & Âm thanh',
      price: 7490000,
      stock: 14,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'Tai nghe chống ồn chủ động hàng đầu thế giới với vi xử lý V1.',
      variantAttributes: ['Màu sắc'],
      variants: [
        ProductVariant(variantId: 7, productId: 5, variantNameAttr: 'Màu Đen', price: 7490000, stockQuantity: 14, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Màu Đen'}),
      ],
    ),
    Product(
      id: '6',
      name: 'Bàn phím cơ không dây FL-Esports GP75',
      sku: 'TS-PROD-6',
      category: 'Phụ kiện máy tính',
      price: 2190000,
      stock: 32,
      status: 'In Stock',
      imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg',
      description: 'Bàn phím cơ 3 chế độ kết nối, switch Gateron mượt mà.',
      variantAttributes: ['Màu sắc'],
      variants: [
        ProductVariant(variantId: 8, productId: 6, variantNameAttr: 'Màu Đen', price: 2190000, stockQuantity: 20, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Màu Đen'}),
        ProductVariant(variantId: 9, productId: 6, variantNameAttr: 'Màu Xanh', price: 2190000, stockQuantity: 12, imageUrl: 'https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-18-pro-01.jpg', attributes: {'Màu sắc': 'Màu Xanh'}),
      ],
    ),
  ];

  List<Product> getMockProducts() {
    return mockProducts;
  }

  Future<List<Product>> getProducts({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        isConnected = true;
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getProducts: $e');
    }
    isConnected = false;
    return getMockProducts();
  }

  Future<List<Product>> getProductsWithVariants({String? token}) async {
    final products = await getProducts(token: token);
    if (!isConnected) {
      return products;
    }
    final fullProducts = await Future.wait(products.map((p) async {
      if (p.variants.isEmpty && p.id.isNotEmpty && int.tryParse(p.id) != null) {
        final detail = await getProductById(p.id, token: token);
        if (detail != null && detail.variants.isNotEmpty) {
          return detail;
        }
      }
      return p;
    }));
    return fullProducts;
  }

  Future<Product?> getProductById(String id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return Product.fromJson(data);
      }
    } catch (e) {
      debugPrint('API Error getProductById: $e');
    }
    return null;
  }

  Future<ApiResult> createProduct(Product product, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: headers(token),
        body: json.encode(product.toCreateJson()),
      ).timeout(const Duration(seconds: 5));

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
      final response = await http.put(
        Uri.parse('$baseUrl/products/${product.id}'),
        headers: headers(token),
        body: json.encode(product.toUpdateJson()),
      ).timeout(const Duration(seconds: 5));

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
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$id/status'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

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
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers(token),
      ).timeout(const Duration(seconds: 4));

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
