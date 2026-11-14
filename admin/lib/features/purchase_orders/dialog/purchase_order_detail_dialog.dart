import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/data_table_container.dart';
import '../widgets/purchase_order_status_badge.dart';

/// Hộp thoại xem chi tiết đầy đủ phiếu nhập hàng và danh sách biến thể nhập kho.
class PurchaseOrderDetailDialog extends StatelessWidget {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final PurchaseOrder purchaseOrder;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const PurchaseOrderDetailDialog({
    super.key,
    required this.purchaseOrder,
    this.onCancel,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final po = purchaseOrder;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(
              'Chi Tiết Phiếu Nhập: ${po.poCode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          PurchaseOrderStatusBadge(status: po.status),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Nhà cung cấp',
                      po.supplierName,
                      textPrimary,
                      textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  Expanded(
                    child: _buildInfoItem(
                      'Ngày tạo',
                      AppDateFormatter.formatDateTime(po.createdAt),
                      textPrimary,
                      textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),

              // Thông tin người tạo phiếu
              Container(
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.space8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space12),
                    Expanded(
                      child: _buildInfoItem(
                        'Người tạo phiếu (Yêu cầu)',
                        po.createdByName.isNotEmpty
                            ? po.createdByName
                            : 'Thủ kho',
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (po.note.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space8),
                _buildInfoItem(
                  'Ghi chú phiếu nhập',
                  po.note,
                  textPrimary,
                  textSecondary,
                ),
              ],
              const SizedBox(height: AppTokens.space12),
              const Divider(),
              const SizedBox(height: AppTokens.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'DANH SÁCH CHI TIẾT CÁC BIẾN THỂ NHẬP KHO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Text(
                    'Tổng dòng hàng: ${po.items.length}',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space8),

              DataTableContainer(
                isScrollableTable: true,
                child: DataTable(
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  headingRowHeight: 36,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 44,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Sản phẩm',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Biến thể',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Đơn giá nhập',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Số lượng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Thành tiền',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  rows: po.items.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.productName.isNotEmpty
                                ? item.productName
                                : item.fullName,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.variantName.isNotEmpty
                                  ? item.variantName
                                  : 'Biến thể #${item.variantId}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFormat.format(item.importPrice),
                            style: TextStyle(fontSize: 11.5, color: textPrimary),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFormat.format(item.totalPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppTokens.space12),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'TỔNG CHI PHÍ PHIẾU NHẬP: ${_currencyFormat.format(po.totalCost)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (po.isDraft) ...[
          if (onCancel != null)
            AppButton(
              label: 'Xóa phiếu nháp',
              variant: AppButtonVariant.danger,
              onPressed: () {
                Navigator.pop(context);
                onCancel!();
              },
            ),
          if (onComplete != null)
            AppButton(
              label: 'Hoàn thành & Nhập kho',
              variant: AppButtonVariant.primary,
              onPressed: () {
                Navigator.pop(context);
                onComplete!();
              },
            ),
        ],
        AppButton(
          label: 'Đóng',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

