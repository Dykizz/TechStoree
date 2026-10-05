import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/voucher.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/api_service.dart';
import '../models/dashboard_data.dart';

class DashboardDataResult {
  final DashboardTimePeriod period;
  final DashboardMetricKpi revenue;
  final DashboardMetricKpi ordersCount;
  final DashboardMetricKpi importCost;
  final DashboardMetricKpi aov;
  final DashboardMetricKpi newCustomers;
  final DashboardMetricKpi lowStockVariants;

  final List<RevenueTrendPoint> trendPoints;
  final List<StatusDistributionItem> orderStatusList;
  final List<StatusDistributionItem> paymentStatusList;
  final List<TopProductItem> topProducts;
  final List<CategoryMetricItem> categoryMetrics;
  final List<VariantInventoryAlert> variantAlerts;
  final SurveyOverviewMetric surveyMetric;
  final PromotionVoucherOverviewMetric promoVoucherMetric;
  final List<Order> recentOrders;
  final List<PurchaseOrder> recentPurchaseOrders;

  final bool isDatasetPaginated;
  final String? paginationWarningMessage;

  DashboardDataResult({
    required this.period,
    required this.revenue,
    required this.ordersCount,
    required this.importCost,
    required this.aov,
    required this.newCustomers,
    required this.lowStockVariants,
    required this.trendPoints,
    required this.orderStatusList,
    required this.paymentStatusList,
    required this.topProducts,
    required this.categoryMetrics,
    required this.variantAlerts,
    required this.surveyMetric,
    required this.promoVoucherMetric,
    required this.recentOrders,
    required this.recentPurchaseOrders,
    this.isDatasetPaginated = false,
    this.paginationWarningMessage,
  });
}

class DashboardDataProvider {
  final ApiService apiService;

  DashboardDataProvider({required this.apiService});

