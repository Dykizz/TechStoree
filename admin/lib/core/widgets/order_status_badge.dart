import 'package:flutter/material.dart';
import '../constants/order_status.dart';
import 'status_badge.dart';

/// Huy hiệu trạng thái tiến trình đơn hàng dùng chung trên toàn hệ thống Admin.
class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = OrderStatusCatalog.find(status);
    if (meta == null) {
      return StatusBadge(label: status);
    }
    return StatusBadge(
      label: meta.label,
      color: meta.color,
      backgroundColor: meta.color.withAlpha(30),
    );
  }
}

