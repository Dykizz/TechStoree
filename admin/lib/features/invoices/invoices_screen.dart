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
import '../../core/widgets/filter_bar.dart';
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
  String _searchQuery = '';
  String _selectedStatus = 'ALL';
  String _selectedPaymentMethod = 'ALL';
  DateTimeRange? _selectedDateRange;
  String _selectedSort = 'createdAt_desc';

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
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    setState(() => _isLoading = true);

    final sortParts = _selectedSort.split('_');
    final sortBy = sortParts[0];
    final isAscending = sortParts.length > 1 && sortParts[1] == 'asc';

    final result = await apiService.getAllInvoices(
      page: _currentPage,
      pageSize: _pageSize,
      status: _selectedStatus,
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
        _invoices = result.items;
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
      helpText: 'Khoảng thời gian lập hóa đơn',
    );
    if (picked != null) {
      setState(() {
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
      _selectedSort != 'createdAt_desc';

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedStatus = 'ALL';
      _selectedPaymentMethod = 'ALL';
      _selectedDateRange = null;
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

    return Padding(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề trang & Nút hành động
          PageHeader(
            title: 'Quản lý Hóa đơn',
            subtitle: 'Tra cứu, theo dõi trạng thái thanh toán và in chứng từ hóa đơn bán hàng',
            action: AppButton(
              label: 'Làm mới',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              onPressed: _isLoading ? null : _loadInvoices,
            ),
          ),

          const SizedBox(height: 12),

          // Quick Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - (3 * 12)) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetricCard(
                    title: 'TỔNG HÓA ĐƠN',
                    value: '$_totalItems',
                    subtitle: 'Hóa đơn trong hệ thống',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.primary,
                    width: cardWidth,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildMetricCard(
                    title: 'ĐÃ THANH TOÁN',
                    value: '${paidInvoices.length}',
                    subtitle: currencyFormat.format(paidAmount),
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    width: cardWidth,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildMetricCard(
                    title: 'CHỜ THANH TOÁN',
                    value: '${unpaidInvoices.length}',
                    subtitle: currencyFormat.format(unpaidAmount),
                    icon: Icons.pending_actions_rounded,
                    iconColor: AppColors.warning,
                    width: cardWidth,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildMetricCard(
                    title: 'ĐÃ HỦY',
                    value: '${cancelledInvoices.length}',
                    subtitle: 'Đơn bị hủy / hoàn tiền',
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.danger,
                    width: cardWidth,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Thanh bộ lọc & Tìm kiếm
          FilterBar(
            searchField: AppSearchField<Invoice>(
              controller: _searchCtrl,
              hintText: 'Tìm theo Mã hóa đơn, Mã đơn hàng, Tên khách...',
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
            filters: [
              AppDropdown<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Trạng thái: Tất cả')),
                  DropdownMenuItem(value: 'PAID', child: Text('Đã thanh toán')),
                  DropdownMenuItem(value: 'UNPAID', child: Text('Chờ thanh toán')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                      _currentPage = 1;
                    });
                    _loadInvoices();
                  }
                },
              ),
              AppDropdown<String>(
                value: _selectedPaymentMethod,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Thanh toán: Tất cả')),
                  DropdownMenuItem(value: 'COD', child: Text('COD (Tiền mặt)')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('Cổng VNPay')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản NH')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPaymentMethod = val;
                      _currentPage = 1;
                    });
                    _loadInvoices();
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
                              _loadInvoices();
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
                      DropdownMenuItem(value: 'invoiceCode_asc', child: Text('Mã HĐ: A → Z')),
                      DropdownMenuItem(value: 'invoiceCode_desc', child: Text('Mã HĐ: Z → A')),
                      DropdownMenuItem(value: 'status_asc', child: Text('Trạng thái: A → Z')),
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
                    'Tổng: $_totalItems hóa đơn',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bảng dữ liệu hóa đơn
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                headingRowHeight: 40,
                                dataRowMinHeight: 48,
                                dataRowMaxHeight: 54,
                                horizontalMargin: 16,
                                columnSpacing: 18,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                                columns: const [
                                  DataColumn(label: Text('MÃ HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('KHÁCH HÀNG', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('TỔNG TIỀN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('THANH TOÁN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('NGÀY LẬP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                  DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                ],
                                rows: _invoices.map((inv) {
                                  return DataRow(
                                    cells: [
                                      // Mã HĐ
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.receipt_rounded, size: 14, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              inv.invoiceCode,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Đơn hàng liên kết
                                      DataCell(
                                        Text(
                                          inv.orderCode,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
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
                                        Text(
                                          currencyFormat.format(inv.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
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
                                            inv.paymentMethodLabel,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required double width,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