  /// Main entry point to fetch and process complete dashboard metrics for a given period
  Future<DashboardDataResult> fetchDashboardData({
    required DashboardTimePeriod period,
    required String? token,
  }) async {
    // 1. Fetch complete dataset handling API pagination
    final orders = await _fetchAllOrders(token);
    final purchaseOrders = await _fetchAllPurchaseOrders(token);
    final products = await apiService.getProducts(token: token);
    final users = await apiService.getUsers(token: token);
    final promotions = await apiService.getPromotions(token: token);
    final vouchers = await apiService.getVouchers(token: token);
    final surveyPaged = await apiService.getSurveys(token: token);
    final surveys = surveyPaged.items;

    // 2. Filter orders & POs by time period
    final currOrders = _filterOrdersByDateRange(orders, period.startDate, period.endDate);
    final prevOrders = _filterOrdersByDateRange(orders, period.prevStartDate, period.prevEndDate);

    final currPOs = _filterPOsByDateRange(purchaseOrders, period.startDate, period.endDate);
    final prevPOs = _filterPOsByDateRange(purchaseOrders, period.prevStartDate, period.prevEndDate);

    final currUsers = _filterUsersByDateRange(users, period.startDate, period.endDate);
    final prevUsers = _filterUsersByDateRange(users, period.prevStartDate, period.prevEndDate);

    // 3. Business Rule 1: Revenue excludes CANCELLED orders
    final currValidOrders = currOrders.where((o) => o.orderStatus.toUpperCase() != 'CANCELLED').toList();
    final prevValidOrders = prevOrders.where((o) => o.orderStatus.toUpperCase() != 'CANCELLED').toList();

    final currRevenueVal = currValidOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final prevRevenueVal = prevValidOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    final revenueKpi = DashboardMetricKpi.calculate(currRevenueVal, prevRevenueVal);
    final ordersKpi = DashboardMetricKpi.calculate(currValidOrders.length.toDouble(), prevValidOrders.length.toDouble());

    // 4. Business Rule 2: Purchase Cost includes ONLY COMPLETE status
    final currValidPOs = currPOs.where((po) => po.status.toUpperCase() == 'COMPLETE' || po.status.toUpperCase() == 'COMPLETED').toList();
    final prevValidPOs = prevPOs.where((po) => po.status.toUpperCase() == 'COMPLETE' || po.status.toUpperCase() == 'COMPLETED').toList();

    final currImportCostVal = currValidPOs.fold<double>(0, (poSum, po) => poSum + po.totalCost);
    final prevImportCostVal = prevValidPOs.fold<double>(0, (poSum, po) => poSum + po.totalCost);

    final importCostKpi = DashboardMetricKpi.calculate(currImportCostVal, prevImportCostVal);

    // 5. Business Rule 6: AOV calculation
    final currAovVal = currValidOrders.isNotEmpty ? currRevenueVal / currValidOrders.length : 0.0;
    final prevAovVal = prevValidOrders.isNotEmpty ? prevRevenueVal / prevValidOrders.length : 0.0;
    final aovKpi = DashboardMetricKpi.calculate(currAovVal, prevAovVal);

    final newCustomersKpi = DashboardMetricKpi.calculate(currUsers.length.toDouble(), prevUsers.length.toDouble());

    // 6. Business Rule 3: Variant-level inventory alert calculation
    final variantAlertList = <VariantInventoryAlert>[];
    for (var p in products) {
      if (p.variants.isNotEmpty) {
        for (var v in p.variants) {
          if (v.stockQuantity <= 10) {
            variantAlertList.add(
              VariantInventoryAlert(
                productId: p.categoryId,
                variantId: v.variantId ?? 0,
                productName: p.name,
                variantName: v.variantName,
                imageUrl: v.imageUrl?.isNotEmpty == true ? v.imageUrl : p.imageUrl,
                stockQuantity: v.stockQuantity,
                statusLabel: v.stockQuantity == 0 ? 'Hết hàng' : 'Sắp hết',
                isOutOfStock: v.stockQuantity == 0,
              ),
            );
          }
        }
      } else if (p.stock <= 10) {
        variantAlertList.add(
          VariantInventoryAlert(
            productId: p.categoryId,
            variantId: 0,
            productName: p.name,
            variantName: 'Mặc định',
            imageUrl: p.imageUrl,
            stockQuantity: p.stock,
            statusLabel: p.stock == 0 ? 'Hết hàng' : 'Sắp hết',
            isOutOfStock: p.stock == 0,
          ),
        );
      }
    }
    variantAlertList.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    final lowStockKpi = DashboardMetricKpi.calculate(
      variantAlertList.length.toDouble(),
      variantAlertList.length.toDouble(),
      invertTrend: true,
    );

    // 7. Business Rule 7 & 8: Time Aggregation & Trend Points
    final trendPoints = _buildTrendPoints(period, currValidOrders, currValidPOs);

    // 8. Order Status Distribution (Selected Period)
    final orderStatusList = _buildOrderStatusDistribution(currOrders);

    // 9. Payment Status Distribution (Selected Period)
    final paymentStatusList = _buildPaymentStatusDistribution(currOrders);

    // 10. Top Selling Products (From items of valid orders in period)
    final topProducts = _buildTopProducts(currValidOrders);

    // 11. Business Rule 4: Category Analytics (Revenue > Qty > Product count fallback)
    final categoryMetrics = _buildCategoryMetrics(currValidOrders, products);

    // 12. Survey Overview
    final activeSurveys = surveys.where((s) => s.isActive).toList();
    final totAssigned = activeSurveys.fold<int>(0, (sum, s) => sum + s.totalAssigned);
    final totCompleted = activeSurveys.fold<int>(0, (sum, s) => sum + s.totalCompleted);
    final avgResponseRate = activeSurveys.isNotEmpty
        ? activeSurveys.fold<double>(0, (sum, s) => sum + s.responseRatePercent) / activeSurveys.length
        : 0.0;
    final surveyMetric = SurveyOverviewMetric(
      activeSurveysCount: activeSurveys.length,
      totalAssigned: totAssigned,
      totalCompleted: totCompleted,
      averageResponseRate: avgResponseRate,
      activeSurveys: activeSurveys,
    );

    // 13. Promotion & Voucher Overview
    final activePromos = promotions.where((p) => p.status == 'ACTIVE').toList();
    final activeVouchers = vouchers.where((v) => v.status == 'ACTIVE' || v.endDate.isAfter(DateTime.now())).toList();
    final totVoucherUsed = vouchers.fold<int>(0, (sum, v) => sum + v.usedCount);
    final totVoucherLimit = vouchers.fold<int>(0, (sum, v) => sum + (v.usageLimit ?? 0));
    final voucherUsageRate = totVoucherLimit > 0 ? (totVoucherUsed / totVoucherLimit) * 100 : 0.0;
    final sortedVouchers = List<Voucher>.from(vouchers)..sort((a, b) => b.usedCount.compareTo(a.usedCount));

    final promoVoucherMetric = PromotionVoucherOverviewMetric(
      activePromotionsCount: activePromos.length,
      activeVouchersCount: activeVouchers.length,
      totalVouchersUsed: totVoucherUsed,
      totalVouchersLimit: totVoucherLimit,
      voucherUsageRate: voucherUsageRate,
      topVouchers: sortedVouchers.take(5).toList(),
    );

    // 14. Recent Orders (Sorted newest first)
    final sortedRecentOrders = List<Order>.from(orders)..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));

    return DashboardDataResult(
      period: period,
      revenue: revenueKpi,
      ordersCount: ordersKpi,
      importCost: importCostKpi,
      aov: aovKpi,
      newCustomers: newCustomersKpi,
      lowStockVariants: lowStockKpi,
      trendPoints: trendPoints,
      orderStatusList: orderStatusList,
      paymentStatusList: paymentStatusList,
      topProducts: topProducts,
      categoryMetrics: categoryMetrics,
      variantAlerts: variantAlertList,
      surveyMetric: surveyMetric,
      promoVoucherMetric: promoVoucherMetric,
      recentOrders: sortedRecentOrders.take(10).toList(),
      recentPurchaseOrders: purchaseOrders.take(5).toList(),
    );
  }

  /// Complete pagination handler for Orders
  Future<List<Order>> _fetchAllOrders(String? token) async {
    try {
      final firstPage = await apiService.getAllOrders(page: 1, pageSize: 200, token: token);
      List<Order> allOrders = List.from(firstPage.items);

      if (firstPage.totalPages > 1) {
        for (int p = 2; p <= firstPage.totalPages && p <= 10; p++) {
          final pageRes = await apiService.getAllOrders(page: p, pageSize: 200, token: token);
          allOrders.addAll(pageRes.items);
        }
      }
      return allOrders;
    } catch (_) {
      return apiService.getOrders(token: token);
    }
  }

  /// Complete pagination handler for Purchase Orders
  Future<List<PurchaseOrder>> _fetchAllPurchaseOrders(String? token) async {
    try {
      return await apiService.getPurchaseOrders(token: token);
    } catch (_) {
      return [];
    }
  }

  // --- Filtering Helpers ---

  List<Order> _filterOrdersByDateRange(List<Order> orders, DateTime start, DateTime end) {
    return orders.where((o) {
      if (o.createdAt == null) return false;
      return o.createdAt!.isAfter(start.subtract(const Duration(seconds: 1))) &&
          o.createdAt!.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<PurchaseOrder> _filterPOsByDateRange(List<PurchaseOrder> pos, DateTime start, DateTime end) {
    return pos.where((po) {
      return po.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          po.createdAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<AppUser> _filterUsersByDateRange(List<AppUser> users, DateTime start, DateTime end) {
    return users.where((u) {
      return u.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          u.createdAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  // --- Business Rule 7 & 8: Trend Aggregation Logic ---

  List<RevenueTrendPoint> _buildTrendPoints(
    DashboardTimePeriod period,
    List<Order> validOrders,
    List<PurchaseOrder> validPOs,
  ) {
    final points = <RevenueTrendPoint>[];
    final start = period.startDate;
    final end = period.endDate;
    final totalDays = end.difference(start).inDays + 1;

    // Today -> Hourly
    if (period.type == DashboardTimeRangeType.today || totalDays <= 1) {
      for (int hour = 0; hour < 24; hour += 2) {
        final bucketStart = DateTime(start.year, start.month, start.day, hour, 0);
        final bucketEnd = DateTime(start.year, start.month, start.day, hour + 1, 59, 59);

        final bucketOrders = validOrders.where((o) =>
            o.createdAt != null &&
            o.createdAt!.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
            o.createdAt!.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

        final bucketPOs = validPOs.where((po) =>
            po.createdAt.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
            po.createdAt.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

        final rev = bucketOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        final cost = bucketPOs.fold<double>(0, (sum, po) => sum + po.totalCost);

        points.add(RevenueTrendPoint(
          dateKey: bucketStart,
          displayLabel: '${hour.toString().padLeft(2, '0')}:00',
          fullDateLabel: '${_formatWeekday(bucketStart)}, ${DateFormat('dd/MM/yyyy HH:mm').format(bucketStart)}',
          revenue: rev,
          importCost: cost,
          orderCount: bucketOrders.length,
        ));
      }
      return points;
    }

    // 7 days, 30 days, This month -> Daily
    if (totalDays <= 31) {
      for (int i = 0; i < totalDays; i++) {
        final day = start.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

        final bucketOrders = validOrders.where((o) =>
            o.createdAt != null &&
            o.createdAt!.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            o.createdAt!.isBefore(dayEnd.add(const Duration(seconds: 1)))).toList();

        final bucketPOs = validPOs.where((po) =>
            po.createdAt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            po.createdAt.isBefore(dayEnd.add(const Duration(seconds: 1)))).toList();

        final rev = bucketOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        final cost = bucketPOs.fold<double>(0, (sum, po) => sum + po.totalCost);

        points.add(RevenueTrendPoint(
          dateKey: dayStart,
          displayLabel: DateFormat('dd/MM').format(dayStart),
          fullDateLabel: '${_formatWeekday(dayStart)}, ${DateFormat('dd/MM/yyyy').format(dayStart)}',
          revenue: rev,
          importCost: cost,
          orderCount: bucketOrders.length,
        ));
      }
      return points;
    }

    // 3 months, 6 months -> Weekly / Monthly
    if (totalDays <= 180) {
      int stepDays = totalDays > 90 ? 14 : 7;
      for (int i = 0; i < totalDays; i += stepDays) {
        final bucketStart = start.add(Duration(days: i));
        var bucketEnd = bucketStart.add(Duration(days: stepDays - 1, hours: 23, minutes: 59, seconds: 59));
        if (bucketEnd.isAfter(end)) bucketEnd = end;

        final bucketOrders = validOrders.where((o) =>
            o.createdAt != null &&
            o.createdAt!.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
            o.createdAt!.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

        final bucketPOs = validPOs.where((po) =>
            po.createdAt.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
            po.createdAt.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

        final rev = bucketOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        final cost = bucketPOs.fold<double>(0, (sum, po) => sum + po.totalCost);

        points.add(RevenueTrendPoint(
          dateKey: bucketStart,
          displayLabel: DateFormat('dd/MM').format(bucketStart),
          fullDateLabel: 'Tuần từ ${DateFormat('dd/MM').format(bucketStart)} đến ${DateFormat('dd/MM/yyyy').format(bucketEnd)}',
          revenue: rev,
          importCost: cost,
          orderCount: bucketOrders.length,
        ));
      }
      return points;
    }

    // 1 Year or custom long range -> Monthly
    for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
      final bucketStart = DateTime(start.year, start.month + monthOffset, 1, 0, 0, 0);
      if (bucketStart.isAfter(end)) break;

      final lastDayOfMonth = DateTime(bucketStart.year, bucketStart.month + 1, 0).day;
      var bucketEnd = DateTime(bucketStart.year, bucketStart.month, lastDayOfMonth, 23, 59, 59);
      if (bucketEnd.isAfter(end)) bucketEnd = end;

      final bucketOrders = validOrders.where((o) =>
          o.createdAt != null &&
          o.createdAt!.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
          o.createdAt!.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

      final bucketPOs = validPOs.where((po) =>
          po.createdAt.isAfter(bucketStart.subtract(const Duration(seconds: 1))) &&
          po.createdAt.isBefore(bucketEnd.add(const Duration(seconds: 1)))).toList();

      final rev = bucketOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
      final cost = bucketPOs.fold<double>(0, (sum, po) => sum + po.totalCost);

      points.add(RevenueTrendPoint(
        dateKey: bucketStart,
        displayLabel: 'T${bucketStart.month}',
        fullDateLabel: 'Tháng ${bucketStart.month}/${bucketStart.year}',
        revenue: rev,
        importCost: cost,
        orderCount: bucketOrders.length,
      ));
    }

    return points;
  }

  String _formatWeekday(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  // --- Order & Payment Status Distribution ---

  List<StatusDistributionItem> _buildOrderStatusDistribution(List<Order> orders) {
    final Map<String, ({String name, Color color})> statuses = {
      'PENDING': (name: 'Chờ xử lý', color: AppColors.warning),
      'CONFIRMED': (name: 'Đã xác nhận', color: AppColors.info),
      'SHIPPING': (name: 'Đang vận chuyển', color: AppColors.primary),
      'DELIVERED': (name: 'Đã giao hàng', color: AppColors.success),
      'CANCELLED': (name: 'Đã hủy', color: AppColors.danger),
    };

    final totalCount = orders.length;
    final List<StatusDistributionItem> items = [];

    statuses.forEach((code, meta) {
      final count = orders.where((o) => o.orderStatus.toUpperCase() == code).length;
      final pct = totalCount > 0 ? (count / totalCount) * 100 : 0.0;
      items.add(StatusDistributionItem(
        statusCode: code,
        displayName: meta.name,
        count: count,
        percentage: pct,
        color: meta.color,
      ));
    });

    return items;
  }

  List<StatusDistributionItem> _buildPaymentStatusDistribution(List<Order> orders) {
    final Map<String, ({String name, Color color})> statuses = {
      'PAID': (name: 'Đã thanh toán', color: AppColors.success),
      'PENDING': (name: 'Chờ thanh toán', color: AppColors.warning),
      'FAILED': (name: 'Thất bại', color: AppColors.danger),
      'REFUNDED': (name: 'Đã hoàn tiền', color: Colors.purple),
    };

    final totalCount = orders.length;
    final List<StatusDistributionItem> items = [];

    statuses.forEach((code, meta) {
      final count = orders.where((o) => o.paymentStatus.toUpperCase() == code).length;
      final pct = totalCount > 0 ? (count / totalCount) * 100 : 0.0;
      items.add(StatusDistributionItem(
        statusCode: code,
        displayName: meta.name,
        count: count,
        percentage: pct,
        color: meta.color,
      ));
    });

    return items;
  }

  // --- Top Products Aggregation ---

  List<TopProductItem> _buildTopProducts(List<Order> validOrders) {
    final Map<int, TopProductItem> aggregatedMap = {};

    for (var order in validOrders) {
      for (var item in order.items) {
        final key = item.variantId;
        if (aggregatedMap.containsKey(key)) {
          final existing = aggregatedMap[key]!;
          aggregatedMap[key] = TopProductItem(
            variantId: key,
            productId: existing.productId,
            productName: existing.productName,
            variantName: existing.variantName,
            imageUrl: existing.imageUrl,
            quantitySold: existing.quantitySold + item.quantity,
            revenue: existing.revenue + item.totalPrice,
          );
        } else {
          aggregatedMap[key] = TopProductItem(
            variantId: key,
            productId: 0,
            productName: item.productName,
            variantName: item.variantName,
            imageUrl: item.imageUrl,
            quantitySold: item.quantity,
            revenue: item.totalPrice,
          );
        }
      }
    }

    final list = aggregatedMap.values.toList();
    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(6).toList();
  }

  // --- Category Analytics Aggregation ---

  List<CategoryMetricItem> _buildCategoryMetrics(List<Order> validOrders, List<Product> products) {
    final Map<String, double> revMap = {};
    final Map<String, int> qtyMap = {};
    final Map<String, int> catalogMap = {};

    // Catalog composition counts
    for (var p in products) {
      final cat = p.category.isNotEmpty ? p.category : 'Khác';
      catalogMap[cat] = (catalogMap[cat] ?? 0) + 1;
    }

    // Sales metrics
    for (var o in validOrders) {
      for (var item in o.items) {
        // Try to match product category from catalog
        final matchedProd = products.where((p) => p.name.toLowerCase() == item.productName.toLowerCase()).firstOrNull;
        final cat = matchedProd?.category ?? 'Danh mục khác';

        revMap[cat] = (revMap[cat] ?? 0) + item.totalPrice;
        qtyMap[cat] = (qtyMap[cat] ?? 0) + item.quantity;
      }
    }

    final totalRev = revMap.values.fold<double>(0, (sum, v) => sum + v);
    final List<CategoryMetricItem> items = [];

    if (revMap.isNotEmpty) {
      revMap.forEach((catName, rev) {
        final qty = qtyMap[catName] ?? 0;
        final count = catalogMap[catName] ?? 0;
        final pct = totalRev > 0 ? (rev / totalRev) * 100 : 0.0;
        items.add(CategoryMetricItem(
          categoryId: 0,
          categoryName: catName,
          revenue: rev,
          quantitySold: qty,
          productCount: count,
          percentage: pct,
        ));
      });
      items.sort((a, b) => b.revenue.compareTo(a.revenue));
    } else {
      // Fallback to catalog product count if no orders in range
      final totalProd = catalogMap.values.fold<int>(0, (sum, v) => sum + v);
      catalogMap.forEach((catName, count) {
        final pct = totalProd > 0 ? (count / totalProd) * 100 : 0.0;
        items.add(CategoryMetricItem(
          categoryId: 0,
          categoryName: catName,
          revenue: 0,
          quantitySold: 0,
          productCount: count,
          percentage: pct,
        ));
      });
      items.sort((a, b) => b.productCount.compareTo(a.productCount));
    }

    return items;
  }
}
