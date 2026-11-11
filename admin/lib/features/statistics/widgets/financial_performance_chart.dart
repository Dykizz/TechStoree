import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/statistics_models.dart';

class FinancialPerformanceChart extends StatefulWidget {
  final List<FinancialMatrixRow> rows;
  final int selectedYear;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const FinancialPerformanceChart({
    super.key,
    required this.rows,
    required this.selectedYear,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<FinancialPerformanceChart> createState() => _FinancialPerformanceChartState();
}

class _FinancialPerformanceChartState extends State<FinancialPerformanceChart> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  int _touchedGroupIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final revRow = widget.rows.firstWhere(
      (r) => r.metricName == 'Tổng thu',
      orElse: () => const FinancialMatrixRow(metricName: 'Tổng thu', q1: 0, q2: 0, q3: 0, q4: 0),
    );
    final expRow = widget.rows.firstWhere(
      (r) => r.metricName == 'Tổng chi',
      orElse: () => const FinancialMatrixRow(metricName: 'Tổng chi', q1: 0, q2: 0, q3: 0, q4: 0),
    );
    final profitRow = widget.rows.firstWhere(
      (r) => r.isProfit,
      orElse: () => const FinancialMatrixRow(metricName: 'Lợi nhuận', q1: 0, q2: 0, q3: 0, q4: 0, isProfit: true),
    );

    // Chuyển đổi sang đơn vị Triệu VNĐ (M)
    final qRevs = [revRow.q1 / 1000000, revRow.q2 / 1000000, revRow.q3 / 1000000, revRow.q4 / 1000000];
    final qExps = [expRow.q1 / 1000000, expRow.q2 / 1000000, expRow.q3 / 1000000, expRow.q4 / 1000000];
    final qProfits = [profitRow.q1 / 1000000, profitRow.q2 / 1000000, profitRow.q3 / 1000000, profitRow.q4 / 1000000];

    // Xác định giá trị cực đại dương và cực đại âm
    double maxPositive = 1.0;
    double maxNegative = 0.0;

    for (int i = 0; i < 4; i++) {
      if (qRevs[i] > maxPositive) maxPositive = qRevs[i];
      if (qExps[i] > maxPositive) maxPositive = qExps[i];
      if (qProfits[i] > maxPositive) maxPositive = qProfits[i];
      if (qProfits[i] < 0 && qProfits[i].abs() > maxNegative) {
        maxNegative = qProfits[i].abs();
      }
    }

    final scale = _calculateYAxisScale(maxPositive, maxNegative);
    final quarterLabels = ['Quý 1', 'Quý 2', 'Quý 3', 'Quý 4'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor.withValues(alpha: widget.isDark ? 0.6 : 0.8)),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF64748B).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề & Chú thích kết hợp (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biểu đồ Hoạt động kinh doanh 4 Quý (Năm ${widget.selectedYear})',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Đơn vị: Triệu VNĐ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.chartRevenue, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Tổng thu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                          const SizedBox(width: 12),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.chartCost, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Tổng chi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                          const SizedBox(width: 12),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Lợi nhuận (Lãi)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                          if (maxNegative > 0) ...[
                            const SizedBox(width: 12),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('Lợi nhuận âm (Lỗ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart kết hợp cả 3 cột (Thu, Chi, Lợi nhuận) và hỗ trợ giá trị âm
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                minY: scale.minY,
                maxY: scale.maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => widget.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    tooltipBorder: BorderSide(color: widget.borderColor.withValues(alpha: 0.5), width: 1),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final qName = quarterLabels[group.x.toInt()];
                      String label;
                      double rawVal;
                      Color itemColor;

                      if (rodIndex == 0) {
                        label = 'Tổng thu';
                        rawVal = qRevs[groupIndex] * 1000000;
                        itemColor = const Color(0xFF93C5FD);
                      } else if (rodIndex == 1) {
                        label = 'Tổng chi';
                        rawVal = qExps[groupIndex] * 1000000;
                        itemColor = const Color(0xFFFDBA74);
                      } else {
                        label = 'Lợi nhuận';
                        rawVal = qProfits[groupIndex] * 1000000;
                        itemColor = rawVal >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
                      }

                      final prefix = (rodIndex == 2 && rawVal > 0) ? '+' : '';
                      final note = (rodIndex == 2 && rawVal < 0) ? ' (Lỗ)' : '';

                      return BarTooltipItem(
                        '$qName (${widget.selectedYear})\n$label: $prefix${currencyFormat.format(rawVal)}$note',
                        TextStyle(color: itemColor, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                        _touchedGroupIndex = -1;
                      } else {
                        _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: scale.interval,
                  getDrawingHorizontalLine: (val) {
                    final isZero = val.abs() < 0.01;
                    return FlLine(
                      color: isZero
                          ? (widget.isDark ? Colors.white60 : const Color(0xFF475569))
                          : widget.borderColor.withValues(alpha: 0.4),
                      strokeWidth: isZero ? 1.5 : 1.0,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: scale.interval,
                      getTitlesWidget: (val, meta) {
                        final remainder = (val / scale.interval).roundToDouble() * scale.interval - val;
                        if (remainder.abs() > 0.05 || val < scale.minY || val > scale.maxY) {
                          return const SizedBox.shrink();
                        }
                        final isZero = val.abs() < 0.01;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '${val.toInt()}', // CHỈ ĐỂ SỐ, KHÔNG KÈM 'M'
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isZero ? FontWeight.bold : FontWeight.normal,
                                color: isZero ? widget.textPrimary : widget.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < quarterLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              quarterLabels[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _touchedGroupIndex == idx ? FontWeight.bold : FontWeight.w600,
                                color: _touchedGroupIndex == idx ? AppColors.primary : widget.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) {
                  final revM = qRevs[i];
                  final expM = qExps[i];
                  final profitM = qProfits[i];
                  final isProfitPositive = profitM >= 0;

                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      // Cột 1: Tổng thu
                      BarChartRodData(
                        toY: revM,
                        color: AppColors.chartRevenue,
                        width: 15,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      // Cột 2: Tổng chi
                      BarChartRodData(
                        toY: expM,
                        color: AppColors.chartCost,
                        width: 15,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      // Cột 3: Lợi nhuận (Lãi đi lên từ 0, Lỗ đi xuống âm dưới vạch 0)
                      BarChartRodData(
                        toY: profitM,
                        color: isProfitPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 15,
                        borderRadius: isProfitPositive
                            ? const BorderRadius.vertical(top: Radius.circular(4))
                            : const BorderRadius.vertical(bottom: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({double maxY, double minY, double interval}) _calculateYAxisScale(double maxPositive, double maxNegative) {
    if (maxPositive <= 0 && maxNegative <= 0) {
      return (maxY: 10.0, minY: 0.0, interval: 2.0);
    }

    final maxVal = math.max(maxPositive, maxNegative);
    const targetDivisions = 4.0;
    final rawInterval = (maxVal * 1.15) / targetDivisions;
    final exponent = (math.log(rawInterval) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final residual = rawInterval / magnitude;

    double step;
    if (residual <= 1.2) {
      step = 1.0 * magnitude;
    } else if (residual <= 2.5) {
      step = 2.0 * magnitude;
    } else if (residual <= 5.0) {
      step = 5.0 * magnitude;
    } else {
      step = 10.0 * magnitude;
    }

    if (step < 1.0) step = 1.0;

    double niceMax = (maxPositive / step).ceil() * step;
    if (niceMax - maxPositive < step * 0.12) {
      niceMax += step;
    }
    if (niceMax <= 0) niceMax = step;

    double niceMin = 0.0;
    if (maxNegative > 0) {
      niceMin = -(maxNegative / step).ceil() * step;
      if (maxNegative - niceMin.abs() < step * 0.12) {
        niceMin -= step;
      }
    }

    return (maxY: niceMax, minY: niceMin, interval: step);
  }
}
