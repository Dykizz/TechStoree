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
import 'widgets/packing_slip_dialog.dart';

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
  String _selectedDatePreset = 'ALL';
  String _selectedSort = 'createdAt_desc';

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalItems = 0;
  int _totalPages = 1;

  List<Order> _orders = [];
  bool _isLoading = true;
  Order? _selectedOrderForDetail;

  static const List<Map<String, String>> _statusTabs = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING', 'label': 'Chờ xử lý'},
    {'key': 'CONFIRMED', 'label': 'Đã xác nhận'},
    {'key': 'SHIPPING', 'label': 'Vận chuyển'},
    {'key': 'DELIVERED', 'label': 'Đã giao'},
    {'key': 'RETURNED', 'label': 'Hoàn hàng'},
    {'key': 'CANCELLED', 'label': 'Đã hủy'},
  ];

  Map<String, int> _statusCounts = {
    'ALL': 0,
    'PENDING': 0,
    'CONFIRMED': 0,
    'SHIPPING': 0,
    'DELIVERED': 0,
    'RETURNED': 0,
    'CANCELLED': 0,
  };

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

    final ordersFuture = apiService.getAllOrders(
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

    final countsFuture = apiService.getOrderStatusCounts(token: token);

    final result = await ordersFuture;
    final counts = await countsFuture;

    if (mounted) {
      // Đồng bộ số liệu trạng thái đảm bảo luôn khớp 100% với cơ sở dữ liệu
      final updatedCounts = Map<String, int>.from(_statusCounts);
      if (counts.isNotEmpty) {
        counts.forEach((k, v) => updatedCounts[k.toUpperCase()] = v);
        if (!updatedCounts.containsKey('RETURNED')) updatedCounts['RETURNED'] = 0;
      }
      // Nếu counts API rỗng hoặc chưa khớp với số lượng thực tế
      if (counts.isEmpty || (updatedCounts['ALL'] ?? 0) == 0 || (updatedCounts['ALL'] != result.totalItems && _selectedOrderStatus == 'ALL' && !_hasActiveFilters)) {
        updatedCounts['ALL'] = result.totalItems;
      }

      setState(() {
        _orders = result.items;
        _totalItems = result.totalItems;
        _totalPages = result.totalPages;
        _currentPage = result.page;
        _pageSize = result.pageSize;
        _statusCounts = updatedCounts;
        _isLoading = false;
      });
    }
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    DateTimeRange? range;

    switch (preset) {
      case 'TODAY':
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        range = DateTimeRange(start: start, end: end);
        break;
      case 'LAST_7_DAYS':
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        range = DateTimeRange(start: start, end: end);
        break;
      case 'THIS_MONTH':
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        range = DateTimeRange(start: start, end: end);
        break;
      case 'ALL':
      default:
        range = null;
        break;
    }

    setState(() {
      _selectedDatePreset = preset;
      _selectedDateRange = range;
      _currentPage = 1;
    });
    _loadOrders();
  }

  Future<void> _pickDateRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      helpText: 'Khoảng thời gian đặt hàng',
    );
    if (picked != null) {
      setState(() {
        _selectedDatePreset = 'CUSTOM';
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
      _selectedDatePreset != 'ALL' ||
      _selectedSort != 'createdAt_desc';

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedOrderStatus = 'ALL';
      _selectedPaymentStatus = 'ALL';
      _selectedPaymentMethod = 'ALL';
      _selectedDateRange = null;
      _selectedDatePreset = 'ALL';
      _selectedSort = 'createdAt_desc';
      _currentPage = 1;
    });
    _loadOrders();
  }

  Future<void> _quickConfirmOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Duyệt đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Xác nhận duyệt đơn hàng ${_currentOrderCode(order)} (chuyển sang trạng thái Đã xác nhận - CONFIRMED)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận duyệt'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await apiService.updateOrderStatus(order.orderId, status: 'CONFIRMED', token: token);
    if (mounted) {
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
  }

  Future<void> _quickShipOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Xuất kho & Giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Chuyển đơn hàng ${_currentOrderCode(order)} sang trạng thái Vận chuyển (SHIPPING) để giao bên vận chuyển?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận giao'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await apiService.updateOrderStatus(order.orderId, status: 'SHIPPING', token: token);
    if (mounted) {
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
  }

  Future<void> _quickDeliverOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Xác nhận giao thành công', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Xác nhận khách hàng đã nhận đơn hàng ${_currentOrderCode(order)} thành công (chuyển sang DELIVERED)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận đã giao'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await apiService.updateOrderStatus(order.orderId, status: 'DELIVERED', token: token);
    if (mounted) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Quản lý đơn hàng',
            subtitle: 'Theo dõi, xử lý và cập nhật tiến trình đơn hàng của hệ thống TechStoree',
          ),
          const SizedBox(height: AppTokens.space12),

          // Horizontal Status Tabs with Real-time Counters
          _buildStatusTabBar(isDark, textPrimary, textSecondary),

          // Filter Controls Bar - Redesigned Modern 2-Tier Layout
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
              AppDropdown<String>(
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
            ],
            secondaryRow: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Icon label
                  Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Thời gian:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(width: 8),

                  // Compact Segmented Pill Control
                  _buildDateSegmentedControl(isDark, textPrimary, textSecondary),
                  const SizedBox(width: 10),

                  // Date Range Button (Custom Date Range Picker)
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _selectedDateRange != null
                              ? AppColors.primary
                              : (isDark ? AppColors.darkCardBorder : const Color(0xFFCBD5E1)),
                          width: _selectedDateRange != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 14,
                            color: _selectedDateRange != null ? AppColors.primary : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedDateRange != null
                                ? '${dateFormatDate.format(_selectedDateRange!.start)} - ${dateFormatDate.format(_selectedDateRange!.end)}'
                                : 'Tùy chọn ngày...',
                            style: TextStyle(
                              fontSize: 12,
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
                                  _selectedDatePreset = 'ALL';
                                  _currentPage = 1;
                                });
                                _loadOrders();
                              },
                              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Reset Filters Button
                  if (_hasActiveFilters) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 14, color: AppColors.danger),
                      label: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dangerBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],

                  const SizedBox(width: 16),

                  // Total items badge
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Tổng: $_totalItems đơn hàng',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders List Table Container
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)))
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
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (order.orderStatus.toUpperCase() == 'PENDING') ...[
                                                      AppButton(
                                                        label: 'Duyệt',
                                                        icon: Icons.check_circle_outline_rounded,
                                                        variant: AppButtonVariant.primary,
                                                        onPressed: () => _quickConfirmOrder(order),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ] else if (order.orderStatus.toUpperCase() == 'CONFIRMED') ...[
                                                      AppButton(
                                                        label: 'Đóng gói',
                                                        icon: Icons.local_shipping_outlined,
                                                        variant: AppButtonVariant.primary,
                                                        onPressed: () => _quickShipOrder(order),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ] else if (order.orderStatus.toUpperCase() == 'SHIPPING') ...[
                                                      AppButton(
                                                        label: 'Đã giao',
                                                        icon: Icons.task_alt_rounded,
                                                        variant: AppButtonVariant.outline,
                                                        onPressed: () => _quickDeliverOrder(order),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    IconButton(
                                                      icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                                                      tooltip: 'In phiếu đóng gói',
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (ctx) => PackingSlipDialog(orders: [order]),
                                                        );
                                                      },
                                                    ),
                                                    AppButton(
                                                      label: 'Chi tiết',
                                                      variant: AppButtonVariant.secondary,
                                                      onPressed: () => setState(() => _selectedOrderForDetail = order),
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
      case 'RETURNED':
        return const StatusBadge(label: 'Hoàn hàng', isDanger: true);
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

  Widget _buildStatusTabBar(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusTabs.map((tab) {
            final key = tab['key']!;
            final label = tab['label']!;
            final isSelected = _selectedOrderStatus == key;
            final count = _statusCounts[key] ?? 0;

            Color tabAccent = AppColors.primary;
            if (key == 'PENDING') tabAccent = AppColors.warning;
            if (key == 'CONFIRMED') tabAccent = const Color(0xFF0284C7);
            if (key == 'SHIPPING') tabAccent = const Color(0xFF6366F1);
            if (key == 'DELIVERED') tabAccent = AppColors.success;
            if (key == 'RETURNED') tabAccent = const Color(0xFFF97316);
            if (key == 'CANCELLED') tabAccent = AppColors.danger;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  if (_selectedOrderStatus != key) {
                    setState(() {
                      _selectedOrderStatus = key;
                      _currentPage = 1;
                    });
                    _loadOrders();
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? tabAccent.withAlpha(50) : tabAccent.withAlpha(25))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? tabAccent : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? tabAccent : textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tabAccent
                              : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateSegmentedControl(bool isDark, Color textPrimary, Color textSecondary) {
    final presets = [
      {'key': 'ALL', 'label': 'Toàn thời gian'},
      {'key': 'TODAY', 'label': 'Hôm nay'},
      {'key': 'LAST_7_DAYS', 'label': '7 ngày qua'},
      {'key': 'THIS_MONTH', 'label': 'Tháng này'},
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: presets.map((p) {
          final key = p['key']!;
          final label = p['label']!;
          final isSelected = _selectedDatePreset == key;

          return InkWell(
            onTap: () => _applyDatePreset(key),
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              height: 27,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primary : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
