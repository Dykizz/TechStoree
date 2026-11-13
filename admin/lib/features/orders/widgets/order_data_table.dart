import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/smooth_loading_wrapper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import '../../../core/widgets/status_badge.dart';

/// Bảng dữ liệu danh sách đơn hàng (7 cột chuẩn, phân trang và các nút thao tác nhanh)
class OrderDataTable extends StatelessWidget {
  final List<Order> orders;
  final bool isLoading;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;
  final ValueChanged<Order> onSelectOrder;
  final ValueChanged<Order> onQuickConfirm;
  final ValueChanged<Order> onQuickShip;
  final ValueChanged<Order> onQuickDeliver;
  final ValueChanged<Order> onPrintPackingSlip;

  const OrderDataTable({
    super.key,
    required this.orders,
    required this.isLoading,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
    required this.onSelectOrder,
    required this.onQuickConfirm,
    required this.onQuickShip,
    required this.onQuickDeliver,
    required this.onPrintPackingSlip,
  });

  String _currentOrderCode(Order order) =>
      order.orderCode.isNotEmpty ? order.orderCode : '#${order.orderId}';

  @override
  Widget build(BuildContext context) {
    return SmoothLoadingWrapper(
      isLoading: isLoading,
      hasData: orders.isNotEmpty,
      initialMinHeight: 420,
      child: _buildTableContent(context),
    );
  }

  Widget _buildTableContent(BuildContext context) {

    if (orders.isEmpty) {
      return const DataTableContainer(
        child: EmptyState(
          title: 'Không tìm thấy đơn hàng nào',
          message: 'Không có đơn hàng nào khớp với điều kiện lọc hiện tại.',
          icon: Icons.shopping_bag_outlined,
        ),
      );
    }

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return DataTableContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScrollableTableWrapper(
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 52,
              columnSpacing: 14,
              horizontalMargin: 14,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
              dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
                }
                if (states.contains(WidgetState.hovered)) {
                  return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
                }
                return null;
              }),
              columns: [
                DataColumn(label: Text('Mã đơn hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Trạng thái đơn', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('TT Thanh toán', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
              ],
              rows: orders.map((order) {
                return DataRow(
                  onSelectChanged: (_) => onSelectOrder(order),
                  cells: [
                    DataCell(
                      Text(
                        _currentOrderCode(order),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.receiverName.isNotEmpty ? order.receiverName : 'Khách vãng lai',
                            style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (order.receiverPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              order.receiverPhone,
                              style: TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    DataCell(_buildOrderStatusBadge(order.orderStatus)),
                    DataCell(_buildPaymentStatusBadge(order.paymentStatus)),
                    DataCell(
                      Text(
                        currencyFormat.format(order.totalAmount),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                    DataCell(
                      Text(
                        order.createdAt != null ? dateFormat.format(order.createdAt!) : 'N/A',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (authProvider.can('Orders.UpdateStatus')) ...[
                            if (order.orderStatus.toUpperCase() == 'PENDING') ...[
                              AppButton(
                                label: 'Duyệt',
                                icon: Icons.check_circle_outline_rounded,
                                variant: AppButtonVariant.primary,
                                onPressed: () => onQuickConfirm(order),
                              ),
                              const SizedBox(width: 4),
                            ] else if (order.orderStatus.toUpperCase() == 'CONFIRMED') ...[
                              AppButton(
                                label: 'Đóng gói',
                                icon: Icons.local_shipping_outlined,
                                variant: AppButtonVariant.primary,
                                onPressed: () => onQuickShip(order),
                              ),
                              const SizedBox(width: 4),
                            ] else if (order.orderStatus.toUpperCase() == 'SHIPPING') ...[
                              AppButton(
                                label: 'Đã giao',
                                icon: Icons.task_alt_rounded,
                                variant: AppButtonVariant.outline,
                                onPressed: () => onQuickDeliver(order),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ],
                          IconButton(
                            icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                            tooltip: 'In phiếu đóng gói',
                            onPressed: () => onPrintPackingSlip(order),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (totalItems > 0)
            AppPagination(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              itemsPerPage: pageSize,
              onPageChanged: onPageChanged,
              onItemsPerPageChanged: onItemsPerPageChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toUpperCase()) {
      case 'PENDING':
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        label = 'Chờ xử lý';
        break;
      case 'CONFIRMED':
        bg = const Color(0xFF0284C7).withAlpha(30);
        fg = const Color(0xFF0284C7);
        label = 'Đã xác nhận';
        break;
      case 'SHIPPING':
        bg = const Color(0xFF6366F1).withAlpha(30);
        fg = const Color(0xFF6366F1);
        label = 'Đang giao';
        break;
      case 'DELIVERED':
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        label = 'Đã giao';
        break;
      case 'RETURNED':
        bg = const Color(0xFFF97316).withAlpha(30);
        fg = const Color(0xFFF97316);
        label = 'Hoàn hàng';
        break;
      case 'CANCELLED':
        bg = AppColors.danger.withAlpha(30);
        fg = AppColors.danger;
        label = 'Đã hủy';
        break;
      default:
        bg = Colors.grey.withAlpha(30);
        fg = Colors.grey;
        label = status;
    }
    return StatusBadge(label: label, color: fg, backgroundColor: bg);
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toUpperCase()) {
      case 'PENDING':
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        label = 'Chờ TT';
        break;
      case 'PAID':
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        label = 'Đã TT';
        break;
      case 'FAILED':
        bg = AppColors.danger.withAlpha(30);
        fg = AppColors.danger;
        label = 'Thất bại';
        break;
      case 'REFUNDED':
        bg = const Color(0xFF8B5CF6).withAlpha(30);
        fg = const Color(0xFF8B5CF6);
        label = 'Hoàn tiền';
        break;
      default:
        bg = Colors.grey.withAlpha(30);
        fg = Colors.grey;
        label = status;
    }
    return StatusBadge(label: label, color: fg, backgroundColor: bg);
  }
}

