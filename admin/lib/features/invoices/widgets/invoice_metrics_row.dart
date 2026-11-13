import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/invoice.dart';
import '../../../core/providers/theme_provider.dart';

/// Hàng 4 thẻ KPI thống kê nhanh cho màn hình Quản lý hóa đơn (cho phép click để lọc theo trạng thái)
class InvoiceMetricsRow extends StatelessWidget {
  final InvoiceStatistics? stats;
  final List<Invoice> invoices;
  final int totalItems;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  const InvoiceMetricsRow({
    super.key,
    required this.stats,
    required this.invoices,
    required this.totalItems,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final paidInvoices = invoices.where((i) => i.isPaid).toList();
    final unpaidInvoices = invoices.where((i) => i.isUnpaid).toList();
    final cancelledInvoices = invoices.where((i) => i.isCancelled).toList();

    final paidAmount = paidInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount);
    final unpaidAmount = unpaidInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final cardWidth = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            InvoiceMetricCard(
              title: 'TỔNG HÓA ĐƠN',
              value: '${stats?.totalInvoices ?? totalItems}',
              subtitle: 'Hóa đơn trong hệ thống',
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              width: cardWidth,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isSelected: selectedStatus == 'ALL',
              onTap: () => onStatusSelected('ALL'),
            ),
            InvoiceMetricCard(
              title: 'ĐÃ THANH TOÁN',
              value: '${stats?.paidCount ?? paidInvoices.length}',
              subtitle: currencyFormat.format(stats?.paidAmount ?? paidAmount),
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              width: cardWidth,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isSelected: selectedStatus == 'PAID',
              onTap: () => onStatusSelected('PAID'),
            ),
            InvoiceMetricCard(
              title: 'CHỜ THANH TOÁN',
              value: '${stats?.unpaidCount ?? unpaidInvoices.length}',
              subtitle: currencyFormat.format(stats?.unpaidAmount ?? unpaidAmount),
              icon: Icons.pending_actions_rounded,
              iconColor: AppColors.warning,
              width: cardWidth,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isSelected: selectedStatus == 'UNPAID',
              onTap: () => onStatusSelected('UNPAID'),
            ),
            InvoiceMetricCard(
              title: 'ĐÃ HỦY',
              value: '${stats?.cancelledCount ?? cancelledInvoices.length}',
              subtitle: 'Đơn bị hủy / hoàn tiền',
              icon: Icons.cancel_outlined,
              iconColor: AppColors.danger,
              width: cardWidth,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isSelected: selectedStatus == 'CANCELLED',
              onTap: () => onStatusSelected('CANCELLED'),
            ),
          ],
        );
      },
    );
  }
}

/// Thẻ chỉ số KPI riêng lẻ có hiệu ứng hover, watermark và trạng thái đang chọn
class InvoiceMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double width;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isSelected;
  final VoidCallback onTap;

  const InvoiceMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.width,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<InvoiceMetricCard> createState() => _InvoiceMetricCardState();
}

class _InvoiceMetricCardState extends State<InvoiceMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isSelected || _isHovered)
                  ? widget.iconColor.withValues(alpha: widget.isSelected ? 0.9 : 0.55)
                  : widget.borderColor.withValues(alpha: widget.isDark ? 0.6 : 0.8),
              width: widget.isSelected ? 1.6 : (_isHovered ? 1.4 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isSelected || _isHovered)
                    ? widget.iconColor.withValues(alpha: widget.isSelected ? (widget.isDark ? 0.28 : 0.16) : (widget.isDark ? 0.20 : 0.12))
                    : (widget.isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.05)),
                blurRadius: widget.isSelected ? 16 : (_isHovered ? 14 : 7),
                offset: (widget.isSelected || _isHovered) ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Biểu tượng watermark trang trí mờ ở góc dưới phải
              Positioned(
                right: -6,
                bottom: -8,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.isDark ? 0.06 : 0.045,
                    child: Icon(
                      widget.icon,
                      size: 58,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.iconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: widget.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _isHovered ? 0.9 : 0.35,
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: _isHovered ? widget.iconColor : widget.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: widget.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: widget.iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

