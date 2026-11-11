import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/page_header.dart';
import 'models/statistics_models.dart';
import 'services/statistics_service.dart';
import 'widgets/category_sales_matrix_view.dart';
import 'widgets/financial_matrix_view.dart';
import 'widgets/product_sales_matrix_view.dart';
import 'widgets/staff_sales_matrix_view.dart';

/// Màn hình Thống kê Kinh doanh Đa chiều (Multi-dimensional Pivot Statistics)
/// Hoàn toàn loại bỏ mock data, tính toán 100% từ Database thực tế (PostgreSQL 17)
class StatisticsScreen extends StatefulWidget {
  final int initialTabIndex;

  const StatisticsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  StatisticsDataset _dataset = StatisticsDataset.empty();

  int _selectedYear = 2026;
  List<int> _selectedProductYears = [2024, 2025, 2026];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Chốt chặn an toàn: Chỉ Quản trị viên (Admin) mới có quyền truy cập dữ liệu Thống kê
    if (!authProvider.isAdmin) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn không có quyền truy cập trang Thống kê (Chỉ dành cho Quản trị viên).';
        });
      }
      return;
    }

    final token = authProvider.token;

    try {
      final dataset = await StatisticsService.fetchDataset(apiService, token);
      if (mounted) {
        setState(() {
          _dataset = dataset;
          if (dataset.availableYears.isNotEmpty) {
            _selectedYear = dataset.availableYears.contains(DateTime.now().year)
                ? DateTime.now().year
                : dataset.availableYears.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối máy chủ khi tải dữ liệu thống kê: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Xuất file CSV theo Tab đang được chọn
  Future<void> _exportActiveTabCsv() async {
    if (_selectedTabIndex == 0) {
      await _exportFinancialCsv();
    } else if (_selectedTabIndex == 1) {
      await _exportStaffCsv();
    } else if (_selectedTabIndex == 2) {
      await _exportProductCsv();
    } else {
      await _exportCategoryCsv();
    }
  }

  // Xuất file CSV cho Tab 1
  Future<void> _exportFinancialCsv() async {
    final rows = StatisticsService.calculateFinancialMatrix(dataset: _dataset, year: _selectedYear);
    final headers = ['Chỉ tiêu ($_selectedYear)', 'Quý 1', 'Quý 2', 'Quý 3', 'Quý 4', 'Tổng cộng'];
    final dataRows = rows.map((r) => [r.metricName, r.q1, r.q2, r.q3, r.q4, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_TaiChinh_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      AppToast.success(context, 'Đã xuất thành công: $path');
    }
  }

  // Xuất file CSV cho Tab 2
  Future<void> _exportStaffCsv() async {
    final rows = StatisticsService.calculateStaffSalesMatrix(dataset: _dataset, year: _selectedYear);
    final headers = ['Mã NV', 'Họ và tên nhân viên', 'Chức vụ', 'Quý 1', 'Quý 2', 'Quý 3', 'Quý 4', 'Tổng cộng'];
    final dataRows = rows.map((r) => [r.staffCode, r.staffName, r.roleTitle, r.q1, r.q2, r.q3, r.q4, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_DoanhSo_NhanVien_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      AppToast.success(context, 'Đã xuất thành công: $path');
    }
  }

  // Xuất file CSV cho Tab 3
  Future<void> _exportProductCsv() async {
    final quarterlyRows = StatisticsService.calculateProductQuarterlySalesMatrix(dataset: _dataset, year: _selectedYear);
    final headers = ['Mã SP', 'Tên sản phẩm', 'Quý 1', 'Quý 2', 'Quý 3', 'Quý 4', 'Tổng cộng'];
    final dataRows = quarterlyRows.map((r) => [r.productCode, r.productName, r.q1, r.q2, r.q3, r.q4, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_DoanhSo_SanPham_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      AppToast.success(context, 'Đã xuất thành công: $path');
    }
  }

  // Xuất file CSV cho Tab 4
  Future<void> _exportCategoryCsv() async {
    final rows = StatisticsService.calculateCategorySalesMatrix(
      dataset: _dataset,
      year: _selectedYear,
      years: _selectedProductYears,
    );
    final headers = ['Mã loại', 'Tên loại sản phẩm', 'Quý 1', 'Quý 2', 'Quý 3', 'Quý 4', 'Tổng cộng', 'Tỷ trọng (%)'];
    final dataRows = rows.map((r) => [
      r.categoryCode,
      r.categoryName,
      r.q1,
      r.q2,
      r.q3,
      r.q4,
      r.totalQuarterly,
      '${r.sharePercentage.toStringAsFixed(1)}%',
    ]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_DoanhSo_LoaiSanPham_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      AppToast.success(context, 'Đã xuất thành công: $path');
    }
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(AppTokens.radiusMd - 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd - 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveKpiSection({
    required FinancialSummaryKpi kpi,
    required int selectedYear,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 550;

        final cards = [
          _StatisticsKpiCard(
            title: 'Tổng thu ($selectedYear)',
            value: NumberDisplayFormatter.format(kpi.totalRevenue),
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _StatisticsKpiCard(
            title: 'Tổng chi ($selectedYear)',
            value: NumberDisplayFormatter.format(kpi.totalExpense),
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.chartCost,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _StatisticsKpiCard(
            title: 'Lợi nhuận ròng ($selectedYear)',
            value: NumberDisplayFormatter.format(kpi.netProfit),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: kpi.netProfit >= 0 ? const Color(0xFF2563EB) : AppColors.danger,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _StatisticsKpiCard(
            title: 'Biên lợi nhuận ròng',
            value: '${kpi.profitMargin.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_outline_rounded,
            iconColor: const Color(0xFF6366F1),
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards.map((c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: c,
              ),
            )).toList(),
          );
        } else if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.only(right: 4, bottom: 8), child: cards[0])),
                  Expanded(child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: cards[1])),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.only(right: 4), child: cards[2])),
                  Expanded(child: Padding(padding: const EdgeInsets.only(left: 4), child: cards[3])),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: cards.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: c,
            )).toList(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (!authProvider.isAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.warning),
              SizedBox(height: 12),
              Text(
                'Truy cập bị từ chối: Chỉ Quản trị viên (Admin) mới có quyền xem Thống kê.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final tabBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Thử lại',
                icon: Icons.refresh_rounded,
                onPressed: _loadData,
              ),
            ],
          ),
        ),
      );
    }

    // Tính toán số liệu trực tiếp từ dataset thực tế
    final financialRows = StatisticsService.calculateFinancialMatrix(
      dataset: _dataset,
      year: _selectedYear,
    );

    final financialKpi = StatisticsService.calculateFinancialSummaryKpi(
      dataset: _dataset,
      year: _selectedYear,
    );

    final staffRows = StatisticsService.calculateStaffSalesMatrix(
      dataset: _dataset,
      year: _selectedYear,
    );

    final productQuarterlyRows = StatisticsService.calculateProductQuarterlySalesMatrix(
      dataset: _dataset,
      year: _selectedYear,
    );

    final productRows = StatisticsService.calculateProductSalesMatrix(
      dataset: _dataset,
      years: _selectedProductYears,
    );

    final categoryRows = StatisticsService.calculateCategorySalesMatrix(
      dataset: _dataset,
      year: _selectedYear,
      years: _selectedProductYears,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề trang đồng nhất hoàn toàn với toàn bộ hệ thống (PageHeader)
          PageHeader(
            title: 'Quản lý thống kê',
            subtitle: 'Theo dõi, phân tích báo cáo ma trận kinh doanh, nhân viên, sản phẩm và ngành hàng',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: AppDropdown<int>(
                    value: _selectedYear,
                    labelText: 'Năm thống kê',
                    items: (_dataset.availableYears.contains(_selectedYear)
                            ? _dataset.availableYears
                            : [_selectedYear, ..._dataset.availableYears])
                        .map((y) => DropdownMenuItem<int>(
                              value: y,
                              child: Text('Năm $y'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Xuất Excel',
                  icon: Icons.file_download_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: _isLoading ? null : _exportActiveTabCsv,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),

          // 4 Thẻ KPI điều hành luôn nằm phía trên các Tab thống kê
          _buildExecutiveKpiSection(
            kpi: financialKpi,
            selectedYear: _selectedYear,
            isDark: isDark,
            cardBg: isDark ? AppColors.darkCard : Colors.white,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: AppTokens.space16),

          // Thanh chuyển 4 Tab phân hệ thống kê (Segmented Navigation)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    index: 0,
                    label: 'Hoạt động kinh doanh',
                    icon: Icons.account_balance_wallet_rounded,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildTabButton(
                    index: 1,
                    label: 'Doanh số nhân viên',
                    icon: Icons.badge_rounded,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildTabButton(
                    index: 2,
                    label: 'Doanh số sản phẩm',
                    icon: Icons.inventory_2_rounded,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildTabButton(
                    index: 3,
                    label: 'Doanh số loại sản phẩm',
                    icon: Icons.category_rounded,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space16),

          // Khối nội dung tương ứng của từng Tab
          if (_selectedTabIndex == 0)
            FinancialMatrixView(
              selectedYear: _selectedYear,
              rows: financialRows,
              isLoading: _isLoading,
            )
          else if (_selectedTabIndex == 1)
            StaffSalesMatrixView(
              selectedYear: _selectedYear,
              staffList: staffRows,
              isLoading: _isLoading,
            )
          else if (_selectedTabIndex == 2)
            ProductSalesMatrixView(
              selectedYear: _selectedYear,
              years: _selectedProductYears,
              quarterlyProducts: productQuarterlyRows,
              productList: productRows,
              isLoading: _isLoading,
              onPeriodChanged: (yrs) => setState(() => _selectedProductYears = yrs),
            )
          else
            CategorySalesMatrixView(
              selectedYear: _selectedYear,
              threeYears: _selectedProductYears,
              categoryList: categoryRows,
              isLoading: _isLoading,
              onPeriodChanged: (yrs) => setState(() => _selectedProductYears = yrs),
            ),
        ],
      ),
    );
  }
}

/// Thẻ KPI điều hành tài chính trang Thống kê
/// Đồng nhất 100% hiệu ứng hover, border glow, shadow và watermark icon với DashboardKpiCard (Trang tổng quan)
class _StatisticsKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _StatisticsKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_StatisticsKpiCard> createState() => _StatisticsKpiCardState();
}

class _StatisticsKpiCardState extends State<_StatisticsKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.iconColor.withValues(alpha: 0.55)
                : widget.borderColor.withValues(alpha: widget.isDark ? 0.6 : 0.8),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: widget.isDark ? 0.20 : 0.12)
                  : (widget.isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.05)),
              blurRadius: _isHovered ? 14 : 7,
              offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // Faint decorative watermark icon in bottom-right corner (đồng nhất 100% với Dashboard)
            Positioned(
              right: -6,
              bottom: -8,
              child: IgnorePointer(
                child: Opacity(
                  opacity: widget.isDark ? 0.06 : 0.045,
                  child: Icon(
                    widget.icon,
                    size: 58,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),

            // Card Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Icon badge + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: widget.isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, size: 14, color: widget.iconColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: widget.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Formatted Value
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
