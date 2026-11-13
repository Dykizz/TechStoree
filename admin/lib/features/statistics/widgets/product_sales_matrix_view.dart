import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import '../../../core/widgets/smooth_loading_wrapper.dart';
import '../models/statistics_models.dart';

enum ProductMatrixMode { quarterly, threeYears }

class ProductSalesMatrixView extends StatefulWidget {
  final int selectedYear;
  final List<int> years;
  final List<ProductQuarterlySalesMatrixRow> quarterlyProducts;
  final List<ProductSalesMatrixRow> productList;
  final ValueChanged<List<int>> onPeriodChanged;
  final bool isLoading;

  const ProductSalesMatrixView({
    super.key,
    required this.selectedYear,
    required this.years,
    required this.quarterlyProducts,
    required this.productList,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  @override
  State<ProductSalesMatrixView> createState() => _ProductSalesMatrixViewState();
}

class _ProductSalesMatrixViewState extends State<ProductSalesMatrixView> {
  ProductMatrixMode _mode = ProductMatrixMode.quarterly;
  late String _selectedPeriodLabel;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  String _searchQuery = '';
  bool _isAdvancedFilterOpen = false;
  String _selectedCategory = 'ALL';
  String _amountOperator = 'ALL';

  int _sortColumnIndex = 5;
  bool _sortAscending = false;

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _selectedPeriodLabel = _buildPeriodLabel(widget.years);
  }

  @override
  void didUpdateWidget(covariant ProductSalesMatrixView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.years != widget.years) {
      _selectedPeriodLabel = _buildPeriodLabel(widget.years);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  String _buildPeriodLabel(List<int> years) {
    if (years.isEmpty) return '2024 - 2026';
    return '${years.first} - ${years.last}';
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchQuery = '';
      _selectedCategory = 'ALL';
      _amountOperator = 'ALL';
      _currentPage = 1;
    });
  }

