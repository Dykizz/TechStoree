import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_data.dart';

enum CategoryMetricType { revenue, quantity, catalogCount }

class CategoryAnalyticsWidget extends StatefulWidget {
  final List<CategoryMetricItem> categoryMetrics;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const CategoryAnalyticsWidget({
    super.key,
    required this.categoryMetrics,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<CategoryAnalyticsWidget> createState() => _CategoryAnalyticsWidgetState();
}

class _CategoryAnalyticsWidgetState extends State<CategoryAnalyticsWidget> {
  late CategoryMetricType _selectedMetric;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final hasSales = widget.categoryMetrics.any((c) => c.revenue > 0 || c.quantitySold > 0);
    _selectedMetric = hasSales ? CategoryMetricType.revenue : CategoryMetricType.catalogCount;
  }

  @override
  Widget build(BuildContext context) {
    final isFallback = _selectedMetric == CategoryMetricType.catalogCount;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFallback ? 'Phân bổ sản phẩm theo danh mục' : 'Phân bổ doanh số theo danh mục',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFallback
                          ? 'Cơ cấu danh mục sản phẩm (Chưa có đơn phát sinh)'
                          : 'Tỷ trọng đóng góp doanh số thực tế',
                      style: TextStyle(fontSize: 11, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Metric Toggle Segmented Controls
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _buildSegmentBtn('Doanh thu', CategoryMetricType.revenue),
                    _buildSegmentBtn('Số lượng', CategoryMetricType.quantity),
                    _buildSegmentBtn('Số SP', CategoryMetricType.catalogCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isFallback) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.info),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Lưu ý: Hiển thị cơ cấu số sản phẩm danh mục (không đại diện cho doanh số).',
                      style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (widget.categoryMetrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Không có dữ liệu danh mục.', style: TextStyle(fontSize: 12, color: widget.textSecondary)),
              ),
            )
          else
            ...widget.categoryMetrics.map((cat) {
              final String valDisplay;
              final double pct;

              if (_selectedMetric == CategoryMetricType.revenue) {
                valDisplay = currencyFormat.format(cat.revenue);
                pct = cat.percentage;
              } else if (_selectedMetric == CategoryMetricType.quantity) {
                valDisplay = '${cat.quantitySold} sản phẩm';
                final totalQty = widget.categoryMetrics.fold<int>(0, (sum, c) => sum + c.quantitySold);
                pct = totalQty > 0 ? (cat.quantitySold / totalQty) * 100 : 0.0;
              } else {
                valDisplay = '${cat.productCount} sản phẩm';
                final totalCount = widget.categoryMetrics.fold<int>(0, (sum, c) => sum + c.productCount);
                pct = totalCount > 0 ? (cat.productCount / totalCount) * 100 : 0.0;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              valDisplay,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.textPrimary),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '(${pct.toStringAsFixed(1)}%)',
                              style: TextStyle(fontSize: 10, color: widget.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct > 0 ? (pct / 100) : 0,
                        backgroundColor: widget.borderColor.withValues(alpha: 0.4),
                        color: AppColors.primary,
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

  Widget _buildSegmentBtn(String label, CategoryMetricType type) {
    final isSelected = _selectedMetric == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetric = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
}
