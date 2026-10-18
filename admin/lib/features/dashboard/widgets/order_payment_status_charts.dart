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
          Text(
            'Trạng thái đơn hàng & Thanh toán',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Phân bổ quy trình xử lý đơn hàng',
            style: TextStyle(fontSize: 11, color: widget.textSecondary),
          ),
          const SizedBox(height: 12),

          // Sub-Section A: Order Status Donut & Vertical Legend
          Row(
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: PieChart(
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
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: _buildOrderPieSections(),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  children: widget.orderStatuses.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.displayName,
                              style: TextStyle(fontSize: 11, color: widget.textPrimary),
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
                            style: TextStyle(fontSize: 10, color: widget.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: widget.borderColor.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 10),

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
                      Text(
                        item.displayName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.textPrimary),
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
                      backgroundColor: widget.borderColor.withValues(alpha: 0.4),
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

  List<PieChartSectionData> _buildOrderPieSections() {
    final total = widget.orderStatuses.fold<int>(0, (sum, i) => sum + i.count);
    if (total == 0) {
      return [
        PieChartSectionData(
          color: widget.borderColor,
          value: 1,
          title: '',
          radius: 18,
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
        title: item.count > 0 ? '${item.percentage.toInt()}%' : '',
        radius: isTouched ? 22.0 : 18.0,
        titleStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
