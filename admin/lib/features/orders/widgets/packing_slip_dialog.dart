import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_button.dart';

class PackingSlipDialog extends StatefulWidget {
  final List<Order> orders;
  final int initialIndex;

  const PackingSlipDialog({
    super.key,
    required this.orders,
    this.initialIndex = 0,
  });

  @override
  State<PackingSlipDialog> createState() => _PackingSlipDialogState();
}

class _PackingSlipDialogState extends State<PackingSlipDialog> {
  late int _currentIndex;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.orders.isEmpty ? 0 : widget.orders.length - 1);
  }

  Order get _currentOrder => widget.orders[_currentIndex];

  void _copySlipText(Order order) {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('    PHIẾU GIAO HÀNG & ĐÓNG GÓI TECHSTOREE');
    buffer.writeln('========================================');
    buffer.writeln('Mã đơn hàng: ${order.orderCode}');
    buffer.writeln('Ngày đặt: ${order.createdAt != null ? dateFormat.format(order.createdAt!) : "N/A"}');
    buffer.writeln('Trạng thái đơn: ${order.orderStatusDisplay}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('NGƯỜI GỬI: TECHSTOREE FULFILLMENT HUB');
    buffer.writeln('Hotline: 1900 8888 | Địa chỉ: Kho Logistics TechStoree, TP.HCM');
    buffer.writeln('----------------------------------------');
    buffer.writeln('NGƯỜI NHẬN: ${order.receiverName.toUpperCase()}');
    buffer.writeln('SĐT: ${order.receiverPhone}');
    buffer.writeln('Địa chỉ: ${order.shippingAddress}');
    if (order.notes != null && order.notes!.isNotEmpty) {
      buffer.writeln('Ghi chú giao: ${order.notes}');
    }
    buffer.writeln('----------------------------------------');
    final isCod = order.paymentMethod.toUpperCase() == 'COD' && order.paymentStatus.toUpperCase() != 'PAID';
    if (isCod) {
      buffer.writeln('>>> TIỀN THU HỘ (COD): ${currencyFormat.format(order.totalAmount)} <<<');
      buffer.writeln('Lưu ý: Thu đủ tiền trước khi giao kiện hàng.');
    } else {
      buffer.writeln('>>> TIỀN THU NGƯỜI NHẬN: 0 VNĐ (ĐÃ THANH TOÁN ONLINE) <<<');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('DANH SÁCH HÀNG HÓA:');
    for (int i = 0; i < order.items.length; i++) {
      final it = order.items[i];
      final variant = it.variantName.isNotEmpty ? ' [${it.variantName}]' : '';
      buffer.writeln(' ${i + 1}. ${it.productName}$variant x${it.quantity} = ${currencyFormat.format(it.totalPrice)}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('TỔNG TIỀN: ${currencyFormat.format(order.totalAmount)}');
    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép nội dung phiếu đóng gói đơn ${order.orderCode} vào clipboard.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgCard = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (widget.orders.isEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không có đơn hàng nào để in phiếu.'),
              const SizedBox(height: 16),
              AppButton(label: 'Đóng', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    final order = _currentOrder;
    final isCodPending = order.paymentMethod.toUpperCase() == 'COD' && order.paymentStatus.toUpperCase() != 'PAID';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 820),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Modal Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mẫu in Phiếu giao hàng & Đóng gói (Packing Slip)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.orders.length > 1
                              ? 'Đang xem phiếu đơn hàng ${_currentIndex + 1} / ${widget.orders.length} đơn được chọn'
                              : 'Chuẩn dán thùng hàng bưu kiện đơn ${order.orderCode}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Carousel navigation if multiple orders
                  if (widget.orders.length > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Đơn trước',
                      onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                    ),
                    Text(
                      '${_currentIndex + 1}/${widget.orders.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Đơn tiếp theo',
                      onPressed: _currentIndex < widget.orders.length - 1 ? () => setState(() => _currentIndex++) : null,
                    ),
                    const SizedBox(width: 8),
                  ],

                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Printable Packing Slip Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.space20),
                child: Center(
                  child: Container(
                    width: 700,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Slip Header: Logo & Order Barcode
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'TECHSTOREE LOGISTICS',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Trung tâm phân phối & Thương mại điện tử TechStoree',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                                const Text(
                                  'Hotline: 1900 8888 • CSKH: support@techstoree.vn',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                              ],
                            ),

                            // Pseudo Barcode & Order Code
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Simulated barcode graphic lines
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (int i = 0; i < 28; i++)
                                            Container(
                                              width: (i % 3 == 0) ? 3 : ((i % 5 == 0) ? 1.5 : 2),
                                              height: 32,
                                              margin: const EdgeInsets.symmetric(horizontal: 1),
                                              color: const Color(0xFF0F172A),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        order.orderCode,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ngày tạo: ${order.createdAt != null ? dateFormat.format(order.createdAt!) : "N/A"}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF0F172A), thickness: 1.5, height: 1.5),
                        const SizedBox(height: 14),

                        // Sender & Receiver Dual Column
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sender Box
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF475569)),
                                        SizedBox(width: 4),
                                        Text(
                                          'TỪ (NGƯỜI GỬI):',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'TechStoree Fulfillment Hub Sài Gòn',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const Text('SĐT gửi: 028.7777.8888', style: TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                                    const Text(
                                      'Địa chỉ: 123 Đường Công Nghệ, Khu CNC, TP. Thủ Đức, TP. Hồ Chí Minh',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Receiver Box (High visibility)
                            Expanded(
                              flex: 6,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.person_pin_circle_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                        SizedBox(width: 4),
                                        Text(
                                          'ĐẾN (NGƯỜI NHẬN):',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.receiverName.toUpperCase(),
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D4ED8),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            order.receiverPhone,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.shippingAddress,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.3),
                                    ),
                                    if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ghi chú: ${order.notes}',
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // COD COLLECTION HIGHLIGHT BOX (CRUCIAL FOR PACKING SLIP)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCodPending ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCodPending ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCodPending ? Icons.monetization_on_rounded : Icons.check_circle_rounded,
                                color: isCodPending ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                size: 36,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCodPending
                                          ? 'TIỀN THU NGƯỜI NHẬN (COD): ${currencyFormat.format(order.totalAmount)}'
                                          : 'ĐÃ THANH TOÁN ONLINE (KHÔNG THU TIỀN NGƯỜI NHẬN)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isCodPending ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isCodPending
                                          ? 'Shipper chú ý: Thu đủ ${currencyFormat.format(order.totalAmount)} trước khi bóc seal kiện hàng. Cho đồng kiểm số lượng.'
                                          : 'Đơn hàng đã được thanh toán qua ${order.paymentMethodDisplay}. Tuyệt đối KHÔNG thu thêm bất kỳ khoản phí nào.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isCodPending ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Order Items Table
                        const Text(
                          'DANH SÁCH SẢN PHẨM TRONG GÓI HÀNG',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 6),

                        Table(
                          border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                          columnWidths: const {
                            0: FixedColumnWidth(36),
                            1: FlexColumnWidth(4),
                            2: FlexColumnWidth(2),
                            3: FixedColumnWidth(55),
                            4: FlexColumnWidth(2),
                            5: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                              children: const [
                                Padding(padding: EdgeInsets.all(6), child: Text('STT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Phân loại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                                Padding(padding: EdgeInsets.all(6), child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Đơn giá', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)))),
                              ],
                            ),
                            ...order.items.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final item = entry.value;
                              final variantStr = item.variantName.isNotEmpty ? item.variantName : 'Mặc định';

                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(6), child: Text('$idx', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      variantStr.isEmpty ? 'Mặc định' : variantStr,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(currencyFormat.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(currencyFormat.format(item.totalPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Financial Summary sub-table
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 320,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tổng số lượng món:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    Text('${order.totalQuantity} món', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tạm tính tiền hàng:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    Text(currencyFormat.format(order.subtotalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                  ],
                                ),
                                if (order.voucherDiscountAmount > 0) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Giảm giá Voucher (${order.voucherCode ?? ""}):', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                                      Text('-${currencyFormat.format(order.voucherDiscountAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tổng tiền đơn hàng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                    Text(
                                      currencyFormat.format(order.totalAmount),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Signatures & Warehouse Verification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSignBlock('Nhân viên đóng gói', '(Ký & ghi rõ họ tên)', 'Đã kiểm hàng KCS [  ]'),
                            _buildSignBlock('Đơn vị vận chuyển', '(Ký xác nhận nhận gói)', 'Nguyên đai nguyên kiện [  ]'),
                            _buildSignBlock('Người nhận hàng', '(Ký nhận khi đã kiểm tra)', 'Đã nhận đủ hàng [  ]'),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Cảm ơn quý khách đã mua sắm tại TechStoree! Website: www.techstoree.vn',
                            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Sao chép phiếu (Text)'),
                        onPressed: () => _copySlipText(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                        ),
                      ),
                      if (widget.orders.length > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Đơn hàng ${_currentIndex + 1} / ${widget.orders.length}',
                          style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      AppButton(
                        label: 'Đóng',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: widget.orders.length > 1 ? 'In phiếu đơn này' : 'In phiếu đóng gói',
                        icon: Icons.print_rounded,
                        variant: AppButtonVariant.primary,
                        onPressed: () {
                          _copySlipText(order);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xuất bản mẫu in. Có thể nhấn Ctrl+P trên máy in hoặc dán nội dung vào máy in bưu phẩm.'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignBlock(String title, String subtitle, String checkText) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 38), // signature space
        Text(checkText, style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
