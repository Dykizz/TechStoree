import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/date_preset_helper.dart';
import '../../core/widgets/app_date_range_picker.dart';
import '../../core/widgets/master_detail_quick_view_layout.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/smooth_loading_wrapper.dart';
import 'widgets/invoice_data_table.dart';
import 'widgets/invoice_detail_dialog.dart';
import 'widgets/invoice_filter_panel.dart';
import 'widgets/invoice_metrics_row.dart';
import 'widgets/invoice_quick_view_panel.dart';
import 'widgets/invoice_toolbar.dart';

/// Màn hình Quản lý hóa đơn (được tổ chức theo kiến trúc component-driven)
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _currencyFormatter = NumberFormat('#,###', 'en_US');

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minAmountCtrl = TextEditingController();
  final TextEditingController _maxAmountCtrl = TextEditingController();
  Timer? _amountDebounceTimer;

  String _searchQuery = '';
  String _selectedStatus = 'ALL';
  String _selectedPaymentMethod = 'ALL';
  DateTimeRange? _selectedDateRange;
  String _selectedDatePreset = 'ALL';
  double? _minAmount;
  double? _maxAmount;
  String _selectedSort = 'createdAt_desc';
  bool _isAdvancedFilterOpen = false;
  InvoiceStatistics? _stats;

  int _currentPage = 1;
  int _pageSize = 10;
  int _totalItems = 0;
  int _totalPages = 1;

  List<Invoice> _invoices = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  Invoice? _selectedInvoice;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadInvoices();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _amountDebounceTimer?.cancel();
    _searchCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _selectedInvoice != null &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      _closeQuickView();
      return true;
    }
    return false;
  }

  Future<void> _loadInvoices() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    setState(() => _isLoading = true);

    final sortParts = _selectedSort.split('_');
    final sortBy = sortParts[0];
    final isAscending = sortParts.length > 1 && sortParts[1] == 'asc';

    final invoicesFuture = apiService.getAllInvoices(
      page: _currentPage,
      pageSize: _pageSize,
      status: _selectedStatus,
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

    final statsFuture = apiService.getInvoiceStatistics(token: token);

    final result = await invoicesFuture;
    final stats = await statsFuture;

    if (mounted) {
      setState(() {
        _invoices = result.items;
        _totalItems = result.totalItems;
        _totalPages = result.totalPages;
        _currentPage = result.page;
        _pageSize = result.pageSize;
        if (stats != null) _stats = stats;
        _isLoading = false;
        _hasLoadedOnce = true;

        // Giữ lại hoặc làm mới hóa đơn đang chọn nếu vẫn tồn tại trên trang
        if (_selectedInvoice != null) {
          final found = _invoices.where((i) => i.invoiceId == _selectedInvoice!.invoiceId).toList();
          _selectedInvoice = found.isNotEmpty ? found.first : null;
        }
      });
    }
  }

  void _toggleQuickView(Invoice inv) {
    setState(() {
      if (_selectedInvoice?.invoiceId == inv.invoiceId) {
        _selectedInvoice = null;
      } else {
        _selectedInvoice = inv;
      }
    });
  }

  void _closeQuickView() {
    if (_selectedInvoice != null) {
      setState(() => _selectedInvoice = null);
    }
  }

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = (_selectedStatus == status && status != 'ALL') ? 'ALL' : status;
      _currentPage = 1;
    });
    _loadInvoices();
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
    _loadInvoices();
  }

  void _onAmountChanged() {
    _amountDebounceTimer?.cancel();
    _amountDebounceTimer = Timer(const Duration(milliseconds: 500), _applyCustomAmount);
  }

  void _applyCustomAmount() {
    final min = DatePresetHelper.parseAmount(_minAmountCtrl.text);
    final max = DatePresetHelper.parseAmount(_maxAmountCtrl.text);

    // Không kích hoạt nếu khoảng giá không hợp lệ (min > max)
    if (min != null && max != null && min > max) {
      return;
    }

    if (min != _minAmount || max != _maxAmount) {
      setState(() {
        _minAmount = min;
        _maxAmount = max;
        _currentPage = 1;
      });
      _loadInvoices();
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
    _loadInvoices();
  }

  Future<void> _pickDateRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      helpText: 'Khoảng thời gian lập hóa đơn',
    );
    if (picked != null) {
      setState(() {
        _selectedDatePreset = 'CUSTOM';
        _selectedDateRange = picked;
        _currentPage = 1;
      });
      _loadInvoices();
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedStatus != 'ALL' ||
      _selectedPaymentMethod != 'ALL' ||
      _selectedDateRange != null ||
      _minAmount != null ||
      _maxAmount != null ||
      _selectedSort != 'createdAt_desc';

  int get _advancedFilterCount {
    int count = 0;
    if (_minAmount != null || _maxAmount != null) count++;
    if (_selectedPaymentMethod != 'ALL') count++;
    if (_selectedDateRange != null && _selectedDatePreset == 'CUSTOM') count++;
    return count;
  }

  void _resetFilters() {
    _amountDebounceTimer?.cancel();
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedStatus = 'ALL';
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
    _loadInvoices();
  }

  void _showInvoiceDetail(Invoice invoice) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InvoiceDetailDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableContent = InvoiceDataTable(
      invoices: _invoices,
      selectedInvoice: _selectedInvoice,
      totalItems: _totalItems,
      totalPages: _totalPages,
      currentPage: _currentPage,
      pageSize: _pageSize,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
        _loadInvoices();
      },
      onItemsPerPageChanged: (newSize) {
        setState(() {
          _pageSize = newSize;
          _currentPage = 1;
        });
        _loadInvoices();
      },
      onSelectInvoice: _toggleQuickView,
    );

    final rightPanel = _selectedInvoice != null
        ? InvoiceQuickViewPanel(
            key: ValueKey('invoice_panel_${_selectedInvoice!.invoiceId}'),
            invoice: _selectedInvoice!,
            onClose: _closeQuickView,
            onViewFullDetail: () => _showInvoiceDetail(_selectedInvoice!),
          )
        : const InvoiceQuickViewPlaceholder(
            key: ValueKey('invoice_quick_view_placeholder'),
          );

    return MasterDetailQuickViewLayout(
      padding: const EdgeInsets.all(AppTokens.space16),
      initialHeaderHeight: 230.0,
      hasSelection: _selectedInvoice != null,
      headerSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Tiêu đề trang
          const PageHeader(
            title: 'Quản lý hóa đơn',
            subtitle: 'Tra cứu, theo dõi trạng thái thanh toán và in chứng từ hóa đơn bán hàng',
          ),
          const SizedBox(height: 12),

          // 2. 4 Thẻ KPI thống kê nhanh (click để lọc trạng thái)
          InvoiceMetricsRow(
            stats: _stats,
            invoices: _invoices,
            totalItems: _totalItems,
            selectedStatus: _selectedStatus,
            onStatusSelected: _selectStatus,
          ),
          const SizedBox(height: 12),

          // 3. Thanh công cụ Tìm kiếm & Lọc nhanh
          InvoiceToolbar(
            searchCtrl: _searchCtrl,
            invoices: _invoices,
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
              _loadInvoices();
            },
            onSearchSubmitted: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
              _loadInvoices();
            },
            onSearchCleared: () {
              setState(() {
                _searchQuery = '';
                _currentPage = 1;
              });
              _loadInvoices();
            },
            onDatePresetChanged: _applyDatePreset,
            onSortChanged: (val) {
              setState(() {
                _selectedSort = val;
                _currentPage = 1;
              });
              _loadInvoices();
            },
            onToggleAdvancedFilter: () {
              setState(() => _isAdvancedFilterOpen = !_isAdvancedFilterOpen);
            },
            onResetFilters: _resetFilters,
          ),

          // 4. Panel lọc nâng cao (Khoảng tiền Min-Max, PTTT, Tag ngày)
          if (_isAdvancedFilterOpen) ...[
            const SizedBox(height: 10),
            InvoiceFilterPanel(
              minAmountCtrl: _minAmountCtrl,
              maxAmountCtrl: _maxAmountCtrl,
              minAmount: _minAmount,
              maxAmount: _maxAmount,
              selectedPaymentMethod: _selectedPaymentMethod,
              selectedDateRange: _selectedDateRange,
              advancedFilterCount: _advancedFilterCount,
              onClose: () => setState(() => _isAdvancedFilterOpen = false),
              onAmountChanged: _onAmountChanged,
              onAmountSubmitted: _applyCustomAmount,
              onPricePresetSelected: _applyPricePreset,
              onPaymentMethodSelected: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                  _currentPage = 1;
                });
                _loadInvoices();
              },
              onClearDateRange: () {
                setState(() {
                  _selectedDateRange = null;
                  _selectedDatePreset = 'ALL';
                  _currentPage = 1;
                });
                _loadInvoices();
              },
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
      bodyWrapper: (child) => SmoothLoadingWrapper(
        isLoading: _isLoading,
        hasData: _hasLoadedOnce,
        initialMinHeight: 420,
        child: child,
      ),
      leftTable: tableContent,
      rightPanel: rightPanel,
    );
  }
}
