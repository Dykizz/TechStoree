import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/app_user.dart';
import '../models/purchase_order.dart';
import '../models/promotion.dart';

class ApiResult {
  final bool success;
  final String message;
  final dynamic data;

  ApiResult({required this.success, this.message = '', this.data});
}

class ApiService extends ChangeNotifier {
  String _baseUrl = 'http://localhost:5000/api';
  bool _isConnected = false;
  bool _isLoading = false;

  String get baseUrl => _baseUrl;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  void setBaseUrl(String url) {
    _baseUrl = url;
    checkBackendConnection();
  }

  Map<String, String> _headers([String? token]) {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  String _extractErrorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'Phiên làm việc hết hạn hoặc chưa được xác thực (HTTP 401). Vui lòng đăng nhập lại!';
    }
    try {
      if (response.body.isNotEmpty) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        if (jsonRes is Map<String, dynamic>) {
          if (jsonRes['message'] != null && jsonRes['message'].toString().isNotEmpty) {
            return jsonRes['message'].toString();
          }
          if (jsonRes['errors'] != null) {
            final errs = jsonRes['errors'];
            if (errs is Map<String, dynamic>) {
              final messages = <String>[];
              errs.forEach((k, v) {
                if (v is List) {
                  messages.addAll(v.map((e) => e.toString()));
                } else {
                  messages.add(v.toString());
                }
              });
              if (messages.isNotEmpty) return messages.join('\n');
            } else if (errs is List) {
              return errs.join('\n');
            }
            return errs.toString();
          }
          if (jsonRes['title'] != null) {
            return jsonRes['title'].toString();
          }
        }
      }
    } catch (_) {}
    return 'Lỗi yêu cầu HTTP ${response.statusCode}';
  }

  dynamic _parseApiResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      final jsonRes = json.decode(utf8.decode(response.bodyBytes));
      if (jsonRes is Map<String, dynamic> && jsonRes.containsKey('success')) {
        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (data is Map<String, dynamic> && data.containsKey('items')) {
            return data['items'];
          }
          return data ?? true;
        }
      } else if (jsonRes is List) {
        return jsonRes;
      }
      return jsonRes;
    }
    return null;
  }

  Future<bool> checkBackendConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories')).timeout(const Duration(seconds: 3));
      _isConnected = response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      _isConnected = false;
    }
    notifyListeners();
    return _isConnected;
  }

  // ==========================================
  // --- PRODUCTS CRUD ---
  // ==========================================
  Future<List<Product>> getProducts({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        _isConnected = true;
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getProducts: $e');
    }
    _isConnected = false;
    return _getMockProducts();
  }

  Future<List<Product>> getProductsWithVariants({String? token}) async {
    final products = await getProducts(token: token);
    if (!_isConnected) {
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
        Uri.parse('$_baseUrl/products/$id'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
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
        Uri.parse('$_baseUrl/products'),
        headers: _headers(token),
        body: json.encode(product.toCreateJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo sản phẩm thành công!');
      }
      return ApiResult(success: false, message: _extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error createProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> updateProduct(Product product, {String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/products/${product.id}'),
        headers: _headers(token),
        body: json.encode(product.toUpdateJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật sản phẩm thành công!');
      }
      return ApiResult(success: false, message: _extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error updateProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> toggleProductStatus(String id, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/products/$id/status'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Cập nhật trạng thái thành công!');
      }
      return ApiResult(success: false, message: _extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error toggleProductStatus: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  Future<ApiResult> deleteProduct(String id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/products/$id'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Xóa sản phẩm thành công!');
      }
      return ApiResult(success: false, message: _extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error deleteProduct: $e');
      return ApiResult(success: false, message: 'Không thể kết nối API: $e');
    }
  }

  // ==========================================
  // --- CATEGORIES CRUD ---
  // ==========================================
  List<Category> _mockCategories = [
    Category(id: '1', name: 'Laptop & Máy tính', code: 'LAPTOP', productCount: 42, description: 'MacBook, Dell XPS, ThinkPad, Asus ROG', iconName: 'laptop'),
    Category(id: '2', name: 'Điện thoại thông minh', code: 'SMARTPHONE', productCount: 58, description: 'iPhone, Samsung Galaxy, Xiaomi, Pixel', iconName: 'phone_android'),
    Category(id: '3', name: 'Máy tính bảng', code: 'TABLET', productCount: 19, description: 'iPad, Samsung Galaxy Tab, Xiaomi Pad', iconName: 'tablet'),
    Category(id: '4', name: 'Phụ kiện & Âm thanh', code: 'ACCESSORIES', productCount: 120, description: 'Tai nghe, Sạc, Cáp, Bàn phím, Chuột, Ba lô', iconName: 'headphones'),
  ];

  Future<List<Category>> getCategories({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getCategories: $e');
    }
    return _mockCategories;
  }

  Future<bool> createCategory(Category category, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: _headers(token),
        body: json.encode(category.toUpsertJson()),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error createCategory: $e');
    }
    _mockCategories.add(category);
    notifyListeners();
    return true;
  }

  Future<bool> updateCategory(Category category, {String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/categories/${category.id}'),
        headers: _headers(token),
        body: json.encode(category.toUpsertJson()),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateCategory: $e');
    }
    final idx = _mockCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _mockCategories[idx] = category;
    notifyListeners();
    return true;
  }

  Future<bool> deleteCategory(String id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/categories/$id'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error deleteCategory: $e');
    }
    _mockCategories.removeWhere((c) => c.id == id);
    notifyListeners();
    return true;
  }

  // ==========================================
  // --- SUPPLIERS CRUD ---
  // ==========================================
  List<Supplier> _mockSuppliers = [
    Supplier(id: '1', name: 'Apple Vietnam LLC', code: 'SUP-AAPL', contactName: 'Trần Minh Đức', phone: '028-3829-1000', email: 'distro@apple.com.vn', address: 'Tòa nhà Bitexco, Q.1, TP.HCM', description: 'Nhà phân phối ủy quyền sản phẩm Apple chính hãng.'),
    Supplier(id: '2', name: 'Samsung Electronics VN', code: 'SUP-SSNG', contactName: 'Nguyễn Thanh Hà', phone: '028-3914-2222', email: 'b2b@samsung.com.vn', address: 'Khu Công Nghệ Cao, Q.9, TP.HCM', description: 'Cung cấp smartphone, máy tính bảng và màn hình Samsung.'),
    Supplier(id: '3', name: 'Dell Technologies Distro', code: 'SUP-DELL', contactName: 'Lê Hoàng Nam', phone: '024-3772-8888', email: 'sales@dell.com.vn', address: 'Tòa nhà Keangnam, Cầu Giấy, Hà Nội', description: 'Nhà phân phối độc quyền dòng laptop Dell XPS, Inspiron, Latitude.'),
  ];

  Future<List<Supplier>> getSuppliers({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/suppliers'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Supplier.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getSuppliers: $e');
    }
    return _mockSuppliers;
  }

  Future<bool> createSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/suppliers'),
        headers: _headers(token),
        body: json.encode(supplier.toUpsertJson()),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error createSupplier: $e');
    }
    _mockSuppliers.add(supplier);
    notifyListeners();
    return true;
  }

  Future<bool> updateSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/suppliers/${supplier.id}'),
        headers: _headers(token),
        body: json.encode(supplier.toUpsertJson()),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateSupplier: $e');
    }
    final idx = _mockSuppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) _mockSuppliers[idx] = supplier;
    notifyListeners();
    return true;
  }

  Future<bool> deleteSupplier(String id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/suppliers/$id'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error deleteSupplier: $e');
    }
    _mockSuppliers.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }

  // ==========================================
  // --- USERS CRUD ---
  // ==========================================
  List<AppUser> _mockUsers = [
    AppUser(id: '1', userName: 'Nguyễn Văn An', email: 'an.nguyen@gmail.com', role: 'ADMIN', status: 'Hoạt động', isLocked: false, phone: '0903112233', createdAt: DateTime.now().subtract(const Duration(days: 120))),
    AppUser(id: '2', userName: 'Trần Thị Bình', email: 'binh.tran@yahoo.com', role: 'USER', status: 'Hoạt động', isLocked: false, phone: '0912334455', createdAt: DateTime.now().subtract(const Duration(days: 45))),
    AppUser(id: '3', userName: 'Phạm Minh Đức', email: 'duc.pham@hotmail.com', role: 'USER', status: 'Tạm khóa', isLocked: true, phone: '0977112244', createdAt: DateTime.now().subtract(const Duration(days: 8))),
  ];

  Future<List<AppUser>> getUsers({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => AppUser.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getUsers: $e');
    }
    return _mockUsers;
  }

  Future<ApiResult> createUser(AppUser user, String password, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers(token),
        body: json.encode({
          'username': user.userName.toLowerCase().replaceAll(' ', '_'),
          'email': user.email,
          'password': password,
          'fullName': user.userName,
          'phone': user.phone,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifyListeners();
        return ApiResult(success: true, message: 'Tạo tài khoản thành công!');
      }
      return ApiResult(success: false, message: _extractErrorMessage(response));
    } catch (e) {
      debugPrint('API Error createUser: $e');
    }
    _mockUsers.add(user);
    notifyListeners();
    return ApiResult(success: true, message: 'Tạo tài khoản thành công (Offline Mode)!');
  }

  Future<bool> toggleUserLock(String userId, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/toggle-lock'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error toggleUserLock: $e');
    }
    final idx = _mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _mockUsers[idx];
      _mockUsers[idx] = AppUser(
        id: old.id,
        userName: old.userName,
        email: old.email,
        role: old.role,
        status: old.isLocked ? 'Hoạt động' : 'Tạm khóa',
        isLocked: !old.isLocked,
        phone: old.phone,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
    return true;
  }

  Future<bool> updateUserRole(String userId, String roleId, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/role'),
        headers: _headers(token),
        body: json.encode({'roleId': roleId}),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateUserRole: $e');
    }
    final idx = _mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _mockUsers[idx];
      _mockUsers[idx] = AppUser(
        id: old.id,
        userName: old.userName,
        email: old.email,
        role: roleId,
        status: old.status,
        isLocked: old.isLocked,
        phone: old.phone,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
    return true;
  }

  // ==========================================
  // --- ORDERS ---
  // ==========================================
  Future<List<Order>> getOrders({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/purchase-orders'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (_) {}
    return _getMockOrders();
  }

  // --- Fallback Mocks ---
  late final List<Product> _mockProducts = [
    Product(
      id: '1',
      name: 'Laptop ASUS Zenbook 14 OLED UX3405',
      sku: 'ASUS-UX3405',
      category: 'Laptop',
      price: 24990000,
      stock: 25,
      status: 'In Stock',
      imageUrl: 'https://picsum.photos/200',
      description: 'Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz',
      variantAttributes: ['Cấu hình (RAM/SSD)', 'Màu sắc'],
      variants: [
        ProductVariant(variantId: 1, productId: 1, variantNameAttr: '16GB RAM / 512GB SSD - Xanh', price: 24990000, stockQuantity: 15, attributes: {'Cấu hình (RAM/SSD)': '16GB RAM / 512GB SSD', 'Màu sắc': 'Xanh'}),
        ProductVariant(variantId: 2, productId: 1, variantNameAttr: '32GB RAM / 1TB SSD - Xanh', price: 29990000, stockQuantity: 10, attributes: {'Cấu hình (RAM/SSD)': '32GB RAM / 1TB SSD', 'Màu sắc': 'Xanh'}),
      ],
    ),
    Product(
      id: '2',
      name: 'Laptop Gaming Acer Nitro V 15',
      sku: 'ACER-NITRO-V15',
      category: 'Laptop',
      price: 21490000,
      stock: 20,
      status: 'In Stock',
      imageUrl: 'https://picsum.photos/200',
      description: 'Laptop gaming hiệu năng cao card đồ họa RTX 4050',
      variantAttributes: ['Cấu hình (RAM/SSD)', 'Màu sắc'],
      variants: [
        ProductVariant(variantId: 3, productId: 2, variantNameAttr: '16GB RAM / 512GB SSD - Đen', price: 21490000, stockQuantity: 20, attributes: {'Cấu hình (RAM/SSD)': '16GB RAM / 512GB SSD', 'Màu sắc': 'Đen'}),
      ],
    ),
    Product(
      id: '3',
      name: 'Tai nghe chụp tai Sony WH-1000XM5',
      sku: 'SONY-WH1000XM5',
      category: 'Phụ kiện',
      price: 7490000,
      stock: 40,
      status: 'In Stock',
      imageUrl: 'https://picsum.photos/200',
      description: 'Tai nghe chống ồn chủ động đỉnh cao',
      variantAttributes: ['Màu sắc'],
      variants: [
        ProductVariant(variantId: 4, productId: 3, variantNameAttr: 'Màu Đen (Midnight Black)', price: 7490000, stockQuantity: 25, attributes: {'Màu sắc': 'Màu Đen (Midnight Black)'}),
        ProductVariant(variantId: 5, productId: 3, variantNameAttr: 'Màu Bạc (Silver Platinum)', price: 7490000, stockQuantity: 15, attributes: {'Màu sắc': 'Màu Bạc (Silver Platinum)'}),
      ],
    ),
  ];

  List<Product> _getMockProducts() {
    return _mockProducts;
  }

  List<Order> _getMockOrders() {
    return [
      Order(
        id: '101',
        orderNumber: 'TS-ORD-2026-089',
        customerName: 'Nguyễn Văn An',
        customerEmail: 'an.nguyen@gmail.com',
        totalAmount: 130980000,
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: [
          OrderItem(productId: '1', productName: 'MacBook Pro 16 M3 Max', quantity: 1, unitPrice: 89990000),
        ],
      ),
    ];
  }

  // --- Purchase Order Methods ---
  Future<List<PurchaseOrder>> getPurchaseOrders({String? token, String? status, int? supplierId, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (supplierId != null && supplierId > 0) {
        queryParams['supplierId'] = supplierId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$_baseUrl/purchase-orders').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final items = body['data']['items'] as List?;
          if (items != null) {
            return items.map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>)).toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching purchase orders: $e');
    }
    return [];
  }

  Future<PurchaseOrder?> getPurchaseOrderById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/purchase-orders/$id');
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return PurchaseOrder.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching PO detail: $e');
    }
    return null;
  }

  void _applyPoStockToMock(PurchaseOrder po) {
    if (po.isCompleted) {
      for (var item in po.items) {
        for (int i = 0; i < _mockProducts.length; i++) {
          var p = _mockProducts[i];
          bool updated = false;
          List<ProductVariant> newVariants = [];
          int newTotalStock = 0;
          for (var v in p.variants) {
            if (v.variantId == item.variantId) {
              updated = true;
              final int newStock = (v.stockQuantity + item.quantity).toInt();
              newTotalStock += newStock;
              newVariants.add(ProductVariant(
                variantId: v.variantId,
                productId: v.productId,
                variantNameAttr: v.variantNameAttr,
                price: v.price,
                stockQuantity: newStock,
                imageUrl: v.imageUrl,
                attributes: v.attributes,
                isActive: v.isActive,
              ));
            } else {
              newTotalStock += v.stockQuantity.toInt();
              newVariants.add(v);
            }
          }
          if (updated) {
            _mockProducts[i] = Product(
              id: p.id,
              name: p.name,
              sku: p.sku,
              category: p.category,
              categoryId: p.categoryId,
              price: p.price,
              stock: newTotalStock,
              status: p.status,
              isActive: p.isActive,
              imageUrl: p.imageUrl,
              description: p.description,
              variantAttributes: p.variantAttributes,
              variants: newVariants,
            );
          }
        }
      }
    }
  }

  Future<ApiResult> createPurchaseOrder(PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/purchase-orders');
      final response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(po.toCreateJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _applyPoStockToMock(po);
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Tạo phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Tạo phiếu nhập hàng thất bại.');
    } catch (e) {
      _applyPoStockToMock(po);
      notifyListeners();
      return ApiResult(success: true, message: 'Tạo phiếu nhập hàng thành công (Offline Mode).');
    }
  }

  Future<ApiResult> updatePurchaseOrder(int id, PurchaseOrder po, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/purchase-orders/$id');
      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(po.toCreateJson()),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _applyPoStockToMock(po);
        notifyListeners();
        return ApiResult(
          success: true,
          message: body['message'] ?? 'Cập nhật phiếu nhập hàng thành công.',
          data: body['data'] != null ? PurchaseOrder.fromJson(body['data']) : null,
        );
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật phiếu nhập hàng thất bại.');
    } catch (e) {
      _applyPoStockToMock(po);
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật phiếu nhập hàng thành công (Offline Mode).');
    }
  }

  Future<ApiResult> deletePurchaseOrder(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/purchase-orders/$id');
      final response = await http.delete(uri, headers: _headers(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa phiếu nhập hàng thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Xóa phiếu nhập hàng thất bại.');
    } catch (e) {
      return ApiResult(success: false, message: 'Lỗi kết nối server: $e');
    }
  }

  // ==========================================
  // --- PROMOTIONS CRUD ---
  // ==========================================
  late final List<Promotion> _mockPromotions = [
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

      final uri = Uri.parse('$_baseUrl/promotions').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Promotion.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('API Error getPromotions: $e');
    }
    return _mockPromotions;
  }

  Future<Promotion?> getPromotionById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotions/$id');
      final response = await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 4));

      final data = _parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return Promotion.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) print('API Error getPromotionById: $e');
    }
    final idx = _mockPromotions.indexWhere((p) => p.promotionId == id);
    if (idx != -1) return _mockPromotions[idx];
    return null;
  }

  Future<ApiResult> createPromotion(Promotion promo, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotions');
      final response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(promo.toUpsertJson()),
      ).timeout(const Duration(seconds: 5));

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
      _mockPromotions.add(promo);
      notifyListeners();
      return ApiResult(success: true, message: 'Tạo khuyến mãi thành công (Offline Mode).');
    }
  }

  Future<ApiResult> updatePromotion(int id, Promotion promo, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotions/$id');
      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(promo.toUpsertJson()),
      ).timeout(const Duration(seconds: 5));

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
      final idx = _mockPromotions.indexWhere((p) => p.promotionId == id);
      if (idx != -1) _mockPromotions[idx] = promo;
      notifyListeners();
      return ApiResult(success: true, message: 'Cập nhật khuyến mãi thành công (Offline Mode).');
    }
  }

  Future<ApiResult> deletePromotion(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotions/$id');
      final response = await http.delete(uri, headers: _headers(token)).timeout(const Duration(seconds: 4));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Xóa khuyến mãi thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Xóa khuyến mãi thất bại.');
    } catch (e) {
      _mockPromotions.removeWhere((p) => p.promotionId == id);
      notifyListeners();
      return ApiResult(success: true, message: 'Xóa khuyến mãi thành công (Offline Mode).');
    }
  }

  Future<ApiResult> togglePromotionActive(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotions/$id/toggle-active');
      final response = await http.patch(uri, headers: _headers(token)).timeout(const Duration(seconds: 4));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return ApiResult(success: true, message: body['message'] ?? 'Cập nhật trạng thái khuyến mãi thành công.');
      }
      return ApiResult(success: false, message: body['message'] ?? 'Cập nhật trạng thái thất bại.');
    } catch (e) {
      final idx = _mockPromotions.indexWhere((p) => p.promotionId == id);
      if (idx != -1) {
        final old = _mockPromotions[idx];
        _mockPromotions[idx] = Promotion(
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
