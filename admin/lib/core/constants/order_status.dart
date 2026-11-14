import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Metadata chuẩn cho từng trạng thái tiến trình đơn hàng (nguồn sự thật duy nhất ở Admin).
class OrderStatusMeta {
  final String code;
  final String label;
  final Color color;

  const OrderStatusMeta({
    required this.code,
    required this.label,
    required this.color,
  });
}

/// Bảng ánh xạ thống nhất tên hiển thị và màu sắc theo mã trạng thái đơn hàng.
class OrderStatusCatalog {
  OrderStatusCatalog._();

  static const List<OrderStatusMeta> all = [
    OrderStatusMeta(code: 'PENDING', label: 'Chờ xử lý', color: AppColors.warning),
    OrderStatusMeta(code: 'CONFIRMED', label: 'Đã xác nhận', color: Color(0xFF0284C7)),
    OrderStatusMeta(code: 'SHIPPING', label: 'Đang vận chuyển', color: Color(0xFF6366F1)),
    OrderStatusMeta(code: 'DELIVERED', label: 'Đã giao hàng', color: AppColors.success),
    OrderStatusMeta(code: 'RETURNED', label: 'Hoàn hàng', color: Color(0xFFF97316)),
    OrderStatusMeta(code: 'CANCELLED', label: 'Đã hủy', color: AppColors.danger),
  ];

  static final Map<String, OrderStatusMeta> _byCode = {
    for (final item in all) item.code: item,
  };

  static OrderStatusMeta? find(String status) => _byCode[status.toUpperCase()];

  static String labelOf(String status) => find(status)?.label ?? status;

  static Color accentColorOf(String status, {Color fallback = AppColors.primary}) =>
      find(status)?.color ?? fallback;

  static List<Map<String, String>> buildFilterTabs() => [
        {'key': 'ALL', 'label': 'Tất cả'},
        for (final item in all) {'key': item.code, 'label': item.label},
      ];
}

