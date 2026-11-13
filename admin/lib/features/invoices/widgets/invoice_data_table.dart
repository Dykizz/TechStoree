import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/invoice.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import '../../../core/widgets/status_badge.dart';

/// Bảng dữ liệu danh sách hóa đơn (5 cột chuẩn, hiệu ứng chọn dòng và phân trang)
class InvoiceDataTable extends StatelessWidget {
  final List<Invoice> invoices;
  final Invoice? selectedInvoice;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;
  final ValueChanged<Invoice> onSelectInvoice;

  const InvoiceDataTable({
    super.key,
    required this.invoices,
    required this.selectedInvoice,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
    required this.onSelectInvoice,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const DataTableContainer(
        child: EmptyState(
          title: 'Không tìm thấy hóa đơn nào',
          message: 'Không có hóa đơn nào khớp với điều kiện lọc hiện tại.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

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
              dataRowMaxHeight: 56,
              horizontalMargin: 16,
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
              columns: [
                DataColumn(label: Text('Mã HĐ', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Ngày lập', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
              ],
              rows: invoices.map((inv) {
                final isSelected = selectedInvoice?.invoiceId == inv.invoiceId;
                return DataRow(
                  selected: false,
                  onSelectChanged: (_) => onSelectInvoice(inv),
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (isSelected) {
                      return isDark
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : const Color(0xFFEFF6FF);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
                    }
                    return null;
                  }),
                  cells: [
                    // Mã HĐ (kèm vạch đánh dấu khi chọn, giữ cố định layout không giật chữ)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3.5,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            inv.invoiceCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tổng tiền
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(inv.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                          ),
                          if (inv.voucherDiscountAmount > 0) ...[
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_number_outlined, size: 10, color: AppColors.success),
                                const SizedBox(width: 2),
                                Text(
                                  '-${currencyFormat.format(inv.voucherDiscountAmount)}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trạng thái hóa đơn
                    DataCell(
                      StatusBadge(
                        label: inv.statusLabel,
                        color: inv.statusColor,
                      ),
                    ),
                    // Ngày lập (2 dòng: Ngày ở trên, Giờ ở dưới)
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateFormatter.formatDate(inv.createdAt),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          Text(
                            AppDateFormatter.formatTime(inv.createdAt),
                            style: TextStyle(fontSize: 10, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Thao tác in nhanh
                    DataCell(
                      IconButton(
                        tooltip: 'In hóa đơn',
                        icon: const Icon(Icons.print_outlined, size: 18),
                        color: textSecondary,
                        onPressed: () {
                          AppToast.info(context, 'Đang chuẩn bị lệnh in cho ${inv.invoiceCode}...');
                        },
                        splashRadius: 18,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          // Phân trang
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
}

