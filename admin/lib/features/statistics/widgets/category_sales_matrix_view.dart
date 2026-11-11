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

enum CategoryMatrixMode { quarterly, threeYears }

class CategorySalesMatrixView extends StatefulWidget {
  final int selectedYear;
  final List<int> threeYears;
  final List<CategorySalesMatrixRow> categoryList;
  final ValueChanged<List<int>> onPeriodChanged;
  final bool isLoading;

  const CategorySalesMatrixView({
    super.key,
    required this.selectedYear,
    required this.threeYears,
    required this.categoryList,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  @override
  State<CategorySalesMatrixView> createState() => _CategorySalesMatrixViewState();
}

class _CategorySalesMatrixViewState extends State<CategorySalesMatrixView> {
  CategoryMatrixMode _mode = CategoryMatrixMode.quarterly;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _sortColumnIndex = 6;
  bool _sortAscending = false;

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final tabBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    final y1 = widget.threeYears.isNotEmpty ? widget.threeYears[0] : 2024;
    final y2 = widget.threeYears.length > 1 ? widget.threeYears[1] : 2025;
    final y3 = widget.threeYears.length > 2 ? widget.threeYears[2] : 2026;

    // Filter by keyword
    final filtered = widget.categoryList.where((cat) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = cat.categoryName.toLowerCase().contains(q) ||
            cat.categoryCode.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp = 0;
      if (_mode == CategoryMatrixMode.quarterly) {
        switch (_sortColumnIndex) {
          case 0:
            cmp = a.categoryCode.compareTo(b.categoryCode);
            break;
          case 1:
            cmp = a.categoryName.compareTo(b.categoryName);
            break;
          case 2:
            cmp = a.q1.compareTo(b.q1);
            break;
          case 3:
            cmp = a.q2.compareTo(b.q2);
            break;
          case 4:
            cmp = a.q3.compareTo(b.q3);
            break;
          case 5:
            cmp = a.q4.compareTo(b.q4);
            break;
          case 6:
            cmp = a.totalQuarterly.compareTo(b.totalQuarterly);
            break;
          case 7:
            cmp = a.sharePercentage.compareTo(b.sharePercentage);
            break;
          default:
            cmp = a.totalQuarterly.compareTo(b.totalQuarterly);
            break;
        }
      } else {
        switch (_sortColumnIndex) {
          case 0:
            cmp = a.categoryCode.compareTo(b.categoryCode);
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
            cmp = a.total3Years.compareTo(b.total3Years);
            break;
        }
      }
      return _sortAscending ? cmp : -cmp;
    });

    // Pagination
    final totalItems = filtered.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
    final safePage = _currentPage.clamp(1, totalPages);
    final paginatedList = filtered.skip((safePage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    // Summary totals
    double totalQ1 = 0, totalQ2 = 0, totalQ3 = 0, totalQ4 = 0, grandTotalQ = 0;
    double totalY1 = 0, totalY2 = 0, totalY3 = 0, grandTotal3Y = 0;
    for (final c in filtered) {
      totalQ1 += c.q1;
      totalQ2 += c.q2;
      totalQ3 += c.q3;
      totalQ4 += c.q4;
      grandTotalQ += c.totalQuarterly;
      totalY1 += c.y2024;
      totalY2 += c.y2025;
      totalY3 += c.y2026;
      grandTotal3Y += c.total3Years;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar: Mode Toggle, Year / Period Selector & Search
        Wrap(
          spacing: AppTokens.space16,
          runSpacing: AppTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Mode Toggle
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
                  _buildToggleBtn('Theo 4 Quý (${widget.selectedYear})', CategoryMatrixMode.quarterly, isDark, textPrimary, textSecondary),
                  _buildToggleBtn('So sánh 3 năm', CategoryMatrixMode.threeYears, isDark, textPrimary, textSecondary),
                ],
              ),
            ),

            // Khi ở chế độ So sánh 3 năm, hiển thị Dropdown chọn giai đoạn so sánh
            if (_mode == CategoryMatrixMode.threeYears)
              SizedBox(
                width: 180,
                child: AppDropdown<String>(
                  value: '${widget.threeYears.first} - ${widget.threeYears.last}',
                  labelText: 'Giai đoạn so sánh',
                  items: const [
                    DropdownMenuItem(value: '2024 - 2026', child: Text('Năm 2024 - 2026')),
                    DropdownMenuItem(value: '2023 - 2025', child: Text('Năm 2023 - 2025')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      if (val == '2024 - 2026') {
                        widget.onPeriodChanged([2024, 2025, 2026]);
                      } else {
                        widget.onPeriodChanged([2023, 2024, 2025]);
                      }
                      setState(() => _currentPage = 1);
                    }
                  },
                ),
              ),

            // Ô tìm kiếm loại sản phẩm
            SizedBox(
              width: 240,
              height: 44,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm loại sản phẩm, mã...',
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
          ],
        ),
        const SizedBox(height: AppTokens.space16),

        // DataTable
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
                  Icon(Icons.category_outlined, size: 40, color: textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('Không tìm thấy loại sản phẩm phù hợp.', style: TextStyle(color: textSecondary, fontSize: 13)),
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
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columnSpacing: 26,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    columns: _mode == CategoryMatrixMode.quarterly
                        ? [
                            DataColumn(label: Text('Mã loại', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(label: Text('Tên loại sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
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
                            DataColumn(numeric: true, label: Text('Tỷ trọng (%)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                          ]
                        : [
                            DataColumn(label: Text('Mã loại', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
                            DataColumn(label: Text('Tên loại sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)), onSort: _onSort),
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
                      ...paginatedList.map((cat) {
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                            }
                            return null;
                          }),
                          cells: _mode == CategoryMatrixMode.quarterly
                              ? [
                                  DataCell(Text(cat.categoryCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.category_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(cat.categoryName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.q1), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.q2), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.q3), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.q4), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(
                                    Text(
                                      NumberDisplayFormatter.format(cat.totalQuarterly),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: (cat.sharePercentage / 100).clamp(0.0, 1.0),
                                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                              minHeight: 4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${cat.sharePercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ]
                              : [
                                  DataCell(Text(cat.categoryCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.category_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(cat.categoryName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.y2024), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.y2025), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(Text(NumberDisplayFormatter.format(cat.y2026), style: TextStyle(fontSize: 13, color: textPrimary))),
                                  DataCell(
                                    Text(
                                      NumberDisplayFormatter.format(cat.total3Years),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                  ),
                                ],
                        );
                      }),

                      // Dòng Tổng cộng chân bảng
                      DataRow(
                        color: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        cells: _mode == CategoryMatrixMode.quarterly
                            ? [
                                const DataCell(SizedBox.shrink()),
                                DataCell(Text('Tổng cộng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ3), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(totalQ4), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
                                DataCell(Text(NumberDisplayFormatter.format(grandTotalQ), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                                const DataCell(Text('100.0%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                              ]
                            : [
                                const DataCell(SizedBox.shrink()),
                                DataCell(Text('Tổng cộng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary))),
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
      ],
    );
  }

  Widget _buildToggleBtn(String label, CategoryMatrixMode mode, bool isDark, Color textPrimary, Color textSecondary) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _mode = mode;
          _sortColumnIndex = mode == CategoryMatrixMode.quarterly ? 6 : 5;
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
