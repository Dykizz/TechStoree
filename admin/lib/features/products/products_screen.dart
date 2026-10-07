import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/product.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/widgets/app_button.dart';
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
import '../../core/widgets/product_price_range.dart';
import '../../core/widgets/promotion_badge.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy');

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _sortBy = 'default';
  String _selectedPricePreset = 'Tất cả giá';
  double? _minPrice;
  double? _maxPrice;

  bool _isGridView = false; // Default compact table view for desktop admin
  int _currentPage = 1;
  int _itemsPerPage = 10;

  Product? _selectedProductForDetail;
  int _detailInitialTabIndex = 0;

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
    _productsFuture = apiService.getProductsWithVariants(token: token);
  }

  void _openProductDetail(Product product, int tabIndex) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    Product targetProduct = product;
    if (product.variants.isEmpty && product.id.isNotEmpty && product.id != '0') {
      final detailed = await apiService.getProductById(product.id, token: token);
      if (detailed != null) {
        targetProduct = detailed;
      }
    }

    if (mounted) {
      setState(() {
        _selectedProductForDetail = targetProduct;
        _detailInitialTabIndex = tabIndex;
      });
    }
  }

  void _applyPricePreset(String preset) {
    setState(() {
      _selectedPricePreset = preset;
      _currentPage = 1;
      switch (preset) {
        case '< 2 triệu':
          _minPrice = null;
          _maxPrice = 2000000;
          _minPriceCtrl.clear();
          _maxPriceCtrl.text = '2000000';
          break;
        case '2 - 5 triệu':
          _minPrice = 2000000;
          _maxPrice = 5000000;
          _minPriceCtrl.text = '2000000';
          _maxPriceCtrl.text = '5000000';
          break;
        case '5 - 10 triệu':
          _minPrice = 5000000;
          _maxPrice = 10000000;
          _minPriceCtrl.text = '5000000';
          _maxPriceCtrl.text = '10000000';
          break;
        case '> 10 triệu':
          _minPrice = 10000000;
          _maxPrice = null;
          _minPriceCtrl.text = '10000000';
          _maxPriceCtrl.clear();
          break;
        case 'Tất cả giá':
        default:
          _minPrice = null;
          _maxPrice = null;
          _minPriceCtrl.clear();
          _maxPriceCtrl.clear();
          break;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchCtrl.clear();
      _selectedCategory = 'Tất cả';
      _selectedStatus = 'Tất cả';
      _selectedPricePreset = 'Tất cả giá';
      _minPrice = null;
      _maxPrice = null;
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _sortBy = 'default';
      _currentPage = 1;
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<ApiService>(context, listen: false).removeListener(_onApiServiceChanged);
    } catch (_) {}
    _searchCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProductForDetail != null) {
      return ProductDetailScreen(
        product: _selectedProductForDetail!,
        initialTabIndex: _detailInitialTabIndex,
        onBack: () => setState(() => _selectedProductForDetail = null),
        onProductUpdated: _loadProducts,
      );
    }

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

        var filteredProducts = allProducts;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          filteredProducts = filteredProducts.where((p) {
            return p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q) ||
                p.variants.any((v) => v.variantName.toLowerCase().contains(q));
          }).toList();
        }

        if (_selectedCategory != 'Tất cả') {
          final catLow = _selectedCategory.trim().toLowerCase();
          filteredProducts = filteredProducts.where((p) =>
            p.category.toLowerCase().contains(catLow) ||
            p.name.toLowerCase().contains(catLow) ||
            p.description.toLowerCase().contains(catLow)
          ).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          filteredProducts = filteredProducts.where((p) => p.status == _selectedStatus).toList();
        }

        if (_minPrice != null) {
          filteredProducts = filteredProducts.where((p) => p.minPrice >= _minPrice!).toList();
        }

        if (_maxPrice != null) {
          filteredProducts = filteredProducts.where((p) => p.maxPrice <= _maxPrice!).toList();
        }

        // Sorting Logic
        if (_sortBy == 'stock_desc') {
          filteredProducts.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        } else if (_sortBy == 'stock_asc') {
          filteredProducts.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        } else if (_sortBy == 'price_asc') {
          filteredProducts.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        } else if (_sortBy == 'price_desc') {
          filteredProducts.sort((a, b) => b.minPrice.compareTo(a.minPrice));
        } else if (_sortBy == 'name_asc') {
          filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        } else if (_sortBy == 'name_desc') {
          filteredProducts.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        }

        final totalItems = filteredProducts.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedProducts = filteredProducts.sublist(startIndex, endIndex);

        final extractedBrands = ['Sony', 'ASUS', 'Acer', 'Apple'];
        final rawCategories = allProducts.map((p) => p.category).toSet().toList();
        final categoriesList = ['Tất cả', ...rawCategories, ...extractedBrands.where((b) => !rawCategories.contains(b))];

        final isFilterActive = _searchQuery.isNotEmpty ||
            _selectedCategory != 'Tất cả' ||
            _selectedStatus != 'Tất cả' ||
            _selectedPricePreset != 'Tất cả giá' ||
            _minPrice != null ||
            _maxPrice != null ||
            _sortBy != 'default';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản lý Sản phẩm',
                subtitle: 'Quản lý thông tin dòng sản phẩm, khoảng giá và các biến thể hệ thống TechStoree',
                action: !authProvider.isSalesStaff ? AppButton(
                  label: 'Thêm sản phẩm mới',
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () => _showProductDialog(context, apiService, authProvider.token),
                ) : null,
              ),
              const SizedBox(height: AppTokens.space12),

              // Filter Bar Container
              FilterBar(
                searchField: AppSearchField<Product>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tên, hãng (Sony, ASUS...), SKU, mô tả...',
                  items: allProducts,
                  searchFilter: (p, q) =>
                      p.name.toLowerCase().contains(q.toLowerCase()) ||
                      p.sku.toLowerCase().contains(q.toLowerCase()) ||
                      p.category.toLowerCase().contains(q.toLowerCase()) ||
                      p.description.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (p) => p.name,
                  itemSubtitle: (p) => '${p.category} • SKU: ${p.sku} • Tồn: ${p.totalStock}',
                  onSelected: (p) => setState(() {
                    _searchQuery = p.name;
                    _currentPage = 1;
                  }),
                  onSubmitted: (val) => setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  }),
                  onCleared: () => setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  }),
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
                    onChanged: (val) => setState(() {
                      _selectedStatus = val ?? 'Tất cả';
                      _currentPage = 1;
                    }),
                  ),
                  AppDropdown<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text('Sắp xếp: Mặc định')),
                      DropdownMenuItem(value: 'stock_desc', child: Text('Tồn kho: Cao → Thấp')),
                      DropdownMenuItem(value: 'stock_asc', child: Text('Tồn kho: Thấp → Cao')),
                      DropdownMenuItem(value: 'price_asc', child: Text('Giá: Thấp → Cao')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Giá: Cao → Thấp')),
                      DropdownMenuItem(value: 'name_asc', child: Text('Tên: A → Z')),
                      DropdownMenuItem(value: 'name_desc', child: Text('Tên: Z → A')),
                    ],
                    onChanged: (val) => setState(() {
                      _sortBy = val ?? 'default';
                      _currentPage = 1;
                    }),
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
                            Icons.view_list_rounded,
                            color: !_isGridView ? AppColors.primary : textSecondary,
                          ),
                          tooltip: 'Xem dạng Bảng (Desktop Table)',
                          onPressed: () => setState(() => _isGridView = false),
                        ),
                        Container(width: 1, height: 18, color: borderColor),
                        IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            color: _isGridView ? AppColors.primary : textSecondary,
                          ),
                          tooltip: 'Xem dạng Thẻ Lưới',
                          onPressed: () => setState(() => _isGridView = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),

              // Category / Brand Chips Row
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
                        onSelected: (_) => setState(() {
                          _selectedCategory = cat;
                          _currentPage = 1;
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTokens.space12),

              // Price Filter Bar Presets
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: borderColor),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Khoảng giá:',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    ...['Tất cả giá', '< 2 triệu', '2 - 5 triệu', '5 - 10 triệu', '> 10 triệu', 'Tùy chỉnh'].map((preset) {
                      final isSel = _selectedPricePreset == preset;
                      return ChoiceChip(
                        label: Text(preset),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: bgSubtle,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : textPrimary,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          side: BorderSide(color: isSel ? AppColors.primary : borderColor),
                        ),
                        onSelected: (_) => _applyPricePreset(preset),
                      );
                    }),
                    if (isFilterActive)
                      TextButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded, size: 15, color: AppColors.danger),
                        label: const Text('Xóa bộ lọc', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: _clearAllFilters,
                      ),
                  ],
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
                  : !_isGridView
                      ? _buildTableProductsView(
                          paginatedProducts,
                          apiService,
                          authProvider,
                          authProvider.token,
                          surfaceColor,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          isDark,
                          safePage,
                          totalPages,
                          totalItems,
                        )
                      : Column(
                          children: [
                            _buildGridProductsView(paginatedProducts, apiService, authProvider.token, surfaceColor, borderColor, textPrimary, textSecondary, isDark),
                            if (totalItems > 0) ...[
                              const SizedBox(height: AppTokens.space16),
                              AppPagination(
                                currentPage: safePage,
                                totalPages: totalPages,
                                totalItems: totalItems,
                                itemsPerPage: _itemsPerPage,
                                itemsPerPageOptions: const [8, 10, 16, 24],
                                onPageChanged: (page) => setState(() => _currentPage = page),
                                onItemsPerPageChanged: (size) => setState(() {
                                  _itemsPerPage = size;
                                  _currentPage = 1;
                                }),
                              ),
                            ],
                          ],
                        ),
            ],
          ),
        );
      },
    );
  }

  // --- PRODUCT LIST COMPACT DESKTOP TABLE VIEW ---
  Widget _buildTableProductsView(
    List<Product> products,
    ApiService apiService,
    AuthProvider authProvider,
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
          ScrollableTableWrapper(
            child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 12,
                    headingRowHeight: 40,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                    columns: const [
                      DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Tổng tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Số biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Khuyến mãi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                    rows: products.map((product) {
                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                          }
                          return null;
                        }),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Row(
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
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.devices, size: 16, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.space8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'SKU: ${product.sku}',
                                          style: TextStyle(color: textSecondary, fontSize: 10.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(ProductPriceRange(product: product)),
                          DataCell(
                            Text(
                              '${product.totalStock}',
                              style: TextStyle(
                                color: product.totalStock > 10 ? textPrimary : (product.totalStock > 0 ? AppColors.warning : AppColors.danger),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${product.variants.length} biến thể',
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                          DataCell(PromotionBadge(productPromotion: product.promotion)),
                          DataCell(
                            StatusBadge(
                              label: product.isActive ? 'Đang bán' : 'Ngừng bán',
                              isSuccess: product.isActive,
                              isDanger: !product.isActive,
                            ),
                          ),
                          DataCell(
                            Text(
                              product.createdAt != null ? dateFormat.format(product.createdAt!) : '01/01/2026',
                              style: TextStyle(color: textSecondary, fontSize: 11.5),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!authProvider.isSalesStaff) ...[
                                  Tooltip(
                                    message: 'Xem & Chỉnh sửa',
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                      onPressed: () => _openProductDetail(product, 0),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Tooltip(
                                    message: 'Xóa sản phẩm',
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                      onPressed: () => _confirmDeleteProduct(context, apiService, token, product),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Tooltip(
                                    message: product.isActive ? 'Ngừng kinh doanh' : 'Kích hoạt kinh doanh',
                                    child: Transform.scale(
                                      scale: 0.7,
                                      child: Switch(
                                        value: product.isActive,
                                        onChanged: (_) async {
                                          final res = await apiService.toggleProductStatus(product.id, token: token);
                                          if (context.mounted) {
                                            if (res.success) _loadProducts();
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
                                ] else ...[
                                  Tooltip(
                                    message: 'Xem chi tiết',
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                                      onPressed: () => _openProductDetail(product, 0),
                                    ),
                                  ),
                                ],
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
              itemsPerPageOptions: const [8, 10, 16, 24],
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

  void _confirmDeleteProduct(BuildContext context, ApiService apiService, String? token, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
            SizedBox(width: AppTokens.space8),
            Text('Xác nhận xóa sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không? Thao tác này không thể hoàn tác.'),
        actions: [
          AppButton(
            label: 'Hủy bỏ',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Xóa sản phẩm',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteProduct(product.id, token: token);
              if (context.mounted) {
                if (res.success) _loadProducts();
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
            childAspectRatio: 0.67,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return AdminProductCard(
              product: p,
              apiService: apiService,
              token: token,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              currencyFormat: currencyFormat,
              onLoadProducts: _loadProducts,
              onShowDetail: (prod) => _openProductDetail(prod, 0),
              onEdit: (prod) => _openProductDetail(prod, 0),
              onManageVariants: (prod) => _openProductDetail(prod, 1),
              onDelete: (prod) => _showDeleteConfirm(context, apiService, token, prod),
              renderStatusBadge: _renderStatusBadge,
            );
          },
        );
      },
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

  void _showDeleteConfirm(BuildContext context, ApiService apiService, String? token, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa dòng sản phẩm "${p.name}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteProduct(p.id, token: token);
              if (context.mounted) {
                if (res.success) _loadProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
                );
              }
            },
            child: const Text('Xóa sản phẩm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- CREATE NEW PRODUCT DIALOG ---
  void _showProductDialog(BuildContext context, ApiService apiService, String? token) async {
    final categories = await apiService.getCategories(token: token);
    if (!context.mounted) return;

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    int selectedCategoryId = categories.isNotEmpty ? (int.tryParse(categories.first.id) ?? 1) : 1;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
          final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            title: const Row(
              children: [
                Icon(Icons.add_box_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: AppTokens.space8),
                Text('Thêm sản phẩm mới vào kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(controller: nameCtrl, labelText: 'Tên sản phẩm (*)'),
                    const SizedBox(height: AppTokens.space12),
                    if (categories.isNotEmpty) ...[
                      AppDropdown<int>(
                        value: selectedCategoryId,
                        items: categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: int.tryParse(cat.id) ?? 1,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: AppTokens.space12),
                    ],
                    AppTextField(
                      controller: priceCtrl,
                      labelText: 'Giá niêm yết mặc định (VNĐ)',
                      hintText: 'VD: 10,000,000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                    const SizedBox(height: AppTokens.space12),
                    AppTextField(controller: descCtrl, labelText: 'Mô tả chi tiết', maxLines: 3),
                    const SizedBox(height: AppTokens.space16),

                    // --- KHUNG DEMO ANH & CHON ANH ---
                    Text('Ảnh đại diện sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Demo Ảnh kế bên (100x100)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            border: Border.all(color: borderColor),
                          ),
                          child: imageCtrl.text.trim().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTokens.radiusSm - 1),
                                  child: Image.network(
                                    imageCtrl.text.trim(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_outlined, color: AppColors.danger, size: 24),
                                          SizedBox(height: 4),
                                          Text('Lỗi ảnh', style: TextStyle(fontSize: 10, color: AppColors.danger)),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, color: textSecondary, size: 28),
                                      const SizedBox(height: 4),
                                      Text('Demo ảnh', style: TextStyle(fontSize: 10, color: textSecondary)),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Nhập URL hoặc tải từ máy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: imageCtrl,
                                labelText: 'URL Ảnh sản phẩm',
                                hintText: 'Dán URL hoặc tải từ máy tính...',
                                onChanged: (_) => setDialogState(() {}),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: isUploadingImage
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.cloud_upload_outlined, size: 16),
                                label: Text(
                                  isUploadingImage ? 'Đang tải ảnh...' : 'Tải ảnh từ máy tính',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: isUploadingImage
                                    ? null
                                    : () async {
                                        final file = await FilePicker.pickFile(type: FileType.image);
                                        if (file != null) {
                                          setDialogState(() => isUploadingImage = true);
                                          final bytes = await file.readAsBytes();
                                          final url = await CloudinaryService.uploadImageBytes(
                                            bytes: bytes,
                                            fileName: file.name,
                                            backendBaseUrl: apiService.baseUrl,
                                            token: token,
                                          );
                                          setDialogState(() {
                                            isUploadingImage = false;
                                            if (url != null) imageCtrl.text = url;
                                          });
                                        }
                                      },
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
            actions: [
              AppButton(label: 'Hủy bỏ', variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: 'Tạo sản phẩm',
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  final rawPrice = priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                  final p = Product(
                    id: '0',
                    name: nameCtrl.text.trim(),
                    sku: 'PROD-${DateTime.now().millisecondsSinceEpoch}',
                    category: categories.where((c) => int.tryParse(c.id) == selectedCategoryId).isNotEmpty
                        ? categories.firstWhere((c) => int.tryParse(c.id) == selectedCategoryId).name
                        : (categories.isNotEmpty ? categories.first.name : 'Công nghệ'),
                    categoryId: selectedCategoryId,
                    price: double.tryParse(rawPrice) ?? 0,
                    stock: 0,
                    status: 'In Stock',
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : 'https://picsum.photos/200',
                    description: descCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  final res = await apiService.createProduct(p, token: token);
                  if (context.mounted) {
                    if (res.success) _loadProducts();
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
}

class AdminProductCard extends StatefulWidget {
  final Product product;
  final ApiService apiService;
  final String? token;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final NumberFormat currencyFormat;
  final VoidCallback onLoadProducts;
  final Function(Product) onShowDetail;
  final Function(Product) onEdit;
  final Function(Product) onManageVariants;
  final Function(Product) onDelete;
  final Widget Function(String) renderStatusBadge;

  const AdminProductCard({
    super.key,
    required this.product,
    required this.apiService,
    required this.token,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.currencyFormat,
    required this.onLoadProducts,
    required this.onShowDetail,
    required this.onEdit,
    required this.onManageVariants,
    required this.onDelete,
    required this.renderStatusBadge,
  });

  @override
  State<AdminProductCard> createState() => _AdminProductCardState();
}

class _AdminProductCardState extends State<AdminProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isDark = widget.isDark;
    final textPrimary = widget.textPrimary;
    final textSecondary = widget.textSecondary;
    final borderColor = widget.borderColor;
    final surfaceColor = widget.surfaceColor;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String highlightLabel = 'Hàng mới về';
    Color highlightBg = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
    Color highlightText = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);

    if (p.status == 'Low Stock' || (p.totalStock > 0 && p.totalStock <= 5)) {
      highlightLabel = 'Sắp hết hàng';
      highlightBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      highlightText = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
    } else if (p.status == 'Out of Stock' || p.totalStock == 0) {
      highlightLabel = 'Sắp về hàng';
      highlightBg = isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6);
      highlightText = isDark ? const Color(0xFFFECDD3) : const Color(0xFFBE123C);
    } else if (p.variants.isNotEmpty) {
      highlightLabel = '${p.variants.length} biến thể';
      highlightBg = AppColors.primary.withOpacity(0.12);
      highlightText = AppColors.primary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withOpacity(0.6) : borderColor,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : AppTokens.subtleShadow(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack Header with Zoom Animation
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMd - 1)),
                  child: Container(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    child: AspectRatio(
                      aspectRatio: 1.35,
                      child: AnimatedScale(
                        scale: _isHovered ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: Image.network(
                          p.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppColors.primary.withOpacity(0.06),
                            child: const Icon(Icons.devices, size: 48, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.radiusMd - 1),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      p.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                if (p.hasPromotion)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PromotionBadge(productPromotion: p.promotion),
                  ),

                Positioned(
                  bottom: 6,
                  right: 6,
                  child: widget.renderStatusBadge(p.status),
                ),
              ],
            ),

            // Main Info Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: highlightBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        highlightLabel,
                        style: TextStyle(
                          color: highlightText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ProductPriceRange(product: p),
                    const SizedBox(height: 6),

                    const Spacer(),

                    Row(
                      children: [
                        Text('SKU: ${p.sku}', style: TextStyle(color: textSecondary, fontSize: 11)),
                        const Spacer(),
                        Text(
                          'Tồn kho: ${p.totalStock}',
                          style: TextStyle(
                            color: p.totalStock > 10 ? AppColors.success : (p.totalStock > 0 ? AppColors.warning : AppColors.danger),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTokens.radiusMd - 1)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                    tooltip: 'Xem chi tiết',
                    onPressed: () => widget.onShowDetail(p),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                    tooltip: 'Sửa sản phẩm',
                    onPressed: () => widget.onEdit(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                    tooltip: 'Quản lý biến thể (${p.variants.length})',
                    onPressed: () => widget.onManageVariants(p),
                  ),
                  const Spacer(),
                  if (!authProvider.isSalesStaff) ...[
                    Tooltip(
                      message: p.isActive ? 'Ngừng kinh doanh' : 'Kích hoạt',
                      child: Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: p.isActive,
                          onChanged: (_) async {
                            final res = await widget.apiService.toggleProductStatus(p.id, token: widget.token);
                            if (context.mounted) {
                              if (res.success) widget.onLoadProducts();
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
                      onPressed: () => widget.onDelete(p),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
