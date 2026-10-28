import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_date_range_picker.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/status_badge.dart';
import 'widgets/invoice_detail_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final dateFormatDate = DateFormat('dd/MM/yyyy');

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minAmountCtrl = TextEditingController();
  final TextEditingController _maxAmountCtrl = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    super.dispose();
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
      });
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
    final now = DateTime.now();
    DateTimeRange? range;
    if (preset == 'TODAY') {
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      range = DateTimeRange(start: start, end: end);
    } else if (preset == 'YESTERDAY') {
      final yesterday = now.subtract(const Duration(days: 1));
      final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      range = DateTimeRange(start: start, end: end);
    } else if (preset == 'LAST_7_DAYS') {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      range = DateTimeRange(start: start, end: end);
    } else if (preset == 'THIS_MONTH') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      range = DateTimeRange(start: start, end: end);
    } else if (preset == 'ALL') {
      range = null;
    }

    setState(() {
      _selectedDatePreset = preset;
      _selectedDateRange = range;
      _currentPage = 1;
    });
    _loadInvoices();
  }

  void _applyPricePreset(double? min, double? max) {
    setState(() {
      _minAmount = min;
      _maxAmount = max;
      _minAmountCtrl.text = min != null ? min.toStringAsFixed(0) : '';
      _maxAmountCtrl.text = max != null ? max.toStringAsFixed(0) : '';
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    // Quick Metrics Calculations
    final paidInvoices = _invoices.where((i) => i.isPaid).toList();
    final unpaidInvoices = _invoices.where((i) => i.isUnpaid).toList();
    final cancelledInvoices = _invoices.where((i) => i.isCancelled).toList();

    final paidAmount = paidInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount);
    final unpaidAmount = unpaidInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề trang & Nút hành động
          PageHeader(
            title: 'Quản lý hóa đơn',
            subtitle: 'Tra cứu, theo dõi trạng thái thanh toán và in chứng từ hóa đơn bán hàng',
            action: AppButton(
              label: 'Làm mới',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              onPressed: _isLoading ? null : _loadInvoices,
            ),
          ),

          const SizedBox(height: 12),

          // Quick Metric Cards (Có thể click trực tiếp để lọc trạng thái)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - (3 * 12)) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InvoiceMetricCard(
                    title: 'TỔNG HÓA ĐƠN',
                    value: '${_stats?.totalInvoices ?? _totalItems}',
                    subtitle: 'Hóa đơn trong hệ thống',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.primary,
                    width: cardWidth,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isSelected: _selectedStatus == 'ALL',
                    onTap: () => _selectStatus('ALL'),
                  ),
                  _InvoiceMetricCard(
                    title: 'ĐÃ THANH TOÁN',
                    value: '${_stats?.paidCount ?? paidInvoices.length}',
                    subtitle: currencyFormat.format(_stats?.paidAmount ?? paidAmount),
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    width: cardWidth,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isSelected: _selectedStatus == 'PAID',
                    onTap: () => _selectStatus('PAID'),
                  ),
                  _InvoiceMetricCard(
                    title: 'CHỜ THANH TOÁN',
                    value: '${_stats?.unpaidCount ?? unpaidInvoices.length}',
                    subtitle: currencyFormat.format(_stats?.unpaidAmount ?? unpaidAmount),
                    icon: Icons.pending_actions_rounded,
                    iconColor: AppColors.warning,
                    width: cardWidth,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isSelected: _selectedStatus == 'UNPAID',
                    onTap: () => _selectStatus('UNPAID'),
                  ),
                  _InvoiceMetricCard(
                    title: 'ĐÃ HỦY',
                    value: '${_stats?.cancelledCount ?? cancelledInvoices.length}',
                    subtitle: 'Đơn bị hủy / hoàn tiền',
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.danger,
                    width: cardWidth,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isSelected: _selectedStatus == 'CANCELLED',
                    onTap: () => _selectStatus('CANCELLED'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // 1 Hàng Tinh Gọn: Thanh Tìm Kiếm & Lọc Nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Omni Search Field
                Expanded(
                  child: AppSearchField<Invoice>(
                    controller: _searchCtrl,
                    hintText: 'Tìm theo Mã HĐ, Đơn hàng, Tên khách hàng...',
                    items: _invoices,
                    searchFilter: (inv, q) =>
                        inv.invoiceCode.toLowerCase().contains(q.toLowerCase()) ||
                        inv.orderCode.toLowerCase().contains(q.toLowerCase()) ||
                        inv.customerName.toLowerCase().contains(q.toLowerCase()),
                    itemLabel: (inv) => '${inv.invoiceCode} - ${inv.customerName}',
                    itemSubtitle: (inv) => '${currencyFormat.format(inv.totalAmount)} • ${inv.statusLabel}',
                    onSelected: (inv) {
                      setState(() {
                        _searchQuery = inv.invoiceCode;
                        _currentPage = 1;
                      });
                      _loadInvoices();
                    },
                    onSubmitted: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      });
                      _loadInvoices();
                    },
                    onCleared: () {
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 1;
                      });
                      _loadInvoices();
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Quick Date Preset Dropdown
                SizedBox(
                  width: 170,
                  child: AppDropdown<String>(
                    value: _selectedDatePreset,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Thời gian: Tất cả')),
                      DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                      DropdownMenuItem(value: 'YESTERDAY', child: Text('Hôm qua')),
                      DropdownMenuItem(value: 'LAST_7_DAYS', child: Text('7 ngày qua')),
                      DropdownMenuItem(value: 'THIS_MONTH', child: Text('Tháng này')),
                      DropdownMenuItem(value: 'CUSTOM', child: Text('Tùy chọn ngày...')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        if (val == 'CUSTOM') {
                          _pickDateRange();
                        } else {
                          _applyDatePreset(val);
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Sort Dropdown
                SizedBox(
                  width: 195,
                  child: AppDropdown<String>(
                    value: _selectedSort,
                    items: const [
                      DropdownMenuItem(value: 'createdAt_desc', child: Text('Sắp xếp: Mới nhất')),
                      DropdownMenuItem(value: 'createdAt_asc', child: Text('Sắp xếp: Cũ nhất')),
                      DropdownMenuItem(value: 'totalAmount_desc', child: Text('Tổng tiền: Cao → Thấp')),
                      DropdownMenuItem(value: 'totalAmount_asc', child: Text('Tổng tiền: Thấp → Cao')),
                      DropdownMenuItem(value: 'invoiceCode_asc', child: Text('Mã HĐ: A → Z')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSort = val;
                          _currentPage = 1;
                        });
                        _loadInvoices();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Nút "Bộ lọc nâng cao"
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isAdvancedFilterOpen = !_isAdvancedFilterOpen);
                  },
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: (_isAdvancedFilterOpen || _advancedFilterCount > 0) ? Colors.white : textPrimary,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _advancedFilterCount > 0 ? 'Lọc ($_advancedFilterCount)' : 'Bộ lọc',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: (_isAdvancedFilterOpen || _advancedFilterCount > 0) ? Colors.white : textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isAdvancedFilterOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: (_isAdvancedFilterOpen || _advancedFilterCount > 0) ? Colors.white : textSecondary,
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_isAdvancedFilterOpen || _advancedFilterCount > 0) ? AppColors.primary : null,
                    side: BorderSide(
                      color: (_isAdvancedFilterOpen || _advancedFilterCount > 0) ? AppColors.primary : borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),

                // Nút Đặt lại bộ lọc (nếu có active filter)
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Đặt lại toàn bộ lọc',
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppColors.danger),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Panel Lọc Nâng Cao (Khoảng tiền Min-Max + Phương thức + Ngày chi tiết)
          if (_isAdvancedFilterOpen) ...[
            const SizedBox(height: 10),
            _buildAdvancedFilterPanel(isDark, cardBg, borderColor, textPrimary, textSecondary),
          ],

          const SizedBox(height: 12),

          // Bảng dữ liệu hóa đơn (Co giãn tự nhiên trong SingleChildScrollView)
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _invoices.isEmpty
                  ? const DataTableContainer(
                      child: EmptyState(
                        title: 'Không tìm thấy hóa đơn nào',
                        message: 'Không có hóa đơn nào khớp với điều kiện lọc hiện tại.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  : DataTableContainer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScrollableTableWrapper(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowHeight: 40,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 56,
                              horizontalMargin: 16,
                              columnSpacing: 18,
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              ),
                              dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9);
                                }
                                return null;
                              }),
                              columns: [
                                DataColumn(label: Text('Mã HĐ / Đơn hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Ngày lập', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                              ],
                              rows: _invoices.map((inv) {
                                return DataRow(
                                  onSelectChanged: (_) => _showInvoiceDetail(inv),
                                  cells: [
                                    // Mã HĐ gộp Đơn hàng
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.invoiceCode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Đơn: ${inv.orderCode}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Khách hàng
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.customerName.isNotEmpty ? inv.customerName : 'Khách vãng lai',
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: textPrimary),
                                          ),
                                          Text(
                                            'ID: #${inv.userId}',
                                            style: TextStyle(fontSize: 10.5, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tổng tiền
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currencyFormat.format(inv.totalAmount),
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                          ),
                                          if (inv.voucherDiscountAmount > 0) ...[
                                            const SizedBox(height: 1),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.confirmation_number_outlined, size: 10, color: AppColors.success),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '-${currencyFormat.format(inv.voucherDiscountAmount)}',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Hình thức thanh toán
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: borderColor, width: 0.8),
                                        ),
                                        child: Text(
                                          inv.paymentMethod == 'BANK_TRANSFER' ? 'Chuyển khoản' : (inv.paymentMethod == 'VNPAY' ? 'VNPay' : inv.paymentMethod),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                                        ),
                                      ),
                                    ),
                                    // Trạng thái hóa đơn
                                    DataCell(
                                      StatusBadge(
                                        label: inv.statusLabel,
                                        color: inv.statusColor,
                                      ),
                                    ),
                                    // Ngày lập
                                    DataCell(
                                      Text(
                                        dateFormat.format(inv.createdAt),
                                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                                      ),
                                    ),
                                    // Thao tác
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Xem chi tiết hóa đơn',
                                            icon: const Icon(Icons.visibility_outlined, size: 18),
                                            color: AppColors.primary,
                                            onPressed: () => _showInvoiceDetail(inv),
                                            splashRadius: 18,
                                          ),
                                          IconButton(
                                            tooltip: 'In hóa đơn',
                                            icon: const Icon(Icons.print_outlined, size: 18),
                                            color: textSecondary,
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Đang chuẩn bị lệnh in cho ${inv.invoiceCode}...'),
                                                  backgroundColor: AppColors.success,
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            splashRadius: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          // Phân trang
                          AppPagination(
                            currentPage: _currentPage,
                            totalPages: _totalPages,
                            totalItems: _totalItems,
                            itemsPerPage: _pageSize,
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
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }


  Widget _buildAdvancedFilterPanel(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ lọc nâng cao',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: textPrimary,
                    ),
                  ),
                  if (_advancedFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_advancedFilterCount điều kiện đang áp dụng',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isAdvancedFilterOpen = false),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),

          // 2 Cột: Khoảng tiền (Min-Max) & Hình thức thanh toán
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột 1: Khoảng tiền
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khoảng tiền hóa đơn (VNĐ)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _minAmountCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12.5, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Từ giá ₫',
                                hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _maxAmountCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12.5, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Đến giá ₫',
                                hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick Price Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPriceChip('Tất cả giá', () => _applyPricePreset(null, null)),
                        _buildPriceChip('< 1 triệu', () => _applyPricePreset(null, 1000000)),
                        _buildPriceChip('1tr - 5tr', () => _applyPricePreset(1000000, 5000000)),
                        _buildPriceChip('5tr - 20tr', () => _applyPricePreset(5000000, 20000000)),
                        _buildPriceChip('> 20 triệu', () => _applyPricePreset(20000000, null)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Cột 2: Hình thức thanh toán
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phương thức thanh toán',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPaymentChip('Tất cả', 'ALL'),
                        _buildPaymentChip('COD (Tiền mặt)', 'COD'),
                        _buildPaymentChip('Cổng VNPay', 'VNPAY'),
                        _buildPaymentChip('Chuyển khoản NH', 'BANK_TRANSFER'),
                      ],
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Thời gian: ${dateFormatDate.format(_selectedDateRange!.start)} - ${dateFormatDate.format(_selectedDateRange!.end)}',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDateRange = null;
                                _selectedDatePreset = 'ALL';
                                _currentPage = 1;
                              });
                              _loadInvoices();
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          // Footer Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _minAmount = null;
                    _maxAmount = null;
                    _minAmountCtrl.clear();
                    _maxAmountCtrl.clear();
                    _selectedPaymentMethod = 'ALL';
                    _selectedDateRange = null;
                    _selectedDatePreset = 'ALL';
                    _currentPage = 1;
                  });
                  _loadInvoices();
                },
                child: Text('Xóa điều kiện lọc', style: TextStyle(color: textSecondary, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  final min = double.tryParse(_minAmountCtrl.text.trim());
                  final max = double.tryParse(_maxAmountCtrl.text.trim());
                  setState(() {
                    _minAmount = min;
                    _maxAmount = max;
                    _currentPage = 1;
                  });
                  _loadInvoices();
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Áp dụng bộ lọc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildPaymentChip(String label, String value) {
    final isSelected = _selectedPaymentMethod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          _currentPage = 1;
        });
        _loadInvoices();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

class _InvoiceMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double width;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isSelected;
  final VoidCallback onTap;

  const _InvoiceMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.width,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_InvoiceMetricCard> createState() => _InvoiceMetricCardState();
}

class _InvoiceMetricCardState extends State<_InvoiceMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isSelected || _isHovered)
                  ? widget.iconColor.withValues(alpha: widget.isSelected ? 0.9 : 0.55)
                  : widget.borderColor.withValues(alpha: widget.isDark ? 0.6 : 0.8),
              width: widget.isSelected ? 1.6 : (_isHovered ? 1.4 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isSelected || _isHovered)
                    ? widget.iconColor.withValues(alpha: widget.isSelected ? (widget.isDark ? 0.28 : 0.16) : (widget.isDark ? 0.20 : 0.12))
                    : (widget.isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.05)),
                blurRadius: widget.isSelected ? 16 : (_isHovered ? 14 : 7),
                offset: (widget.isSelected || _isHovered) ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Faint decorative watermark icon in bottom-right corner (giống KPI card Tổng quan)
              Positioned(
                right: -6,
                bottom: -8,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.isDark ? 0.06 : 0.045,
                    child: Icon(
                      widget.icon,
                      size: 58,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),

              // Card Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.iconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: widget.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _isHovered ? 0.9 : 0.35,
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: _isHovered ? widget.iconColor : widget.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: widget.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: widget.iconColor,
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
      ),
    );
  }
}
