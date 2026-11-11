import 'package:intl/intl.dart';

/// Bộ định dạng tiền tệ chuẩn kèm ký hiệu đơn vị "đ" (ví dụ: "2.650.000.000 đ")
class NumberDisplayFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  static String format(num value) {
    if (value == 0) return '0 đ';
    final formatted = _formatter.format(value.round()).replaceAll(',', '.');
    return '$formatted đ';
  }

  static String formatWithoutUnit(num value) {
    if (value == 0) return '0';
    final formatted = _formatter.format(value.round()).replaceAll(',', '.');
    return formatted;
  }
}

/// Dòng số liệu thống kê tài chính (Bảng a - Hoạt động kinh doanh)
class FinancialMatrixRow {
  final String metricName;
  final double q1;
  final double q2;
  final double q3;
  final double q4;
  final bool isProfit;

  const FinancialMatrixRow({
    required this.metricName,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    this.isProfit = false,
  });

  double get total => q1 + q2 + q3 + q4;
}

/// Dòng số liệu thống kê doanh số nhân viên (Bảng b)
class StaffSalesMatrixRow {
  final String staffCode;
  final String staffName;
  final String roleTitle;
  final String? email;
  final double q1;
  final double q2;
  final double q3;
  final double q4;

  const StaffSalesMatrixRow({
    required this.staffCode,
    required this.staffName,
    required this.roleTitle,
    this.email,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });

  double get total => q1 + q2 + q3 + q4;
}

/// Dòng số liệu thống kê doanh số sản phẩm qua các năm (Bảng c)
class ProductSalesMatrixRow {
  final String productCode;
  final String sku;
  final String productName;
  final String categoryName;
  final String imageUrl;
  final double y2024;
  final double y2025;
  final double y2026;

  const ProductSalesMatrixRow({
    required this.productCode,
    this.sku = '',
    required this.productName,
    required this.categoryName,
    this.imageUrl = '',
    required this.y2024,
    required this.y2025,
    required this.y2026,
  });

  double get total => y2024 + y2025 + y2026;
}

/// Thẻ tóm lược chỉ số tài chính (KPI điều hành cho Tab 1)
class FinancialSummaryKpi {
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double profitMargin; // % Lợi nhuận ròng
  final double? prevYearRevenue;
  final double? revenueGrowthRate; // % YoY
  final String peakQuarter; // 'Q1', 'Q2', 'Q3', 'Q4'
  final double peakQuarterRevenue;

  const FinancialSummaryKpi({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.profitMargin,
    this.prevYearRevenue,
    this.revenueGrowthRate,
    required this.peakQuarter,
    required this.peakQuarterRevenue,
  });
}

/// Dòng số liệu doanh số sản phẩm theo 4 Quý trong năm (Tab 3 - Chế độ Quý)
class ProductQuarterlySalesMatrixRow {
  final String productCode;
  final String sku;
  final String productName;
  final String categoryName;
  final String imageUrl;
  final double q1;
  final double q2;
  final double q3;
  final double q4;

  const ProductQuarterlySalesMatrixRow({
    required this.productCode,
    this.sku = '',
    required this.productName,
    required this.categoryName,
    this.imageUrl = '',
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });

  double get total => q1 + q2 + q3 + q4;
}

/// Dòng số liệu thống kê doanh số theo Loại sản phẩm (Tab 4 - Danh mục)
class CategorySalesMatrixRow {
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final int productCount;
  final double q1;
  final double q2;
  final double q3;
  final double q4;
  final double y2024;
  final double y2025;
  final double y2026;
  final double totalQuarterly;
  final double total3Years;
  final double sharePercentage; // % Đóng góp doanh thu

  const CategorySalesMatrixRow({
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.productCount,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.y2024,
    required this.y2025,
    required this.y2026,
    required this.totalQuarterly,
    required this.total3Years,
    required this.sharePercentage,
  });
}
