import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/data_table_container.dart';
import '../models/statistics_models.dart';

class FinancialMatrixView extends StatelessWidget {
  final int selectedYear;
  final List<int> availableYears;
  final List<FinancialMatrixRow> rows;
  final ValueChanged<int> onYearChanged;
  final bool isLoading;

  const FinancialMatrixView({
    super.key,
    required this.selectedYear,
    required this.availableYears,
    required this.rows,
    required this.onYearChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final yearsList = availableYears.contains(selectedYear)
        ? availableYears
        : [selectedYear, ...availableYears];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar ngữ cảnh của Tab 1 (Chọn năm thống kê)
        SizedBox(
          width: 160,
          child: AppDropdown<int>(
            value: selectedYear,
            labelText: 'Năm thống kê',
            items: yearsList.map((y) {
              return DropdownMenuItem<int>(
                value: y,
                child: Text('Năm $y'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onYearChanged(val);
            },
          ),
        ),
        const SizedBox(height: AppTokens.space16),

        // Bảng Ma trận Kế toán Doanh thu - Chi phí - Lợi nhuận (Bảng a)
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DataTableContainer(
            isScrollableTable: true,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 46,
              dataRowMinHeight: 54,
              dataRowMaxHeight: 54,
              columnSpacing: 28,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Chỉ tiêu tài chính (Năm $selectedYear)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    'Quý 1 (Q1)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    'Quý 2 (Q2)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    'Quý 3 (Q3)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    'Quý 4 (Q4)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TỔNG CỘNG (TC)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ],
              rows: rows.map((row) {
                final isProfit = row.isProfit;
                final isExpense = row.metricName.toLowerCase().contains('chi');
                final isPositive = row.total >= 0;
                final profitColor = isProfit
                    ? (isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C))
                    : textPrimary;

                final rowBg = isProfit
                    ? (isDark
                        ? (isPositive
                            ? const Color(0xFF0F2E1E).withValues(alpha: 0.5)
                            : const Color(0xFF3B1219).withValues(alpha: 0.5))
                        : (isPositive
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2)))
                    : null;

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                    }
                    return rowBg;
                  }),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              row.metricName,
                              style: TextStyle(
                                fontWeight: isProfit ? FontWeight.bold : FontWeight.w600,
                                color: isProfit ? profitColor : textPrimary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isProfit
                                  ? 'Thu nhập ròng (Thu - Chi)'
                                  : (isExpense ? 'Chi phí nhập kho (PO)' : 'Doanh thu bán hàng thực tế'),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberDisplayFormatter.format(row.q1),
                        style: TextStyle(
                          fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                          color: profitColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberDisplayFormatter.format(row.q2),
                        style: TextStyle(
                          fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                          color: profitColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberDisplayFormatter.format(row.q3),
                        style: TextStyle(
                          fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                          color: profitColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberDisplayFormatter.format(row.q4),
                        style: TextStyle(
                          fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                          color: profitColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isProfit
                              ? (isDark
                                  ? (isPositive ? const Color(0xFF0F2E1E) : const Color(0xFF3B1219))
                                  : (isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isProfit
                                ? (isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C))
                                : cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          NumberDisplayFormatter.format(row.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isProfit ? profitColor : textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: AppTokens.space16),
        // Chú thích công thức kế toán
        Text(
          '* Ghi chú: Dữ liệu được tính toán 100% từ Database thực tế. Lợi nhuận = Tổng thu (Đơn hàng DELIVERED/CONFIRMED sau khuyến mãi) - Tổng chi (Phiếu nhập COMPLETED). Đơn vị tiền tệ: VNĐ (đ).',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
        ),
      ],
    );
  }
}
