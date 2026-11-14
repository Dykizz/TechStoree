import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/constants/order_status.dart';
import '../../core/models/order.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/date_preset_helper.dart';
import '../../core/widgets/app_date_range_picker.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/page_header.dart';
import 'order_detail_screen.dart';
import 'widgets/order_data_table.dart';
import 'widgets/order_filter_panel.dart';
import 'widgets/order_status_tabs.dart';
import 'widgets/order_toolbar.dart';
import 'widgets/packing_slip_dialog.dart';

/// Màn hình Quản lý đơn hàng (Được tổ chức theo cấu trúc module hóa component)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _currencyFormatter = NumberFormat('#,###', 'en_US');

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minAmountCtrl = TextEditingController();
  final TextEditingController _maxAmountCtrl = TextEditingController();
  Timer? _amountDebounceTimer;

  String _searchQuery = '';
  String _selectedOrderStatus = 'ALL';
  String _selectedPaymentStatus = 'ALL';
  String _selectedPaymentMethod = 'ALL';
  DateTimeRange? _selectedDateRange;
  String _selectedDatePreset = 'ALL';
  double? _minAmount;
  double? _maxAmount;
  String _selectedSort = 'createdAt_desc';
  bool _isAdvancedFilterOpen = false;

  int get _advancedFilterCount {
    int count = 0;
    if (_minAmount != null || _maxAmount != null) count++;
    if (_selectedPaymentStatus != 'ALL') count++;
    if (_selectedPaymentMethod != 'ALL') count++;
    if (_selectedDatePreset == 'CUSTOM' && _selectedDateRange != null) count++;
    return count;
  }

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalItems = 0;
  int _totalPages = 1;

  List<Order> _orders = [];
  bool _isLoading = true;
  Order? _selectedOrderForDetail;

  static final List<Map<String, String>> _statusTabs = OrderStatusCatalog.buildFilterTabs();

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
    _amountDebounceTimer?.cancel();
    _searchCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
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
      minAmount: _minAmount,
      maxAmount: _maxAmount,
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
    if (preset == 'CUSTOM') {
      _pickDateRange();
      return;
    }

    setState(() {
      _selectedDatePreset = preset;
      _selectedDateRange = DatePresetHelper.getRangeForPreset(preset);
      _currentPage = 1;
    });
    _loadOrders();
  }

  void _onAmountChanged() {
    _amountDebounceTimer?.cancel();
    _amountDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyCustomAmount();
    });
  }

  void _applyCustomAmount() {
    final min = DatePresetHelper.parseAmount(_minAmountCtrl.text);
    final max = DatePresetHelper.parseAmount(_maxAmountCtrl.text);

    if (min != null && max != null && min > max) {
      return;
    }

    if (min != _minAmount || max != _maxAmount) {
      setState(() {
        _minAmount = min;
        _maxAmount = max;
        _currentPage = 1;
      });
      _loadOrders();
    }
  }

  void _applyPricePreset(double? min, double? max) {
    _amountDebounceTimer?.cancel();
    setState(() {
      _minAmount = min;
      _maxAmount = max;
      _minAmountCtrl.text = min != null ? _currencyFormatter.format(min.toInt()) : '';
      _maxAmountCtrl.text = max != null ? _currencyFormatter.format(max.toInt()) : '';
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
      _minAmount != null ||
      _maxAmount != null ||
      _selectedSort != 'createdAt_desc';

  void _resetFilters() {
    _amountDebounceTimer?.cancel();
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedOrderStatus = 'ALL';
      _selectedPaymentStatus = 'ALL';
      _selectedPaymentMethod = 'ALL';
      _selectedDateRange = null;
      _selectedDatePreset = 'ALL';
      _minAmount = null;
      _maxAmount = null;
      _minAmountCtrl.clear();
      _maxAmountCtrl.clear();
      _selectedSort = 'createdAt_desc';
      _currentPage = 1;
    });
    _loadOrders();
  }

  String _currentOrderCode(Order order) =>
      order.orderCode.isNotEmpty ? order.orderCode : '#${order.orderId}';

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
      if (res.success) {
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Duyệt đơn hàng thành công!');
        _loadOrders();
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Duyệt đơn hàng thất bại!');
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
        content: Text('Chuyển đơn hàng ${_currentOrderCode(order)} sang trạng thái Đang vận chuyển (SHIPPING)?'),
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
      if (res.success) {
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Chuyển trạng thái Đang vận chuyển thành công!');
        _loadOrders();
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Thao tác thất bại!');
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
            Text('Xác nhận đã giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Xác nhận đơn hàng ${_currentOrderCode(order)} đã giao hàng thành công tới người nhận (DELIVERED)?'),
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
      if (res.success) {
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Cập nhật trạng thái Đã giao hàng thành công!');
        _loadOrders();
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Thao tác thất bại!');
      }
    }
  }

  void _openPackingSlip(Order order) async {
    if (order.items.isEmpty) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final fullOrder = await apiService.getOrderById(order.orderId, token: token);
      if (fullOrder != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => PackingSlipDialog(orders: [fullOrder]),
        );
        return;
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => PackingSlipDialog(orders: [order]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedOrderForDetail != null) {
      return OrderDetailScreen(
        order: _selectedOrderForDetail!,
        onBack: () => setState(() => _selectedOrderForDetail = null),
        onOrderUpdated: _loadOrders,
      );
    }

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

          // 1. Thanh Tab trạng thái nằm ngang
          OrderStatusTabs(
            tabs: _statusTabs,
            selectedStatus: _selectedOrderStatus,
            statusCounts: _statusCounts,
            onStatusSelected: (status) {
              setState(() {
                _selectedOrderStatus = status;
                _currentPage = 1;
              });
              _loadOrders();
            },
          ),

          // 2. Thanh Toolbar (Tìm kiếm, Dropdown ngày, Sắp xếp, Nút lọc, Nút đặt lại)
          OrderToolbar(
            searchCtrl: _searchCtrl,
            orders: _orders,
            selectedDatePreset: _selectedDatePreset,
            selectedDateRange: _selectedDateRange,
            selectedSort: _selectedSort,
            isAdvancedFilterOpen: _isAdvancedFilterOpen,
            advancedFilterCount: _advancedFilterCount,
            hasActiveFilters: _hasActiveFilters,
            onSearchSelected: (code) {
              setState(() {
                _searchQuery = code;
                _currentPage = 1;
              });
              _loadOrders();
            },
            onSearchSubmitted: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
              _loadOrders();
            },
            onSearchCleared: () {
              setState(() {
                _searchQuery = '';
                _currentPage = 1;
              });
              _loadOrders();
            },
            onDatePresetChanged: _applyDatePreset,
            onSortChanged: (val) {
              setState(() {
                _selectedSort = val;
                _currentPage = 1;
              });
              _loadOrders();
            },
            onToggleAdvancedFilter: () {
              setState(() => _isAdvancedFilterOpen = !_isAdvancedFilterOpen);
            },
            onResetFilters: _resetFilters,
          ),

          // 3. Panel Lọc Nâng Cao (Khoảng tiền Min-Max, PTTT, TT Thanh toán, Thời gian)
          if (_isAdvancedFilterOpen) ...[
            const SizedBox(height: 10),
            OrderFilterPanel(
              minAmountCtrl: _minAmountCtrl,
              maxAmountCtrl: _maxAmountCtrl,
              minAmount: _minAmount,
              maxAmount: _maxAmount,
              selectedPaymentStatus: _selectedPaymentStatus,
              selectedPaymentMethod: _selectedPaymentMethod,
              selectedDateRange: _selectedDateRange,
              selectedDatePreset: _selectedDatePreset,
              advancedFilterCount: _advancedFilterCount,
              onClose: () => setState(() => _isAdvancedFilterOpen = false),
              onAmountChanged: _onAmountChanged,
              onAmountSubmitted: _applyCustomAmount,
              onPricePresetSelected: _applyPricePreset,
              onPaymentStatusSelected: (status) {
                setState(() {
                  _selectedPaymentStatus = status;
                  _currentPage = 1;
                });
                _loadOrders();
              },
              onPaymentMethodSelected: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                  _currentPage = 1;
                });
                _loadOrders();
              },
              onClearDateRange: () {
                setState(() {
                  _selectedDateRange = null;
                  _selectedDatePreset = 'ALL';
                  _currentPage = 1;
                });
                _loadOrders();
              },
            ),
          ],

          const SizedBox(height: 12),

          // 4. Bảng danh sách đơn hàng & Phân trang
          OrderDataTable(
            orders: _orders,
            isLoading: _isLoading,
            totalItems: _totalItems,
            totalPages: _totalPages,
            currentPage: _currentPage,
            pageSize: _pageSize,
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
            onSelectOrder: (order) => setState(() => _selectedOrderForDetail = order),
            onQuickConfirm: _quickConfirmOrder,
            onQuickShip: _quickShipOrder,
            onQuickDeliver: _quickDeliverOrder,
            onPrintPackingSlip: _openPackingSlip,
          ),
        ],
      ),
    );
  }
}
