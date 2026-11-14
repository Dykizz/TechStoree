import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import 'purchase_order_status_badge.dart';

/// Bảng danh sách phiếu nhập hàng kèm cột thao tác nhanh và thanh phân trang.
class PurchaseOrderDataTable extends StatelessWidget {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final List<PurchaseOrder> paginatedOrders;
  final int? selectedPoId;
  final int totalItems;
  final int safePage;
  final int totalPages;
  final int itemsPerPage;
  final bool canUpdate;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<PurchaseOrder> onRowTap;
  final ValueChanged<PurchaseOrder> onEdit;
  final ValueChanged<PurchaseOrder> onComplete;
  final ValueChanged<PurchaseOrder> onCancel;
  final ValueChanged<PurchaseOrder> onViewDetail;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;

  const PurchaseOrderDataTable({
    super.key,
    required this.paginatedOrders,
    required this.selectedPoId,
    required this.totalItems,
    required this.safePage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.canUpdate,
    this.errorMessage,
    this.onRetry,
    required this.onRowTap,
    required this.onEdit,
    required this.onComplete,
    required this.onCancel,
    required this.onViewDetail,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return DataTableContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ScrollableTableWrapper(
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columnSpacing: 16,
              horizontalMargin: 14,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Mã PO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nhà cung cấp',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tổng chi phí',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ngày tạo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Thao tác',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              rows: paginatedOrders.map((po) {
                final isSelected = selectedPoId == po.purchaseOrderId;
                return DataRow(
                  selected: false,
                  onSelectChanged: (_) => onRowTap(po),
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (isSelected) {
                      return isDark
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : const Color(0xFFEFF6FF);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : const Color(0xFFF8FAFC);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return isDark
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : const Color(0xFFDBEAFE);
                    }
                    return null;
                  }),
                  cells: [
                    // Mã PO kèm indicator vạch dọc khi active (cố định layout không giật vị trí chữ)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3.5,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            po.poCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Nhà cung cấp
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 165),
                        child: Text(
                          po.supplierName,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Tổng chi phí (kèm số dòng hàng bên dưới)
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currencyFormat.format(po.totalCost),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            '${po.totalItems} dòng hàng',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trạng thái
                    DataCell(PurchaseOrderStatusBadge(status: po.status)),
                    // Ngày tạo (2 dòng: Ngày ở trên, Giờ ở dưới)
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateFormatter.formatDate(po.createdAt),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            AppDateFormatter.formatTime(po.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Thao tác
                    DataCell(
                      po.isDraft && canUpdate
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Chỉnh sửa phiếu nháp',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: textSecondary,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () => onEdit(po),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Hoàn thành phiếu (COMPLETE)',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () => onComplete(po),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Xóa phiếu nháp',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.danger,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () => onCancel(po),
                                  ),
                                ),
                              ],
                            )
                          : Tooltip(
                              message: 'Xem chi tiết',
                              child: IconButton(
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  size: 17,
                                  color: textSecondary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () => onViewDetail(po),
                              ),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (totalItems > 0)
            AppPagination(
              currentPage: safePage,
              totalPages: totalPages,
              totalItems: totalItems,
              itemsPerPage: itemsPerPage,
              onPageChanged: onPageChanged,
              onItemsPerPageChanged: onItemsPerPageChanged,
            ),
        ],
      ),
    );
  }
}

