import 'package:flutter/material.dart';
import '../../../core/widgets/status_badge.dart';

/// Huy hiệu trạng thái của phiếu nhập hàng (COMPLETE / DRAFT).
class PurchaseOrderStatusBadge extends StatelessWidget {
  final String status;

  const PurchaseOrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    if (normalized == 'COMPLETE' || normalized == 'COMPLETED') {
      return const StatusBadge(label: 'COMPLETE', isSuccess: true);
    }
    if (normalized == 'CANCLE' || normalized == 'CANCEL' || normalized == 'CANCELLED') {
      return const StatusBadge(label: 'CANCLE', isDanger: true);
    }
    return const StatusBadge(label: 'DRAFT', isWarning: true);
  }
}

