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

    double maxRevM = 1.0;
    double maxCostM = 1.0;

    for (var p in widget.points) {
      final revM = p.revenue / 1000000;
      final costM = p.importCost / 1000000;
      if (revM > maxRevM) maxRevM = revM;
      if (costM > maxCostM) maxCostM = costM;
    }

    double maxVal = maxRevM;
    if (_mode == RevenueChartMode.all) {
      maxVal = maxRevM > maxCostM ? maxRevM : maxCostM;
    } else if (_mode == RevenueChartMode.costOnly) {
      maxVal = maxCostM;
    }
    maxVal = (maxVal * 1.15).ceilToDouble();
    if (maxVal <= 0) maxVal = 10.0;

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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.borderColor),
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
                    _mode == RevenueChartMode.revenueOnly
                        ? 'Biểu đồ Doanh thu'
                        : (_mode == RevenueChartMode.costOnly ? 'Biểu đồ Chi phí nhập' : 'Doanh thu vs Chi phí nhập hàng'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đơn vị: Triệu VNĐ (Dữ liệu thực tế)',
                    style: TextStyle(fontSize: 11, color: widget.textSecondary),
                  ),
                ],
              ),

              // View Mode Segmented Controls
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        _buildModeBtn('Tất cả', RevenueChartMode.all),
                        _buildModeBtn('Doanh thu', RevenueChartMode.revenueOnly),
                        _buildModeBtn('Chi phí nhập', RevenueChartMode.costOnly),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxVal,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: widget.borderColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}M',
                          style: TextStyle(fontSize: 10, color: widget.textSecondary),
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
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx >= 0 && idx < widget.points.length) {
                          final p = widget.points[idx];
                          final isRev = spot.barIndex == 0 && _mode != RevenueChartMode.costOnly;
                          final label = isRev ? 'Doanh thu' : 'Chi phí nhập';
                          final valStr = currencyFormat.format(isRev ? p.revenue : p.importCost);
                          final orderStr = isRev ? '\nĐơn hàng: ${p.orderCount}' : '';
                          return LineTooltipItem(
                            '${p.fullDateLabel}\n$label: $valStr$orderStr',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          );
                        }
                        return null;
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Revenue Line
                  if (_mode == RevenueChartMode.all || _mode == RevenueChartMode.revenueOnly)
                    LineChartBarData(
                      spots: revSpots,
                      isCurved: true,
                      curveSmoothness: 0.15,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: 2.2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.10),
                      ),
                    ),

                  // Import Cost Line
                  if (_mode == RevenueChartMode.all || _mode == RevenueChartMode.costOnly)
                    LineChartBarData(
                      spots: costSpots,
                      isCurved: true,
                      curveSmoothness: 0.15,
                      preventCurveOverShooting: true,
                      color: AppColors.info,
                      barWidth: 2.0,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.info.withValues(alpha: 0.06),
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

  Widget _buildModeBtn(String label, RevenueChartMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : widget.textSecondary,
          ),
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(8),
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
