import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/app_user.dart';

class ApiService extends ChangeNotifier {
  String _baseUrl = 'http://localhost:5000/api';
  bool _isConnected = false;
  final bool _isLoading = false;

  String get baseUrl => _baseUrl;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  void setBaseUrl(String url) {
    _baseUrl = url;
    checkBackendConnection();
  }

  Future<bool> checkBackendConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products')).timeout(const Duration(seconds: 2));
      _isConnected = response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      _isConnected = false;
    }
    notifyListeners();
    return _isConnected;
  }

  // ==========================================
  // --- PRODUCTS ---
  // ==========================================
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _isConnected = true;
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error, using fallback products: $e');
    }
    _isConnected = false;
    return _getMockProducts();
  }

  // ==========================================
  // --- ORDERS ---
  // ==========================================
  Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/orders')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (_) {}
    return _getMockOrders();
  }

  // ==========================================
  // --- CATEGORIES CRUD ---
  // ==========================================
  List<Category> _mockCategories = [
    Category(id: '1', name: 'Laptop & Máy tính', code: 'LAPTOP', productCount: 42, description: 'MacBook, Dell XPS, ThinkPad, Asus ROG', iconName: 'laptop'),
    Category(id: '2', name: 'Điện thoại thông minh', code: 'SMARTPHONE', productCount: 58, description: 'iPhone, Samsung Galaxy, Xiaomi, Pixel', iconName: 'phone_android'),
    Category(id: '3', name: 'Máy tính bảng', code: 'TABLET', productCount: 19, description: 'iPad, Samsung Galaxy Tab, Xiaomi Pad', iconName: 'tablet'),
    Category(id: '4', name: 'Phụ kiện & Âm thanh', code: 'ACCESSORIES', productCount: 120, description: 'Tai nghe, Sạc, Cáp, Bàn phím, Chuột, Ba lô', iconName: 'headphones'),
    Category(id: '5', name: 'Thiết bị lưu trữ', code: 'STORAGE', productCount: 35, description: 'SSD di động, Thẻ nhớ, Hard Drive, NAS', iconName: 'sd_storage'),
  ];

  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      }
    } catch (_) {}
    return _mockCategories;
  }

  Future<bool> createCategory(Category category) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}
    _mockCategories.add(category);
    notifyListeners();
    return true;
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/categories/${category.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _mockCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _mockCategories[idx] = category;
    notifyListeners();
    return true;
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/categories/$id')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 || response.statusCode == 204) return true;
    } catch (_) {}
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
    Supplier(id: '4', name: 'Sony Electronics Vietnam', code: 'SUP-SONY', contactName: 'Phạm Thu Trang', phone: '028-3822-5555', email: 'support@sony.com.vn', address: 'Số 93 Nguyễn Du, Q.1, TP.HCM', description: 'Phân phối tai nghe chống ồn, loa không dây và phụ kiện Sony.'),
  ];

  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/suppliers')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Supplier.fromJson(json)).toList();
      }
    } catch (_) {}
    return _mockSuppliers;
  }

  Future<bool> createSupplier(Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/suppliers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplier.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}
    _mockSuppliers.add(supplier);
    notifyListeners();
    return true;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/suppliers/${supplier.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplier.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _mockSuppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) _mockSuppliers[idx] = supplier;
    notifyListeners();
    return true;
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/suppliers/$id')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 || response.statusCode == 204) return true;
    } catch (_) {}
    _mockSuppliers.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }

  // ==========================================
  // --- USERS CRUD ---
  // ==========================================
  List<AppUser> _mockUsers = [
    AppUser(id: '1', userName: 'Nguyễn Văn An', email: 'an.nguyen@gmail.com', role: 'Admin', status: 'Hoạt động', phone: '0903112233', createdAt: DateTime.now().subtract(const Duration(days: 120))),
    AppUser(id: '2', userName: 'Trần Thị Bình', email: 'binh.tran@yahoo.com', role: 'Customer', status: 'Hoạt động', phone: '0912334455', createdAt: DateTime.now().subtract(const Duration(days: 45))),
    AppUser(id: '3', userName: 'Lê Hoàng Cường', email: 'cuong.le@techcorp.vn', role: 'Staff', status: 'Hoạt động', phone: '0988776655', createdAt: DateTime.now().subtract(const Duration(days: 15))),
    AppUser(id: '4', userName: 'Phạm Minh Đức', email: 'duc.pham@hotmail.com', role: 'Customer', status: 'Tạm khóa', phone: '0977112244', createdAt: DateTime.now().subtract(const Duration(days: 8))),
  ];

  Future<List<AppUser>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => AppUser.fromJson(json)).toList();
      }
    } catch (_) {}
    return _mockUsers;
  }

  Future<bool> createUser(AppUser user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}
    _mockUsers.add(user);
    notifyListeners();
    return true;
  }

  Future<bool> updateUser(AppUser user) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _mockUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) _mockUsers[idx] = user;
    notifyListeners();
    return true;
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$id')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 || response.statusCode == 204) return true;
    } catch (_) {}
    _mockUsers.removeWhere((u) => u.id == id);
    notifyListeners();
    return true;
  }

  // --- Mock Products & Orders Data ---
  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'MacBook Pro 16 M3 Max',
        sku: 'MBP-16-M3M',
        category: 'Laptop',
        price: 89990000,
        stock: 14,
        status: 'In Stock',
        imageUrl: 'https://picsum.photos/200',
        description: 'Chip Apple M3 Max 16-core CPU, 40-core GPU, 36GB RAM, 1TB SSD.',
      ),
      Product(
        id: '2',
        name: 'iPhone 16 Pro Max 512GB',
        sku: 'IP16PM-512',
        category: 'Điện thoại',
        price: 40990000,
        stock: 8,
        status: 'Low Stock',
        imageUrl: 'https://picsum.photos/200',
        description: 'Khung Titan Sa Mạc, màn hình Super Retina XDR 6.9 inch, chip A18 Pro.',
      ),
      Product(
        id: '3',
        name: 'Dell XPS 15 9530 i9',
        sku: 'DELL-XPS15',
        category: 'Laptop',
        price: 65490000,
        stock: 22,
        status: 'In Stock',
        imageUrl: 'https://picsum.photos/200',
        description: 'Intel Core i9-13900H, 32GB DDR5, RTX 4060, màn 3.5K OLED Touch.',
      ),
    ];
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
          OrderItem(productId: '2', productName: 'iPhone 16 Pro Max 512GB', quantity: 1, unitPrice: 40990000),
        ],
      ),
    ];
  }
}
