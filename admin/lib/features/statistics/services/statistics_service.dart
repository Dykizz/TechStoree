import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/services/api_service.dart';
import '../models/statistics_models.dart';

class StatisticsDataset {
  final List<Order> orders;
  final List<PurchaseOrder> purchaseOrders;
  final List<Product> products;
  final List<AppUser> staffList;
  final List<int> availableYears;

  const StatisticsDataset({
    required this.orders,
    required this.purchaseOrders,
    required this.products,
    required this.staffList,
    required this.availableYears,
  });

  factory StatisticsDataset.empty() {
    return const StatisticsDataset(
      orders: [],
      purchaseOrders: [],
      products: [],
      staffList: [],
      availableYears: [2026, 2025, 2024],
    );
  }
}

class StatisticsService {
  /// Lấy toàn bộ tập dữ liệu thực tế từ hệ thống Backend API
  static Future<StatisticsDataset> fetchDataset(ApiService apiService, String? token) async {
    // 1. Tải toàn bộ đơn hàng
    List<Order> orders = [];
    try {
      final paged = await apiService.getAllOrders(page: 1, pageSize: 200, token: token);
      orders = List.from(paged.items);
      if (paged.totalPages > 1) {
        for (int p = 2; p <= paged.totalPages && p <= 5; p++) {
          final next = await apiService.getAllOrders(page: p, pageSize: 200, token: token);
          orders.addAll(next.items);
        }
      }
    } catch (e) {
      debugPrint('[StatisticsService] Lỗi tải đơn hàng: $e');
    }

    // Nạp chi tiết các mặt hàng nếu đơn hàng chưa có OrderItem
    final validOrders = orders.where((o) => o.orderStatus.toUpperCase() != 'CANCELLED').toList();
    if (validOrders.any((o) => o.items.isEmpty)) {
      final enriched = await Future.wait(validOrders.map((o) async {
        if (o.items.isNotEmpty) return o;
        try {
          final detail = await apiService.getOrderById(o.orderId, token: token);
          return detail ?? o;
        } catch (_) {
          return o;
        }
      }));
      for (final en in enriched) {
        final idx = orders.indexWhere((o) => o.orderId == en.orderId);
        if (idx != -1) orders[idx] = en;
      }
    }

    // 2. Tải toàn bộ phiếu nhập hàng
    List<PurchaseOrder> purchaseOrders = [];
    try {
      purchaseOrders = await apiService.getPurchaseOrders(token: token);
    } catch (e) {
      debugPrint('[StatisticsService] Lỗi tải phiếu nhập: $e');
    }

    // 3. Tải danh sách sản phẩm
    List<Product> products = [];
    try {
      products = await apiService.getProducts(token: token);
    } catch (e) {
      debugPrint('[StatisticsService] Lỗi tải sản phẩm: $e');
    }

    // 4. Tải danh sách nhân sự nội bộ (isStaffOnly = true)
    List<AppUser> staffList = [];
    try {
      staffList = await apiService.getUsers(token: token, isStaffOnly: true);
    } catch (e) {
      debugPrint('[StatisticsService] Lỗi tải danh sách nhân viên: $e');
    }

    // Đảm bảo chỉ lấy tài khoản nhân sự nội bộ (loại bỏ hoàn toàn khách hàng thông thường)
    staffList = staffList.where((u) {
      final isStaff = u.roles.any((r) => r.toUpperCase() != 'USER') || u.role.toUpperCase() != 'USER';
      return isStaff;
    }).toList();

    // Xác định danh sách năm có dữ liệu thực tế
    final Set<int> yearSet = {DateTime.now().year};
    for (final o in orders) {
      if (o.createdAt != null) yearSet.add(o.createdAt!.year);
    }
    for (final po in purchaseOrders) {
      yearSet.add(po.createdAt.year);
    }
    yearSet.addAll([2024, 2025, 2026]);
    final sortedYears = yearSet.toList()..sort((a, b) => b.compareTo(a));

    return StatisticsDataset(
      orders: orders,
      purchaseOrders: purchaseOrders,
      products: products,
      staffList: staffList,
      availableYears: sortedYears,
    );
  }

