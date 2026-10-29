import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/voucher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_date_range_picker.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final numberFormat = NumberFormat('#,###', 'en_US');
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final dateFormatDate = DateFormat('dd/MM/yyyy');
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedDiscountType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  DateTimeRange? _selectedDateRange;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final Set<int> _togglingVoucherIds = {};
  late Future<List<Voucher>> _vouchersFuture;

  static double? _parseCleanDouble(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final cleaned = val.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  static int? _parseCleanInt(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final cleaned = val.replaceAll('.', '').replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ApiService>(context, listen: false).addListener(_onApiServiceChanged);
      }
    });
    _loadData();
  }

  void _onApiServiceChanged() {
    if (mounted) {
      setState(() {
        _loadData();
      });
    }
  }

  void _loadData() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _vouchersFuture = apiService.getVouchers(token: token);
  }

  @override
  void dispose() {
    try {
      Provider.of<ApiService>(context, listen: false).removeListener(_onApiServiceChanged);
    } catch (_) {}
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      helpText: 'Khoảng thời gian áp dụng voucher',
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentPage = 1;
      });
    }
  }

  Future<void> _handleToggleActive(ApiService apiService, AuthProvider authProvider, Voucher voucher) async {
    if (_togglingVoucherIds.contains(voucher.voucherId)) return;
    setState(() => _togglingVoucherIds.add(voucher.voucherId));

    try {
      final res = await apiService.toggleVoucherActive(
        voucher.voucherId,
        token: authProvider.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _togglingVoucherIds.remove(voucher.voucherId));
      }
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedDiscountType != 'Tất cả' ||
      _selectedStatus != 'Tất cả' ||
      _selectedDateRange != null;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<Voucher>>(
      future: _vouchersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var vouchers = snapshot.data ?? [];

        // Apply Search & Filters
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          vouchers = vouchers.where((v) =>
            v.code.toLowerCase().contains(query) ||
            v.title.toLowerCase().contains(query) ||
            (v.description?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        if (_selectedDiscountType != 'Tất cả') {
          vouchers = vouchers.where((v) => v.discountType == _selectedDiscountType).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          if (_selectedStatus == 'PAUSED') {
            vouchers = vouchers.where((v) => !v.isActive).toList();
          } else {
            vouchers = vouchers.where((v) => v.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
          }
        }

        if (_selectedDateRange != null) {
          final rangeStart = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
            0, 0, 0,
          );
          final rangeEnd = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23, 59, 59, 999,
          );

          vouchers = vouchers.where((v) {
            return !v.startDate.isAfter(rangeEnd) && !v.endDate.isBefore(rangeStart);
          }).toList();
        }

        final totalItems = vouchers.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (_currentPage > totalPages && totalPages > 0) {
          _currentPage = totalPages;
        }

        final startIndex = (totalItems == 0) ? 0 : (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;
        final paginatedVouchers = (startIndex < totalItems) ? vouchers.sublist(startIndex, endIndex) : <Voucher>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'Quản lý voucher giảm giá',
                subtitle: 'Tạo và quản lý các mã giảm giá bill áp dụng khi khách hàng thanh toán',
                action: authProvider.can('Vouchers.Create')
                    ? AppButton(
                        label: 'Tạo voucher mới',
                        icon: Icons.add_rounded,
                        onPressed: () => _showVoucherFormDialog(context, null),
                      )
                    : null,
              ),

              // Filter Controls Bar
              FilterBar(
                searchField: AppSearchField<Voucher>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo mã voucher hoặc tiêu đề...',
                  items: vouchers,
                  searchFilter: (v, q) => v.code.toLowerCase().contains(q.toLowerCase()) ||
                      v.title.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (v) => '${v.code} - ${v.title}',
                  itemSubtitle: (v) => '${v.formattedDiscountValue(currencyFormat)} • Đã dùng: ${v.usedCount}${v.usageLimit != null ? "/${v.usageLimit}" : ""}',
                  onSelected: (v) {
                    setState(() {
                      _searchQuery = v.code;
                      _currentPage = 1;
                    });
                  },
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                  },
                  onCleared: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedDiscountType,
                    labelText: 'Loại giảm giá',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả loại')),
                      DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần trăm (%)')),
                      DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Tiền cố định (VNĐ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDiscountType = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  AppDropdown<String>(
                    value: _selectedStatus,
                    labelText: 'Trạng thái',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Đang diễn ra (ACTIVE)')),
                      DropdownMenuItem(value: 'UPCOMING', child: Text('Sắp diễn ra (UPCOMING)')),
                      DropdownMenuItem(value: 'EXPIRED', child: Text('Đã hết hạn (EXPIRED)')),
                      DropdownMenuItem(value: 'PAUSED', child: Text('Tạm dừng (PAUSED)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStatus = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  _buildDateRangeFilter(
                    context: context,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                secondaryRow: _hasActiveFilters
                    ? Row(
                        children: [
                          Text('Đang áp dụng lọc:', style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          if (_selectedDateRange != null)
                            Chip(
                              label: Text(
                                'Thời gian: ${dateFormatDate.format(_selectedDateRange!.start)} - ${dateFormatDate.format(_selectedDateRange!.end)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
                              onDeleted: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.danger),
                            label: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 11.5, color: AppColors.danger)),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                                _selectedDiscountType = 'Tất cả';
                                _selectedStatus = 'Tất cả';
                                _selectedDateRange = null;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ],
                      )
                    : null,
              ),

              // Data Table Container (Tối ưu 5 cột gọn gàng, đồng bộ với Promotions & Products)
              Flexible(
                child: DataTableContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: paginatedVouchers.isEmpty
                            ? const EmptyState(
                                icon: Icons.confirmation_number_outlined,
                                title: 'Không tìm thấy voucher nào',
                                message: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc trạng thái.',
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: ScrollableTableWrapper(
                                  child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 46,
                                      dataRowMaxHeight: 52,
                                      columnSpacing: 20,
                                      horizontalMargin: 16,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        DataColumn(label: Text('Mã & Tên voucher', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Mức giảm', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Đã dùng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                      ],
                                      rows: paginatedVouchers.map((voucher) {
                                        return DataRow(
                                          onSelectChanged: (_) => _showVoucherDetailDialog(context, voucher),
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            // 1. Mã & Tên voucher (Mã badge + Tên + Mô tả ngắn)
                                            DataCell(
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 320),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primaryLight,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                                          ),
                                                          child: Text(
                                                            voucher.code,
                                                            style: const TextStyle(
                                                              color: AppColors.primary,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        InkWell(
                                                          onTap: () {
                                                            Clipboard.setData(ClipboardData(text: voucher.code));
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('Đã sao chép mã: ${voucher.code}'),
                                                                duration: const Duration(seconds: 2),
                                                                backgroundColor: AppColors.success,
                                                              ),
                                                            );
                                                          },
                                                          child: const Padding(
                                                            padding: EdgeInsets.all(2.0),
                                                            child: Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                                                          ),
                                                        ),
                                                        if (!voucher.isPublic) ...[
                                                          const SizedBox(width: 4),
                                                          Tooltip(
                                                            message: 'Voucher ẩn / Mã bí mật',
                                                            child: Icon(Icons.lock_rounded, size: 13, color: textSecondary),
                                                          ),
                                                        ],
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            voucher.title,
                                                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (voucher.description != null && voucher.description!.trim().isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        voucher.description!,
                                                        style: TextStyle(color: textSecondary, fontSize: 11),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // 2. Mức giảm (-20% hoặc -100.000₫ kèm đơn từ...)
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '-${voucher.formattedDiscountValue(currencyFormat)}',
                                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  Text(
                                                    voucher.minOrderValue > 0
                                                        ? 'Đơn từ: ${currencyFormat.format(voucher.minOrderValue)}'
                                                        : 'Mọi đơn hàng',
                                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 3. Đã dùng (Đã dùng: X / Y)
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${voucher.usedCount} / ${voucher.usageLimit ?? '∞'}',
                                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                                  ),
                                                  Text(
                                                    'Tối đa ${voucher.limitPerUser} lần/khách',
                                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 4. Trạng thái (chỉ Badge sạch sẽ, đồng nhất)
                                            DataCell(
                                              _buildStatusBadge(voucher.status, voucher.isActive),
                                            ),

                                            // 5. Thao tác (Đồng nhất với Promotions: [Sửa] [Switch Toggle 0.7] [Xóa])
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (authProvider.can('Vouchers.Update')) ...[
                                                    Tooltip(
                                                      message: 'Chỉnh sửa voucher',
                                                      child: IconButton(
                                                        icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                        onPressed: () => _showVoucherFormDialog(context, voucher),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Tooltip(
                                                      message: voucher.isActive ? 'Tạm dừng voucher (Gạt để tắt)' : 'Kích hoạt voucher (Gạt để bật)',
                                                      child: _togglingVoucherIds.contains(voucher.voucherId)
                                                          ? const Padding(
                                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                                              child: SizedBox(
                                                                width: 14,
                                                                height: 14,
                                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                                              ),
                                                            )
                                                          : Transform.scale(
                                                              scale: 0.7,
                                                              child: Switch(
                                                                value: voucher.isActive,
                                                                activeThumbColor: AppColors.primary,
                                                                onChanged: (val) => _handleToggleActive(apiService, authProvider, voucher),
                                                              ),
                                                            ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                  ],
                                                  if (authProvider.can('Vouchers.Delete'))
                                                    Tooltip(
                                                      message: 'Xóa voucher',
                                                      child: IconButton(
                                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                        onPressed: () => _confirmDeleteVoucher(context, apiService, authProvider, voucher),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                      ),

                      // Pagination Controls
                      if (totalItems > 0)
                        AppPagination(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          totalItems: totalItems,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                          onItemsPerPageChanged: (items) {
                            setState(() {
                              _itemsPerPage = items;
                              _currentPage = 1;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isActive) {
    if (!isActive) {
      return const StatusBadge(label: 'TẠM DỪNG', isWarning: true);
    }

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const StatusBadge(label: 'HOẠT ĐỘNG', isSuccess: true);
      case 'UPCOMING':
        return const StatusBadge(label: 'SẮP DIỄN RA', isInfo: true);
      case 'EXPIRED':
        return const StatusBadge(label: 'ĐÃ HẾT HẠN', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }

  Widget _buildDateRangeFilter({
    required BuildContext context,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final borderColor = _selectedDateRange != null
        ? AppColors.primary
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);
    final fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: _selectedDateRange != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 18,
              color: _selectedDateRange != null ? AppColors.primary : textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${dateFormatDate.format(_selectedDateRange!.start)} - ${dateFormatDate.format(_selectedDateRange!.end)}'
                    : 'Khoảng thời gian: Tất cả',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: _selectedDateRange != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedDateRange != null ? textPrimary : textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedDateRange != null)
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedDateRange = null;
                    _currentPage = 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: textSecondary),
                ),
              )
            else
              Icon(Icons.arrow_drop_down, size: 20, color: textSecondary),
          ],
        ),
      ),
    );
  }

  void _showVoucherDetailDialog(BuildContext context, Voucher voucher) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final limit = voucher.usageLimit;
    final double ratio = (limit != null && limit > 0) ? (voucher.usedCount / limit).clamp(0.0, 1.0) : 0.0;
    final percentUsed = (ratio * 100).toInt();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        voucher.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: voucher.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép mã: ${voucher.code}'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(voucher.status, voucher.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.title,
                    style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: textSecondary, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 2-column info cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trái: Thể lệ & Mức giảm
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.discount_outlined, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('THỂ LỆ ƯU ĐÃI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Loại giảm giá:', voucher.isPercentage ? 'Phần trăm (%)' : 'Số tiền cố định (VNĐ)', textPrimary, textSecondary),
                            const SizedBox(height: 8),
                            _buildDetailRow('Mức giảm:', voucher.formattedDiscountValue(currencyFormat), AppColors.success, textSecondary, isBold: true),
                            const SizedBox(height: 8),
                            _buildDetailRow('Đơn hàng tối thiểu:', currencyFormat.format(voucher.minOrderValue), textPrimary, textSecondary),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Giảm tối đa:',
                              voucher.isPercentage
                                  ? (voucher.maxDiscountAmount != null ? currencyFormat.format(voucher.maxDiscountAmount) : 'Không giới hạn')
                                  : 'Theo mức giảm cố định',
                              textPrimary,
                              textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Cột phải: Thời gian & Hiển thị
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('THỜI GIAN & HIỂN THỊ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Bắt đầu:', dateFormat.format(voucher.startDate), textPrimary, textSecondary),
                            const SizedBox(height: 8),
                            _buildDetailRow('Kết thúc:', dateFormat.format(voucher.endDate), textPrimary, textSecondary),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Công khai trên sàn:',
                              voucher.isPublic ? 'Công khai toàn sàn' : 'Voucher ẩn / Mã riêng',
                              voucher.isPublic ? AppColors.success : AppColors.warning,
                              textSecondary,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Kích hoạt:',
                              voucher.isActive ? 'Đang kích hoạt' : 'Đang tạm dừng',
                              voucher.isActive ? AppColors.success : AppColors.danger,
                              textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card tiến độ sử dụng
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('TIẾN ĐỘ SỬ DỤNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                            ],
                          ),
                          Text(
                            'Đã dùng: ${voucher.usedCount} / ${voucher.usageLimit ?? '∞'} ($percentUsed%)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: voucher.usageLimit != null ? ratio : 0.05,
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio >= 0.8 ? AppColors.warning : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giới hạn mỗi khách hàng: Tối đa ${voucher.limitPerUser} lần', style: TextStyle(fontSize: 12, color: textSecondary)),
                          Text('Lượt nhận: ${voucher.totalClaimedCount}', style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Thể lệ chi tiết / Ghi chú
                if (voucher.description != null && voucher.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('MÔ TẢ / ĐIỀU KIỆN ÁP DỤNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          voucher.description!,
                          style: TextStyle(fontSize: 13, color: textPrimary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx),
          ),
          if (authProvider.can('Vouchers.Update'))
            AppButton(
              label: 'Chỉnh Sửa',
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.primary,
              onPressed: () {
                Navigator.pop(ctx);
                _showVoucherFormDialog(context, voucher);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, Color labelColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: labelColor)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showVoucherFormDialog(BuildContext context, Voucher? voucher) {
    final isEdit = voucher != null;
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: voucher?.code ?? '');
    final titleCtrl = TextEditingController(text: voucher?.title ?? '');
    final descCtrl = TextEditingController(text: voucher?.description ?? '');

    final discountValCtrl = TextEditingController(
      text: voucher != null
          ? (voucher.isPercentage
              ? (voucher.discountValue % 1 == 0 ? voucher.discountValue.toInt().toString() : voucher.discountValue.toString())
              : numberFormat.format(voucher.discountValue.toInt()))
          : '',
    );
    final minOrderValCtrl = TextEditingController(
      text: voucher != null
          ? (voucher.minOrderValue > 0 ? numberFormat.format(voucher.minOrderValue.toInt()) : '0')
          : '0',
    );
    final maxDiscountValCtrl = TextEditingController(
      text: voucher?.maxDiscountAmount != null
          ? numberFormat.format(voucher!.maxDiscountAmount!.toInt())
          : '',
    );
    final usageLimitCtrl = TextEditingController(text: voucher?.usageLimit?.toString() ?? '');
    final limitPerUserCtrl = TextEditingController(text: voucher?.limitPerUser.toString() ?? '1');

    String discountType = voucher?.discountType ?? 'PERCENTAGE';
    DateTime startDate = voucher?.startDate ?? DateTime.now();
    DateTime endDate = voucher?.endDate ?? DateTime.now().add(const Duration(days: 14));
    bool isActive = voucher?.isActive ?? true;
    bool isPublic = voucher?.isPublic ?? true;
    bool isSaving = false;

    void generateRandomCode() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = Random();
      final suffix = List.generate(5, (_) => chars[rnd.nextInt(chars.length)]).join();
      codeCtrl.text = 'TECH$suffix';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
            final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
            final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

            final parsedDiscountVal = _parseCleanDouble(discountValCtrl.text) ?? 0;
            final parsedMinOrderVal = _parseCleanDouble(minOrderValCtrl.text) ?? 0;
            final parsedMaxDiscountVal = _parseCleanDouble(maxDiscountValCtrl.text);

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                children: [
                  Icon(isEdit ? Icons.edit_note_rounded : Icons.add_card_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Chỉnh Sửa Chiến Dịch Voucher' : 'Tạo Mới Voucher Giảm Giá',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 840,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== CỘT TRÁI: THÔNG TIN CƠ BẢN & THỜI GIAN =====
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    controller: codeCtrl,
                                    readOnly: isEdit,
                                    textCapitalization: TextCapitalization.characters,
                                    labelText: 'Mã Voucher (VD: TECHSALE)*',
                                    hintText: 'Nhập mã không khoảng trắng',
                                    suffixIcon: !isEdit
                                        ? Tooltip(
                                            message: 'Tạo mã ngẫu nhiên',
                                            child: IconButton(
                                              icon: const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                                              onPressed: () {
                                                setModalState(() {
                                                  generateRandomCode();
                                                });
                                              },
                                            ),
                                          )
                                        : null,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Mã voucher không được để trống';
                                      if (val.trim().length < 3) return 'Mã voucher tối thiểu 3 ký tự';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  AppTextField(
                                    controller: titleCtrl,
                                    labelText: 'Tiêu Đề Hiển Thị*',
                                    hintText: 'VD: Giảm 100K cho đơn từ 2 triệu',
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                                  ),
                                  const SizedBox(height: 12),

                                  AppTextField(
                                    controller: descCtrl,
                                    maxLines: 2,
                                    labelText: 'Thể lệ / Mô tả chi tiết',
                                    hintText: 'Nhập điều kiện áp dụng nếu có...',
                                  ),
                                  const SizedBox(height: 12),

                                  // Date pickers
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: startDate,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2035),
                                            );
                                            if (pickedDate != null) {
                                              if (!context.mounted) return;
                                              final pickedTime = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.fromDateTime(startDate),
                                              );
                                              if (pickedTime != null) {
                                                setModalState(() {
                                                  startDate = DateTime(
                                                    pickedDate.year,
                                                    pickedDate.month,
                                                    pickedDate.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  );
                                                });
                                              }
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Ngày Bắt Đầu*',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(dateFormat.format(startDate), style: TextStyle(color: textPrimary, fontSize: 12.5)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: endDate,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2035),
                                            );
                                            if (pickedDate != null) {
                                              if (!context.mounted) return;
                                              final pickedTime = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.fromDateTime(endDate),
                                              );
                                              if (pickedTime != null) {
                                                setModalState(() {
                                                  endDate = DateTime(
                                                    pickedDate.year,
                                                    pickedDate.month,
                                                    pickedDate.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  );
                                                });
                                              }
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Ngày Kết Thúc*',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(dateFormat.format(endDate), style: TextStyle(color: textPrimary, fontSize: 12.5)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Toggles
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Kích hoạt ngay', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                          value: isActive,
                                          activeThumbColor: AppColors.primary,
                                          onChanged: (val) => setModalState(() => isActive = val),
                                        ),
                                      ),
                                      Expanded(
                                        child: SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Công khai sàn', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                          value: isPublic,
                                          activeThumbColor: AppColors.primary,
                                          onChanged: (val) => setModalState(() => isPublic = val),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),

                            // ===== CỘT PHẢI: THỂ LỆ & GIỚI HẠN SỬ DỤNG =====
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppDropdown<String>(
                                          value: discountType,
                                          labelText: 'Loại giảm giá*',
                                          items: const [
                                            DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần Trăm (%)')),
                                            DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Tiền Cố Định (VNĐ)')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                discountType = val;
                                                if (discountType == 'FIXED_AMOUNT') {
                                                  maxDiscountValCtrl.clear();
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AppTextField(
                                          controller: discountValCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: discountType == 'FIXED_AMOUNT'
                                              ? [CurrencyInputFormatter()]
                                              : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                          labelText: discountType == 'PERCENTAGE' ? 'Mức giảm (%)*' : 'Mức giảm (VNĐ)*',
                                          hintText: discountType == 'PERCENTAGE' ? 'VD: 10' : 'VD: 100,000',
                                          onChanged: (_) => setModalState(() {}),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Nhập mức giảm';
                                            final numVal = _parseCleanDouble(val);
                                            if (numVal == null || numVal <= 0) return 'Mức giảm phải > 0';
                                            if (discountType == 'PERCENTAGE' && numVal > 100) return 'Tối đa 100%';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          controller: minOrderValCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [CurrencyInputFormatter()],
                                          labelText: 'Đơn tối thiểu (VNĐ)',
                                          hintText: '0 = Không giới hạn',
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      if (discountType == 'PERCENTAGE') ...[
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: AppTextField(
                                            controller: maxDiscountValCtrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [CurrencyInputFormatter()],
                                            labelText: 'Giảm tối đa (VNĐ)',
                                            hintText: 'Để trống = không giới hạn',
                                            onChanged: (_) => setModalState(() {}),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          controller: usageLimitCtrl,
                                          keyboardType: TextInputType.number,
                                          labelText: 'Lượt toàn sàn',
                                          hintText: 'Trống = Không giới hạn',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AppTextField(
                                          controller: limitPerUserCtrl,
                                          keyboardType: TextInputType.number,
                                          labelText: 'Lượt / 1 Khách*',
                                          hintText: 'Mặc định: 1',
                                          validator: (val) {
                                            final numVal = int.tryParse(val ?? '1');
                                            if (numVal == null || numVal < 1) return 'Tối thiểu 1';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Preview Card
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.remove_red_eye_outlined, size: 14, color: textSecondary),
                                            const SizedBox(width: 6),
                                            Text('XEM TRƯỚC ƯU ĐÃI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          discountType == 'PERCENTAGE'
                                              ? 'Giảm ${parsedDiscountVal > 0 ? (parsedDiscountVal % 1 == 0 ? parsedDiscountVal.toInt() : parsedDiscountVal) : 0}% ${parsedMaxDiscountVal != null && parsedMaxDiscountVal > 0 ? "(Tối đa ${currencyFormat.format(parsedMaxDiscountVal)})" : ""}'
                                              : 'Giảm ${currencyFormat.format(parsedDiscountVal)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Áp dụng cho đơn hàng từ ${currencyFormat.format(parsedMinOrderVal)}',
                                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                                        ),
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
                ),
              ),
              actions: [
                AppButton(
                  label: 'Hủy',
                  variant: AppButtonVariant.outline,
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                ),
                AppButton(
                  label: isEdit ? 'Lưu Cập Nhật' : 'Tạo Voucher',
                  variant: AppButtonVariant.primary,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    if (startDate.isAfter(endDate) || startDate.isAtSameMomentAs(endDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu.'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    setModalState(() => isSaving = true);

                    final apiService = Provider.of<ApiService>(context, listen: false);
                    final token = Provider.of<AuthProvider>(context, listen: false).token;

                    final discountVal = _parseCleanDouble(discountValCtrl.text) ?? 0;
                    final minOrderVal = _parseCleanDouble(minOrderValCtrl.text) ?? 0;
                    final maxDiscountVal = discountType == 'PERCENTAGE'
                        ? _parseCleanDouble(maxDiscountValCtrl.text)
                        : null;
                    final usageLimit = _parseCleanInt(usageLimitCtrl.text);
                    final limitPerUser = _parseCleanInt(limitPerUserCtrl.text) ?? 1;

                    final newVoucher = Voucher(
                      voucherId: voucher?.voucherId ?? 0,
                      code: codeCtrl.text.trim().toUpperCase(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      discountType: discountType,
                      discountValue: discountVal,
                      minOrderValue: minOrderVal,
                      maxDiscountAmount: maxDiscountVal,
                      usageLimit: usageLimit,
                      limitPerUser: limitPerUser,
                      startDate: startDate,
                      endDate: endDate,
                      isActive: isActive,
                      isPublic: isPublic,
                      createdAt: voucher?.createdAt ?? DateTime.now(),
                    );

                    final res = isEdit
                        ? await apiService.updateVoucher(voucher.voucherId, newVoucher, token: token)
                        : await apiService.createVoucher(newVoucher, token: token);

                    if (!ctx.mounted) return;

                    setModalState(() => isSaving = false);

                    if (res.success) {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVoucher(BuildContext context, ApiService apiService, AuthProvider authProvider, Voucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa voucher mã "${voucher.code}" (${voucher.title}) không?'),
            if (voucher.usedCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voucher này đã có ${voucher.usedCount} lượt sử dụng. Xóa có thể ảnh hưởng đến lịch sử đối soát!',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Xóa Voucher',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteVoucher(voucher.voucherId, token: authProvider.token);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: res.success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
