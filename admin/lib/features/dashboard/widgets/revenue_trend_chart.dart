import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

enum RevenueChartMode { all, revenueOnly, costOnly }

class RevenueTrendChart extends StatefulWidget {
  final List<RevenueTrendPoint> points;
  final bool showImportCostComparison;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const RevenueTrendChart({
    super.key,
    required this.points,
    this.showImportCostComparison = true,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const Color revenueColor = AppColors.chartRevenue;
  static const Color costColor = AppColors.chartCost;

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  RevenueChartMode _mode = RevenueChartMode.all;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return _buildEmptyState();
    }

    final showCost = widget.showImportCostComparison;
    double maxRevM = 1.0;
    double maxCostM = 1.0;

    for (var p in widget.points) {
      final revM = p.revenue / 1000000;
      final costM = p.importCost / 1000000;
      if (revM > maxRevM) maxRevM = revM;
      if (costM > maxCostM) maxCostM = costM;
    }

    double peakVal = maxRevM;
    if (showCost && _mode == RevenueChartMode.all) {
      peakVal = maxRevM > maxCostM ? maxRevM : maxCostM;
    } else if (showCost && _mode == RevenueChartMode.costOnly) {
      peakVal = maxCostM;
    }

    final scale = _calculateYAxisScale(peakVal);

    final revSpots = <FlSpot>[];
    final costSpots = <FlSpot>[];

    for (int i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      revSpots.add(FlSpot(i.toDouble(), p.revenue / 1000000));
      costSpots.add(FlSpot(i.toDouble(), p.importCost / 1000000));
    }

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
          BoxShadow(
            color: widget.isDark ? Colors.black.withValues(alpha: 0.20) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !showCost || _mode == RevenueChartMode.revenueOnly
                          ? 'Biểu đồ Doanh thu'
                          : (_mode == RevenueChartMode.costOnly ? 'Biểu đồ Chi phí nhập' : 'Doanh thu vs. Chi phí nhập hàng'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Đơn vị: Triệu VNĐ',
                          style: TextStyle(fontSize: 11, color: widget.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        if (_mode == RevenueChartMode.all || _mode == RevenueChartMode.revenueOnly) ...[
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: RevenueTrendChart.revenueColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Doanh thu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                          const SizedBox(width: 10),
                        ],
                        if (showCost && (_mode == RevenueChartMode.all || _mode == RevenueChartMode.costOnly)) ...[
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: RevenueTrendChart.costColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Chi phí nhập', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // View Mode Segmented Controls
              if (showCost)
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      _buildModeBtn('Tất cả', RevenueChartMode.all),
                      _buildModeBtn('Doanh thu', RevenueChartMode.revenueOnly, activeColor: RevenueTrendChart.revenueColor),
                      _buildModeBtn('Chi phí nhập', RevenueChartMode.costOnly, activeColor: RevenueTrendChart.costColor),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: scale.maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: scale.interval,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: widget.borderColor.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: scale.interval,
                      getTitlesWidget: (val, meta) {
                        final remainder = (val / scale.interval).roundToDouble() * scale.interval - val;
                        if (remainder.abs() > 0.05 || val < 0 || val > scale.maxY) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '${val.toInt()}',
                              style: TextStyle(fontSize: 10, color: widget.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _calculateLabelInterval(widget.points.length),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < widget.points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.points[idx].displayLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textSecondary),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => widget.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    tooltipBorder: BorderSide(
                      color: widget.borderColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx >= 0 && idx < widget.points.length) {
                          final p = widget.points[idx];
                          final isRev = spot.barIndex == 0 && _mode != RevenueChartMode.costOnly;
                          final label = isRev ? 'Doanh thu' : 'Chi phí nhập';
                          final valStr = currencyFormat.format(isRev ? p.revenue : p.importCost);
                          final orderStr = isRev ? '\nĐơn hàng: ${p.orderCount}' : '';
                          final isFirst = spot == touchedSpots.first;
                          final datePrefix = isFirst ? '${p.fullDateLabel}\n' : '';
                          return LineTooltipItem(
                            '$datePrefix$label: $valStr$orderStr',
                            TextStyle(
                              color: isRev ? const Color(0xFF93C5FD) : const Color(0xFFFDBA74),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return null;
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Revenue Line (Blue Area Gradient)
                  if (_mode == RevenueChartMode.all || _mode == RevenueChartMode.revenueOnly)
                    LineChartBarData(
                      spots: revSpots,
                      isCurved: true,
                      curveSmoothness: 0.20,
                      preventCurveOverShooting: true,
                      color: RevenueTrendChart.revenueColor,
                      barWidth: 2.4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            RevenueTrendChart.revenueColor.withValues(alpha: 0.25),
                            RevenueTrendChart.revenueColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),

                  // Import Cost Line (Orange Area Gradient)
                  if (showCost && (_mode == RevenueChartMode.all || _mode == RevenueChartMode.costOnly))
                    LineChartBarData(
                      spots: costSpots,
                      isCurved: true,
                      curveSmoothness: 0.20,
                      preventCurveOverShooting: true,
                      color: RevenueTrendChart.costColor,
                      barWidth: 2.2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            RevenueTrendChart.costColor.withValues(alpha: 0.20),
                            RevenueTrendChart.costColor.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String label, RevenueChartMode mode, {Color? activeColor}) {
    final isSelected = _mode == mode;
    final selectedColor = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? widget.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? selectedColor : widget.textSecondary,
          ),
        ),
      ),
    );
  }

  ({double maxY, double interval}) _calculateYAxisScale(double maxVal) {
    if (maxVal <= 0) return (maxY: 10.0, interval: 2.0);

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

    double niceMax = (maxVal / step).ceil() * step;
    if (niceMax - maxVal < step * 0.12) {
      niceMax += step;
    }

    return (maxY: niceMax, interval: step);
  }

  double _calculateLabelInterval(int length) {
    if (length <= 8) return 1;
    if (length <= 15) return 2;
    if (length <= 31) return 4;
    return (length / 8).ceilToDouble();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor),
      ),
      child: Center(
        child: Text(
          'Chưa có dữ liệu doanh thu trong khoảng thời gian này.',
          style: TextStyle(fontSize: 12, color: widget.textSecondary),
        ),
      ),
    );
  }
}