  /// Tính toán Bảng a: Hoạt động kinh doanh (Thu - Chi - Lợi nhuận) từ số liệu thực
  static List<FinancialMatrixRow> calculateFinancialMatrix({
    required StatisticsDataset dataset,
    required int year,
  }) {
    // Khoảng thời gian 4 Quý
    final q1Start = DateTime(year, 1, 1);
    final q1End = DateTime(year, 3, 31, 23, 59, 59);

    final q2Start = DateTime(year, 4, 1);
    final q2End = DateTime(year, 6, 30, 23, 59, 59);

    final q3Start = DateTime(year, 7, 1);
    final q3End = DateTime(year, 9, 30, 23, 59, 59);

    final q4Start = DateTime(year, 10, 1);
    final q4End = DateTime(year, 12, 31, 23, 59, 59);

    double sumOrders(DateTime start, DateTime end) {
      return dataset.orders
          .where((o) =>
              o.orderStatus.toUpperCase() != 'CANCELLED' &&
              o.createdAt != null &&
              !o.createdAt!.isBefore(start) &&
              !o.createdAt!.isAfter(end))
          .fold<double>(0.0, (acc, o) => acc + o.totalAmount);
    }

    double sumPurchaseOrders(DateTime start, DateTime end) {
      return dataset.purchaseOrders
          .where((po) {
            final st = po.status.toUpperCase();
            final isCompleted = st == 'COMPLETE' || st == 'COMPLETED';
            return isCompleted && !po.createdAt.isBefore(start) && !po.createdAt.isAfter(end);
          })
          .fold<double>(0.0, (acc, po) => acc + po.totalCost);
    }

    final revQ1 = sumOrders(q1Start, q1End);
    final revQ2 = sumOrders(q2Start, q2End);
    final revQ3 = sumOrders(q3Start, q3End);
    final revQ4 = sumOrders(q4Start, q4End);

    final costQ1 = sumPurchaseOrders(q1Start, q1End);
    final costQ2 = sumPurchaseOrders(q2Start, q2End);
    final costQ3 = sumPurchaseOrders(q3Start, q3End);
    final costQ4 = sumPurchaseOrders(q4Start, q4End);

    final profitQ1 = revQ1 - costQ1;
    final profitQ2 = revQ2 - costQ2;
    final profitQ3 = revQ3 - costQ3;
    final profitQ4 = revQ4 - costQ4;

    return [
      FinancialMatrixRow(metricName: 'Tổng thu', q1: revQ1, q2: revQ2, q3: revQ3, q4: revQ4),
      FinancialMatrixRow(metricName: 'Tổng chi', q1: costQ1, q2: costQ2, q3: costQ3, q4: costQ4),
      FinancialMatrixRow(metricName: 'Lợi nhuận', q1: profitQ1, q2: profitQ2, q3: profitQ3, q4: profitQ4, isProfit: true),
    ];
  }

