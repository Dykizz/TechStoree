import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_pagination.dart';

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
  bool _isGridView = true; // Toggle between Grid Card View and Table View
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

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allProducts = snapshot.data ?? [];
        
        // Calculate Metrics
        final totalCount = allProducts.length;
        final totalStockSum = allProducts.fold<int>(0, (sum, p) => sum + p.stock);
        final lowStockCount = allProducts.where((p) => p.stock > 0 && p.stock <= 10).length;
        final outOfStockCount = allProducts.where((p) => p.stock == 0).length;

        // Apply Filters
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

        // Distinct Categories
        final categoriesList = ['Tất cả', ...allProducts.map((p) => p.category).toSet().toList()];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý Sản phẩm',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Danh sách các sản phẩm, biến thể và mức tồn kho hệ thống TechStoree',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showProductDialog(context, apiService, authProvider.token),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Thêm sản phẩm mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Stats Overview Bar
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isWide ? 2.5 : 1.8,
                    children: [
                      _buildSummaryCard(
                        title: 'TỔNG SẢN PHẨM',
                        value: '$totalCount',
                        subtext: 'Mẫu sản phẩm đăng bán',
                        icon: Icons.inventory_2_rounded,
                        iconColor: AppColors.primary,
                        bgColor: backgroundColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildSummaryCard(
                        title: 'TỔNG SỐ LƯỢNG TỒN',
                        value: '$totalStockSum cái',
                        subtext: 'Trên tất cả kho hàng',
                        icon: Icons.store_rounded,
                        iconColor: AppColors.success,
                        bgColor: backgroundColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildSummaryCard(
                        title: 'CẢNH BÁO TỒN THẤP',
                        value: '$lowStockCount sản phẩm',
                        subtext: 'Số lượng ≤ 10 sản phẩm',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.warning,
                        bgColor: backgroundColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildSummaryCard(
                        title: 'HẾT HÀNG KHO',
                        value: '$outOfStockCount sản phẩm',
                        subtext: 'Cần nhập bổ sung kho',
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.danger,
                        bgColor: backgroundColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Search & Filter Controls Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search Box
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm sản phẩm theo tên, mã SKU...',
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
                                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                contentPadding: EdgeInsets.zero,
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
                        const SizedBox(width: 16),

                        // Status Filter Dropdown
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              dropdownColor: backgroundColor,
                              icon: Icon(Icons.filter_list_rounded, color: textSecondary, size: 18),
                              style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              items: ['Tất cả', 'In Stock', 'Low Stock', 'Out of Stock', 'Ngừng bán']
                                  .map((st) => DropdownMenuItem(
                                        value: st,
                                        child: Text(st == 'In Stock'
                                            ? 'Còn hàng'
                                            : (st == 'Low Stock'
                                                ? 'Sắp hết'
                                                : (st == 'Out of Stock' ? 'Hết hàng' : st))),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedStatus = val ?? 'Tất cả'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // View Mode Switcher (Grid vs Table)
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  color: _isGridView ? AppColors.primary : textSecondary,
                                  size: 20,
                                ),
                                tooltip: 'Xem dạng thẻ Lưới',
                                onPressed: () => setState(() => _isGridView = true),
                              ),
                              Container(width: 1, height: 20, color: borderColor),
                              IconButton(
                                icon: Icon(
                                  Icons.view_list_rounded,
                                  color: !_isGridView ? AppColors.primary : textSecondary,
                                  size: 20,
                                ),
                                tooltip: 'Xem dạng Bảng',
                                onPressed: () => setState(() => _isGridView = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Category Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categoriesList.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Products Display (Grid vs Table)
              filteredProducts.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy sản phẩm phù hợp',
                            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Thử đổi từ khóa tìm kiếm hoặc bỏ chọn các bộ lọc.',
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? _buildGridProductsView(paginatedProducts, apiService, authProvider.token, backgroundColor, borderColor, textPrimary, textSecondary, isDark)
                      : _buildTableProductsView(paginatedProducts, apiService, authProvider.token, backgroundColor, borderColor, textPrimary, textSecondary, isDark),

              const SizedBox(height: 16),
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
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtext,
                  style: TextStyle(color: textSecondary, fontSize: 11),
                  maxLines: 1,
                ),
              ],
            ),
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
    Color bgColor,
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
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.76,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image & Badges
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withOpacity(0.08),
                              child: const Icon(Icons.devices, size: 48, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.category,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _buildStatusBadge(p.status),
                      ),
                    ],
                  ),

                  // Product Main Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${p.sku}',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 8),

                          // Variants Info Chip
                          if (p.variants.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${p.variants.length} biến thể (${p.variants.map((v) => v.variantName).take(2).join(', ')})',
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          const Spacer(),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Price & Stock Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Giá niêm yết', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  Text(
                                    currencyFormat.format(p.price),
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Tồn kho', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  Text(
                                    '${p.stock} cái',
                                    style: TextStyle(
                                      color: p.stock > 10 ? textPrimary : (p.stock > 0 ? AppColors.warning : AppColors.danger),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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

                  // Actions Footer Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'Xem chi tiết',
                          onPressed: () => _showProductDetailView(context, p, textPrimary, textSecondary, isDark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                          tooltip: 'Sửa sản phẩm',
                          onPressed: () => _showProductDialog(context, apiService, token, product: p),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: p.status == 'Ngừng bán' ? 'Kích hoạt lại' : 'Ngừng bán',
                          child: Switch(
                            value: p.status != 'Ngừng bán',
                            activeColor: AppColors.success,
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
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
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
    Color bgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
              ),
              dataRowMinHeight: 70,
              dataRowMaxHeight: 70,
              columns: const [
                DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Biến thể', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Giá niêm yết', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: products.map((product) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.devices, size: 22, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${product.variants.length} mẫu',
                        style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${product.stock} cái',
                        style: TextStyle(
                          color: product.stock > 10 ? textPrimary : (product.stock > 0 ? AppColors.warning : AppColors.danger),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(product.status)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                            onPressed: () => _showProductDetailView(context, product, textPrimary, textSecondary, isDark),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                            onPressed: () => _showProductDialog(context, apiService, token, product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
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
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'In Stock':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Còn hàng';
        break;
      case 'Low Stock':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Sắp hết';
        break;
      case 'Out of Stock':
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        label = 'Hết hàng';
        break;
      default:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        label = 'Ngừng bán';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // --- QUICK VIEW DETAIL DIALOG ---
  void _showProductDetailView(BuildContext context, Product p, Color textPrimary, Color textSecondary, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 2.2,
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.devices, size: 48, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mã SKU:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(p.sku, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Danh mục:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(p.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Mô tả sản phẩm:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text(
                  p.description.isNotEmpty ? p.description : 'Chưa có mô tả chi tiết.',
                  style: TextStyle(color: textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Danh sách Biến thể (${p.variants.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (p.variants.isEmpty)
                  const Text('Không có biến thể cụ thể.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                else
                  Column(
                    children: p.variants.map((v) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.variantName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(v.attributesText, style: TextStyle(color: textSecondary, fontSize: 11)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(v.price), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
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

    // Initialize Attribute Types
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_rounded : Icons.add_box_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(isEditing ? 'Sửa thông tin sản phẩm' : 'Thêm sản phẩm mới vào kho', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên sản phẩm (*)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  if (categories.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: categories.any((c) => int.tryParse(c.id) == selectedCategoryId)
                          ? selectedCategoryId
                          : (int.tryParse(categories.first.id) ?? 1),
                      decoration: const InputDecoration(
                        labelText: 'Danh mục sản phẩm (*)',
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá niêm yết mặc định (VNĐ)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '1. KHAI BÁO LOẠI BIẾN THỂ (VD: RAM, Dung lượng, Màu sắc...)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhập tên các loại biến thể trước. Các ô nhập giá trị tương ứng sẽ tự động hiển thị ở danh sách biến thể bên dưới.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ...attrTypeCtrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              onChanged: (_) {
                                setDialogState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Loại biến thể #${index + 1}',
                                hintText: 'vd: RAM, Dung lượng, Màu sắc',
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
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
                    child: TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          attrTypeCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm loại biến thể', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. THÔNG SỐ VÀ GIÁ BÁN CHO TỪNG BIẾN THỂ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            variantRows.add(_VariantInputRow(price: double.tryParse(priceCtrl.text) ?? 0));
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('Thêm biến thể', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...variantRows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;

                    final activeAttrNames = attrTypeCtrls
                        .map((c) => c.text.trim())
                        .where((name) => name.isNotEmpty)
                        .toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Biến thể #${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              if (variantRows.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  onPressed: () {
                                    setDialogState(() {
                                      row.dispose();
                                      variantRows.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (activeAttrNames.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Vui lòng thêm loại biến thể ở mục 1 trước (vd: RAM, Dung lượng).',
                                style: TextStyle(color: AppColors.warning, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            Column(
                              children: activeAttrNames.map((attrName) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: TextField(
                                    controller: row.getControllerForAttribute(attrName),
                                    decoration: InputDecoration(
                                      labelText: '$attrName (vd: 16GB, 256GB...)',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          TextField(
                            controller: row.priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá bán biến thể (VNĐ)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
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
            TextButton(
              onPressed: () {
                for (var r in variantRows) { r.dispose(); }
                for (var c in attrTypeCtrls) { c.dispose(); }
                Navigator.pop(ctx);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
              child: Text(isEditing ? 'Cập Nhật' : 'Lưu Sản Phẩm', style: const TextStyle(color: Colors.white)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}" khỏi hệ thống không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
