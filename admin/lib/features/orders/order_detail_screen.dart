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
import '../invoices/widgets/invoice_detail_dialog.dart';
import '../../core/widgets/status_badge.dart';
import 'widgets/packing_slip_dialog.dart';

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
        nextStatuses = ['DELIVERED', 'RETURNED', 'CANCELLED'];
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
                    initialValue: selectedStatus,
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
                      if (st == 'RETURNED') label = 'RETURNED - Hoàn hàng / Giao thất bại';
                      if (st == 'CANCELLED') label = 'CANCELLED - Hủy đơn hàng';
                      return DropdownMenuItem(value: st, child: Text(label, style: const TextStyle(fontSize: 12.5)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.space12),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lưu ý: Đơn thanh toán trực tuyến (VNPAY/Ngân hàng) đã ghi nhận thanh toán thành công. Đối với đơn COD, sau khi giao thành công, bấm "Xác nhận thanh toán COD" khi đối soát tiền thu hộ.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),

                  if (selectedStatus == 'RETURNED') ...[
                    Text('Lý do hoàn hàng / giao thất bại (*)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do hoàn hàng (Khách không nhận, sai địa chỉ, giao 3 lần không thành công...)...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.assignment_return_outlined, size: 16, color: AppColors.warning),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Lưu ý: Hoàn hàng sẽ tự động khôi phục số lượng tồn kho nguyên tử và hoàn trả voucher vào ví khách hàng.',
                              style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        if (selectedStatus == 'RETURNED' && reasonCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do hoàn hàng / giao thất bại.'), backgroundColor: AppColors.danger),
                          );
                          return;
                        }
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
                          reason: reasonCtrl.text.trim(),
                          token: token,
                        );

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
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

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
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

  void _showInvoiceForCurrentOrder() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final invoice = await apiService.getInvoiceByOrderId(_currentOrder.orderId, token: token);
    if (!mounted) return;

    if (invoice != null) {
      showDialog(
        context: context,
        builder: (ctx) => InvoiceDetailDialog(invoice: invoice),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đơn hàng ${_currentOrder.orderCode} chưa có hóa đơn được tạo trong hệ thống.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showCodReconciliationDialog() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final noteCtrl = TextEditingController();
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
                const Icon(Icons.price_check_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: 8),
                Text('Xác nhận thanh toán COD đơn ${_currentOrder.orderCode}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số tiền COD cần thu từ ĐVVC:',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600)),
                              Text(currencyFormat.format(_currentOrder.totalAmount),
                                  style: const TextStyle(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text('Xác nhận tiền thu hộ COD đã được thu thành công và chuyển vào tài khoản doanh nghiệp. Trạng thái thanh toán của đơn hàng sẽ chuyển thành PAID (Đã thanh toán).',
                      style: TextStyle(fontSize: 12, color: textPrimary, height: 1.35)),
                  const SizedBox(height: AppTokens.space12),
                  Text('Ghi chú thanh toán:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú thanh toán (nếu có)...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              AppButton(
                label: 'Hủy bỏ',
                variant: AppButtonVariant.secondary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              ),
              AppButton(
                label: isSubmitting ? 'Đang lưu...' : 'Xác nhận đã nhận tiền',
                variant: AppButtonVariant.primary,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final res = await apiService.updateOrderPaymentStatus(
                          _currentOrder.orderId,
                          paymentStatus: 'PAID',
                          note: noteCtrl.text.trim(),
                          token: token,
                        );

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
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
    final authProvider = Provider.of<AuthProvider>(context);
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
                            if (_currentOrder.orderStatus != 'CANCELLED' && _currentOrder.orderStatus != 'RETURNED')
                              AppButton(
                                label: 'In phiếu đóng gói',
                                icon: Icons.print_rounded,
                                variant: AppButtonVariant.outline,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => PackingSlipDialog(orders: [_currentOrder]),
                                  );
                                },
                              ),
                            if (authProvider.can('Invoices.View')) ...[
                              const SizedBox(width: 8),
                              AppButton(
                                label: 'Xem hóa đơn',
                                icon: Icons.receipt_long_rounded,
                                variant: AppButtonVariant.outline,
                                onPressed: _showInvoiceForCurrentOrder,
                              ),
                            ],
                            if (authProvider.can('Orders.UpdateStatus') &&
                                _currentOrder.paymentMethod.toUpperCase() == 'COD' &&
                                _currentOrder.orderStatus.toUpperCase() == 'DELIVERED' &&
                                _currentOrder.paymentStatus.toUpperCase() != 'PAID') ...[
                              const SizedBox(width: 8),
                              AppButton(
                                label: 'Xác nhận thanh toán COD',
                                icon: Icons.price_check_rounded,
                                variant: AppButtonVariant.primary,
                                onPressed: _showCodReconciliationDialog,
                              ),
                            ],
                            if (authProvider.can('Orders.UpdateStatus') &&
                                _currentOrder.orderStatus != 'DELIVERED' &&
                                _currentOrder.orderStatus != 'CANCELLED' &&
                                _currentOrder.orderStatus != 'RETURNED') ...[
                              const SizedBox(width: 8),
                              AppButton(
                                label: 'Cập nhật tiến trình',
                                icon: Icons.edit_road_rounded,
                                variant: AppButtonVariant.primary,
                                onPressed: _showUpdateStatusDialog,
                              ),
                            ],
                            if (authProvider.can('Orders.Cancel') && _currentOrder.canCancel) ...[
                              const SizedBox(width: 8),
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

                  // Section: ORDER STEPPER TIMELINE
                  _buildOrderTimeline(isDark, textPrimary, textSecondary, borderColor, surfaceColor),
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
                                                child: (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                                                    ? Image.network(
                                                        item.imageUrl!.trim(),
                                                        width: 38,
                                                        height: 38,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (c, e, s) => Container(
                                                          width: 38,
                                                          height: 38,
                                                          color: isDark ? const Color(0xFF334155) : Colors.black12,
                                                          child: const Icon(Icons.devices, size: 20),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 38,
                                                        height: 38,
                                                        color: isDark ? const Color(0xFF334155) : Colors.black12,
                                                        child: const Icon(Icons.devices, size: 20),
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
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (item.hasPromotion && item.originalPrice > item.unitPrice)
                                                    Text(
                                                      currencyFormat.format(item.originalPrice),
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        color: textSecondary,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  Text(
                                                    currencyFormat.format(item.unitPrice),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: (item.hasPromotion && item.originalPrice > item.unitPrice)
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textPrimary)),
                                            ),
                                            DataCell(
                                              item.hasPromotion && item.promotionDiscount > 0
                                                  ? Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '-${currencyFormat.format(item.promotionDiscount)}/sp',
                                                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                                                        ),
                                                        if (item.promotionName != null && item.promotionName!.isNotEmpty)
                                                          Text(
                                                            item.promotionName!,
                                                            style: TextStyle(fontSize: 9.5, color: textSecondary),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
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
                                  if (_currentOrder.totalSavings > 0) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                        border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.savings_outlined, size: 16, color: AppColors.success),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Đã tiết kiệm ${currencyFormat.format(_currentOrder.totalSavings)} từ khuyến mãi & voucher',
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                      Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
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
                                    _currentOrder.paidAt != null
                                        ? dateFormat.format(_currentOrder.paidAt!)
                                        : (_currentOrder.paymentStatus.toUpperCase() == 'PAID'
                                            ? 'Đã thanh toán'
                                            : 'Chưa thanh toán'),
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
                                      Text('Mã giảm giá voucher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
                                    ],
                                  ),
                                  const Divider(height: 20),

                                  if (_currentOrder.voucherId != null || _currentOrder.voucherCode != null) ...[
                                    _buildInfoRow('Mã voucher:', _currentOrder.voucherCode ?? 'N/A', AppColors.primary, textSecondary, isBoldValue: true),
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
                                      _currentOrder.cancellationReason ?? 'N/A',
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

                                  _buildInfoRow('Người tạo:', _currentOrder.createdByName ?? 'N/A', textPrimary, textSecondary),
                                  _buildInfoRow('Cập nhật lần cuối:', _currentOrder.updatedByName ?? 'Chưa cập nhật', textPrimary, textSecondary),
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

  Widget _buildOrderTimeline(bool isDark, Color textPrimary, Color textSecondary, Color borderColor, Color surfaceColor) {
    final status = _currentOrder.orderStatus.toUpperCase();
    final isCancelled = status == 'CANCELLED';
    final isReturned = status == 'RETURNED';

    bool step1Done = true;
    bool step2Done = !isCancelled && ['CONFIRMED', 'SHIPPING', 'DELIVERED', 'RETURNED'].contains(status);
    bool step3Done = !isCancelled && ['SHIPPING', 'DELIVERED', 'RETURNED'].contains(status);
    bool step4Done = ['DELIVERED', 'RETURNED', 'CANCELLED'].contains(status);

    int currentStepIndex = 0;
    if (status == 'PENDING') {
      currentStepIndex = 0;
    } else if (status == 'CONFIRMED') {
      currentStepIndex = 1;
    } else if (status == 'SHIPPING') {
      currentStepIndex = 2;
    } else if (status == 'DELIVERED' || status == 'RETURNED' || status == 'CANCELLED') {
      currentStepIndex = 3;
    }

    final steps = [
      {
        'title': 'Đặt hàng',
        'subtitle': _currentOrder.createdAt != null ? dateFormat.format(_currentOrder.createdAt!) : 'Đã tạo',
        'icon': Icons.shopping_bag_outlined,
        'done': step1Done,
        'active': currentStepIndex == 0,
        'isFail': false,
      },
      {
        'title': 'Xác nhận đơn',
        'subtitle': isCancelled ? 'Không thực hiện' : (step2Done ? 'Đã duyệt đơn' : 'Chờ duyệt'),
        'icon': Icons.assignment_turned_in_outlined,
        'done': step2Done,
        'active': !isCancelled && currentStepIndex == 1,
        'isFail': false,
      },
      {
        'title': 'Đang vận chuyển',
        'subtitle': isCancelled ? 'Không thực hiện' : (step3Done ? 'Đã giao cho ĐVVC' : 'Chờ đóng gói & giao'),
        'icon': Icons.local_shipping_outlined,
        'done': step3Done,
        'active': !isCancelled && currentStepIndex == 2,
        'isFail': false,
      },
      {
        'title': isCancelled
            ? 'Đã hủy đơn'
            : (isReturned ? 'Hoàn hàng' : 'Giao thành công'),
        'subtitle': isCancelled
            ? (_currentOrder.cancelledAt != null ? dateFormat.format(_currentOrder.cancelledAt!) : 'Đã hủy hoàn kho')
            : (isReturned
                ? 'Giao thất bại / Hoàn kho'
                : (status == 'DELIVERED' ? 'Khách đã nhận hàng' : 'Chờ giao đến khách')),
        'icon': isCancelled
            ? Icons.cancel_outlined
            : (isReturned ? Icons.assignment_return_outlined : Icons.check_circle_outline),
        'done': step4Done,
        'active': currentStepIndex == 3,
        'isFail': isCancelled || isReturned,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20, vertical: AppTokens.space16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tiến trình xử lý đơn hàng',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textPrimary),
                  ),
                ],
              ),
              _buildOrderStatusBadge(_currentOrder.orderStatus),
            ],
          ),
          const SizedBox(height: AppTokens.space16),

          // Horizontal Stepper
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: _buildTimelineStepItem(
                    stepIndex: i + 1,
                    title: steps[i]['title'] as String,
                    subtitle: steps[i]['subtitle'] as String,
                    icon: steps[i]['icon'] as IconData,
                    isDone: steps[i]['done'] as bool,
                    isActive: steps[i]['active'] as bool,
                    isFail: steps[i]['isFail'] as bool,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
                if (i < steps.length - 1)
                  _buildTimelineConnector(
                    isPassed: !isCancelled && ((steps[i + 1]['done'] as bool) || (steps[i + 1]['active'] as bool)),
                    isFail: !isCancelled && (steps[i + 1]['isFail'] as bool) && (steps[i + 1]['done'] as bool),
                    isCancelled: isCancelled,
                    isDark: isDark,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStepItem({
    required int stepIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDone,
    required bool isActive,
    required bool isFail,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    Color iconBgColor;
    Color iconColor;
    Color borderColor;

    if (isFail) {
      iconBgColor = AppColors.dangerBg;
      iconColor = AppColors.danger;
      borderColor = AppColors.danger;
    } else if (isDone) {
      iconBgColor = AppColors.success.withValues(alpha: 0.15);
      iconColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (isActive) {
      iconBgColor = AppColors.primary.withValues(alpha: 0.15);
      iconColor = AppColors.primary;
      borderColor = AppColors.primary;
    } else {
      iconBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      iconColor = textSecondary;
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    }

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isActive ? 2.5 : 1.5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (isFail ? AppColors.danger : AppColors.primary).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: isFail ? AppColors.danger : (isActive || isDone ? textPrimary : textSecondary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isFail ? AppColors.danger : textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector({
    required bool isPassed,
    required bool isFail,
    required bool isCancelled,
    required bool isDark,
  }) {
    Color lineColor;
    if (isCancelled) {
      lineColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    } else if (isFail) {
      lineColor = AppColors.danger;
    } else if (isPassed) {
      lineColor = AppColors.success;
    } else {
      lineColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    }

    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 34, left: 4, right: 4),
        color: lineColor,
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
      case 'RETURNED':
        return const StatusBadge(label: 'RETURNED - Hoàn hàng / Giao thất bại', isDanger: true);
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
        return const StatusBadge(
          label: 'PENDING - Chờ thanh toán',
          isWarning: true,
        );
      case 'REFUNDED':
        return const StatusBadge(label: 'REFUNDED - Đã hoàn tiền', isInfo: true);
      case 'FAILED':
        return const StatusBadge(label: 'FAILED - Thất bại', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }
}
