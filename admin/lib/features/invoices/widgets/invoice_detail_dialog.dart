import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/invoice.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class InvoiceDetailDialog extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final bgCard = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết hóa đơn bán hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.invoiceCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: invoice.statusLabel,
                    color: invoice.statusColor,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Body invoice content (Scrollable receipt view)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Receipt Header
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'TechStoree Vietnam',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Hệ thống bán lẻ & phân phối thiết bị công nghệ chính hãng',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hotline: 1900 8888 | Website: www.techstoree.vn',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: invoice.statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: invoice.statusColor, width: 1),
                                ),
                                child: Text(
                                  invoice.statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: invoice.statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mã HĐ: ${invoice.invoiceCode}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Two columns info (Customer info & Order metadata)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer
                        Expanded(
                          child: _buildInfoCard(
                            isDark: isDark,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            title: 'THÔNG TIN KHÁCH HÀNG',
                            icon: Icons.person_outline_rounded,
                            rows: [
                              _InfoRow(label: 'Tên khách hàng', value: invoice.customerName),
                              _InfoRow(label: 'Mã khách hàng (User ID)', value: '#${invoice.userId}'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Order details
                        Expanded(
                          child: _buildInfoCard(
                            isDark: isDark,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            title: 'THÔNG TIN THANH TOÁN',
                            icon: Icons.receipt_outlined,
                            rows: [
                              _InfoRow(label: 'Đơn hàng liên kết', value: invoice.orderCode, isHighlighted: true),
                              _InfoRow(label: 'Phương thức', value: invoice.paymentMethodLabel),
                              _InfoRow(label: 'Ngày lập HĐ', value: dateFormat.format(invoice.createdAt)),
                              _InfoRow(
                                label: 'Ngày thanh toán',
                                value: invoice.paidAt != null ? dateFormat.format(invoice.paidAt!) : 'Chưa ghi nhận',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Amount Summary Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TỔNG TIỀN HÓA ĐƠN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                currencyFormat.format(invoice.totalAmount),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes_rounded, size: 16, color: textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ghi chú: ${invoice.note}',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notice text
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hóa đơn điện tử này có giá trị xác nhận giao dịch thanh toán hợp lệ giữa TechStoree và khách hàng.',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer modal actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Đóng',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'In hóa đơn / Xuất PDF',
                    icon: Icons.print_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đang chuẩn bị lệnh in cho hóa đơn ${invoice.invoiceCode}...'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        r.label,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Text(
                        r.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: r.isHighlighted ? FontWeight.w700 : FontWeight.w600,
                          color: r.isHighlighted ? AppColors.primary : textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isHighlighted;

  _InfoRow({required this.label, required this.value, this.isHighlighted = false});
}
