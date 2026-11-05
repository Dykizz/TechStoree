import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import '../models/statistics_models.dart';

class ProductSalesMatrixView extends StatefulWidget {
  final List<int> years;
  final List<ProductSalesMatrixRow> productList;
  final ValueChanged<List<int>> onPeriodChanged;
  final bool isLoading;

  const ProductSalesMatrixView({
    super.key,
    required this.years,
    required this.productList,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  @override
  State<ProductSalesMatrixView> createState() => _ProductSalesMatrixViewState();
}

class _ProductSalesMatrixViewState extends State<ProductSalesMatrixView> {
  late String _selectedPeriodLabel;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  String _searchQuery = '';
  bool _isAdvancedFilterOpen = false;
  String _selectedCategory = 'ALL';
  String _amountOperator = 'ALL'; // ALL, GT (>), GTE (>=), LT (<), BETWEEN
  String _targetPeriod = 'TOTAL'; // TOTAL, Y1, Y2, Y3

  
  int _sortColumnIndex = 5;
  bool _sortAscending = false; 

  // Phân trang & PageSize đồng nhất với toàn bộ hệ thống
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
      _targetPeriod = 'TOTAL';
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

    final y1 = widget.years.isNotEmpty ? widget.years[0] : 2024;
    final y2 = widget.years.length > 1 ? widget.years[1] : 2025;
    final y3 = widget.years.length > 2 ? widget.years[2] : 2026;

    final categories = <String>['ALL', ...widget.productList.map((p) => p.categoryName).toSet()];
    final minAmt = _parseAmount(_minAmountController.text);
    final maxAmt = _parseAmount(_maxAmountController.text);

    // 1. Lọc theo từ khóa, danh mục và toán tử so sánh số tiền (Đề xuất 3)
    final filtered = widget.productList.where((p) {
      // Lọc từ khóa
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchSearch = p.productName.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.productCode.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q);
        if (!matchSearch) return false;
      }

      // Lọc theo danh mục
      if (_selectedCategory != 'ALL' && p.categoryName != _selectedCategory) {
        return false;
      }

      // Lọc theo điều kiện số tiền
      if (_amountOperator != 'ALL') {
        double val = p.total;
        if (_targetPeriod == 'Y1') val = p.y2024;
        if (_targetPeriod == 'Y2') val = p.y2025;
        if (_targetPeriod == 'Y3') val = p.y2026;

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

    // 2. Sắp xếp động theo cột được chọn (Đề xuất 4)
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.productName.compareTo(b.productName);
          break;
        case 1:
          cmp = a.categoryName.compareTo(b.categoryName);
          break;
        case 2:
          cmp = a.y2024.compareTo(b.y2024);
          break;
        case 3:
          cmp = a.y2025.compareTo(b.y2025);
          break;
        case 4:
          cmp = a.y2026.compareTo(b.y2026);
          break;
        case 5:
        default:
          cmp = a.total.compareTo(b.total);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    // 3. Tính tổng lũy kế các năm từ toàn bộ danh sách đã lọc
    double totalY1 = 0;
    double totalY2 = 0;
    double totalY3 = 0;
    for (final p in filtered) {
      totalY1 += p.y2024;
      totalY2 += p.y2025;
      totalY3 += p.y2026;
    }
    final grandTotal = totalY1 + totalY2 + totalY3;

    // 4. Phân trang dữ liệu (Pagination Slice)
    final totalItems = filtered.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
    final safePage = _currentPage.clamp(1, totalPages);
    final paginatedList = filtered.skip((safePage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar ngữ cảnh của Tab 3 (Bộ lọc giai đoạn, Tìm kiếm & Nút mở Bộ lọc nâng cao)
        Wrap(
          spacing: AppTokens.space16,
          runSpacing: AppTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
            SizedBox(
              width: 320,
              height: 44,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm theo tên, mã SKU hoặc loại...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                }),
              ),
            ),
            // Nút "Bộ lọc nâng cao" (Đề xuất 3)
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isAdvancedFilterOpen = !_isAdvancedFilterOpen);
              },
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: (_isAdvancedFilterOpen || _activeFilterCount > 0) ? Colors.white : textPrimary,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeFilterCount > 0 ? 'Lọc ($_activeFilterCount)' : 'Bộ lọc nâng cao',
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

        // Panel Lọc Nâng Cao (Đề xuất 3: Lọc theo Danh mục & Toán tử so sánh doanh số)
        if (_isAdvancedFilterOpen) ...[
          const SizedBox(height: AppTokens.space12),
          Container(
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: filterPanelBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: cardBorder, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Tìm kiếm nâng cao (Danh mục & Điều kiện doanh số)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Hiển thị $totalItems / ${widget.productList.length} sản phẩm',
                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Lọc theo Danh mục
                    SizedBox(
                      width: 190,
                      child: AppDropdown<String>(
                        value: _selectedCategory,
                        labelText: 'Loại sản phẩm',
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat == 'ALL' ? 'Tất cả danh mục' : cat),
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
                    // Phạm vi áp dụng (Năm)
                    SizedBox(
                      width: 170,
                      child: AppDropdown<String>(
                        value: _targetPeriod,
                        labelText: 'Chỉ tiêu so sánh',
                        items: [
                          const DropdownMenuItem(value: 'TOTAL', child: Text('Cả giai đoạn (TC)')),
                          DropdownMenuItem(value: 'Y1', child: Text('Năm $y1')),
                          DropdownMenuItem(value: 'Y2', child: Text('Năm $y2')),
                          DropdownMenuItem(value: 'Y3', child: Text('Năm $y3')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _targetPeriod = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                    // Toán tử so sánh
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
                    // Ô nhập số tiền Min / Giá trị lọc
                    if (_amountOperator != 'ALL') ...[
                      SizedBox(
                        width: 180,
                        height: 44,
                        child: TextField(
                          controller: _minAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: _amountOperator == 'LT' ? 'Mức trần (VNĐ)' : 'Mức sàn (VNĐ)',
                            labelStyle: TextStyle(color: textSecondary, fontSize: 12),
                            hintText: 'VD: 50.000.000',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: const BorderSide(color: AppColors.primary)),
                          ),
                          onChanged: (_) => setState(() => _currentPage = 1),
                        ),
                      ),
                      if (_amountOperator == 'BETWEEN')
                        SizedBox(
                          width: 180,
                          height: 44,
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Đến mức (VNĐ)',
                              labelStyle: TextStyle(color: textSecondary, fontSize: 12),
                              hintText: 'VD: 300.000.000',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: BorderSide(color: cardBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd), borderSide: const BorderSide(color: AppColors.primary)),
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

        // Bảng Ma trận Doanh số Sản phẩm (Bảng c - Có Quick Sort & Phân trang AppPagination)
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    'Không tìm thấy sản phẩm phù hợp với điều kiện tìm kiếm/lọc hiện tại.',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          DataTableContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScrollableTableWrapper(
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 46,
                    dataRowMinHeight: 54,
                    dataRowMaxHeight: 54,
                    columnSpacing: 28,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    columns: [
                      DataColumn(
                        label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: Text('Loại sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Năm $y1', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Năm $y2', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Năm $y3', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('TỔNG CỘNG (TC)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 12)),
                        ),
                        onSort: _onSort,
                      ),
                    ],
                    rows: [
                      ...paginatedList.map((p) {
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                            }
                            return null;
                          }),
                          cells: [
                            // Cột lồng ghép Ảnh sản phẩm + Tên + Mã SKU bên dưới
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                          border: Border.all(color: cardBorder, width: 0.5),
                                        ),
                                        child: p.imageUrl.isNotEmpty
                                            ? Image.network(
                                                p.imageUrl,
                                                width: 36,
                                                height: 36,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  width: 36,
                                                  height: 36,
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  child: const Icon(Icons.devices, size: 16, color: AppColors.primary),
                                                ),
                                              )
                                            : Container(
                                                width: 36,
                                                height: 36,
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                child: const Icon(Icons.devices, size: 16, color: AppColors.primary),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.space10),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            p.productName,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'SKU: ${p.sku.isNotEmpty ? p.sku : p.productCode}',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
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
                                  p.categoryName,
                                  style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(p.y2024),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(p.y2025),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(p.y2026),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: cardBorder, width: 0.8),
                                ),
                                child: Text(
                                  NumberDisplayFormatter.format(p.total),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Dòng TỔNG CỘNG TOÀN BỘ SẢN PHẨM (Grand Total Row - Expanded chống tràn)
                      DataRow(
                        color: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Row(
                                children: [
                                  const Icon(Icons.functions_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'TỔNG DOANH SỐ SẢN PHẨM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '—',
                              style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalY1),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalY2),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalY3),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary, width: 1),
                              ),
                              child: Text(
                                NumberDisplayFormatter.format(grandTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Thanh phân trang AppPagination chuẩn hệ thống
                if (totalItems > 0)
                  AppPagination(
                    currentPage: safePage,
                    totalPages: totalPages,
                    totalItems: totalItems,
                    itemsPerPage: _itemsPerPage,
                    itemsPerPageOptions: const [10, 20, 50, 100],
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
        const SizedBox(height: AppTokens.space16),
        // Chú thích phương pháp thống kê
        Text(
          '* Ghi chú: Dữ liệu được tính toán 100% từ Database thực tế. Doanh số tính theo giá trị thực thu của từng mặt hàng qua các năm. Đơn vị tiền tệ: VNĐ (đ). Click tiêu đề cột để sắp xếp nhanh.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
        ),
      ],
    );
  }
}
