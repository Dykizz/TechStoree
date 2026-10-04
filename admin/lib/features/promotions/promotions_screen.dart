import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/promotion.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_pagination.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedDiscountType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 10;

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

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
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

        final totalItems = promotions.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedPromotions = promotions.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Controls
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Box
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tên khuyến mãi, mô tả...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: backgroundColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Discount Type Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDiscountType,
                        dropdownColor: backgroundColor,
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả loại giảm giá')),
                          DropdownMenuItem(value: 'PERCENTAGE', child: Text('Giảm theo phần trăm (%)')),
                          DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Giảm số tiền cố định (VNĐ)')),
                        ],
                        onChanged: (val) => setState(() => _selectedDiscountType = val ?? 'Tất cả'),
                      ),
                    ),
                  ),

                  // Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: backgroundColor,
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Đang diễn ra (ACTIVE)')),
                          DropdownMenuItem(value: 'UPCOMING', child: Text('Sắp diễn ra (UPCOMING)')),
                          DropdownMenuItem(value: 'EXPIRED', child: Text('Đã kết thúc (EXPIRED)')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val ?? 'Tất cả'),
                      ),
                    ),
                  ),

                  // Create Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Tạo khuyến mãi mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data Table Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: promotions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_outlined, size: 48, color: textSecondary),
                                const SizedBox(height: 12),
                                Text('Chưa có chương trình khuyến mãi nào', style: TextStyle(color: textSecondary, fontSize: 14)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                ),
                                dataRowMinHeight: 65,
                                dataRowMaxHeight: 65,
                                columns: const [
                                  DataColumn(label: Text('Tên chương trình', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Loại giảm giá', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Mức giảm', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Thời gian áp dụng', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Số SP áp dụng', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Thời hạn', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Bật/Tắt', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: paginatedPromotions.map((promo) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              promo.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
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
                                      DataCell(_buildDiscountTypeChip(promo.discountType)),
                                      DataCell(
                                        Text(
                                          promo.formattedDiscountValue(currencyFormat),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Từ: ${dateFormat.format(promo.startDate)}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                            Text('Đến: ${dateFormat.format(promo.endDate)}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text('${promo.variantCount} biến thể', style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                      DataCell(_buildStatusChip(promo.status)),
                                      DataCell(
                                        Switch(
                                          value: promo.isActive,
                                          activeColor: AppColors.success,
                                          onChanged: (val) async {
                                            final res = await apiService.togglePromotionActive(promo.promotionId, token: authProvider.token);
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
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.info),
                                              tooltip: 'Xem danh sách SP áp dụng',
                                              onPressed: () => _showDetailDialog(context, apiService, authProvider.token, promo.promotionId),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                              tooltip: 'Chỉnh sửa khuyến mãi',
                                              onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, existingPromoId: promo.promotionId),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                              tooltip: 'Xóa khuyến mãi',
                                              onPressed: () => _showDeleteConfirm(context, apiService, authProvider.token, promo),
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
                ),
              ),
              const SizedBox(height: 16),
              AppPagination(
                currentPage: safePage,
                totalPages: totalPages,
                totalItems: totalItems,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
                onItemsPerPageChanged: (size) => setState(() {
                  _itemsPerPage = size;
                  _currentPage = 1;
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountTypeChip(String discountType) {
    bool isPercentage = discountType == 'PERCENTAGE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPercentage ? AppColors.primary.withOpacity(0.12) : AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPercentage ? 'Phần trăm (%)' : 'Số tiền cố định',
        style: TextStyle(
          color: isPercentage ? AppColors.primary : AppColors.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'ĐANG DIỄN RA';
        break;
      case 'UPCOMING':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'SẮP DIỄN RA';
        break;
      default:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        label = 'ĐÃ KẾT THÚC';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  // --- Show Detail Dialog ---
  void _showDetailDialog(BuildContext context, ApiService apiService, String? token, int promoId) async {
    final promo = await apiService.getPromotionById(promoId, token: token);
    if (!context.mounted || promo == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Chi Tiết Khuyến Mãi: ${promo.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            _buildStatusChip(promo.status),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('Hình thức giảm', promo.isPercentage ? 'Giảm phần trăm (%)' : 'Giảm số tiền cố định')),
                    Expanded(child: _buildInfoItem('Mức giảm ưu đãi', promo.formattedDiscountValue(currencyFormat))),
                    Expanded(child: _buildInfoItem('Trạng thái kích hoạt', promo.isActive ? 'ĐANG BẬT' : 'ĐÃ TẮT')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('Thời gian bắt đầu', dateFormat.format(promo.startDate))),
                    Expanded(child: _buildInfoItem('Thời gian kết thúc', dateFormat.format(promo.endDate))),
                  ],
                ),
                if (promo.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoItem('Mô tả thể lệ', promo.description),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'DANH SÁCH SẢN PHẨM / BIẾN THỂ ÁP DỤNG (${promo.variants.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 8),

                promo.variants.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('Chưa gán biến thể sản phẩm nào cho chương trình khuyến mãi này.')),
                      )
                    : DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Sản phẩm / Biến thể', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Giá niêm yết', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Giá ưu đãi', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Mức giảm', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: promo.variants.map((v) {
                          return DataRow(cells: [
                            DataCell(Text(v.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            DataCell(Text(currencyFormat.format(v.originalPrice), style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey))),
                            DataCell(Text(currencyFormat.format(v.promotionalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success))),
                            DataCell(Text('-${currencyFormat.format(v.discountAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger))),
                            DataCell(Text('${v.stockQuantity}', style: const TextStyle(fontSize: 12))),
                          ]);
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- Create / Edit Dialog ---
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
    }

    if (!context.mounted) return;

    // Collect all variants from products
    List<_VariantChoiceOption> availableVariants = [];
    for (var p in products) {
      if (p.variants.isNotEmpty) {
        for (var v in p.variants) {
          final vId = v.variantId ?? 0;
          if (vId > 0) {
            availableVariants.add(_VariantChoiceOption(
              variantId: vId,
              label: '${p.name} - ${v.variantName}',
              price: v.price > 0 ? v.price : p.price,
            ));
          }
        }
      }
    }

    final isEditing = existingPromo != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingPromo.name : '');
    final descCtrl = TextEditingController(text: isEditing ? existingPromo.description : '');
    final discountValCtrl = TextEditingController(
      text: isEditing
          ? (existingPromo.isPercentage ? existingPromo.discountValue.toInt().toString() : existingPromo.discountValue.toInt().toString())
          : '10',
    );

    String discountType = isEditing ? existingPromo.discountType : 'PERCENTAGE';
    DateTime startDate = isEditing ? existingPromo.startDate : DateTime.now();
    DateTime endDate = isEditing ? existingPromo.endDate : DateTime.now().add(const Duration(days: 7));
    bool isActive = isEditing ? existingPromo.isActive : true;

    Set<int> selectedVariantIds = isEditing ? existingPromo.variantIds.toSet() : <int>{};
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Sửa Khuyến Mãi: ${existingPromo?.name}' : 'Tạo Chương Trình Khuyến Mãi Mới',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên chương trình khuyến mãi (*)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Mô tả thể lệ khuyến mãi', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Discount Type & Value Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: discountType,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Loại giảm giá (*)', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'PERCENTAGE', child: Text('Giảm theo % phần trăm')),
                              DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Giảm số tiền cố định (VNĐ)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => discountType = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: discountValCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: discountType == 'PERCENTAGE' ? 'Mức giảm (%) (*)' : 'Số tiền giảm (VNĐ) (*)',
                              border: const OutlineInputBorder(),
                              suffixText: discountType == 'PERCENTAGE' ? '%' : '₫',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start & End Date Pickers Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (date != null && context.mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(startDate),
                                );
                                setDialogState(() {
                                  startDate = DateTime(
                                    date.year, date.month, date.day,
                                    time?.hour ?? startDate.hour, time?.minute ?? startDate.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Thời gian bắt đầu (*)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
                              child: Text(dateFormat.format(startDate), style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (date != null && context.mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(endDate),
                                );
                                setDialogState(() {
                                  endDate = DateTime(
                                    date.year, date.month, date.day,
                                    time?.hour ?? endDate.hour, time?.minute ?? endDate.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Thời gian kết thúc (*)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.event_available_rounded, size: 18)),
                              child: Text(dateFormat.format(endDate), style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Active Switch
                    Row(
                      children: [
                        const Text('Kích hoạt khuyến mãi ngay khi lưu:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 10),
                        Switch(
                          value: isActive,
                          activeColor: AppColors.success,
                          onChanged: (val) => setDialogState(() => isActive = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Variant Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SẢN PHẨM / BIẾN THỂ ÁP DỤNG (${selectedVariantIds.length}/${availableVariants.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              if (selectedVariantIds.length == availableVariants.length) {
                                selectedVariantIds.clear();
                              } else {
                                selectedVariantIds = availableVariants.map((v) => v.variantId).toSet();
                              }
                            });
                          },
                          child: Text(selectedVariantIds.length == availableVariants.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Variant Checklist Grid / Container
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: availableVariants.isEmpty
                          ? const Center(child: Text('Chưa có danh sách biến thể sản phẩm.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: availableVariants.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final opt = availableVariants[idx];
                                final isChecked = selectedVariantIds.contains(opt.variantId);

                                return CheckboxListTile(
                                  dense: true,
                                  value: isChecked,
                                  title: Text(opt.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  subtitle: Text('Giá niêm yết: ${currencyFormat.format(opt.price)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  activeColor: AppColors.primary,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedVariantIds.add(opt.variantId);
                                      } else {
                                        selectedVariantIds.remove(opt.variantId);
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
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nameCtrl.dispose();
                  descCtrl.dispose();
                  discountValCtrl.dispose();
                  Navigator.pop(ctx);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên chương trình khuyến mãi.'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }

                  final val = double.tryParse(discountValCtrl.text) ?? 0;
                  if (val <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mức giảm giá phải lớn hơn 0.'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }

                  if (discountType == 'PERCENTAGE' && val > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mức giảm phần trăm không được vượt quá 100%.'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }

                  if (endDate.isBefore(startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu.'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }

                  final newPromo = Promotion(
                    promotionId: isEditing ? existingPromo!.promotionId : 0,
                    name: name,
                    description: descCtrl.text.trim(),
                    discountType: discountType,
                    discountValue: val,
                    startDate: startDate,
                    endDate: endDate,
                    isActive: isActive,
                    createdAt: isEditing ? existingPromo!.createdAt : DateTime.now(),
                    variantIds: selectedVariantIds.toList(),
                  );

                  ApiResult res;
                  if (isEditing) {
                    res = await apiService.updatePromotion(existingPromo!.promotionId, newPromo, token: token);
                  } else {
                    res = await apiService.createPromotion(newPromo, token: token);
                  }

                  nameCtrl.dispose();
                  descCtrl.dispose();
                  discountValCtrl.dispose();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    if (res.success) {
                      setState(() => _loadData());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Cập Nhật Khuyến Mãi' : 'Tạo Khuyến Mãi', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Delete Confirm ---
  void _showDeleteConfirm(BuildContext context, ApiService apiService, String? token, Promotion promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa khuyến mãi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa chương trình khuyến mãi "${promo.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final result = await apiService.deletePromotion(promo.promotionId, token: token);
              if (context.mounted) {
                Navigator.pop(ctx);
                if (result.success) {
                  setState(() => _loadData());
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _VariantChoiceOption {
  final int variantId;
  final String label;
  final double price;

  _VariantChoiceOption({required this.variantId, required this.label, required this.price});
}
