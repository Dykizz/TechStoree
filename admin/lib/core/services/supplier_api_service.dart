import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import 'base_api_service.dart';

mixin SupplierApiService on BaseApiService {
  final List<Supplier> mockSuppliers = [
    Supplier(id: '1', name: 'Apple Vietnam LLC', code: 'SUP-AAPL', contactName: 'Trần Minh Đức', phone: '028-3829-1000', email: 'distro@apple.com.vn', address: 'Tòa nhà Bitexco, Q.1, TP.HCM', description: 'Nhà phân phối ủy quyền sản phẩm Apple chính hãng.'),
    Supplier(id: '2', name: 'Samsung Electronics VN', code: 'SUP-SSNG', contactName: 'Nguyễn Thanh Hà', phone: '028-3914-2222', email: 'b2b@samsung.com.vn', address: 'Khu Công Nghệ Cao, Q.9, TP.HCM', description: 'Cung cấp smartphone, máy tính bảng và màn hình Samsung.'),
    Supplier(id: '3', name: 'Dell Technologies Distro', code: 'SUP-DELL', contactName: 'Lê Hoàng Nam', phone: '024-3772-8888', email: 'sales@dell.com.vn', address: 'Tòa nhà Keangnam, Cầu Giấy, Hà Nội', description: 'Nhà phân phối độc quyền dòng laptop Dell XPS, Inspiron, Latitude.'),
  ];

  Future<List<Supplier>> getSuppliers({String? token}) async {
    try {
      final response = await httpGet(
        Uri.parse('$baseUrl/suppliers'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null && data is List) {
        return data.map((json) => Supplier.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('API Error getSuppliers: $e');
    }
    return mockSuppliers;
  }

  Future<bool> createSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await httpPost(
        Uri.parse('$baseUrl/suppliers'),
        token: token,
        body: json.encode(supplier.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error createSupplier: $e');
    }
    mockSuppliers.add(supplier);
    notifyListeners();
    return true;
  }

  Future<bool> updateSupplier(Supplier supplier, {String? token}) async {
    try {
      final response = await httpPut(
        Uri.parse('$baseUrl/suppliers/${supplier.id}'),
        token: token,
        body: json.encode(supplier.toUpsertJson()),
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error updateSupplier: $e');
    }
    final idx = mockSuppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) mockSuppliers[idx] = supplier;
    notifyListeners();
    return true;
  }

  Future<bool> deleteSupplier(String id, {String? token}) async {
    try {
      final response = await httpDelete(
        Uri.parse('$baseUrl/suppliers/$id'),
        token: token,
      );

      final data = parseApiResponse(response);
      if (data != null) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('API Error deleteSupplier: $e');
    }
    mockSuppliers.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }
}
