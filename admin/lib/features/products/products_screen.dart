import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/product.dart';
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
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  bool _isGridView = true;
  int _currentPage = 1;
  int _itemsPerPage = 8;

  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ApiService>(context, listen: false).addListener(_onApiServiceChanged);
      }
    });
    _loadProducts();
  }

  void _onApiServiceChanged() {
    if (mounted) {
      setState(() {
        _loadProducts();
      });
    }
  }

  void _loadProducts() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _productsFuture = apiService.getProducts(token: token);
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
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bgSubtle = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allProducts = snapshot.data ?? [];

        final totalCount = allProducts.length;
        final totalStockSum = allProducts.fold<int>(0, (sum, p) => sum + p.stock);
        final lowStockCount = allProducts.where((p) => p.stock > 0 && p.stock <= 10).length;
        final outOfStockCount = allProducts.where((p) => p.stock == 0).length;

        var filteredProducts = allProducts;
        if (_searchQuery.isNotEmpty) {
          filteredProducts = filteredProducts.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.sku.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (_selectedCategory != 'Tất cả') {
          filteredProducts = filteredProducts.where((p) => p.category == _selectedCategory).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          filteredProducts = filteredProducts.where((p) => p.status == _selectedStatus).toList();
        }

        final totalItems = filteredProducts.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedProducts = filteredProducts.sublist(startIndex, endIndex);

        final categoriesList = ['Tất cả', ...allProducts.map((p) => p.category).toSet().toList()];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản lý Sản phẩm',
                subtitle: 'Danh sách các sản phẩm, biến thể và mức tồn kho hệ thống TechStoree',
                action: AppButton(
                  label: 'Thêm sản phẩm mới',
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () => _showProductDialog(context, apiService, authProvider.token),
                ),
              ),
              const SizedBox(height: AppTokens.space20),

              // Summary Stats
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppTokens.space16,
                    crossAxisSpacing: AppTokens.space16,
                    childAspectRatio: isWide ? 2.5 : 1.8,
                    children: [
                      StatCard(
                        title: 'TỔNG SẢN PHẨM',
                        value: '$totalCount',
                        trendText: '+5.2%',
                        isTrendPositive: true,
                        icon: Icons.inventory_2_outlined,
                        iconColor: AppColors.primary,
                      ),
                      StatCard(
                        title: 'TỔNG TỒN KHO',
                        value: '$totalStockSum cái',
                        trendText: '+12%',
                        isTrendPositive: true,
                        icon: Icons.store_outlined,
                        iconColor: AppColors.success,
                      ),
                      StatCard(
                        title: 'TỒN THẤP',
                        value: '$lowStockCount sản phẩm',
                        trendText: '-2',
                        isTrendPositive: false,
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.warning,
                      ),
                      StatCard(
                        title: 'HẾT HÀNG KHO',
                        value: '$outOfStockCount sản phẩm',
                        trendText: '0',
                        isTrendPositive: true,
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.danger,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTokens.space20),

              // Filter Bar Container
              FilterBar(
                searchField: AppSearchField<Product>(
                  controller: _searchCtrl,
                  hintText: 'Tìm kiếm sản phẩm theo tên, mã SKU...',
                  items: allProducts,
                  searchFilter: (p, q) => p.name.toLowerCase().contains(q.toLowerCase()) || p.sku.toLowerCase().contains(q.toLowerCase()) || p.category.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (p) => p.name,
                  itemSubtitle: (p) => '${p.category} • SKU: ${p.sku} • ${currencyFormat.format(p.price)}',
                  onSelected: (p) => setState(() => _searchQuery = p.name),
                  onSubmitted: (val) => setState(() => _searchQuery = val),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'In Stock', child: Text('Còn hàng')),
                      DropdownMenuItem(value: 'Low Stock', child: Text('Sắp hết')),
                      DropdownMenuItem(value: 'Out of Stock', child: Text('Hết hàng')),
                      DropdownMenuItem(value: 'Ngừng bán', child: Text('Ngừng bán')),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val ?? 'Tất cả'),
                  ),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgSubtle,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            color: _isGridView ? AppColors.primary : textSecondary,
                          ),
                          tooltip: 'Xem dạng thẻ Lưới',
                          onPressed: () => setState(() => _isGridView = true),
                        ),
                        Container(width: 1, height: 18, color: borderColor),
                        IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(
                            Icons.view_list_rounded,
                            color: !_isGridView ? AppColors.primary : textSecondary,
                          ),
                          tooltip: 'Xem dạng Bảng',
                          onPressed: () => setState(() => _isGridView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),

              // Horizontal Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoriesList.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTokens.space8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: surfaceColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTokens.space20),

              // Display Area
              filteredProducts.isEmpty
                  ? const DataTableContainer(
                      child: EmptyState(
                        title: 'Không tìm thấy sản phẩm phù hợp',
                        message: 'Thử đổi từ khóa tìm kiếm hoặc chọn bộ lọc danh mục khác.',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  : _isGridView
                      ? Column(
                          children: [
                            _buildGridProductsView(paginatedProducts, apiService, authProvider.token, surfaceColor, borderColor, textPrimary, textSecondary, isDark),
                            if (totalItems > 0) ...[
                              const SizedBox(height: AppTokens.space16),
                              AppPagination(
                                currentPage: safePage,
                                totalPages: totalPages,
                                totalItems: totalItems,
                                itemsPerPage: _itemsPerPage,
                                itemsPerPageOptions: const [4, 8, 12, 24],
                                onPageChanged: (page) => setState(() => _currentPage = page),
                                onItemsPerPageChanged: (size) => setState(() {
                                  _itemsPerPage = size;
                                  _currentPage = 1;
                                }),
                              ),
                            ],
                          ],
                        )
                      : _buildTableProductsView(
                          paginatedProducts,
                          apiService,
                          authProvider.token,
                          surfaceColor,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          isDark,
                          safePage,
                          totalPages,
                          totalItems,
                        ),
            ],
          ),
        );
      },
    );
  }

  // --- GRID CARD VIEW ---
  Widget _buildGridProductsView(
    List<Product> products,
    ApiService apiService,
    String? token,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 700) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1400) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppTokens.space16,
            crossAxisSpacing: AppTokens.space16,
            childAspectRatio: 0.78,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: borderColor),
                boxShadow: AppTokens.subtleShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image & Badges Header
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMd)),
                        child: AspectRatio(
                          aspectRatio: 1.7,
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.primary.withOpacity(0.06),
                              child: const Icon(Icons.devices, size: 40, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          ),
                          child: Text(
                            p.category,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _renderStatusBadge(p.status),
                      ),
                    ],
                  ),

                  // Main Info Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${p.sku}',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 6),

                          if (p.variants.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              ),
                              child: Text(
                                '${p.variants.length} biến thể (${p.variants.map((v) => v.variantName).take(2).join(', ')})',
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          const Spacer(),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Giá niêm yết', style: TextStyle(color: textSecondary, fontSize: 10)),
                                  Text(
                                    currencyFormat.format(p.price),
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Tồn kho', style: TextStyle(color: textSecondary, fontSize: 10)),
                                  Text(
                                    '${p.stock} cái',
                                    style: TextStyle(
                                      color: p.stock > 10 ? textPrimary : (p.stock > 0 ? AppColors.warning : AppColors.danger),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTokens.radiusMd)),
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                          tooltip: 'Xem chi tiết',
                          onPressed: () => _showProductDetailView(context, p, textPrimary, textSecondary, isDark),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                          tooltip: 'Sửa sản phẩm',
                          onPressed: () => _showProductDialog(context, apiService, token, product: p),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: p.status == 'Ngừng bán' ? 'Kích hoạt lại' : 'Ngừng bán',
                          child: Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: p.status != 'Ngừng bán',
                              onChanged: (_) async {
                                final res = await apiService.toggleProductStatus(p.id, token: token);
                                if (context.mounted) {
                                  if (res.success) setState(() { _loadProducts(); });
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          tooltip: 'Xóa sản phẩm',
                          onPressed: () => _showDeleteConfirm(context, apiService, token, p),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TABLE VIEW ---
  Widget _buildTableProductsView(
    List<Product> products,
    ApiService apiService,
    String? token,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    int safePage,
    int totalPages,
    int totalItems,
  ) {
    return DataTableContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 44,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
              columns: const [
                DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Giá niêm yết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              ],
              rows: products.map((product) {
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            child: Image.network(
                              product.imageUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 36,
                                height: 36,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.devices, size: 18, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                product.description,
                                style: TextStyle(color: textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(product.sku, style: TextStyle(color: textSecondary, fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${product.variants.length} mẫu',
                        style: TextStyle(color: textPrimary, fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${product.stock} cái',
                        style: TextStyle(
                          color: product.stock > 10 ? textPrimary : (product.stock > 0 ? AppColors.warning : AppColors.danger),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(_renderStatusBadge(product.status)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                            onPressed: () => _showProductDetailView(context, product, textPrimary, textSecondary, isDark),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                            onPressed: () => _showProductDialog(context, apiService, token, product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                            onPressed: () => _showDeleteConfirm(context, apiService, token, product),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (totalItems > 0)
            AppPagination(
              currentPage: safePage,
              totalPages: totalPages,
              totalItems: totalItems,
              itemsPerPage: _itemsPerPage,
              itemsPerPageOptions: const [4, 8, 12, 24],
              onPageChanged: (page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (size) => setState(() {
                _itemsPerPage = size;
                _currentPage = 1;
              }),
            ),
        ],
      ),
    );
  }

  Widget _renderStatusBadge(String status) {
    switch (status) {
      case 'In Stock':
        return const StatusBadge(label: 'Còn hàng', isSuccess: true);
      case 'Low Stock':
        return const StatusBadge(label: 'Sắp hết', isWarning: true);
      case 'Out of Stock':
        return const StatusBadge(label: 'Hết hàng', isDanger: true);
      default:
        return const StatusBadge(label: 'Ngừng bán');
    }
  }

  // --- QUICK VIEW DETAIL DIALOG ---
  void _showProductDetailView(BuildContext context, Product p, Color textPrimary, Color textSecondary, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: AspectRatio(
                    aspectRatio: 2.2,
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppColors.primary.withOpacity(0.08),
                        child: const Icon(Icons.devices, size: 44, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mã SKU:', style: TextStyle(color: textSecondary, fontSize: 11)),
                          Text(p.sku, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danh mục:', style: TextStyle(color: textSecondary, fontSize: 11)),
                          Text(p.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space12),
                Text('Mô tả sản phẩm:', style: TextStyle(color: textSecondary, fontSize: 11)),
                Text(
                  p.description.isNotEmpty ? p.description : 'Chưa có mô tả chi tiết.',
                  style: TextStyle(color: textPrimary, fontSize: 13),
                ),
                const SizedBox(height: AppTokens.space16),
                const Divider(),
                const SizedBox(height: AppTokens.space8),
                Text('Danh sách Biến thể (${p.variants.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: AppTokens.space8),
                if (p.variants.isEmpty)
                  Text('Không có biến thể cụ thể.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: textSecondary))
                else
                  Column(
                    children: p.variants.map((v) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTokens.space8),
                        padding: const EdgeInsets.all(AppTokens.space12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.variantName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                Text(v.attributesText, style: TextStyle(color: textSecondary, fontSize: 11)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(v.price), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                                Text('Tồn: ${v.stockQuantity} cái', style: TextStyle(color: textSecondary, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // --- EDIT / CREATE DIALOG ---
  void _showProductDialog(BuildContext context, ApiService apiService, String? token, {Product? product}) async {
    final categories = await apiService.getCategories(token: token);

    if (!context.mounted) return;

    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: isEditing ? product.name : '');
    final priceCtrl = TextEditingController(text: isEditing ? product.price.toInt().toString() : '');
    final descCtrl = TextEditingController(text: isEditing ? product.description : '');

    int selectedCategoryId;
    if (isEditing) {
      selectedCategoryId = product.categoryId;
    } else if (categories.isNotEmpty) {
      selectedCategoryId = int.tryParse(categories.first.id) ?? 1;
    } else {
      selectedCategoryId = 1;
    }

    List<TextEditingController> attrTypeCtrls = [];
    if (isEditing && product.variantAttributes.isNotEmpty) {
      for (var attrName in product.variantAttributes) {
        attrTypeCtrls.add(TextEditingController(text: attrName));
      }
    } else if (isEditing && product.variants.isNotEmpty) {
      Set<String> keys = {};
      for (var v in product.variants) {
        keys.addAll(v.attributes.keys);
      }
      for (var k in keys) {
        attrTypeCtrls.add(TextEditingController(text: k));
      }
    }

    List<_VariantInputRow> variantRows = [];
    if (isEditing && product.variants.isNotEmpty) {
      for (var v in product.variants) {
        variantRows.add(_VariantInputRow(
          price: v.price,
          initialAttributes: v.attributes,
          variantId: v.variantId,
        ));
      }
    } else {
      variantRows.add(_VariantInputRow(price: isEditing ? product.price : 0));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_outlined : Icons.add_box_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppTokens.space8),
              Text(isEditing ? 'Sửa thông tin sản phẩm' : 'Thêm sản phẩm mới vào kho', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    labelText: 'Tên sản phẩm (*)',
                  ),
                  const SizedBox(height: AppTokens.space12),
                  if (categories.isNotEmpty) ...[
                    AppDropdown<int>(
                      value: categories.any((c) => int.tryParse(c.id) == selectedCategoryId)
                          ? selectedCategoryId
                          : (int.tryParse(categories.first.id) ?? 1),
                      items: categories.map((cat) {
                        final catId = int.tryParse(cat.id) ?? 1;
                        return DropdownMenuItem<int>(
                          value: catId,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategoryId = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppTokens.space12),
                  ],
                  AppTextField(
                    controller: priceCtrl,
                    labelText: 'Giá niêm yết mặc định (VNĐ)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  AppTextField(
                    controller: descCtrl,
                    labelText: 'Mô tả chi tiết',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppTokens.space20),
                  const Divider(),
                  const SizedBox(height: AppTokens.space8),
                  const Text(
                    '1. KHAI BÁO LOẠI BIẾN THỂ (VD: RAM, Dung lượng, Màu sắc...)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhập tên các loại biến thể trước. Các ô nhập giá trị tương ứng sẽ tự động hiển thị ở danh sách biến thể bên dưới.',
                    style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  ...attrTypeCtrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: ctrl,
                              labelText: 'Loại biến thể #${index + 1}',
                              hintText: 'vd: RAM, Dung lượng, Màu sắc',
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 18),
                            onPressed: () {
                              setDialogState(() {
                                ctrl.dispose();
                                attrTypeCtrls.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Thêm loại biến thể',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        setDialogState(() {
                          attrTypeCtrls.add(TextEditingController());
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),
                  const Divider(),
                  const SizedBox(height: AppTokens.space8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. THÔNG SỐ VÀ GIÁ BÁN CHO TỪNG BIẾN THỂ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
                      ),
                      AppButton(
                        label: 'Thêm biến thể',
                        icon: Icons.add_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          setDialogState(() {
                            variantRows.add(_VariantInputRow(price: double.tryParse(priceCtrl.text) ?? 0));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),

                  ...variantRows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;

                    final activeAttrNames = attrTypeCtrls
                        .map((c) => c.text.trim())
                        .where((name) => name.isNotEmpty)
                        .toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.space12),
                      padding: const EdgeInsets.all(AppTokens.space12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Biến thể #${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const Spacer(),
                              if (variantRows.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                  onPressed: () {
                                    setDialogState(() {
                                      row.dispose();
                                      variantRows.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.space8),
                          if (activeAttrNames.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Vui lòng thêm loại biến thể ở mục 1 trước (vd: RAM, Dung lượng).',
                                style: TextStyle(color: AppColors.warning, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            Column(
                              children: activeAttrNames.map((attrName) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppTokens.space8),
                                  child: AppTextField(
                                    controller: row.getControllerForAttribute(attrName),
                                    labelText: '$attrName (vd: 16GB, 256GB...)',
                                  ),
                                );
                              }).toList(),
                            ),
                          AppTextField(
                            controller: row.priceCtrl,
                            labelText: 'Giá bán biến thể (VNĐ)',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            AppButton(
              label: 'Hủy',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                for (var r in variantRows) { r.dispose(); }
                for (var c in attrTypeCtrls) { c.dispose(); }
                Navigator.pop(ctx);
              },
            ),
            AppButton(
              label: isEditing ? 'Cập Nhật' : 'Lưu Sản Phẩm',
              variant: AppButtonVariant.primary,
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final finalAttrTypes = attrTypeCtrls
                    .map((c) => c.text.trim())
                    .where((name) => name.isNotEmpty)
                    .toList();

                List<ProductVariant> variants = [];
                for (var row in variantRows) {
                  final vPrice = double.tryParse(row.priceCtrl.text) ?? (double.tryParse(priceCtrl.text) ?? 0);
                  Map<String, String> attrs = {};

                  for (var attrName in finalAttrTypes) {
                    final val = row.getControllerForAttribute(attrName).text.trim();
                    if (val.isNotEmpty) {
                      attrs[attrName] = val;
                    }
                  }

                  variants.add(ProductVariant(
                    variantId: row.variantId,
                    price: vPrice,
                    attributes: attrs,
                    imageUrl: isEditing ? product.imageUrl : 'https://picsum.photos/200',
                    isActive: true,
                  ));
                }

                String selectedCatName = 'Công nghệ';
                try {
                  final matchedCat = categories.firstWhere((c) => int.tryParse(c.id) == selectedCategoryId);
                  selectedCatName = matchedCat.name;
                } catch (_) {}

                final p = Product(
                  id: isEditing ? product.id : '0',
                  name: nameCtrl.text.trim(),
                  sku: isEditing ? product.sku : 'PROD-${DateTime.now().millisecondsSinceEpoch}',
                  category: selectedCatName,
                  categoryId: selectedCategoryId,
                  price: double.tryParse(priceCtrl.text) ?? (variants.isNotEmpty ? variants.first.price : 0),
                  stock: isEditing ? product.stock : 10,
                  status: isEditing ? product.status : 'In Stock',
                  imageUrl: isEditing ? product.imageUrl : 'https://picsum.photos/200',
                  description: descCtrl.text.trim(),
                  variantAttributes: finalAttrTypes,
                  variants: variants,
                );

                ApiResult result;
                if (isEditing) {
                  result = await apiService.updateProduct(p, token: token);
                } else {
                  result = await apiService.createProduct(p, token: token);
                }

                for (var r in variantRows) { r.dispose(); }
                for (var c in attrTypeCtrls) { c.dispose(); }

                if (context.mounted) {
                  Navigator.pop(ctx);
                  if (result.success) {
                    setState(() {
                      _loadProducts();
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? AppColors.success : AppColors.danger,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ApiService apiService, String? token, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: const Text('Xác nhận xóa sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}" khỏi hệ thống không?'),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Xóa',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              final result = await apiService.deleteProduct(product.id, token: token);
              if (context.mounted) {
                Navigator.pop(ctx);
                if (result.success) {
                  setState(() {
                    _loadProducts();
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppColors.success : AppColors.danger,
                    duration: const Duration(seconds: 4),
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

class _VariantInputRow {
  final TextEditingController priceCtrl;
  final Map<String, TextEditingController> attributeCtrls;
  int? variantId;

  _VariantInputRow({
    double price = 0,
    Map<String, String>? initialAttributes,
    this.variantId,
  })  : priceCtrl = TextEditingController(text: price > 0 ? price.toInt().toString() : ''),
        attributeCtrls = {} {
    if (initialAttributes != null) {
      initialAttributes.forEach((k, v) {
        attributeCtrls[k] = TextEditingController(text: v);
      });
    }
  }

  TextEditingController getControllerForAttribute(String attrName) {
    if (!attributeCtrls.containsKey(attrName)) {
      attributeCtrls[attrName] = TextEditingController();
    }
    return attributeCtrls[attrName]!;
  }

  void dispose() {
    priceCtrl.dispose();
    for (var ctrl in attributeCtrls.values) {
      ctrl.dispose();
    }
  }
}
