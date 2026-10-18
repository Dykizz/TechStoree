import 'package:flutter/material.dart';

enum DashboardTimeRangeType {
  today,
  last7Days,
  last30Days,
  thisMonth,
  last3Months,
  last6Months,
  thisYear,
  custom,
}

extension DashboardTimeRangeTypeExtension on DashboardTimeRangeType {
  String get displayName {
    switch (this) {
      case DashboardTimeRangeType.today:
        return 'Hôm nay';
      case DashboardTimeRangeType.last7Days:
        return '7 ngày qua';
      case DashboardTimeRangeType.last30Days:
        return '30 ngày qua';
      case DashboardTimeRangeType.thisMonth:
        return 'Tháng này';
      case DashboardTimeRangeType.last3Months:
        return '3 tháng qua';
      case DashboardTimeRangeType.last6Months:
        return '6 tháng qua';
      case DashboardTimeRangeType.thisYear:
        return 'Năm nay';
      case DashboardTimeRangeType.custom:
        return 'Tùy chỉnh';
    }
  }
}

class DashboardTimePeriod {
  final DashboardTimeRangeType type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime prevStartDate;
  final DateTime prevEndDate;

  DashboardTimePeriod({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.prevStartDate,
    required this.prevEndDate,
  });

  factory DashboardTimePeriod.fromType(DashboardTimeRangeType type, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (type == DashboardTimeRangeType.custom && customRange != null) {
      final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day, 0, 0, 0);
      final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
      final duration = end.difference(start);
      final prevEnd = start.subtract(const Duration(seconds: 1));
      final prevStart = prevEnd.subtract(duration);
      return DashboardTimePeriod(
        type: type,
        startDate: start,
        endDate: end,
        prevStartDate: prevStart,
        prevEndDate: prevEnd,
      );
    }

    switch (type) {
      case DashboardTimeRangeType.today:
        final prevStart = todayStart.subtract(const Duration(days: 1));
        final prevEnd = todayEnd.subtract(const Duration(days: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: todayStart,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.last7Days:
        final start = todayStart.subtract(const Duration(days: 6));
        final prevStart = start.subtract(const Duration(days: 7));
        final prevEnd = start.subtract(const Duration(seconds: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.last30Days:
        final start = todayStart.subtract(const Duration(days: 29));
        final prevStart = start.subtract(const Duration(days: 30));
        final prevEnd = start.subtract(const Duration(seconds: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final daysInPrevMonth = DateTime(now.year, now.month, 0).day;
        final prevStart = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, 1, 0, 0, 0);
        final prevEnd = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, daysInPrevMonth, 23, 59, 59);
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.last3Months:
        final start = todayStart.subtract(const Duration(days: 89));
        final prevStart = start.subtract(const Duration(days: 90));
        final prevEnd = start.subtract(const Duration(seconds: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.last6Months:
        final start = todayStart.subtract(const Duration(days: 179));
        final prevStart = start.subtract(const Duration(days: 180));
        final prevEnd = start.subtract(const Duration(seconds: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final prevStart = DateTime(now.year - 1, 1, 1, 0, 0, 0);
        final prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );

      case DashboardTimeRangeType.custom:
        final start = todayStart.subtract(const Duration(days: 6));
        final prevStart = start.subtract(const Duration(days: 7));
        final prevEnd = start.subtract(const Duration(seconds: 1));
        return DashboardTimePeriod(
          type: type,
          startDate: start,
          endDate: todayEnd,
          prevStartDate: prevStart,
          prevEndDate: prevEnd,
        );
    }
  }
}

class DashboardMetricKpi {
  final double current;
  final double previous;
  final double? percentageChange;
  final bool isPositiveTrend;

  DashboardMetricKpi({
    required this.current,
    required this.previous,
    this.percentageChange,
    required this.isPositiveTrend,
  });

  factory DashboardMetricKpi.calculate(double current, double previous, {bool invertTrend = false}) {
    double? change;
    bool positive = true;

    if (previous > 0) {
      change = ((current - previous) / previous) * 100;
      positive = change >= 0;
    } else if (current > 0) {
      change = 100.0;
      positive = true;
    }

    if (invertTrend) {
      positive = !positive;
    }

    return DashboardMetricKpi(
      current: current,
      previous: previous,
      percentageChange: change,
      isPositiveTrend: positive,
    );
  }
}

class RevenueTrendPoint {
  final DateTime dateKey;
  final String displayLabel; // e.g. "28/09" or "14:00"
  final String fullDateLabel; // e.g. "Thứ Hai, 28/09/2026"
  final double revenue;
  final double importCost;
  final int orderCount;

  RevenueTrendPoint({
    required this.dateKey,
    required this.displayLabel,
    required this.fullDateLabel,
    required this.revenue,
    required this.importCost,
    required this.orderCount,
  });
}

class StatusDistributionItem {
  final String statusCode;
  final String displayName;
  final int count;
  final double percentage;
  final Color color;

  StatusDistributionItem({
    required this.statusCode,
    required this.displayName,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class TopProductItem {
  final int variantId;
  final int productId;
  final String productName;
  final String variantName;
  final String? imageUrl;
  final int quantitySold;
  final double revenue;

  TopProductItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    this.imageUrl,
    required this.quantitySold,
    required this.revenue,
  });

  String get fullName {
    if (variantName.isEmpty || variantName.toLowerCase() == 'phiên bản tiêu chuẩn' || variantName.toLowerCase() == 'biến thể mặc định') {
      return productName;
    }
    return '$productName ($variantName)';
  }
}

class CategoryMetricItem {
  final int categoryId;
  final String categoryName;
  final double revenue;
  final int quantitySold;
  final int productCount;
  final double percentage;

  CategoryMetricItem({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.quantitySold,
    required this.productCount,
    required this.percentage,
  });
}

class VariantInventoryAlert {
  final int productId;
  final int variantId;
  final String productName;
  final String variantName;
  final String? imageUrl;
  final int stockQuantity;
  final String statusLabel; // "Hết hàng" or "Sắp hết hàng"
  final bool isOutOfStock;

  VariantInventoryAlert({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.imageUrl,
    required this.stockQuantity,
    required this.statusLabel,
    required this.isOutOfStock,
  });

  String get fullName {
    if (variantName.isEmpty || variantName.toLowerCase() == 'phiên bản tiêu chuẩn' || variantName.toLowerCase() == 'biến thể mặc định') {
      return productName;
    }
    return '$productName ($variantName)';
  }
}

class SurveyOverviewMetric {
  final int activeSurveysCount;
  final int totalAssigned;
  final int totalCompleted;
  final double averageResponseRate;
  final List<dynamic> activeSurveys;

  SurveyOverviewMetric({
    required this.activeSurveysCount,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.averageResponseRate,
    required this.activeSurveys,
  });
}

class PromotionVoucherOverviewMetric {
  final int activePromotionsCount;
  final int activeVouchersCount;
  final int totalVouchersUsed;
  final int totalVouchersLimit;
  final double voucherUsageRate;
  final List<dynamic> topVouchers;

  PromotionVoucherOverviewMetric({
    required this.activePromotionsCount,
    required this.activeVouchersCount,
    required this.totalVouchersUsed,
    required this.totalVouchersLimit,
    required this.voucherUsageRate,
    required this.topVouchers,
  });
}
