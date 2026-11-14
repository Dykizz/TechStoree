import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import 'purchase_order_status_badge.dart';

/// Khung xem nhanh thông tin phiếu nhập hàng (Purchase Order Quick View Panel)
/// Chuẩn thiết kế Adaptive Master-Detail Panel
class PurchaseOrderQuickViewPanel extends StatelessWidget {
  final PurchaseOrder purchaseOrder;
  final List<PurchaseOrderItem> items;
  final bool isLoadingItems;
  final String? itemsError;
  final VoidCallback? onRetryItems;
  final VoidCallback onClose;
  final VoidCallback onViewFullDetail;
  final VoidCallback? onEdit;

  const PurchaseOrderQuickViewPanel({
    super.key,
    required this.purchaseOrder,
    required this.items,
    this.isLoadingItems = false,
    this.itemsError,
    this.onRetryItems,
    required this.onClose,
    required this.onViewFullDetail,
    this.onEdit,
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

    final displayItems = items.isNotEmpty ? items : purchaseOrder.items;

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Panel
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
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
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 18),
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
                              purchaseOrder.poCode,
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
                          PurchaseOrderStatusBadge(status: purchaseOrder.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NCC: ${purchaseOrder.supplierName}',
                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
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

          // 2. Scrollable Body Content (co gọn theo nội dung khi ít hàng, tự cuộn khi vượt maxHeight)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(14),
              children: [
                  // --- SECTION: DANH SÁCH MẶT HÀNG NHẬP ---
                  Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'MẶT HÀNG NHẬP (${displayItems.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (isLoadingItems)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Đang tải chi tiết mặt hàng...',
                            style: TextStyle(fontSize: 11.5, color: AppColors.primary),
                          ),
                        ],
                      ),
                    )
                  else if (itemsError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            itemsError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.danger,
                            ),
                          ),
                          if (onRetryItems != null) ...[
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Thử lại',
                              icon: Icons.refresh_rounded,
                              variant: AppButtonVariant.secondary,
                              onPressed: onRetryItems,
                            ),
                          ],
                        ],
                      ),
                    )
                  else if (displayItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Text(
                        'Phiếu nhập chưa có mặt hàng nào',
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
                        itemCount: displayItems.length,
                        separatorBuilder: (ctx, i) => Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon linh kiện/thiết bị
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor, width: 0.8),
                                  ),
                                  child: const Icon(Icons.devices_other_rounded, size: 17, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),

                                // Tên mặt hàng & SL x Đơn giá
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.fullName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'SL: ${item.quantity} × ${currencyFormat.format(item.importPrice)}',
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

                                // Thành tiền dòng
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

                  const SizedBox(height: 12),

                  // --- SECTION: TỔNG KẾT TÀI CHÍNH NHẬP HÀNG ---
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryLine('Số dòng sản phẩm', '${displayItems.length} mặt hàng', textSecondary, textPrimary),
                        const SizedBox(height: 6),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'TỔNG CHI PHÍ NHẬP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyFormat.format(purchaseOrder.totalCost),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- SECTION: NHÀ CUNG CẤP & THÔNG TIN LẬP PHIẾU ---
                  Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'THÔNG TIN ĐỐI TÁC & LẬP PHIẾU',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Nhà cung cấp',
                          value: purchaseOrder.supplierName,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Người lập phiếu',
                          value: purchaseOrder.createdByName.isNotEmpty ? purchaseOrder.createdByName : 'Admin',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày tạo phiếu',
                          value: dateFormat.format(purchaseOrder.createdAt),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        if (purchaseOrder.approvedByName != null && purchaseOrder.approvedByName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            icon: Icons.verified_user_outlined,
                            label: 'Người phê duyệt',
                            value: purchaseOrder.approvedByName!,
                            textPrimary: AppColors.success,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (purchaseOrder.receivedByName != null && purchaseOrder.receivedByName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            icon: Icons.assignment_turned_in_outlined,
                            label: 'Người nhận hàng',
                            value: purchaseOrder.receivedByName!,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (purchaseOrder.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Ghi chú',
                            value: purchaseOrder.note,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Footer Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                if (purchaseOrder.isDraft && onEdit != null) ...[
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Sửa nháp',
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: onEdit,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: labelColor, fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: valueColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Khung giữ chỗ bên phải khi người dùng chưa chọn phiếu nhập nào để xem nhanh
class PurchaseOrderQuickViewPlaceholder extends StatelessWidget {
  const PurchaseOrderQuickViewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor =
        isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : AppColors.primary)
                      .withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 38,
                  color: textSecondary.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chưa chọn phiếu nhập',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấp vào một phiếu nhập trong danh sách\nđể xem nhanh chi tiết tại đây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: textSecondary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

