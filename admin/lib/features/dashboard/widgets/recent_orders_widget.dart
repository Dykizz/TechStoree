import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order.dart';
import '../../../core/widgets/status_badge.dart';

class RecentOrdersWidget extends StatelessWidget {
  final List<Order> orders;
  final ValueChanged<Order>? onOrderTap;
  final VoidCallback? onViewAll;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const RecentOrdersWidget({
    super.key,
    required this.orders,
    this.onOrderTap,
    this.onViewAll,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng gần đây',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('Danh sách 10 đơn hàng mới nhất từ hệ thống', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              if (onViewAll != null)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                )
              else
                Text(
                  '${orders.length} đơn hàng',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Chưa có đơn hàng.', style: TextStyle(fontSize: 12, color: textSecondary)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 8,
                headingRowHeight: 36,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 44,
                dividerThickness: 0.5,
                columns: [
                  DataColumn(label: Text('MÃ ĐƠN HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                  DataColumn(label: Text('KHÁCH HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                  DataColumn(numeric: true, label: Text('TỔNG TIỀN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                  DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                  DataColumn(label: Text('THANH TOÁN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                  DataColumn(label: Text('THỜI GIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                ],
                rows: orders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () => onOrderTap?.call(order),
                          child: Text(
                            order.orderCode,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          order.customerName,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ),
                      DataCell(
                        _buildOrderBadge(order.orderStatusDisplay, order.orderStatus),
                      ),
                      DataCell(
                        _buildPaymentBadge(order.paymentStatusDisplay, order.paymentStatus),
                      ),
                      DataCell(
                        Text(
                          order.createdAt != null ? dateFormat.format(order.createdAt!) : 'N/A',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderBadge(String label, String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return StatusBadge(label: label, isSuccess: true);
      case 'SHIPPING':
      case 'CONFIRMED':
        return StatusBadge(label: label, isInfo: true);
      case 'PENDING':
        return StatusBadge(label: label, isWarning: true);
      case 'CANCELLED':
        return StatusBadge(label: label, isDanger: true);
      default:
        return StatusBadge(label: label);
    }
  }

  Widget _buildPaymentBadge(String label, String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return StatusBadge(label: label, isSuccess: true);
      case 'PENDING':
        return StatusBadge(label: label, isWarning: true);
      case 'FAILED':
        return StatusBadge(label: label, isDanger: true);
      case 'REFUNDED':
        return StatusBadge(label: label, color: Colors.purple, backgroundColor: Colors.purple.withValues(alpha: 0.1));
      default:
        return StatusBadge(label: label);
    }
  }
}
