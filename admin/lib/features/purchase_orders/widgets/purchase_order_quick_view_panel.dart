import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

/// Khung xem nhanh thông tin phiếu nhập hàng (Purchase Order Quick View Panel)
/// Chuẩn thiết kế Adaptive Master-Detail Panel
class PurchaseOrderQuickViewPanel extends StatelessWidget {
  final PurchaseOrder purchaseOrder;
  final List<PurchaseOrderItem> items;
  final bool isLoadingItems;
  final VoidCallback onClose;
  final VoidCallback onViewFullDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const PurchaseOrderQuickViewPanel({
    super.key,
    required this.purchaseOrder,
    required this.items,
    this.isLoadingItems = false,
    required this.onClose,
    required this.onViewFullDetail,
    this.onEdit,
    this.onComplete,
    this.onCancel,
  });

  Widget _renderStatusBadge(String status) {
    final s = status.toUpperCase();
    if (s == 'COMPLETE' || s == 'COMPLETED') {
      return const StatusBadge(label: 'COMPLETE', isSuccess: true);
    } else if (s == 'CANCLE' || s == 'CANCELLED') {
      return const StatusBadge(label: 'CANCLE', isDanger: true);
    } else {
      return const StatusBadge(label: 'DRAFT', isWarning: true);
    }
  }

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
    final totalQuantity = displayItems.fold<int>(0, (sum, i) => sum + i.quantity);

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
                          _renderStatusBadge(purchaseOrder.status),
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

          // 2. Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION: DANH SÁCH MẶT HÀNG NHẬP ---
                  Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'MẶT HÀNG NHẬP (${displayItems.length})',
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
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon linh kiện/thiết bị
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor, width: 0.8),
                                  ),
                                  child: const Icon(Icons.devices_other_rounded, size: 18, color: AppColors.primary),
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

                  const SizedBox(height: 16),

                  // --- SECTION: TỔNG KẾT TÀI CHÍNH NHẬP HÀNG ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryLine('Số dòng sản phẩm', '${displayItems.length} mặt hàng', textSecondary, textPrimary),
                        const SizedBox(height: 6),
                        _buildSummaryLine('Tổng số lượng nhập', '$totalQuantity chiếc/cái', textSecondary, textPrimary),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TỔNG CHI PHÍ NHẬP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
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

                  const SizedBox(height: 16),

                  // --- SECTION: NHÀ CUNG CẤP & THÔNG TIN LẬP PHIẾU ---
                  Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'THÔNG TIN ĐỐI TÁC & LẬP PHIẾU',
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
                        _buildInfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Nhà cung cấp',
                          value: purchaseOrder.supplierName,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Người lập phiếu',
                          value: purchaseOrder.createdByName.isNotEmpty ? purchaseOrder.createdByName : 'Admin',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày tạo phiếu',
                          value: dateFormat.format(purchaseOrder.createdAt),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        if (purchaseOrder.approvedByName != null && purchaseOrder.approvedByName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.verified_user_outlined,
                            label: 'Người phê duyệt',
                            value: purchaseOrder.approvedByName!,
                            textPrimary: AppColors.success,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (purchaseOrder.receivedByName != null && purchaseOrder.receivedByName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.assignment_turned_in_outlined,
                            label: 'Người nhận hàng',
                            value: purchaseOrder.receivedByName!,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (purchaseOrder.note.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: labelColor, fontWeight: FontWeight.w400),
        ),
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

