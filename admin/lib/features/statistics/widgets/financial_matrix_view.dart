import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/smooth_loading_wrapper.dart';
import '../models/statistics_models.dart';
import 'financial_performance_chart.dart';

class FinancialMatrixView extends StatelessWidget {
  final int selectedYear;
  final List<FinancialMatrixRow> rows;
  final bool isLoading;

  const FinancialMatrixView({
    super.key,
    required this.selectedYear,
    required this.rows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    final revRow = rows.firstWhere(
      (r) => r.metricName == 'Tổng thu',
      orElse: () => const FinancialMatrixRow(metricName: 'Tổng thu', q1: 0, q2: 0, q3: 0, q4: 0),
    );
    final profitRow = rows.firstWhere(
      (r) => r.isProfit,
      orElse: () => const FinancialMatrixRow(metricName: 'Lợi nhuận', q1: 0, q2: 0, q3: 0, q4: 0, isProfit: true),
    );

    final totalRev = revRow.total;
    final netProfit = profitRow.total;

    final marginQ1 = revRow.q1 > 0 ? (profitRow.q1 / revRow.q1) * 100 : 0.0;
    final marginQ2 = revRow.q2 > 0 ? (profitRow.q2 / revRow.q2) * 100 : 0.0;
    final marginQ3 = revRow.q3 > 0 ? (profitRow.q3 / revRow.q3) * 100 : 0.0;
    final marginQ4 = revRow.q4 > 0 ? (profitRow.q4 / revRow.q4) * 100 : 0.0;
    final marginTotal = totalRev > 0 ? (netProfit / totalRev) * 100 : 0.0;

    return SmoothLoadingWrapper(
      isLoading: isLoading,
      hasData: rows.isNotEmpty,
      initialMinHeight: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // 1. Biểu đồ cột nhóm Hoạt động kinh doanh 4 Quý (Thu - Chi - Lãi)
        FinancialPerformanceChart(
          rows: rows,
          selectedYear: selectedYear,
          isDark: isDark,
          cardBg: cardBg,
          borderColor: cardBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: AppTokens.space16),

        // 2. Bảng Ma trận Kế toán Doanh thu - Chi phí - Lợi nhuận (Bảng a)
        DataTableContainer(
          isScrollableTable: true,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 46,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
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
                  'Quý 1',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  'Quý 2',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  'Quý 3',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  'Quý 4',
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
                    'Tổng cộng',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 12),
                  ),
                ),
              ),
            ],
            rows: [
              ...rows.map((row) {
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
              }),

              // Dòng phụ trợ: Tỷ suất lợi nhuận (%)
              DataRow(
                color: WidgetStateProperty.all(
                  isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
                ),
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
                            'Tỷ suất lợi nhuận (%)',
                            style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Biên lãi ròng (Lợi nhuận / Doanh thu)',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text('${marginQ1.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary))),
                  DataCell(Text('${marginQ2.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary))),
                  DataCell(Text('${marginQ3.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary))),
                  DataCell(Text('${marginQ4.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${marginTotal.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),

        // 3. Chú thích kế toán
        Text(
          '* Ghi chú: Dữ liệu được tính toán 100% từ Database thực tế. Lợi nhuận = Tổng thu (Đơn hàng DELIVERED/CONFIRMED sau khuyến mãi) - Tổng chi (Phiếu nhập COMPLETED). Đơn vị tiền tệ: VNĐ (đ).',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
        ),
      ],
      ),
    );
  }
}
