import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/category.dart';
import '../../core/models/product.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/product_price_range.dart';
import '../../core/widgets/promotion_badge.dart';
import 'product_detail_screen.dart';
import 'widgets/create_product_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy');

  final TextEditingController _searchCtrl = TextEditingController();

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

  final ScrollController _categoryScrollCtrl = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isCategoryExpanded = false;

  Product? _selectedProductForDetail;
  int _detailInitialTabIndex = 0;

  late Future<List<Product>> _productsFuture;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoryScrollCtrl.addListener(_updateCategoryScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ApiService>(context, listen: false).addListener(_onApiServiceChanged);
        _updateCategoryScrollButtons();
      }
    });
    _loadProducts(notify: false);
  }


  void _onApiServiceChanged() {
    if (mounted) {
      _loadProducts();
    }
  }

  void _loadProducts({bool notify = true}) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    void updateFutures() {
      _productsFuture = apiService.getProductsWithVariants(token: token);
      _categoriesFuture = apiService.getCategories(token: token);
    }
    if (notify && mounted) {
      setState(updateFutures);
    } else {
      updateFutures();
    }
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
          break;
        case '2 - 5 triệu':
          _minPrice = 2000000;
          _maxPrice = 5000000;
          break;
        case '5 - 10 triệu':
          _minPrice = 5000000;
          _maxPrice = 10000000;
          break;
        case '> 10 triệu':
          _minPrice = 10000000;
          _maxPrice = null;
          break;
        case 'Tất cả giá':
        default:
          _minPrice = null;
          _maxPrice = null;
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
      _sortBy = 'default';
      _currentPage = 1;
    });
  }

  void _updateCategoryScrollButtons() {
    if (!_categoryScrollCtrl.hasClients) return;
    final maxScroll = _categoryScrollCtrl.position.maxScrollExtent;
    final currentScroll = _categoryScrollCtrl.offset;
    final canLeft = currentScroll > 5;
    final canRight = currentScroll < maxScroll - 5;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollCategoryLeft() {
    if (!_categoryScrollCtrl.hasClients) return;
    final newOffset = (_categoryScrollCtrl.offset - 250).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent);
    _categoryScrollCtrl.animateTo(newOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _scrollCategoryRight() {
    if (!_categoryScrollCtrl.hasClients) return;
    final newOffset = (_categoryScrollCtrl.offset + 250).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent);
    _categoryScrollCtrl.animateTo(newOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget _buildCategoryChip(
    String cat,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    List<Product> allProducts,
  ) {
    final isSelected = _selectedCategory == cat;
    final int count = cat == 'Tất cả'
        ? allProducts.length
        : allProducts.where((p) {
            final catLow = cat.trim().toLowerCase();
            return p.category.trim().toLowerCase() == catLow ||
                p.category.toLowerCase().contains(catLow);
          }).length;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      onTap: () => setState(() {
        _selectedCategory = cat;
        _currentPage = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : surfaceColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color borderColor,
    required Color bgSubtle,
    required Color textSecondary,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgSubtle,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 18, color: textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      Provider.of<ApiService>(context, listen: false).removeListener(_onApiServiceChanged);
    } catch (_) {}
    _searchCtrl.dispose();
    _categoryScrollCtrl.removeListener(_updateCategoryScrollButtons);
    _categoryScrollCtrl.dispose();
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

    return FutureBuilder(
      future: Future.wait([
        _productsFuture.catchError((_) => <Product>[]),
        _categoriesFuture.catchError((_) => <Category>[]),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allProducts = (snapshot.data?[0] as List<Product>?) ?? [];
        final dbCategories = (snapshot.data?[1] as List<Category>?) ?? [];

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
            p.category.trim().toLowerCase() == catLow ||
            p.category.toLowerCase().contains(catLow)
          ).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          if (_selectedStatus == 'active') {
            filteredProducts = filteredProducts.where((p) => p.isActive).toList();
          } else if (_selectedStatus == 'inactive') {
            filteredProducts = filteredProducts.where((p) => !p.isActive).toList();
          } else if (_selectedStatus == 'in_stock') {
            filteredProducts = filteredProducts.where((p) => p.isInStock).toList();
          } else if (_selectedStatus == 'low_stock') {
            filteredProducts = filteredProducts.where((p) => p.isLowStock).toList();
          } else if (_selectedStatus == 'critical_stock') {
            filteredProducts = filteredProducts.where((p) => p.isCriticalStock).toList();
          } else if (_selectedStatus == 'out_of_stock') {
            filteredProducts = filteredProducts.where((p) => p.isOutOfStock).toList();
          } else {
            filteredProducts = filteredProducts.where((p) => p.status == _selectedStatus).toList();
          }
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
        } else {
          // Default: Sắp xếp sản phẩm mới nhất lên đầu danh sách
          filteredProducts.sort((a, b) {
            if (a.createdAt != null && b.createdAt != null) {
              return b.createdAt!.compareTo(a.createdAt!);
            }
            final idA = int.tryParse(a.id) ?? 0;
            final idB = int.tryParse(b.id) ?? 0;
            return idB.compareTo(idA);
          });
        }

        final totalItems = filteredProducts.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final paginatedProducts = filteredProducts.sublist(startIndex, endIndex);

        final Set<String> categoryNames = {};
        for (var c in dbCategories) {
          if (c.name.trim().isNotEmpty) categoryNames.add(c.name.trim());
        }
        for (var p in allProducts) {
          if (p.category.trim().isNotEmpty) categoryNames.add(p.category.trim());
        }
        final rawCategories = categoryNames.toList()..sort();
        final categoriesList = ['Tất cả', ...rawCategories];

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
                title: 'Quản lý sản phẩm',
                subtitle: 'Quản lý thông tin dòng sản phẩm, khoảng giá và các biến thể hệ thống TechStoree',
                action: authProvider.can('Products.Create') ? AppButton(
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
                      DropdownMenuItem(value: 'active', child: Text('Đang kinh doanh')),
                      DropdownMenuItem(value: 'inactive', child: Text('Ngừng kinh doanh')),
                      DropdownMenuItem(value: 'in_stock', child: Text('Còn hàng (> 20)')),
                      DropdownMenuItem(value: 'low_stock', child: Text('Tồn kho thấp (11 - 20)')),
                      DropdownMenuItem(value: 'critical_stock', child: Text('Sắp hết (1 - 10)')),
                      DropdownMenuItem(value: 'out_of_stock', child: Text('Hết hàng (0)')),
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
                          tooltip: 'Xem dạng bảng',
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
                          tooltip: 'Xem dạng thẻ lưới',
                          onPressed: () => setState(() => _isGridView = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),

              // Category Filter Container (Thiết kế chống tràn, hỗ trợ cuộn chuột, nút điều hướng & xem tất cả)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của Thanh Loại sản phẩm
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Loại sản phẩm:',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedCategory != 'Tất cả')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCategory,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() {
                                    _selectedCategory = 'Tất cả';
                                    _currentPage = 1;
                                  }),
                                  child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),

                        // Chọn nhanh danh mục qua PopupMenu
                        PopupMenuButton<String>(
                          tooltip: 'Chọn nhanh danh mục từ danh sách',
                          icon: Icon(Icons.playlist_add_check_rounded, size: 18, color: textSecondary),
                          onSelected: (cat) => setState(() {
                            _selectedCategory = cat;
                            _currentPage = 1;
                          }),
                          itemBuilder: (ctx) => categoriesList.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return PopupMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  if (isSel)
                                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? AppColors.primary : textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 4),

                        // Nút mở rộng dạng Lưới hoặc Thu gọn
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isCategoryExpanded
                                      ? 'Thu gọn'
                                      : 'Xem tất cả (${categoriesList.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isCategoryExpanded ? AppColors.primary : textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isCategoryExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: _isCategoryExpanded ? AppColors.primary : textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Danh sách Chips (dạng Wrap khi mở rộng hoặc dạng Cuộn mượt khi thu gọn)
                    if (_isCategoryExpanded)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoriesList.map((cat) => _buildCategoryChip(cat, surfaceColor, borderColor, textPrimary, allProducts)).toList(),
                      )
                    else
                      Row(
                        children: [
                          if (_canScrollLeft)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _buildScrollButton(
                                icon: Icons.chevron_left_rounded,
                                onPressed: _scrollCategoryLeft,
                                borderColor: borderColor,
                                bgSubtle: bgSubtle,
                                textSecondary: textSecondary,
                                tooltip: 'Cuộn sang trái',
                              ),
                            ),
                          Expanded(
                            child: Listener(
                              onPointerSignal: (pointerSignal) {
                                if (pointerSignal is PointerScrollEvent && _categoryScrollCtrl.hasClients) {
                                  final newOffset = (_categoryScrollCtrl.offset + pointerSignal.scrollDelta.dy)
                                      .clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent);
                                  _categoryScrollCtrl.jumpTo(newOffset);
                                }
                              },
                              child: SingleChildScrollView(
                                controller: _categoryScrollCtrl,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: categoriesList.map((cat) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildCategoryChip(cat, surfaceColor, borderColor, textPrimary, allProducts),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          if (_canScrollRight)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildScrollButton(
                                icon: Icons.chevron_right_rounded,
                                onPressed: _scrollCategoryRight,
                                borderColor: borderColor,
                                bgSubtle: bgSubtle,
                                textSecondary: textSecondary,
                                tooltip: 'Cuộn sang phải',
                              ),
                            ),
                        ],
                      ),
                  ],
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
                    columns: [
                      DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Tổng tồn kho', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Số biến thể', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Khuyến mãi', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                      DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${product.totalStock}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStockBadge(product.totalStock, isDark),
                              ],
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
                                if (authProvider.can('Products.Update')) ...[
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
                                    message: product.isActive ? 'Ngừng kinh doanh' : 'Kích hoạt kinh doanh',
                                    child: Transform.scale(
                                      scale: 0.7,
                                      child: Switch(
                                        value: product.isActive,
                                        onChanged: (_) async {
                                          final res = await apiService.toggleProductStatus(product.id, token: token);
                                          if (mounted) {
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
                                  const SizedBox(width: 2),
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
                                  const SizedBox(width: 2),
                                ],
                                if (authProvider.can('Products.Delete')) ...[
                                  Tooltip(
                                    message: 'Xóa sản phẩm',
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                      onPressed: () => _confirmDeleteProduct(context, apiService, token, product),
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
        int crossAxisCount = 5;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth < 1250) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth < 1650) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppTokens.space12,
            crossAxisSpacing: AppTokens.space12,
            childAspectRatio: 0.58,
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
              onLoadProducts: _loadProducts,
              onShowDetail: (prod) => _openProductDetail(prod, 0),
              onEdit: (prod) => _openProductDetail(prod, 0),
              onManageVariants: (prod) => _openProductDetail(prod, 1),
              onDelete: (prod) => _confirmDeleteProduct(context, apiService, token, prod),
            );
          },
        );
      },
    );
  }

  Widget _buildStockBadge(int stock, bool isDark) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;
    IconData icon;

    if (stock == 0) {
      label = 'Hết hàng';
      textColor = const Color(0xFFDC2626);
      bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFDC2626).withValues(alpha: 0.3);
      icon = Icons.cancel_rounded;
    } else if (stock <= 10) {
      label = 'Sắp hết';
      textColor = const Color(0xFFEA580C);
      bgColor = isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFEA580C).withValues(alpha: 0.3);
      icon = Icons.report_problem_rounded;
    } else if (stock <= 20) {
      label = 'Tồn kho thấp';
      textColor = isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309);
      bgColor = isDark ? const Color(0xFF422006) : const Color(0xFFFEFCE8);
      borderColor = const Color(0xFFEAB308).withValues(alpha: 0.3);
      icon = Icons.inventory_2_outlined;
    } else {
      label = 'Còn hàng';
      textColor = const Color(0xFF16A34A);
      bgColor = isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF16A34A).withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- CREATE NEW PRODUCT DIALOG (OPTION 1: SHOPIFY-STYLE MATRIX CREATION) ---
  void _showProductDialog(BuildContext context, ApiService apiService, String? token) async {
    final categories = await apiService.getCategories(token: token);
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateProductDialog(
        categories: categories,
        token: token,
        onCreated: () {
          _currentPage = 1;
          _searchQuery = '';
          _searchCtrl.clear();
          _selectedCategory = 'Tất cả';
          _selectedStatus = 'Tất cả';
          _loadProducts();
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
  final VoidCallback onLoadProducts;
  final Function(Product) onShowDetail;
  final Function(Product) onEdit;
  final Function(Product) onManageVariants;
  final Function(Product) onDelete;

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
    required this.onLoadProducts,
    required this.onShowDetail,
    required this.onEdit,
    required this.onManageVariants,
    required this.onDelete,
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

    // Stock level styling: 4 levels matching ERP standards
    Color stockColor;
    if (p.isOutOfStock) {
      stockColor = const Color(0xFFDC2626);
    } else if (p.isCriticalStock) {
      stockColor = const Color(0xFFEA580C);
    } else if (p.isLowStock) {
      stockColor = isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309);
    } else {
      stockColor = const Color(0xFF16A34A);
    }

    final outVariants = p.variants.where((v) => v.stockQuantity == 0).toList();
    final lowVariants = p.variants.where((v) => v.stockQuantity > 0 && v.stockQuantity <= 10).toList();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withValues(alpha: 0.5) : borderColor,
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Header (Aspect Ratio 1.50)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMd - 1)),
                  child: Container(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    child: AspectRatio(
                      aspectRatio: 1.50,
                      child: AnimatedScale(
                        scale: _isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: ColorFiltered(
                          colorFilter: !p.isActive
                              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              child: Center(
                                child: Icon(
                                  Icons.devices_other_rounded,
                                  size: 38,
                                  color: textSecondary.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Promotion Badge (Top-Right only - Compact Pill, Zero Overlap!)
                if (p.hasPromotion && p.promotion != null && p.promotion!.hasPromotion)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Tooltip(
                      message: p.promotion!.promotionName,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 10.5, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              p.promotion!.discountType == 'PERCENTAGE' && p.promotion!.discountValue != null
                                  ? '-${p.promotion!.discountValue!.toInt()}%'
                                  : 'KM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Inactive Badge (Top-Left only)
                if (!p.isActive)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle_outline, size: 9.5, color: Colors.white),
                          SizedBox(width: 2.5),
                          Text(
                            'Ngừng bán',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Stock Badge (Bottom-Right on image)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: stockColor.withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          'Kho: ${p.totalStock}',
                          style: TextStyle(
                            color: stockColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. Main Info Body (Clickable to detail/edit)
            Expanded(
              child: InkWell(
                onTap: () => widget.onEdit(p),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Eyebrow Tag (Never overlaps with promotion!)
                      Text(
                        p.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Product Name
                      Text(
                        p.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price Range
                      ProductPriceRange(product: p, compact: true),
                      const SizedBox(height: 4),

                      // Variant & Stock Alert Pill
                      if (p.variants.isNotEmpty && outVariants.isNotEmpty)
                        Tooltip(
                          message: 'Biến thể hết hàng:\n${outVariants.map((v) => '• ${v.variantName} (0)').join('\n')}',
                          child: InkWell(
                            onTap: () => widget.onManageVariants(p),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${outVariants.length} biến thể hết',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (p.variants.isNotEmpty && lowVariants.isNotEmpty)
                        Tooltip(
                          message: 'Biến thể sắp hết:\n${lowVariants.map((v) => '• ${v.variantName} (${v.stockQuantity})').join('\n')}',
                          child: InkWell(
                            onTap: () => widget.onManageVariants(p),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.report_problem_outlined, size: 10, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${lowVariants.length} biến thể sắp hết',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (p.variants.isNotEmpty)
                        InkWell(
                          onTap: () => widget.onManageVariants(p),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.layers_outlined, size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  '${p.variants.length} biến thể',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Bottom SKU & Stock Status Label (Full visibility, never cut off!)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'SKU: ${p.sku}',
                                style: TextStyle(color: textSecondary, fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.stockStatusLabel,
                              style: TextStyle(
                                color: stockColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Compact Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTokens.radiusMd - 1)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => widget.onEdit(p),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            authProvider.can('Products.Update') ? Icons.edit_outlined : Icons.visibility_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            authProvider.can('Products.Update') ? 'Chỉnh sửa' : 'Chi tiết',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (authProvider.can('Products.Update')) ...[
                    Tooltip(
                      message: p.isActive ? 'Đang kinh doanh (Gạt để tắt)' : 'Đã ngừng kinh doanh (Gạt để bật)',
                      child: Transform.scale(
                        scale: 0.68,
                        child: Switch(
                          value: p.isActive,
                          onChanged: (_) async {
                            final res = await widget.apiService.toggleProductStatus(p.id, token: widget.token);
                            if (!context.mounted) return;
                            if (res.success) widget.onLoadProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: res.success ? AppColors.success : AppColors.danger,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (authProvider.can('Products.Delete')) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                      tooltip: 'Xóa sản phẩm',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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
