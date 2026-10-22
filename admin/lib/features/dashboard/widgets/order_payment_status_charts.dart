import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

class OrderPaymentStatusCharts extends StatefulWidget {
  final List<StatusDistributionItem> orderStatuses;
  final List<StatusDistributionItem> paymentStatuses;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const OrderPaymentStatusCharts({
    super.key,
    required this.orderStatuses,
    required this.paymentStatuses,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<OrderPaymentStatusCharts> createState() => _OrderPaymentStatusChartsState();
}

class _OrderPaymentStatusChartsState extends State<OrderPaymentStatusCharts> {
  int _touchedOrderIndex = -1;

  @override
  Widget build(BuildContext context) {
    final totalOrders = widget.orderStatuses.fold<int>(0, (sum, i) => sum + i.count);

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
          Text(
            'Trạng thái đơn hàng & Thanh toán',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Phân bổ quy trình xử lý đơn hàng',
            style: TextStyle(fontSize: 11, color: widget.textSecondary),
          ),
          const SizedBox(height: 14),

          // Sub-Section A: Order Status Donut with Dynamic Center & Vertical Legend
          Row(
            children: [
              SizedBox(
                height: 116,
                width: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedOrderIndex = -1;
                                return;
                              }
                              _touchedOrderIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 32,
                        sections: _buildOrderPieSections(),
                      ),
                    ),
                    _buildDonutCenter(totalOrders),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  children: widget.orderStatuses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isHighlighted = idx == _touchedOrderIndex;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _touchedOrderIndex = idx),
                      onExit: (_) => setState(() => _touchedOrderIndex = -1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isHighlighted ? item.color.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                  color: widget.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.count}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${item.percentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                color: isHighlighted ? item.color : widget.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: widget.borderColor.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),

          // Sub-Section B: Payment Status Progress Bars
          Text(
            'Trạng thái thanh toán',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.textPrimary),
          ),
          const SizedBox(height: 8),

          ...widget.paymentStatuses.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.displayName,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '${item.count} (${item.percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.percentage > 0 ? (item.percentage / 100) : 0,
                      backgroundColor: widget.borderColor.withValues(alpha: 0.35),
                      color: item.color,
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDonutCenter(int totalOrders) {
    if (_touchedOrderIndex >= 0 && _touchedOrderIndex < widget.orderStatuses.length) {
      final item = widget.orderStatuses[_touchedOrderIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${item.count}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: widget.textPrimary,
              height: 1.1,
            ),
          ),
          Text(
            '${item.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$totalOrders',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: widget.textPrimary,
            height: 1.1,
          ),
        ),
        Text(
          'Tổng đơn',
          style: TextStyle(
            fontSize: 9.5,
            color: widget.textSecondary,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildOrderPieSections() {
    final total = widget.orderStatuses.fold<int>(0, (sum, i) => sum + i.count);
    if (total == 0) {
      return [
        PieChartSectionData(
          color: widget.borderColor.withValues(alpha: 0.4),
          value: 1,
          title: '',
          radius: 16,
        )
      ];
    }

    return widget.orderStatuses.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final isTouched = idx == _touchedOrderIndex;
      return PieChartSectionData(
        color: item.color,
        value: item.count.toDouble(),
        title: '', // Keep donut clean since center displays stats
        radius: isTouched ? 20.0 : 15.0,
      );
    }).toList();
  }
}
