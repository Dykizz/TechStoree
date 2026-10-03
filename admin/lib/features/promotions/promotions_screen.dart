import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/promotion.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'Khuyến Mãi & Giảm Giá',
                subtitle: 'Quản lý các chương trình Flash Sale và giảm giá biến thể sản phẩm',
                action: AppButton(
                  label: 'Tạo Khuyến Mãi Mới',
                  icon: Icons.add_rounded,
                  onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token),
                ),
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
                ],
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 48,
                                      columns: [
                                        DataColumn(label: Text('TÊN CHƯƠNG TRÌNH', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('LOẠI GIẢM GIÁ', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('MỨC GIẢM', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('THỜI GIAN ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('SỐ SP ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('BẬT/TẮT', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                      ],
                                      rows: paginatedPromotions.map((promo) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    promo.name,
                                                    style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
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
                                                activeThumbColor: AppColors.primary,
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
                                                    icon: Icon(Icons.visibility_outlined, size: 18, color: textSecondary),
                                                    tooltip: 'Xem chi tiết biến thể',
                                                    onPressed: () => _showPromotionDetailsDialog(context, apiService, authProvider.token, promo.promotionId),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                                                    tooltip: 'Sửa chương trình',
                                                    onPressed: () => _showCreateOrEditDialog(context, apiService, authProvider.token, existingPromoId: promo.promotionId),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                                    tooltip: 'Xóa khuyến mãi',
                                                    onPressed: () => _confirmDeletePromotion(context, apiService, authProvider.token, promo),
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

  Widget _buildStatusChip(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const StatusBadge(label: 'Đang diễn ra', isSuccess: true);
      case 'UPCOMING':
        return const StatusBadge(label: 'Sắp diễn ra', isInfo: true);
      case 'EXPIRED':
        return const StatusBadge(label: 'Đã hết hạn', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }

  void _showPromotionDetailsDialog(BuildContext context, ApiService apiService, String? token, int promoId) async {
    final promo = await apiService.getPromotionById(promoId, token: token);
    if (!context.mounted || promo == null) return;

    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(promo.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(promo.description.isNotEmpty ? promo.description : 'Không có mô tả thể lệ.', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Text('Biến thể áp dụng (${promo.variants.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: promo.variants.length,
                  itemBuilder: (c, i) {
                    final item = promo.variants[i];
                    return ListTile(
                      dense: true,
                      title: Text(item.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Gốc: ${currencyFormat.format(item.originalPrice)} ➔ Giảm: ${currencyFormat.format(item.promotionalPrice)}', style: const TextStyle(fontSize: 12)),
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
    }

    if (!context.mounted) return;

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
      text: isEditing ? existingPromo.discountValue.toInt().toString() : '10',
    );

    String discountType = isEditing ? existingPromo.discountType : 'PERCENTAGE';
    DateTime startDate = isEditing ? existingPromo.startDate : DateTime.now();
    DateTime endDate = isEditing ? existingPromo.endDate : DateTime.now().add(const Duration(days: 7));
    bool isActive = isEditing ? existingPromo.isActive : true;

    Set<int> selectedVariantIds = isEditing ? existingPromo.variantIds.toSet() : <int>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              isEditing ? 'Sửa Khuyến Mãi: ${existingPromo?.name}' : 'Tạo Chương Trình Khuyến Mãi Mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(controller: nameCtrl, labelText: 'Tên chương trình khuyến mãi (*)'),
                    const SizedBox(height: 12),
                    AppTextField(controller: descCtrl, maxLines: 2, labelText: 'Mô tả thể lệ khuyến mãi'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            value: discountType,
                            labelText: 'Loại giảm giá',
                            items: const [
                              DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần trăm (%)')),
                              DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Số tiền cố định (VNĐ)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialogState(() => discountType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: discountValCtrl,
                            keyboardType: TextInputType.number,
                            labelText: 'Mức giảm giá (*)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Chọn biến thể sản phẩm áp dụng (${selectedVariantIds.length}):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.lightCardBorder), borderRadius: BorderRadius.circular(8)),
                      child: ListView.builder(
                        itemCount: availableVariants.length,
                        itemBuilder: (c, i) {
                          final item = availableVariants[i];
                          final isSelected = selectedVariantIds.contains(item.variantId);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(item.label, style: const TextStyle(fontSize: 12)),
                            subtitle: Text(currencyFormat.format(item.price), style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedVariantIds.add(item.variantId);
                                } else {
                                  selectedVariantIds.remove(item.variantId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Kích hoạt ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final dVal = double.tryParse(discountValCtrl.text.trim()) ?? 0;
                  final promo = Promotion(
                    promotionId: isEditing ? existingPromo!.promotionId : 0,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    discountType: discountType,
                    discountValue: dVal,
                    startDate: startDate,
                    endDate: endDate,
                    isActive: isActive,
                    createdAt: isEditing ? existingPromo!.createdAt : DateTime.now(),
                    variantIds: selectedVariantIds.toList(),
                  );

                  final res = isEditing
                      ? await apiService.updatePromotion(existingPromo!.promotionId, promo, token: token)
                      : await apiService.createPromotion(promo, token: token);


                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
                    );
                  }
                },
              ),
            ],
          );
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
  final String label;
  final double price;

  _VariantChoiceOption({required this.variantId, required this.label, required this.price});
}