  double? _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean);
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'ALL' ||
      (_amountOperator != 'ALL' &&
          (_minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty));

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedCategory != 'ALL') count++;
    if (_amountOperator != 'ALL' &&
        (_minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty)) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final filterPanelBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : const Color(0xFFF8FAFC);
    final tabBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    final y1 = widget.years.isNotEmpty ? widget.years[0] : 2024;
    final y2 = widget.years.length > 1 ? widget.years[1] : 2025;
    final y3 = widget.years.length > 2 ? widget.years[2] : 2026;

    // Thu thập danh sách Loại sản phẩm duy nhất (Loại bỏ 100% trùng lặp giữa 2 danh sách)
    final Set<String> categorySet = {};
    for (final p in widget.quarterlyProducts) {
      final name = p.categoryName.trim();
      if (name.isNotEmpty && name != 'ALL') {
        categorySet.add(name);
      }
    }
    for (final p in widget.productList) {
      final name = p.categoryName.trim();
      if (name.isNotEmpty && name != 'ALL') {
        categorySet.add(name);
      }
    }
    final sortedCategories = categorySet.toList()..sort((a, b) => a.compareTo(b));
    final categories = ['ALL', ...sortedCategories];
    final effectiveCategory = categories.contains(_selectedCategory) ? _selectedCategory : 'ALL';
    final minAmt = _parseAmount(_minAmountController.text);
    final maxAmt = _parseAmount(_maxAmountController.text);

    // Filter logic depending on current Mode
    List<dynamic> filteredItems = [];

    if (_mode == ProductMatrixMode.quarterly) {
      filteredItems = widget.quarterlyProducts.where((p) {
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final match = p.productName.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.productCode.toLowerCase().contains(q);
          if (!match) return false;
        }

        if (effectiveCategory != 'ALL' &&
            p.categoryName.trim().toLowerCase() != effectiveCategory.toLowerCase()) {
          return false;
        }

        if (_amountOperator != 'ALL') {
          final val = p.total;

          switch (_amountOperator) {
            case 'GT':
              if (minAmt != null && val <= minAmt) return false;
              break;
            case 'GTE':
              if (minAmt != null && val < minAmt) return false;
              break;
            case 'LT':
              if (maxAmt != null && val >= maxAmt) return false;
              break;
            case 'BETWEEN':
              if (minAmt != null && val < minAmt) return false;
              if (maxAmt != null && val > maxAmt) return false;
              break;
          }
        }
        return true;
      }).toList();

      // Sort quarterly
      filteredItems.sort((a, b) {
        final pA = a as ProductQuarterlySalesMatrixRow;
        final pB = b as ProductQuarterlySalesMatrixRow;
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 0:
            cmp = pA.productName.compareTo(pB.productName);
            break;
          case 1:
            cmp = pA.q1.compareTo(pB.q1);
            break;
          case 2:
            cmp = pA.q2.compareTo(pB.q2);
            break;
          case 3:
            cmp = pA.q3.compareTo(pB.q3);
            break;
          case 4:
            cmp = pA.q4.compareTo(pB.q4);
            break;
          case 5:
          default:
            cmp = pA.total.compareTo(pB.total);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
    } else {
      // 3-Year mode
      filteredItems = widget.productList.where((p) {
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final match = p.productName.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.productCode.toLowerCase().contains(q);
          if (!match) return false;
        }

        if (effectiveCategory != 'ALL' &&
            p.categoryName.trim().toLowerCase() != effectiveCategory.toLowerCase()) {
          return false;
        }

        if (_amountOperator != 'ALL') {
          final val = p.total;

          switch (_amountOperator) {
            case 'GT':
              if (minAmt != null && val <= minAmt) return false;
              break;
            case 'GTE':
              if (minAmt != null && val < minAmt) return false;
              break;
            case 'LT':
              if (maxAmt != null && val >= maxAmt) return false;
              break;
            case 'BETWEEN':
              if (minAmt != null && val < minAmt) return false;
              if (maxAmt != null && val > maxAmt) return false;
              break;
          }
        }
        return true;
      }).toList();

      filteredItems.sort((a, b) {
        final pA = a as ProductSalesMatrixRow;
        final pB = b as ProductSalesMatrixRow;
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 0:
            cmp = pA.productName.compareTo(pB.productName);
            break;
          case 1:
            cmp = pA.y2024.compareTo(pB.y2024);
            break;
          case 2:
            cmp = pA.y2025.compareTo(pB.y2025);
            break;
          case 3:
            cmp = pA.y2026.compareTo(pB.y2026);
            break;
          case 4:
          default:
            cmp = pA.total.compareTo(pB.total);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    // Pagination
    final totalItems = filteredItems.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
    final safePage = _currentPage.clamp(1, totalPages);
    final paginatedList = filteredItems.skip((safePage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    // Calculate Grand Totals
    double totalQ1 = 0, totalQ2 = 0, totalQ3 = 0, totalQ4 = 0, grandTotalQ = 0;
    double totalY1 = 0, totalY2 = 0, totalY3 = 0, grandTotal3Y = 0;

    if (_mode == ProductMatrixMode.quarterly) {
      for (final item in filteredItems) {
        final p = item as ProductQuarterlySalesMatrixRow;
        totalQ1 += p.q1;
        totalQ2 += p.q2;
        totalQ3 += p.q3;
        totalQ4 += p.q4;
        grandTotalQ += p.total;
      }
    } else {
      for (final item in filteredItems) {
        final p = item as ProductSalesMatrixRow;
        totalY1 += p.y2024;
        totalY2 += p.y2025;
        totalY3 += p.y2026;
        grandTotal3Y += p.total;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar: Mode Toggle, Year/Period Dropdown, Search, Advanced Filter Button
        Wrap(
          spacing: AppTokens.space16,
          runSpacing: AppTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Mode Toggle (Theo Quý vs So sánh 3 năm)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: tabBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: cardBorder, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleBtn('Theo 4 Quý (${widget.selectedYear})', ProductMatrixMode.quarterly, isDark, textPrimary, textSecondary),
                  _buildToggleBtn('So sánh 3 năm', ProductMatrixMode.threeYears, isDark, textPrimary, textSecondary),
                ],
              ),
            ),

            // Khi ở chế độ So sánh 3 năm, hiển thị Dropdown chọn giai đoạn so sánh
            if (_mode == ProductMatrixMode.threeYears)
              SizedBox(
                width: 180,
                child: AppDropdown<String>(
                  value: _selectedPeriodLabel,
                  labelText: 'Giai đoạn so sánh',
                  items: const [
                    DropdownMenuItem(value: '2024 - 2026', child: Text('Năm 2024 - 2026')),
                    DropdownMenuItem(value: '2023 - 2025', child: Text('Năm 2023 - 2025')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPeriodLabel = val;
                        _currentPage = 1;
                      });
                      if (val == '2024 - 2026') {
                        widget.onPeriodChanged([2024, 2025, 2026]);
                      } else {
                        widget.onPeriodChanged([2023, 2024, 2025]);
                      }
                    }
                  },
                ),
              ),

            // Ô tìm kiếm sản phẩm
            SizedBox(
              width: 240,
              height: 44,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm theo tên, SKU...',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: const BorderSide(color: AppColors.primary)),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
              ),
            ),

            // Nút Bộ lọc
            OutlinedButton.icon(
              onPressed: () => setState(() => _isAdvancedFilterOpen = !_isAdvancedFilterOpen),
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? Colors.white : textPrimary,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeFilterCount > 0 ? 'Lọc ($_activeFilterCount)' : 'Bộ lọc',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? Colors.white : textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isAdvancedFilterOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? Colors.white : textSecondary,
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? AppColors.primary : null,
                side: BorderSide(
                  color: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? AppColors.primary : cardBorder,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
              ),
            ),

            if (_hasActiveFilters)
              IconButton(
                tooltip: 'Đặt lại toàn bộ lọc',
                onPressed: _resetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppColors.danger),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                ),
              ),
          ],
        ),

        // Khối Bộ lọc (nếu mở)
        if (_isAdvancedFilterOpen) ...[
          const SizedBox(height: AppTokens.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: filterPanelBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: cardBorder, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Bộ lọc',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_activeFilterCount điều kiện đang áp dụng',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hiển thị $totalItems / ${_mode == ProductMatrixMode.quarterly ? widget.quarterlyProducts.length : widget.productList.length} sản phẩm',
                          style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Đóng',
                          onPressed: () => setState(() => _isAdvancedFilterOpen = false),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: AppDropdown<String>(
                          value: effectiveCategory,
                          labelText: 'Loại sản phẩm',
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat == 'ALL' ? 'Tất cả loại sản phẩm' : cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                                _currentPage = 1;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: AppDropdown<String>(
                          value: _amountOperator,
                          labelText: 'Toán tử so sánh',
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('Tất cả mức tiền')),
                            DropdownMenuItem(value: 'GT', child: Text('Lớn hơn ( > )')),
                            DropdownMenuItem(value: 'GTE', child: Text('Từ mức ( >= )')),
                            DropdownMenuItem(value: 'LT', child: Text('Nhỏ hơn ( < )')),
                            DropdownMenuItem(value: 'BETWEEN', child: Text('Trong khoảng [Min - Max]')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _amountOperator = val;
                                _currentPage = 1;
                              });
                            }
                          },
                        ),
                      ),
                      if (_amountOperator != 'ALL') ...[
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: _amountOperator == 'LT' ? 'Mức trần' : 'Mức sàn',
                              hintText: '50,000,000',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                            ),
                            onChanged: (_) => setState(() => _currentPage = 1),
                          ),
                        ),
                        if (_amountOperator == 'BETWEEN')
                          SizedBox(
                            width: 160,
                            height: 44,
                            child: TextField(
                              controller: _maxAmountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Đến mức',
                                hintText: '300,000,000',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                              ),
                              onChanged: (_) => setState(() => _currentPage = 1),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppTokens.space16),

        // DataTable (Không có cột Loại sản phẩm như người dùng yêu cầu!)
        SmoothLoadingWrapper(
          isLoading: widget.isLoading,
          hasData: widget.quarterlyProducts.isNotEmpty || widget.productList.isNotEmpty,
          initialMinHeight: 360,
          child: filteredItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 40, color: textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text('Không tìm thấy sản phẩm phù hợp.', style: TextStyle(color: textSecondary, fontSize: 13)),
                      ],
                    ),
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
                    headingRowHeight: 46,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columnSpacing: 28,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    columns: _mode == ProductMatrixMode.quarterly
                        ? [
                            DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Quý 1', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Quý 2', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Quý 3', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Quý 4', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(
                              numeric: true,
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                child: Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 12)),
                              ),
                              onSort: _onSort,
                            ),
                          ]
                        : [
                            DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Năm $y1', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Năm $y2', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(numeric: true, label: Text('Năm $y3', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(
                              numeric: true,
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                child: Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 12)),
                              ),
                              onSort: _onSort,
                            ),
                          ],
                    rows: [
                      ...paginatedList.map((item) {
                        final isQuarterly = _mode == ProductMatrixMode.quarterly;
                        final String pName = isQuarterly ? (item as ProductQuarterlySalesMatrixRow).productName : (item as ProductSalesMatrixRow).productName;
                        final String pSku = isQuarterly ? (item as ProductQuarterlySalesMatrixRow).sku : (item as ProductSalesMatrixRow).sku;
                        final String pImg = isQuarterly ? (item as ProductQuarterlySalesMatrixRow).imageUrl : (item as ProductSalesMatrixRow).imageUrl;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                            }
                            return null;
                          }),
                          cells: isQuarterly
                              ? [
                                  // Cột Sản phẩm (Ảnh + Tên + SKU)
                                  DataCell(
                                    SizedBox(
                                      width: 280,
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                              child: pImg.isNotEmpty
                                                  ? Image.network(pImg, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 18))
                                                  : const Icon(Icons.inventory_2_outlined, size: 18),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(pName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 2),
                                                Text(pSku, style: TextStyle(fontSize: 11, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(NumberDisplayFormatter.format((item as ProductQuarterlySalesMatrixRow).q1), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.q2), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.q3), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.q4), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                ]
                              : [
                                  DataCell(
                                    SizedBox(
                                      width: 280,
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                              child: pImg.isNotEmpty
                                                  ? Image.network(pImg, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 18))
                                                  : const Icon(Icons.inventory_2_outlined, size: 18),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(pName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 2),
                                                Text(pSku, style: TextStyle(fontSize: 11, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(NumberDisplayFormatter.format((item as ProductSalesMatrixRow).y2024), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.y2025), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.y2026), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(item.total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                ],
                        );
                      }),

                      // Dòng Tổng cộng chân bảng
                      DataRow(
                        color: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        cells: _mode == ProductMatrixMode.quarterly
                            ? [
                                DataCell(Text('Tổng cộng (${filteredItems.length} sản phẩm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ3), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ4), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(grandTotalQ), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                              ]
                            : [
                                DataCell(Text('Tổng cộng (${filteredItems.length} sản phẩm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalY1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalY2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalY3), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(grandTotal3Y), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                              ],
                      ),
                    ],
                  ),
                ),

                // Phân trang
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AppPagination(
                    currentPage: safePage,
                    totalPages: totalPages,
                    totalItems: totalItems,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    onItemsPerPageChanged: (n) => setState(() {
                      _itemsPerPage = n;
                      _currentPage = 1;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, ProductMatrixMode mode, bool isDark, Color textPrimary, Color textSecondary) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _mode = mode;
          _sortColumnIndex = mode == ProductMatrixMode.quarterly ? 5 : 4;
          _sortAscending = false;
          _currentPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(AppTokens.radiusMd - 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF0F172A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd - 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : textSecondary,
          ),
        ),
      ),
    );
  }
}
