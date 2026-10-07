import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/order.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final VoidCallback onBack;
  final VoidCallback onOrderUpdated;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.onBack,
    required this.onOrderUpdated,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late Order _currentOrder;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _fetchFullDetail();
  }

  Future<void> _fetchFullDetail() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    setState(() => _isLoadingDetails = true);
    final detailed = await apiService.getOrderById(_currentOrder.orderId, token: token);
    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
        if (detailed != null) {
          _currentOrder = detailed;
        }
      });
    }
  }

  void _showUpdateStatusDialog() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    // Determine allowed next statuses based on current status
    List<String> nextStatuses = [];
    switch (_currentOrder.orderStatus.toUpperCase()) {
      case 'PENDING':
        nextStatuses = ['CONFIRMED', 'CANCELLED'];
        break;
      case 'CONFIRMED':
        nextStatuses = ['SHIPPING', 'CANCELLED'];
        break;
      case 'SHIPPING':
        nextStatuses = ['DELIVERED'];
        break;
      default:
        nextStatuses = [];
    }

    if (nextStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đơn hàng ở trạng thái "${_currentOrder.orderStatusDisplay}" không thể chuyển tiếp trạng thái.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    String selectedStatus = nextStatuses.first;
    String selectedPaymentStatus = _currentOrder.paymentStatus;
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(dialogCtx).isDarkMode;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            title: Row(
              children: [
                const Icon(Icons.edit_road_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: AppTokens.space8),
                Text('Cập nhật tiến trình đơn ${_currentOrder.orderCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái tiến trình mới (*)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                    ),
                    items: nextStatuses.map((st) {
                      String label = st;
                      if (st == 'CONFIRMED') label = 'CONFIRMED - Đã xác nhận đơn hàng';
                      if (st == 'SHIPPING') label = 'SHIPPING - Đã chuyển đơn vị vận chuyển';
                      if (st == 'DELIVERED') label = 'DELIVERED - Khách đã nhận hàng thành công';
                      if (st == 'CANCELLED') label = 'CANCELLED - Hủy đơn hàng';
                      return DropdownMenuItem(value: st, child: Text(label, style: const TextStyle(fontSize: 12.5)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.space12),

                  Text('Trạng thái thanh toán (*)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPaymentStatus,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('PENDING - Chờ thanh toán', style: TextStyle(fontSize: 12.5))),
                      DropdownMenuItem(value: 'PAID', child: Text('PAID - Đã thanh toán thành công', style: TextStyle(fontSize: 12.5))),
                      DropdownMenuItem(value: 'FAILED', child: Text('FAILED - Thanh toán thất bại', style: TextStyle(fontSize: 12.5))),
                      DropdownMenuItem(value: 'REFUNDED', child: Text('REFUNDED - Đã hoàn tiền', style: TextStyle(fontSize: 12.5))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPaymentStatus = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.space12),

                  if (selectedStatus == 'CANCELLED') ...[
                    Text('Lý do hủy đơn (*)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do hủy đơn...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Lưu ý: Hủy đơn sẽ tự động hoàn tồn kho và hoàn voucher về ví khách hàng trên Backend.',
                              style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              AppButton(
                label: 'Quay lại',
                variant: AppButtonVariant.secondary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              ),
              AppButton(
                label: isSubmitting ? 'Đang lưu...' : 'Xác nhận cập nhật',
                variant: AppButtonVariant.primary,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (selectedStatus == 'CANCELLED' && reasonCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do hủy đơn hàng.'), backgroundColor: AppColors.danger),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final res = await apiService.updateOrderStatus(
                          _currentOrder.orderId,
                          status: selectedStatus,
                          paymentStatus: selectedPaymentStatus,
                          reason: reasonCtrl.text.trim(),
                          token: token,
                        );

                        if (mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? AppColors.success : AppColors.danger,
                            ),
                          );
                          if (res.success) {
                            widget.onOrderUpdated();
                            _fetchFullDetail();
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelOrderDialog() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(dialogCtx).isDarkMode;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            title: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
                const SizedBox(width: AppTokens.space8),
                Text('Hủy đơn hàng ${_currentOrder.orderCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn có chắc chắn muốn hủy đơn hàng ${_currentOrder.orderCode}?',
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppTokens.space12),

                  // Warning Notice
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thao tác này sẽ hủy đơn hàng. Hệ thống sẽ tự động xử lý hoàn tồn kho và voucher theo nghiệp vụ backend.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.danger, height: 1.3, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  Text('Lý do hủy đơn hàng (*)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: TextStyle(color: textPrimary, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do chi tiết hủy đơn (Ví dụ: Khách báo hủy, hết hàng trong kho, sai thông tin nhận hàng...)',
                      hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              AppButton(
                label: 'Quay lại',
                variant: AppButtonVariant.secondary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              ),
              AppButton(
                label: isSubmitting ? 'Đang hủy...' : 'Xác nhận hủy',
                variant: AppButtonVariant.danger,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do hủy đơn hàng.'), backgroundColor: AppColors.danger),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final res = await apiService.cancelOrder(
                          _currentOrder.orderId,
                          reason: reasonCtrl.text.trim(),
                          token: token,
                        );

                        if (mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? AppColors.success : AppColors.danger,
                            ),
                          );
                          if (res.success) {
                            widget.onOrderUpdated();
                            _fetchFullDetail();
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb Header
                  Row(
                    children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Đơn hàng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      Text('  /  ', style: TextStyle(color: textSecondary, fontSize: 13)),
                      Text(
                        _currentOrder.orderCode,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),

                  // Section A: ORDER HEADER BAR
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _currentOrder.orderCode,
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildOrderStatusBadge(_currentOrder.orderStatus),
                                  const SizedBox(width: 8),
                                  _buildPaymentStatusBadge(_currentOrder.paymentStatus),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ngày đặt: ${_currentOrder.createdAt != null ? dateFormat.format(_currentOrder.createdAt!) : "N/A"} • Cập nhật gần nhất: ${_currentOrder.updatedAt != null ? dateFormat.format(_currentOrder.updatedAt!) : "N/A"}',
                                style: TextStyle(color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (_currentOrder.orderStatus != 'DELIVERED' && _currentOrder.orderStatus != 'CANCELLED') ...[
                              AppButton(
                                label: 'Cập nhật tiến trình',
                                icon: Icons.edit_road_rounded,
                                variant: AppButtonVariant.primary,
                                onPressed: _showUpdateStatusDialog,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_currentOrder.canCancel) ...[
                              AppButton(
                                label: 'Hủy đơn hàng',
                                icon: Icons.cancel_outlined,
                                variant: AppButtonVariant.danger,
                                onPressed: _showCancelOrderDialog,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  // Main 2-column Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Customer & Shipping + Order Items
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            // Section B: CUSTOMER & SHIPPING
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Thông tin giao hàng & Khách hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  _buildInfoRow('Người nhận:', _currentOrder.receiverName, textPrimary, textSecondary),
                                  _buildInfoRow('Số điện thoại:', _currentOrder.receiverPhone, textPrimary, textSecondary),
                                  _buildInfoRow('Địa chỉ giao hàng:', _currentOrder.shippingAddress, textPrimary, textSecondary),
                                  if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty)
                                    _buildInfoRow('Ghi chú khách hàng:', _currentOrder.notes!, textPrimary, textSecondary),
                                  if (_currentOrder.customerEmail != 'N/A' && _currentOrder.customerEmail.isNotEmpty)
                                    _buildInfoRow('Email tài khoản:', _currentOrder.customerEmail, textPrimary, textSecondary),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.space16),

                            // Section F: ORDER ITEMS TABLE
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Danh sách sản phẩm (${_currentOrder.items.length} mặt hàng, ${_currentOrder.totalQuantity} món)',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.space12),

                                  DataTableContainer(
                                    isScrollableTable: true,
                                    child: DataTable(
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 50,
                                      dataRowMaxHeight: 56,
                                      columnSpacing: 12,
                                      horizontalMargin: 10,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Ảnh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                        DataColumn(label: Text('Sản phẩm & Biến thể', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                        DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                        DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                        DataColumn(label: Text('KM SP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                        DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
                                      ],
                                      rows: _currentOrder.items.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  item.imageUrl ?? '',
                                                  width: 38,
                                                  height: 38,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Container(
                                                    width: 38,
                                                    height: 38,
                                                    color: Colors.black12,
                                                    child: const Icon(Icons.devices, size: 20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (item.variantName.isNotEmpty && item.variantName != 'Phiên bản tiêu chuẩn')
                                                    Text(
                                                      'Phân loại: ${item.variantName}',
                                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(currencyFormat.format(item.unitPrice), style: TextStyle(fontSize: 12, color: textPrimary)),
                                            ),
                                            DataCell(
                                              Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textPrimary)),
                                            ),
                                            DataCell(
                                              item.hasPromotion
                                                  ? Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '-${currencyFormat.format(item.promotionDiscount)}',
                                                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                                                        ),
                                                        if (item.promotionName != null)
                                                          Text(item.promotionName!, style: TextStyle(fontSize: 9.5, color: textSecondary)),
                                                      ],
                                                    )
                                                  : Text('-', style: TextStyle(color: textSecondary, fontSize: 11)),
                                            ),
                                            DataCell(
                                              Text(
                                                currencyFormat.format(item.totalPrice),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTokens.space16),

                      // Right Column: Summary + Payment + Voucher + Cancellation Info
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            // Section C: ORDER SUMMARY
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Tổng quan giá trị đơn hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  _buildSummaryRow('Tạm tính tiền hàng (Subtotal):', currencyFormat.format(_currentOrder.subtotalAmount), textPrimary, textSecondary),
                                  if (_currentOrder.voucherDiscountAmount > 0)
                                    _buildSummaryRow('Giảm giá từ Voucher:', '-${currencyFormat.format(_currentOrder.voucherDiscountAmount)}', AppColors.success, textSecondary),
                                  if (_currentOrder.totalSavings > 0)
                                    _buildSummaryRow('Tổng tiết kiệm được:', currencyFormat.format(_currentOrder.totalSavings), AppColors.info, textSecondary),
                                  const Divider(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Tổng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                                      Text(
                                        currencyFormat.format(_currentOrder.totalAmount),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.space16),

                            // Section D: PAYMENT INFORMATION
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.payment_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Thông tin Thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  _buildInfoRow('Phương thức thanh toán:', _currentOrder.paymentMethodDisplay, textPrimary, textSecondary),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Trạng thái thanh toán:', style: TextStyle(color: textSecondary, fontSize: 12)),
                                        _buildPaymentStatusBadge(_currentOrder.paymentStatus),
                                      ],
                                    ),
                                  ),
                                  _buildInfoRow(
                                    'Thời điểm thanh toán:',
                                    _currentOrder.paidAt != null ? dateFormat.format(_currentOrder.paidAt!) : 'Chưa thanh toán',
                                    textPrimary,
                                    textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.space16),

                            // Section E: VOUCHER INFORMATION
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Mã giảm giá Voucher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  if (_currentOrder.voucherId != null || _currentOrder.voucherCode != null) ...[
                                    _buildInfoRow('Mã Voucher:', _currentOrder.voucherCode ?? 'N/A', AppColors.primary, textSecondary, isBoldValue: true),
                                    if (_currentOrder.voucherTitle != null)
                                      _buildInfoRow('Tên chương trình:', _currentOrder.voucherTitle!, textPrimary, textSecondary),
                                    _buildInfoRow('Số tiền giảm:', '-${currencyFormat.format(_currentOrder.voucherDiscountAmount)}', AppColors.success, textSecondary, isBoldValue: true),
                                  ] else
                                    Text('Không sử dụng voucher cho đơn hàng này', style: TextStyle(color: textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.space16),

                            // Section G: CANCELLATION INFORMATION (Only if cancelled)
                            if (_currentOrder.cancelledAt != null || _currentOrder.orderStatus == 'CANCELLED') ...[
                              Container(
                                padding: const EdgeInsets.all(AppTokens.space16),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                  border: Border.all(color: AppColors.dangerBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, color: AppColors.danger, size: 18),
                                        SizedBox(width: 6),
                                        Text('Thông tin Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.danger)),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    _buildInfoRow(
                                      'Thời điểm hủy:',
                                      _currentOrder.cancelledAt != null ? dateFormat.format(_currentOrder.cancelledAt!) : 'N/A',
                                      AppColors.danger,
                                      textSecondary,
                                    ),
                                    _buildInfoRow(
                                      'Lý do hủy đơn:',
                                      _currentOrder.cancellationReason ?? 'Không ghi rõ lý do',
                                      textPrimary,
                                      textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppTokens.space16),

                            // Section H: AUDIT TRAIL
                            Container(
                              padding: const EdgeInsets.all(AppTokens.space16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Dấu vết kiểm toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  _buildInfoRow('Người tạo:', _currentOrder.createdByName ?? 'Khách hàng tự đặt', textPrimary, textSecondary),
                                  _buildInfoRow('Cập nhật lần cuối:', _currentOrder.updatedByName ?? 'Hệ thống', textPrimary, textSecondary),
                                ],
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
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color labelColor, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: textColor, fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const StatusBadge(label: 'PENDING - Chờ xử lý', isWarning: true);
      case 'CONFIRMED':
        return const StatusBadge(label: 'CONFIRMED - Đã xác nhận', isInfo: true);
      case 'SHIPPING':
        return const StatusBadge(label: 'SHIPPING - Đang giao', isInfo: true);
      case 'DELIVERED':
        return const StatusBadge(label: 'DELIVERED - Đã giao', isSuccess: true);
      case 'CANCELLED':
        return const StatusBadge(label: 'CANCELLED - Đã hủy', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const StatusBadge(label: 'PAID - Đã thanh toán', isSuccess: true);
      case 'PENDING':
        return const StatusBadge(label: 'PENDING - Chờ thanh toán', isWarning: true);
      case 'REFUNDED':
        return const StatusBadge(label: 'REFUNDED - Đã hoàn tiền', isInfo: true);
      case 'FAILED':
        return const StatusBadge(label: 'FAILED - Thất bại', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }
}
