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

class StaffSalesMatrixView extends StatefulWidget {
  final int selectedYear;
  final List<int> availableYears;
  final List<StaffSalesMatrixRow> staffList;
  final ValueChanged<int> onYearChanged;
  final bool isLoading;

  const StaffSalesMatrixView({
    super.key,
    required this.selectedYear,
    required this.availableYears,
    required this.staffList,
    required this.onYearChanged,
    this.isLoading = false,
  });

  @override
  State<StaffSalesMatrixView> createState() => _StaffSalesMatrixViewState();
}

class _StaffSalesMatrixViewState extends State<StaffSalesMatrixView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  String _searchQuery = '';
  bool _isAdvancedFilterOpen = false;
  String _amountOperator = 'ALL'; // ALL, GT (>), GTE (>=), LT (<), BETWEEN
  String _targetPeriod = 'TOTAL'; // TOTAL, Q1, Q2, Q3, Q4

  // Đề xuất 4: Sắp xếp theo cột (Mặc định: Top doanh số cao nhất lên đầu)
  int _sortColumnIndex = 5; // Cột 5 là TỔNG CỘNG (TC)
  bool _sortAscending = false; // false = Giảm dần

  // Phân trang & PageSize đồng nhất với toàn bộ hệ thống
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
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
      (_amountOperator != 'ALL' &&
          (_minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty));

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
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

    final yearsList = widget.availableYears.contains(widget.selectedYear)
        ? widget.availableYears
        : [widget.selectedYear, ...widget.availableYears];

    final minAmt = _parseAmount(_minAmountController.text);
    final maxAmt = _parseAmount(_maxAmountController.text);

    // 1. Lọc theo từ khóa tìm kiếm và toán tử so sánh số tiền (Đề xuất 3)
    final filtered = widget.staffList.where((s) {
      // Lọc từ khóa
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchSearch = s.staffName.toLowerCase().contains(q) || s.staffCode.toLowerCase().contains(q);
        if (!matchSearch) return false;
      }

      // Lọc theo điều kiện số tiền
      if (_amountOperator != 'ALL') {
        double val = s.total;
        if (_targetPeriod == 'Q1') val = s.q1;
        if (_targetPeriod == 'Q2') val = s.q2;
        if (_targetPeriod == 'Q3') val = s.q3;
        if (_targetPeriod == 'Q4') val = s.q4;

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
          cmp = a.staffName.compareTo(b.staffName);
          break;
        case 1:
          cmp = a.q1.compareTo(b.q1);
          break;
        case 2:
          cmp = a.q2.compareTo(b.q2);
          break;
        case 3:
          cmp = a.q3.compareTo(b.q3);
          break;
        case 4:
          cmp = a.q4.compareTo(b.q4);
          break;
        case 5:
        default:
          cmp = a.total.compareTo(b.total);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    // 3. Tính tổng lũy kế toàn công ty từ toàn bộ danh sách đã lọc
    double totalQ1 = 0;
    double totalQ2 = 0;
    double totalQ3 = 0;
    double totalQ4 = 0;
    for (final s in filtered) {
      totalQ1 += s.q1;
      totalQ2 += s.q2;
      totalQ3 += s.q3;
      totalQ4 += s.q4;
    }
    final grandTotal = totalQ1 + totalQ2 + totalQ3 + totalQ4;

    // 4. Phân trang dữ liệu (Pagination Slice)
    final totalItems = filtered.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
    final safePage = _currentPage.clamp(1, totalPages);
    final paginatedList = filtered.skip((safePage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar ngữ cảnh của Tab 2 (Chọn năm, Tìm kiếm & Nút mở Bộ lọc nâng cao)
        Wrap(
          spacing: AppTokens.space16,
          runSpacing: AppTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: AppDropdown<int>(
                value: widget.selectedYear,
                labelText: 'Năm thống kê',
                items: yearsList.map((y) {
                  return DropdownMenuItem<int>(
                    value: y,
                    child: Text('Năm $y'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) widget.onYearChanged(val);
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
                  hintText: 'Tìm theo mã hoặc tên nhân viên...',
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

        // Panel Lọc Nâng Cao (Đề xuất 3: Toán tử so sánh >, <, >=, Trong khoảng)
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
                          'Tìm kiếm nâng cao',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Hiển thị $totalItems / ${widget.staffList.length} nhân viên',
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
                    // Phạm vi áp dụng
                    SizedBox(
                      width: 170,
                      child: AppDropdown<String>(
                        value: _targetPeriod,
                        labelText: 'Chỉ tiêu so sánh',
                        items: const [
                          DropdownMenuItem(value: 'TOTAL', child: Text('Cả năm (TC)')),
                          DropdownMenuItem(value: 'Q1', child: Text('Quý 1 (Q1)')),
                          DropdownMenuItem(value: 'Q2', child: Text('Quý 2 (Q2)')),
                          DropdownMenuItem(value: 'Q3', child: Text('Quý 3 (Q3)')),
                          DropdownMenuItem(value: 'Q4', child: Text('Quý 4 (Q4)')),
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
                              hintText: 'VD: 200.000.000',
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

        // Bảng Ma trận Doanh số Nhân viên (Bảng b - Có Quick Sort & Phân trang AppPagination)
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
                  Icon(Icons.person_search_outlined, size: 40, color: textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    'Không tìm thấy nhân viên phù hợp với điều kiện tìm kiếm/lọc hiện tại.',
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
                        label: Text('Nhân viên bán hàng', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Quý 1 (Q1)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Quý 2 (Q2)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Quý 3 (Q3)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text('Quý 4 (Q4)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
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
                      ...paginatedList.map((s) {
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                            }
                            return null;
                          }),
                          cells: [
                            // Cột lồng ghép Tên nhân viên và Mã/Chức vụ bên dưới
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.staffName,
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
                                      'Mã: ${s.staffCode}  •  ${s.roleTitle}',
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
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(s.q1),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(s.q2),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(s.q3),
                                style: TextStyle(fontSize: 13, color: textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                NumberDisplayFormatter.format(s.q4),
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
                                  NumberDisplayFormatter.format(s.total),
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
                      // Dòng TỔNG CỘNG TOÀN CÔNG TY (Grand Total Row - Expanded chống tràn)
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
                                      'TỔNG CỘNG TOÀN CÔNG TY',
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
                              NumberDisplayFormatter.format(totalQ1),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalQ2),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalQ3),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              NumberDisplayFormatter.format(totalQ4),
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
                    itemsPerPageOptions: const [5, 10, 20, 50],
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
          '* Ghi chú: Dữ liệu được tính toán 100% từ Database thực tế. Doanh số ghi nhận theo nhân viên phụ trách/xác nhận đơn hàng. Đơn vị tiền tệ: VNĐ (đ). Click tiêu đề cột để sắp xếp nhanh.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
        ),
      ],
    );
  }
}
