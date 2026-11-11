import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/invoice.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/status_badge.dart';

/// Khung xem nhanh thông tin hóa đơn (Quick View Panel)
/// Thiết kế theo chuẩn Adaptive Master-Detail Panel
class InvoiceQuickViewPanel extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onClose;
  final VoidCallback onViewFullDetail;

  const InvoiceQuickViewPanel({
    super.key,
    required this.invoice,
    required this.onClose,
    required this.onViewFullDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final bgCard = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final subCardBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              invoice.invoiceCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(label: invoice.statusLabel, color: invoice.statusColor),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đơn hàng: ${invoice.orderCode}',
                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Đóng xem nhanh (ESC)',
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: textSecondary,
                    splashRadius: 16,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION: DANH SÁCH SẢN PHẨM ---
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'SẢN PHẨM (${invoice.items.length})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (invoice.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Text(
                        'Không có chi tiết mặt hàng',
                        style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoice.items.length,
                        separatorBuilder: (ctx, i) => Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final item = invoice.items[index];
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail sản phẩm
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor, width: 0.8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 20,
                                            color: textSecondary,
                                          ),
                                        )
                                      : Icon(Icons.shopping_bag_outlined, size: 20, color: textSecondary),
                                ),
                                const SizedBox(width: 10),

                                // Tên + Biến thể + Đơn giá
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.variantName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Phân loại: ${item.variantName}',
                                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                                        ),
                                      ],
                                      const SizedBox(height: 3),
                                      Text(
                                        'SL: ${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Tổng tiền dòng
                                Text(
                                  currencyFormat.format(item.totalPrice),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // --- SECTION: TỔNG KẾT TÀI CHÍNH ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryLine('Tạm tính tiền hàng', currencyFormat.format(invoice.subtotalAmount), textSecondary, textPrimary),
                        if (invoice.voucherDiscountAmount > 0) ...[
                          const SizedBox(height: 6),
                          _buildSummaryLine(
                            'Giảm giá voucher ${invoice.voucherCode != null ? "(${invoice.voucherCode})" : ""}',
                            '-${currencyFormat.format(invoice.voucherDiscountAmount)}',
                            AppColors.success,
                            AppColors.success,
                            isBold: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TỔNG THANH TOÁN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              currencyFormat.format(invoice.totalAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Phương thức', style: TextStyle(fontSize: 11, color: textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: borderColor, width: 0.8),
                              ),
                              child: Text(
                                invoice.paymentMethodLabel,
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- SECTION: THÔNG TIN NGƯỜI MUA & NHẬN HÀNG ---
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'THÔNG TIN NGƯỜI MUA',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildCustomerInfoRow(
                          icon: Icons.account_circle_outlined,
                          label: 'Khách hàng',
                          value: invoice.customerName.isNotEmpty ? invoice.customerName : 'Khách vãng lai',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 8),
                        _buildCustomerInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại',
                          value: invoice.receiverPhone.isNotEmpty ? invoice.receiverPhone : 'Chưa cập nhật',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 8),
                        _buildCustomerInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Địa chỉ giao',
                          value: invoice.shippingAddress.isNotEmpty ? invoice.shippingAddress : 'Nhận tại cửa hàng',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 8),
                        _buildCustomerInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày lập HĐ',
                          value: dateFormat.format(invoice.createdAt),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                        if (invoice.paidAt != null) ...[
                          const SizedBox(height: 8),
                          _buildCustomerInfoRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Ngày thanh toán',
                            value: dateFormat.format(invoice.paidAt!),
                            textPrimary: AppColors.success,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                          ),
                        ],
                        if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildCustomerInfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Ghi chú',
                            value: invoice.note!,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Footer Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Xem đầy đủ',
                    icon: Icons.open_in_new_rounded,
                    variant: AppButtonVariant.primary,
                    onPressed: onViewFullDetail,
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'In HĐ',
                  icon: Icons.print_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    AppToast.info(context, 'Đang chuẩn bị lệnh in cho ${invoice.invoiceCode}...');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, Color labelColor, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: labelColor,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

