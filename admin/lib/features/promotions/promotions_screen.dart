import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/promotion.dart';
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

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final dateFormatDate = DateFormat('dd/MM/yyyy');
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedDiscountType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  DateTimeRange? _selectedDateRange;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final Set<int> _togglingPromoIds = {};

  late Future<List<Promotion>> _promotionsFuture;

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
    _promotionsFuture = apiService.getPromotions(token: token);
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
      helpText: 'Khoảng thời gian áp dụng khuyến mãi',
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentPage = 1;
      });
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

    return FutureBuilder<List<Promotion>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var promotions = snapshot.data ?? [];

        // Apply Local Search & Filters
        if (_searchQuery.isNotEmpty) {
          promotions = promotions.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (_selectedDiscountType != 'Tất cả') {
          promotions = promotions.where((p) => p.discountType == _selectedDiscountType).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          promotions = promotions.where((p) => p.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
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

          promotions = promotions.where((p) {
            return !p.startDate.isAfter(rangeEnd) && !p.endDate.isBefore(rangeStart);
          }).toList();
        }

        final totalItems = promotions.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedPromotions = promotions.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'Khuyến mãi & giảm giá',
                subtitle: 'Quản lý các chương trình Flash Sale và giảm giá biến thể sản phẩm',
                action: authProvider.can('Promotions.Create')
                    ? AppButton(
                        label: 'Tạo khuyến mãi mới',
                        icon: Icons.add_rounded,
                        onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token),
                      )
                    : null,
              ),

              // Filter Bar
              FilterBar(
                searchField: AppSearchField<Promotion>(
                  controller: _searchCtrl,
                  hintText: 'Tìm kiếm tên khuyến mãi, mô tả...',
                  items: promotions,
                  searchFilter: (p, q) => p.name.toLowerCase().contains(q.toLowerCase()) ||
                      p.description.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (p) => p.name,
                  itemSubtitle: (p) => '${p.formattedDiscountValue(currencyFormat)} • ${p.status}',
                  onSelected: (p) => setState(() => _searchQuery = p.name),
                  onSubmitted: (val) => setState(() => _searchQuery = val),
                  onCleared: () => setState(() => _searchQuery = ''),
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
                      if (val != null) setState(() => _selectedDiscountType = val);
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
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
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

              // Data Table Container
              Flexible(
                child: DataTableContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: paginatedPromotions.isEmpty
                            ? const EmptyState(
                                icon: Icons.local_offer_outlined,
                                title: 'Không tìm thấy chương trình khuyến mãi nào',
                                message: 'Thử thay đổi bộ lọc hoặc tạo chương trình mới.',
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: ScrollableTableWrapper(
                                  child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 48,
                                      columns: [
                                        DataColumn(label: Text('Tên chương trình', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Mức giảm', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                      ],
                                      rows: paginatedPromotions.map((promo) {
                                        return DataRow(
                                          onSelectChanged: (_) => _showPromotionDetailsDialog(context, apiService, authProvider.token, promo.promotionId),
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            // 1. Tên chương trình & Mô tả (rút gọn ... nếu quá dài)
                                            DataCell(
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 340),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      promo.name,
                                                      style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (promo.description.isNotEmpty)
                                                      Text(
                                                        promo.description,
                                                        style: TextStyle(color: textSecondary, fontSize: 11),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // 2. Mức giảm (chỉ hiển thị số tiền/phần trăm, bỏ nhãn badge % và VNĐ)
                                            DataCell(
                                              Text(
                                                '-${promo.formattedDiscountValue(currencyFormat)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                              ),
                                            ),
                                            // 3. Trạng thái (chỉ hiển thị Badge sạch sẽ, đồng nhất)
                                            DataCell(_buildStatusChip(promo)),
                                            // 4. Thao tác (Đồng nhất với bảng Sản phẩm: [Sửa] [Switch Toggle] [Xóa])
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (authProvider.can('Promotions.Update')) ...[
                                                    Tooltip(
                                                      message: 'Chỉnh sửa chương trình',
                                                      child: IconButton(
                                                        icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                        onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, existingPromoId: promo.promotionId),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Tooltip(
                                                      message: promo.isActive ? 'Tạm dừng khuyến mãi (Gạt để tắt)' : 'Kích hoạt khuyến mãi (Gạt để bật)',
                                                      child: Transform.scale(
                                                        scale: 0.7,
                                                        child: Switch(
                                                          value: promo.isActive,
                                                          activeThumbColor: AppColors.primary,
                                                          onChanged: _togglingPromoIds.contains(promo.promotionId)
                                                              ? null
                                                              : (val) async {
                                                                  setState(() {
                                                                    _togglingPromoIds.add(promo.promotionId);
                                                                  });
                                                                  try {
                                                                    final res = await apiService.togglePromotionActive(promo.promotionId, token: authProvider.token);
                                                                    if (context.mounted) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(res.message),
                                                                          backgroundColor: res.success ? AppColors.success : AppColors.danger,
                                                                        ),
                                                                      );
                                                                    }
                                                                  } finally {
                                                                    if (mounted) {
                                                                      setState(() {
                                                                        _togglingPromoIds.remove(promo.promotionId);
                                                                      });
                                                                    }
                                                                  }
                                                                },
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                  ],
                                                  if (authProvider.can('Promotions.Delete'))
                                                    Tooltip(
                                                      message: 'Xóa khuyến mãi',
                                                      child: IconButton(
                                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                        onPressed: () => _confirmDeletePromotion(context, apiService, authProvider.token, promo),
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
                      if (totalItems > 0)
                        AppPagination(
                          currentPage: safePage,
                          totalPages: totalPages,
                          totalItems: totalItems,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                          onItemsPerPageChanged: (items) => setState(() {
                            _itemsPerPage = items;
                            _currentPage = 1;
                          }),
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

  Widget _buildDiscountTypeChip(String type) {
    if (type == 'PERCENTAGE') {
      return const StatusBadge(label: 'Phần trăm (%)', isInfo: true);
    }
    return const StatusBadge(label: 'Tiền cố định (VNĐ)', isWarning: true);
  }

  Widget _buildStatusChip(Promotion promo) {
    if (!promo.isActive) {
      return const StatusBadge(label: 'Tạm dừng', isWarning: true);
    }
    switch (promo.status.toUpperCase()) {
      case 'ACTIVE':
        return const StatusBadge(label: 'Đang diễn ra', isSuccess: true);
      case 'UPCOMING':
        return const StatusBadge(label: 'Sắp diễn ra', isInfo: true);
      case 'EXPIRED':
        return const StatusBadge(label: 'Đã hết hạn', isDanger: true);
      default:
        return StatusBadge(label: promo.status);
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

  void _showPromotionDetailsDialog(BuildContext context, ApiService apiService, String? token, int promoId) async {
    final promo = await apiService.getPromotionById(promoId, token: token);
    if (!context.mounted) return;
    if (promo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải chi tiết khuyến mãi.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                promo.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(promo),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Mức giảm giá: ', style: TextStyle(fontSize: 12, color: textSecondary)),
                        Text(
                          promo.formattedDiscountValue(currencyFormat),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        _buildDiscountTypeChip(promo.discountType),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thời gian áp dụng: ${dateFormat.format(promo.startDate)}  ➔  ${dateFormat.format(promo.endDate)}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    if (promo.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Mô tả thể lệ: ${promo.description}', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Biến thể áp dụng (${promo.variants.length}):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
              const SizedBox(height: 8),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: promo.variants.isEmpty
                    ? Center(child: Text('Không có biến thể nào được áp dụng', style: TextStyle(color: textSecondary, fontSize: 12)))
                    : ListView.separated(
                        itemCount: promo.variants.length,
                        separatorBuilder: (c, i) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                        itemBuilder: (c, i) {
                          final item = promo.variants[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            title: Text(item.fullName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary)),
                            subtitle: Row(
                              children: [
                                Text('Giá gốc: ${currencyFormat.format(item.originalPrice)}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                const SizedBox(width: 6),
                                Text(
                                  '➔ ${currencyFormat.format(item.promotionalPrice)}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(label: 'Đóng', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  void _showCreateOrEditDialog(
    BuildContext context,
    ApiService apiService,
    String? token, {
    int? existingPromoId,
  }) async {
    final products = await apiService.getProductsWithVariants(token: token);
    Promotion? existingPromo;
    if (existingPromoId != null && existingPromoId > 0) {
      existingPromo = await apiService.getPromotionById(existingPromoId, token: token);
      if (existingPromo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải thông tin khuyến mãi cần sửa.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PromotionFormDialog(
        existingPromo: existingPromo,
        products: products,
        apiService: apiService,
        token: token,
        onSaved: () {
          setState(() {
            _loadData();
          });
        },
      ),
    );
  }

  void _confirmDeletePromotion(BuildContext context, ApiService apiService, String? token, Promotion promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa chương trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Bạn có chắc muốn xóa khuyến mãi "${promo.name}" không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Xóa Khuyến Mãi',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deletePromotion(promo.promotionId, token: token);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _VariantChoiceOption {
  final int variantId;
  final int productId;
  final String productName;
  final String variantName;
  final String label;
  final double price;
  final String? imageUrl;
  final int stockQuantity;

  _VariantChoiceOption({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.label,
    required this.price,
    this.imageUrl,
    this.stockQuantity = 0,
  });
}

class _PromotionFormDialog extends StatefulWidget {
  final Promotion? existingPromo;
  final List<Product> products;
  final ApiService apiService;
  final String? token;
  final VoidCallback onSaved;

  const _PromotionFormDialog({
    required this.existingPromo,
    required this.products,
    required this.apiService,
    required this.token,
    required this.onSaved,
  });

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _discountValCtrl;
  late final TextEditingController _productSearchCtrl;
  late final FocusNode _searchFocusNode;

  late String _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;
  late Set<int> _selectedVariantIds;

  List<_VariantChoiceOption> _availableVariants = [];
  String _searchQuery = '';
  bool _showDropdown = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final promo = widget.existingPromo;
    final isEditing = promo != null;

    String formatDiscountInit(double val) {
      if (val == val.roundToDouble()) {
        return val.toInt().toString();
      }
      return val.toString();
    }

    _nameCtrl = TextEditingController(text: isEditing ? promo.name : '');
    _descCtrl = TextEditingController(text: isEditing ? promo.description : '');
    _discountValCtrl = TextEditingController(
      text: isEditing ? formatDiscountInit(promo.discountValue) : '10',
    );
    _productSearchCtrl = TextEditingController();
    _searchFocusNode = FocusNode();

    _discountType = isEditing ? promo.discountType : 'PERCENTAGE';
    _startDate = isEditing ? promo.startDate : DateTime.now();
    _endDate = isEditing ? promo.endDate : DateTime.now().add(const Duration(days: 7));
    _isActive = isEditing ? promo.isActive : true;
    _selectedVariantIds = isEditing ? promo.variantIds.toSet() : <int>{};

    _buildAvailableVariants();

    _productSearchCtrl.addListener(() {
      final q = _productSearchCtrl.text.trim();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
          _showDropdown = q.isNotEmpty;
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _productSearchCtrl.text.trim().isNotEmpty) {
        setState(() {
          _showDropdown = true;
        });
      }
    });
  }


  void _buildAvailableVariants() {
    _availableVariants = [];
    for (var p in widget.products) {
      final pId = int.tryParse(p.id) ?? 0;
      if (p.variants.isNotEmpty) {
        for (var v in p.variants) {
          final vId = v.variantId ?? 0;
          if (vId > 0) {
            final img = (v.imageUrl != null && v.imageUrl!.isNotEmpty)
                ? v.imageUrl
                : (p.imageUrl.isNotEmpty ? p.imageUrl : null);
            _availableVariants.add(_VariantChoiceOption(
              variantId: vId,
              productId: v.productId ?? pId,
              productName: p.name,
              variantName: v.variantName,
              label: '${p.name} - ${v.variantName}',
              price: v.price > 0 ? v.price : p.price,
              imageUrl: img,
              stockQuantity: v.stockQuantity,
            ));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountValCtrl.dispose();
    _productSearchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: isStart ? 'CHỌN NGÀY BẮT ĐẦU KHUYẾN MÃI' : 'CHỌN NGÀY KẾT THÚC KHUYẾN MÃI',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: isStart ? 'CHỌN GIỜ BẮT ĐẦU' : 'CHỌN GIỜ KẾT THÚC',
    );
    if (!mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? current.hour,
      pickedTime?.minute ?? current.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = newDateTime;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = newDateTime;
      }
    });
  }

  double _parseDiscountValue() {
    final text = _discountValCtrl.text.trim();
    if (text.isEmpty) return 0;
    if (_discountType == 'PERCENTAGE') {
      return double.tryParse(text.replaceAll(',', '.')) ?? 0;
    } else {
      final cleaned = text.replaceAll(',', '').replaceAll('.', '');
      return double.tryParse(cleaned) ?? 0;
    }
  }

  double _calculatePromoPrice(double originalPrice) {
    final dVal = _parseDiscountValue();
    if (_discountType == 'PERCENTAGE') {
      return originalPrice * (1 - (dVal / 100).clamp(0.0, 1.0));
    } else {
      return (originalPrice - dVal).clamp(0.0, double.infinity);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên chương trình khuyến mãi'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian kết thúc phải diễn ra sau thời gian bắt đầu!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final dVal = _parseDiscountValue();
    if (dVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mức giảm giá phải lớn hơn 0'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_discountType == 'PERCENTAGE' && dVal > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mức giảm giá theo phần trăm không được vượt quá 100%'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_selectedVariantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một sản phẩm để áp dụng khuyến mãi'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEditing = widget.existingPromo != null;
    final promo = Promotion(
      promotionId: isEditing ? widget.existingPromo!.promotionId : 0,
      name: name,
      description: _descCtrl.text.trim(),
      discountType: _discountType,
      discountValue: dVal,
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
      createdAt: isEditing ? widget.existingPromo!.createdAt : DateTime.now(),
      variantIds: _selectedVariantIds.toList(),
    );

    final res = isEditing
        ? await widget.apiService.updatePromotion(widget.existingPromo!.promotionId, promo, token: widget.token)
        : await widget.apiService.createPromotion(promo, token: widget.token);

    if (mounted) {
      setState(() => _isSaving = false);
      if (res.success) {
        Navigator.pop(context);
        widget.onSaved();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final isEditing = widget.existingPromo != null;

    final isDateRangeInvalid = _endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate);

    final matchingVariants = _searchQuery.isEmpty
        ? <_VariantChoiceOption>[]
        : _availableVariants.where((v) {
            final q = _searchQuery.toLowerCase();
            return v.productName.toLowerCase().contains(q) ||
                v.variantName.toLowerCase().contains(q) ||
                v.label.toLowerCase().contains(q) ||
                v.variantId.toString().contains(q);
          }).toList();

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditing ? 'Sửa Khuyến Mãi: ${widget.existingPromo?.name}' : 'Tạo Chương Trình Khuyến Mãi Mới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
      content: SizedBox(
        width: (MediaQuery.of(context).size.width * 0.92).clamp(760.0, 980.0),
        height: (MediaQuery.of(context).size.height * 0.82).clamp(480.0, 620.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CỘT TRÁI: THỂ LỆ & THỜI GIAN (flex: 5) ===
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THÔNG TIN CHƯƠNG TRÌNH',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 1. Tên & Mô tả
                    AppTextField(
                      controller: _nameCtrl,
                      labelText: 'Tên chương trình khuyến mãi (*)',
                      hintText: 'Ví dụ: Flash Sale Cuối Tuần Giảm 20%',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      labelText: 'Mô tả thể lệ khuyến mãi',
                      hintText: 'Chi tiết về điều kiện và thể lệ áp dụng...',
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'HÌNH THỨC & THỜI GIAN ÁP DỤNG',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Loại giảm giá & Mức giảm
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            value: _discountType,
                            labelText: 'Loại giảm giá (*)',
                            items: const [
                              DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần trăm (%)')),
                              DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Cố định (VNĐ)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _discountType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            controller: _discountValCtrl,
                            keyboardType: TextInputType.number,
                            labelText: _discountType == 'PERCENTAGE' ? 'Mức giảm (%)(*)' : 'Mức giảm (VNĐ)(*)',
                            hintText: _discountType == 'PERCENTAGE' ? 'Ví dụ: 15' : 'Ví dụ: 500000',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Khung điền Thời gian bắt đầu và kết thúc
                    Row(
                      children: [
                        // Start Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thời gian bắt đầu (*)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _pickDateTime(true),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dateFormat.format(_startDate),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // End Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Thời gian kết thúc (*)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDateRangeInvalid ? AppColors.danger : textPrimary,
                                    ),
                                  ),
                                  if (isDateRangeInvalid) ...[
                                    const SizedBox(width: 4),
                                    const Text('(Lỗi)', style: TextStyle(fontSize: 10.5, color: AppColors.danger)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _pickDateTime(false),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDateRangeInvalid ? AppColors.danger : borderColor,
                                      width: isDateRangeInvalid ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 15,
                                        color: isDateRangeInvalid ? AppColors.danger : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dateFormat.format(_endDate),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDateRangeInvalid ? AppColors.danger : textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isDateRangeInvalid)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          '⚠️ Thời gian kết thúc phải sau thời gian bắt đầu!',
                          style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 4. Kích hoạt ngay Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: SwitchListTile(
                        title: const Text('Kích hoạt chương trình ngay', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        subtitle: Text('Áp dụng trực tiếp giá khuyến mãi cho khách', style: TextStyle(fontSize: 11, color: textSecondary)),
                        value: _isActive,
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            VerticalDivider(width: 24, thickness: 1, color: borderColor),

            // === CỘT PHẢI: CHỌN SẢN PHẨM & PREVIEW GIÁ (flex: 6) ===
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SẢN PHẨM ÁP DỤNG (*)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_selectedVariantIds.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: AppColors.danger),
                          label: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 11.5, color: AppColors.danger)),
                          onPressed: () {
                            setState(() {
                              _selectedVariantIds.clear();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Ô tìm kiếm sản phẩm
                  AppTextField(
                    controller: _productSearchCtrl,
                    focusNode: _searchFocusNode,
                    labelText: 'Tìm kiếm sản phẩm hoặc biến thể...',
                    hintText: 'Nhập tên sản phẩm (vd: ASUS, iPhone...), mã...',
                    prefixIcon: Icons.search_rounded,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _productSearchCtrl.clear();
                                _searchQuery = '';
                                _showDropdown = false;
                              });
                            },
                          )
                        : null,
                  ),

                  // Dropdown gợi ý nếu đang tìm kiếm
                  if (_showDropdown && _searchQuery.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: matchingVariants.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Không tìm thấy sản phẩm nào khớp với "$_searchQuery"',
                                      style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Gợi ý sản phẩm (${matchingVariants.length}):',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                                      ),
                                      Row(
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                for (var v in matchingVariants) {
                                                  _selectedVariantIds.add(v.variantId);
                                                }
                                              });
                                            },
                                            child: const Text('Thêm tất cả gợi ý', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => setState(() => _showDropdown = false),
                                            child: Icon(Icons.close, size: 14, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: matchingVariants.length,
                                    separatorBuilder: (ctx, index) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                                    itemBuilder: (ctx, idx) {
                                      final item = matchingVariants[idx];
                                      final isAdded = _selectedVariantIds.contains(item.variantId);
                                      final promoPrice = _calculatePromoPrice(item.price);
                                      final dVal = _parseDiscountValue();

                                      return ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                              ? Image.network(
                                                  item.imageUrl!,
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 32,
                                                    height: 32,
                                                    color: Colors.black12,
                                                    child: const Icon(Icons.devices, size: 14),
                                                  ),
                                                )
                                              : Container(
                                                  width: 32,
                                                  height: 32,
                                                  color: Colors.black12,
                                                  child: const Icon(Icons.devices, size: 14),
                                                ),
                                        ),
                                        title: Text(
                                          item.label,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Row(
                                          children: [
                                            Text(
                                              currencyFormat.format(item.price),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: textSecondary,
                                                decoration: isAdded && dVal > 0 ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            if (dVal > 0) ...[
                                              const SizedBox(width: 3),
                                              const Icon(Icons.arrow_forward_rounded, size: 9, color: AppColors.success),
                                              const SizedBox(width: 2),
                                              Text(
                                                currencyFormat.format(promoPrice),
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            Text('| Tồn: ${item.stockQuantity}', style: TextStyle(fontSize: 10, color: textSecondary)),
                                          ],
                                        ),
                                        trailing: isAdded
                                            ? Chip(
                                                label: const Text('Đã chọn', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                                                side: BorderSide.none,
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                                avatar: const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                              )
                                            : ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  visualDensity: VisualDensity.compact,
                                                  elevation: 0,
                                                ),
                                                icon: const Icon(Icons.add_rounded, size: 12),
                                                label: const Text('Thêm', style: TextStyle(fontSize: 10.5)),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedVariantIds.add(item.variantId);
                                                  });
                                                },
                                              ),
                                        onTap: () {
                                          setState(() {
                                            if (isAdded) {
                                              _selectedVariantIds.remove(item.variantId);
                                            } else {
                                              _selectedVariantIds.add(item.variantId);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        'Danh sách đã chọn (${_selectedVariantIds.length})',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(áp dụng trực tiếp giảm giá)',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                      child: _selectedVariantIds.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 32, color: textSecondary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Chưa có sản phẩm nào được chọn',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textSecondary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Tìm kiếm ở ô trên để thêm sản phẩm vào khuyến mãi',
                                    style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _selectedVariantIds.length,
                              separatorBuilder: (ctx, index) => Divider(height: 1, color: borderColor.withValues(alpha: 0.4)),
                              itemBuilder: (c, i) {
                                final vId = _selectedVariantIds.elementAt(i);
                                final item = _availableVariants.firstWhere(
                                  (v) => v.variantId == vId,
                                  orElse: () => _VariantChoiceOption(
                                    variantId: vId,
                                    productId: 0,
                                    productName: 'Biến thể #$vId',
                                    variantName: '',
                                    label: 'Biến thể #$vId',
                                    price: 0,
                                  ),
                                );

                                final promoPrice = _calculatePromoPrice(item.price);
                                final dVal = _parseDiscountValue();

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 32,
                                              height: 32,
                                              color: Colors.black12,
                                              child: const Icon(Icons.devices, size: 14),
                                            ),
                                          )
                                        : Container(
                                            width: 32,
                                            height: 32,
                                            color: Colors.black12,
                                            child: const Icon(Icons.devices, size: 14),
                                          ),
                                  ),
                                  title: Text(
                                    item.label,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text('Giá gốc: ${currencyFormat.format(item.price)}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                      if (dVal > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '➔ ${currencyFormat.format(promoPrice)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                                    tooltip: 'Gỡ khỏi khuyến mãi',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    onPressed: () {
                                      setState(() {
                                        _selectedVariantIds.remove(vId);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy',
          variant: AppButtonVariant.outline,
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        AppButton(
          label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _handleSave,
        ),
      ],
    );
  }
}
