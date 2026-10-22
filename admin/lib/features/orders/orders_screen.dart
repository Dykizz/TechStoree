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
import '../../core/widgets/app_date_range_picker.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final dateFormatDate = DateFormat('dd/MM/yyyy');

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedOrderStatus = 'ALL';
  String _selectedPaymentStatus = 'ALL';
  String _selectedPaymentMethod = 'ALL';
  DateTimeRange? _selectedDateRange;
  String _selectedSort = 'createdAt_desc';

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalItems = 0;
  int _totalPages = 1;

  List<Order> _orders = [];
  bool _isLoading = true;
  Order? _selectedOrderForDetail;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    setState(() => _isLoading = true);

    final sortParts = _selectedSort.split('_');
    final sortBy = sortParts[0];
    final isAscending = sortParts.length > 1 && sortParts[1] == 'asc';

    final result = await apiService.getAllOrders(
      page: _currentPage,
      pageSize: _pageSize,
      status: _selectedOrderStatus,
      paymentStatus: _selectedPaymentStatus,
      paymentMethod: _selectedPaymentMethod,
      search: _searchQuery,
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
      sortBy: sortBy,
      isAscending: isAscending,
      token: token,
    );

    if (mounted) {
      setState(() {
        _orders = result.items;
        _totalItems = result.totalItems;
        _totalPages = result.totalPages;
        _currentPage = result.page;
        _pageSize = result.pageSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      helpText: 'Khoảng thời gian đặt hàng',
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentPage = 1;
      });
      _loadOrders();
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedOrderStatus != 'ALL' ||
      _selectedPaymentStatus != 'ALL' ||
      _selectedPaymentMethod != 'ALL' ||
      _selectedDateRange != null ||
      _selectedSort != 'createdAt_desc';

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedOrderStatus = 'ALL';
      _selectedPaymentStatus = 'ALL';
      _selectedPaymentMethod = 'ALL';
      _selectedDateRange = null;
      _selectedSort = 'createdAt_desc';
      _currentPage = 1;
    });
    _loadOrders();
  }

  void _showUpdateStatusDialog(Order order) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    List<String> nextStatuses = [];
    switch (order.orderStatus.toUpperCase()) {
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
          content: Text('Đơn hàng ${_currentOrderCode(order)} ở trạng thái "${order.orderStatusDisplay}" không thể chuyển tiếp.'),
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
                Text('Cập nhật tiến trình đơn ${order.orderCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 460,
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
                      if (st == 'DELIVERED') label = 'DELIVERED - Khách đã nhận hàng';
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
                            'Trạng thái thanh toán sẽ được hệ thống tự động suy ra từ trạng thái đơn hàng (Ví dụ: Chuyển sang Đã giao hàng sẽ tự động thành Đã thanh toán).',
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
                      padding: const EdgeInsets.all(8),
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
                              'Hệ thống Backend sẽ tự động hoàn tồn kho và voucher về ví khách hàng.',
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
                          order.orderId,
                          status: selectedStatus,
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
                            _loadOrders();
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

  void _showCancelOrderDialog(Order order) {
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
                Text('Hủy đơn hàng ${order.orderCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn có chắc muốn hủy đơn ${order.orderCode}?',
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
                      hintText: 'Nhập lý do chi tiết hủy đơn hàng...',
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
                          order.orderId,
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
                            _loadOrders();
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

  String _currentOrderCode(Order o) => o.orderCode.isNotEmpty ? o.orderCode : 'ORD-${o.orderId}';

  @override
  Widget build(BuildContext context) {
    if (_selectedOrderForDetail != null) {
      return OrderDetailScreen(
        order: _selectedOrderForDetail!,
        onBack: () => setState(() => _selectedOrderForDetail = null),
        onOrderUpdated: () {
          _loadOrders();
        },
      );
    }

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Quản lý Đơn hàng',
            subtitle: 'Theo dõi, xử lý và cập nhật tiến trình đơn hàng của hệ thống TechStoree',
          ),

          // Filter Controls Bar
          FilterBar(
            searchField: AppSearchField<Order>(
              controller: _searchCtrl,
              hintText: 'Tìm theo Mã đơn, Người nhận, SĐT...',
              items: _orders,
              searchFilter: (o, q) =>
                  o.orderCode.toLowerCase().contains(q.toLowerCase()) ||
                  o.receiverName.toLowerCase().contains(q.toLowerCase()) ||
                  o.receiverPhone.contains(q),
              itemLabel: (o) => '${_currentOrderCode(o)} - ${o.receiverName}',
              itemSubtitle: (o) => '${currencyFormat.format(o.totalAmount)} • ${o.orderStatusDisplay}',
              onSelected: (o) {
                setState(() {
                  _searchQuery = o.orderCode;
                  _currentPage = 1;
                });
                _loadOrders();
              },
              onSubmitted: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
                _loadOrders();
              },
              onCleared: () {
                setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                });
                _loadOrders();
              },
            ),
            filters: [
              AppDropdown<String>(
                value: _selectedOrderStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Trạng thái đơn: Tất cả')),
                  DropdownMenuItem(value: 'PENDING', child: Text('PENDING - Chờ xử lý')),
                  DropdownMenuItem(value: 'CONFIRMED', child: Text('CONFIRMED - Đã xác nhận')),
                  DropdownMenuItem(value: 'SHIPPING', child: Text('SHIPPING - Vận chuyển')),
                  DropdownMenuItem(value: 'DELIVERED', child: Text('DELIVERED - Đã giao')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED - Đã hủy')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedOrderStatus = val;
                      _currentPage = 1;
                    });
                    _loadOrders();
                  }
                },
              ),
              AppDropdown<String>(
                value: _selectedPaymentStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('TT Thanh toán: Tất cả')),
                  DropdownMenuItem(value: 'PENDING', child: Text('PENDING - Chờ TT')),
                  DropdownMenuItem(value: 'PAID', child: Text('PAID - Đã thanh toán')),
                  DropdownMenuItem(value: 'FAILED', child: Text('FAILED - Thất bại')),
                  DropdownMenuItem(value: 'REFUNDED', child: Text('REFUNDED - Hoàn tiền')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPaymentStatus = val;
                      _currentPage = 1;
                    });
                    _loadOrders();
                  }
                },
              ),
              AppDropdown<String>(
                value: _selectedPaymentMethod,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('PT Thanh toán: Tất cả')),
                  DropdownMenuItem(value: 'COD', child: Text('COD (Khi nhận hàng)')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('Cổng VNPAY')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản NH')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPaymentMethod = val;
                      _currentPage = 1;
                    });
                    _loadOrders();
                  }
                },
              ),
            ],
            secondaryRow: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Date Range Button
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedDateRange != null
                            ? AppColors.primary
                            : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                        width: _selectedDateRange != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: _selectedDateRange != null ? AppColors.primary : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedDateRange != null
                              ? '${dateFormatDate.format(_selectedDateRange!.start)} - ${dateFormatDate.format(_selectedDateRange!.end)}'
                              : 'Khoảng ngày: Tất cả',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _selectedDateRange != null ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedDateRange != null ? textPrimary : textSecondary,
                          ),
                        ),
                        if (_selectedDateRange != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDateRange = null;
                                _currentPage = 1;
                              });
                              _loadOrders();
                            },
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sort Dropdown
                SizedBox(
                  width: 210,
                  child: AppDropdown<String>(
                    value: _selectedSort,
                    items: const [
                      DropdownMenuItem(value: 'createdAt_desc', child: Text('Sắp xếp: Mới nhất')),
                      DropdownMenuItem(value: 'createdAt_asc', child: Text('Sắp xếp: Cũ nhất')),
                      DropdownMenuItem(value: 'totalAmount_desc', child: Text('Tổng tiền: Cao → Thấp')),
                      DropdownMenuItem(value: 'totalAmount_asc', child: Text('Tổng tiền: Thấp → Cao')),
                      DropdownMenuItem(value: 'orderCode_asc', child: Text('Mã đơn: A → Z')),
                      DropdownMenuItem(value: 'orderCode_desc', child: Text('Mã đơn: Z → A')),
                      DropdownMenuItem(value: 'orderStatus_asc', child: Text('Trạng thái: A → Z')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSort = val;
                          _currentPage = 1;
                        });
                        _loadOrders();
                      }
                    },
                  ),
                ),

                // Reset Filters Button
                if (_hasActiveFilters)
                  OutlinedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 15, color: AppColors.danger),
                    label: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.dangerBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),

                // Total items badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Tổng: $_totalItems đơn hàng',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Orders List Table Container
          Flexible(
            fit: FlexFit.loose,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _orders.isEmpty
                    ? const DataTableContainer(
                        child: EmptyState(
                          title: 'Không tìm thấy đơn hàng nào',
                          message: 'Không có đơn hàng nào khớp với điều kiện lọc hiện tại.',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      )
                    : DataTableContainer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScrollableTableWrapper(
                              child: DataTable(
                                        headingRowHeight: 40,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 52,
                                        columnSpacing: 14,
                                        horizontalMargin: 14,
                                        headingRowColor: WidgetStateProperty.all(
                                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('Mã đơn hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Người nhận', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Trạng thái đơn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('PT Thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('TT Thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Tổng món', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                          DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        ],
                                        rows: _orders.map((order) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                InkWell(
                                                  onTap: () => setState(() => _selectedOrderForDetail = order),
                                                  child: Text(
                                                    _currentOrderCode(order),
                                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(order.receiverName, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                                              ),
                                              DataCell(
                                                Text(order.receiverPhone, style: TextStyle(color: textSecondary, fontSize: 12)),
                                              ),
                                              DataCell(_buildOrderStatusBadge(order.orderStatus)),
                                              DataCell(
                                                Text(order.paymentMethod, style: TextStyle(color: textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500)),
                                              ),
                                              DataCell(_buildPaymentStatusBadge(order.paymentStatus)),
                                              DataCell(
                                                Text('${order.totalQuantity} món', style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                                              ),
                                              DataCell(
                                                Text(
                                                  currencyFormat.format(order.totalAmount),
                                                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  order.createdAt != null ? dateFormat.format(order.createdAt!) : 'N/A',
                                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    AppButton(
                                                      label: 'Chi tiết',
                                                      variant: AppButtonVariant.secondary,
                                                      onPressed: () => setState(() => _selectedOrderForDetail = order),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    PopupMenuButton<String>(
                                                      icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                                                      tooltip: 'Thao tác khác',
                                                      onSelected: (val) {
                                                        if (val == 'UPDATE') {
                                                          _showUpdateStatusDialog(order);
                                                        } else if (val == 'CANCEL') {
                                                          _showCancelOrderDialog(order);
                                                        }
                                                      },
                                                      itemBuilder: (ctx) => [
                                                        const PopupMenuItem(
                                                          value: 'UPDATE',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit_road_rounded, size: 16, color: AppColors.primary),
                                                              SizedBox(width: 8),
                                                              Text('Cập nhật tiến trình', style: TextStyle(fontSize: 12)),
                                                            ],
                                                          ),
                                                        ),
                                                        if (order.canCancel)
                                                          const PopupMenuItem(
                                                            value: 'CANCEL',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                                                                SizedBox(width: 8),
                                                                Text('Hủy đơn hàng', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                            ),
                            if (_totalItems > 0)
                              AppPagination(
                                currentPage: _currentPage,
                                totalPages: _totalPages,
                                totalItems: _totalItems,
                                itemsPerPage: _pageSize,
                                onPageChanged: (page) {
                                  setState(() => _currentPage = page);
                                  _loadOrders();
                                },
                                onItemsPerPageChanged: (size) {
                                  setState(() {
                                    _pageSize = size;
                                    _currentPage = 1;
                                  });
                                  _loadOrders();
                                },
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const StatusBadge(label: 'Chờ xử lý', isWarning: true);
      case 'CONFIRMED':
        return const StatusBadge(label: 'Đã xác nhận', isInfo: true);
      case 'SHIPPING':
        return const StatusBadge(label: 'Vận chuyển', isInfo: true);
      case 'DELIVERED':
        return const StatusBadge(label: 'Đã giao', isSuccess: true);
      case 'CANCELLED':
        return const StatusBadge(label: 'Đã hủy', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const StatusBadge(label: 'Đã TT', isSuccess: true);
      case 'PENDING':
        return const StatusBadge(label: 'Chờ TT', isWarning: true);
      case 'REFUNDED':
        return const StatusBadge(label: 'Hoàn tiền', isInfo: true);
      case 'FAILED':
        return const StatusBadge(label: 'Thất bại', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }
}