  static String _formatRoleTitle(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'SALES_STAFF':
        return 'Nhân viên bán hàng';
      case 'WAREHOUSE_STAFF':
        return 'Thủ kho';
      case 'SURVEY_STAFF':
        return 'Nhân viên khảo sát & CRM';
      default:
        return role;
    }
  }

  /// Tính toán Bảng b: Doanh số theo Nhân viên từ số liệu thực
  static List<StaffSalesMatrixRow> calculateStaffSalesMatrix({
    required StatisticsDataset dataset,
    required int year,
  }) {
    final q1Start = DateTime(year, 1, 1);
    final q1End = DateTime(year, 3, 31, 23, 59, 59);

    final q2Start = DateTime(year, 4, 1);
    final q2End = DateTime(year, 6, 30, 23, 59, 59);

    final q3Start = DateTime(year, 7, 1);
    final q3End = DateTime(year, 9, 30, 23, 59, 59);

    final q4Start = DateTime(year, 10, 1);
    final q4End = DateTime(year, 12, 31, 23, 59, 59);

    final validOrders = dataset.orders.where((o) =>
        o.orderStatus.toUpperCase() != 'CANCELLED' &&
        o.createdAt != null &&
        o.createdAt!.year == year).toList();

    // Chuẩn hóa nghiệp vụ: Bảng doanh số nhân viên chỉ áp dụng cho bộ phận Bán hàng (SALES_STAFF)
    final salesStaffList = dataset.staffList.where((u) {
      final hasSalesRole = u.roles.any((r) => r.toUpperCase() == 'SALES_STAFF' || r.toUpperCase().contains('SALES'));
      final roleIsSales = u.role.toUpperCase() == 'SALES_STAFF' || u.role.toUpperCase().contains('SALES');
      return hasSalesRole || roleIsSales;
    }).toList();

    List<StaffSalesMatrixRow> result = [];

    for (int i = 0; i < salesStaffList.length; i++) {
      final staff = salesStaffList[i];
      final staffIdNum = int.tryParse(staff.id) ?? -1;

      double sumQuarter(DateTime start, DateTime end) {
        return validOrders.where((o) {
          final isTime = !o.createdAt!.isBefore(start) && !o.createdAt!.isAfter(end);
          if (!isTime) return false;

          // Khớp theo ID người phụ trách / xác nhận đơn hàng (updatedByUserId hoặc updatedByName)
          final matchUpdatedId = o.updatedByUserId != null && o.updatedByUserId == staffIdNum;
          final matchUpdatedName = o.updatedByName != null &&
              (o.updatedByName!.toLowerCase() == staff.userName.toLowerCase() ||
               o.updatedByName!.toLowerCase() == staff.fullName.toLowerCase());
          return matchUpdatedId || matchUpdatedName;
        }).fold<double>(0.0, (acc, o) => acc + o.totalAmount);
      }

      final q1 = sumQuarter(q1Start, q1End);
      final q2 = sumQuarter(q2Start, q2End);
      final q3 = sumQuarter(q3Start, q3End);
      final q4 = sumQuarter(q4Start, q4End);

      result.add(StaffSalesMatrixRow(
        staffCode: 'NV${staff.id.padLeft(2, '0')}',
        staffName: staff.fullName,
        roleTitle: _formatRoleTitle(staff.roles.firstWhere((r) => r.toUpperCase() != 'USER', orElse: () => staff.role)),
        email: staff.email,
        q1: q1,
        q2: q2,
        q3: q3,
        q4: q4,
      ));
    }

    return result;
  }

  /// Tính toán Bảng c: Doanh số theo Sản phẩm qua chuỗi năm từ số liệu thực
  static List<ProductSalesMatrixRow> calculateProductSalesMatrix({
    required StatisticsDataset dataset,
    required List<int> years, // Ví dụ: [2024, 2025, 2026]
  }) {
    final validOrders = dataset.orders.where((o) =>
        o.orderStatus.toUpperCase() != 'CANCELLED' &&
        o.createdAt != null).toList();

    final y1 = years.isNotEmpty ? years[0] : 2024;
    final y2 = years.length > 1 ? years[1] : 2025;
    final y3 = years.length > 2 ? years[2] : 2026;

    List<ProductSalesMatrixRow> result = [];

    for (int i = 0; i < dataset.products.length; i++) {
      final product = dataset.products[i];
      final pNameLower = product.name.toLowerCase();
      final pIdStr = product.id.toString();

      double sumYear(int targetYear) {
        double yearTotal = 0.0;
        final ordersInYear = validOrders.where((o) => o.createdAt!.year == targetYear);

        for (final o in ordersInYear) {
          for (final item in o.items) {
            final matchId = item.productId == pIdStr;
            final matchName = item.productName.toLowerCase().contains(pNameLower) ||
                pNameLower.contains(item.productName.toLowerCase());
            if (matchId || matchName) {
              yearTotal += item.totalPrice;
            }
          }
        }
        return yearTotal;
      }

      final valY1 = sumYear(y1);
      final valY2 = sumYear(y2);
      final valY3 = sumYear(y3);

      result.add(ProductSalesMatrixRow(
        productCode: product.sku.isNotEmpty ? product.sku : 'SP${product.id.padLeft(2, '0')}',
        sku: product.sku.isNotEmpty ? product.sku : 'TS-PROD-${product.id}',
        productName: product.name,
        categoryName: product.category.isNotEmpty ? product.category : 'Sản phẩm công nghệ',
        imageUrl: product.imageUrl,
        y2024: valY1,
        y2025: valY2,
        y2026: valY3,
      ));
    }

    return result;
  }

  /// Trích xuất bảng số liệu ra file CSV / Excel thuần UTF-8 BOM
  static Future<String?> exportCsvFile({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final buffer = StringBuffer();
    // Ghi UTF-8 BOM để Excel hiển thị đúng dấu tiếng Việt không bị lỗi font
    buffer.write('\uFEFF');

    // Dòng tiêu đề
    buffer.writeln(headers.map((h) => '"$h"').join(','));

    // Các dòng dữ liệu
    for (final row in rows) {
      buffer.writeln(row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(','));
    }

    final bytes = utf8.encode(buffer.toString());

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Chọn nơi lưu tệp thống kê (CSV / Excel)',
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savedUri != null) {
        final f = File.fromUri(savedUri);
        if (!await f.exists() || await f.length() == 0) {
          await f.writeAsBytes(bytes);
        }
        return f.path;
      }
    } catch (_) {}

    // Lưu dự phòng vào Downloads
    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
      final downloadsDir = Directory('$userProfile\\Downloads');
      final targetDir = await downloadsDir.exists() ? downloadsDir.path : userProfile;
      final file = File('$targetDir\\$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('[StatisticsService] Lỗi lưu file: $e');
      return null;
    }
  }
}
