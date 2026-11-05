import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/page_header.dart';
import 'services/statistics_service.dart';
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
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 2);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
    } else {
      await _exportProductCsv();
    }
  }

  // Xuất file CSV cho Tab 1
  Future<void> _exportFinancialCsv() async {
    final rows = StatisticsService.calculateFinancialMatrix(dataset: _dataset, year: _selectedYear);
    final headers = ['Chỉ tiêu ($_selectedYear)', 'Quý 1 (Q1)', 'Quý 2 (Q2)', 'Quý 3 (Q3)', 'Quý 4 (Q4)', 'TỔNG CỘNG (TC)'];
    final dataRows = rows.map((r) => [r.metricName, r.q1, r.q2, r.q3, r.q4, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_TaiChinh_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất thành công: $path'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Xuất file CSV cho Tab 2
  Future<void> _exportStaffCsv() async {
    final rows = StatisticsService.calculateStaffSalesMatrix(dataset: _dataset, year: _selectedYear);
    final headers = ['Mã NV', 'Họ và tên nhân viên', 'Chức vụ', 'Quý 1 (Q1)', 'Quý 2 (Q2)', 'Quý 3 (Q3)', 'Quý 4 (Q4)', 'TỔNG CỘNG (TC)'];
    final dataRows = rows.map((r) => [r.staffCode, r.staffName, r.roleTitle, r.q1, r.q2, r.q3, r.q4, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_DoanhSo_NhanVien_$_selectedYear.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất thành công: $path'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Xuất file CSV cho Tab 3
  Future<void> _exportProductCsv() async {
    final rows = StatisticsService.calculateProductSalesMatrix(dataset: _dataset, years: _selectedProductYears);
    final headers = ['Mã SP', 'Tên sản phẩm', 'Loại sản phẩm', 'Năm ${_selectedProductYears[0]}', 'Năm ${_selectedProductYears[1]}', 'Năm ${_selectedProductYears[2]}', 'TỔNG CỘNG (TC)'];
    final dataRows = rows.map((r) => [r.productCode, r.productName, r.categoryName, r.y2024, r.y2025, r.y2026, r.total]).toList();

    final path = await StatisticsService.exportCsvFile(
      fileName: 'BaoCao_DoanhSo_SanPham.csv',
      headers: headers,
      rows: dataRows,
    );

    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất thành công: $path'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
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

    final staffRows = StatisticsService.calculateStaffSalesMatrix(
      dataset: _dataset,
      year: _selectedYear,
    );

    final productRows = StatisticsService.calculateProductSalesMatrix(
      dataset: _dataset,
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
            subtitle: 'Theo dõi, phân tích báo cáo ma trận kinh doanh, doanh số nhân viên và sản phẩm',
            action: AppButton(
              label: 'Xuất Excel',
              icon: Icons.file_download_outlined,
              variant: AppButtonVariant.outline,
              onPressed: _isLoading ? null : _exportActiveTabCsv,
            ),
          ),
          const SizedBox(height: AppTokens.space12),

          // Thanh chuyển Tab phân hệ thống kê (Segmented Navigation)
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space16),

          // Khối nội dung tương ứng của từng Tab
          if (_selectedTabIndex == 0)
            FinancialMatrixView(
              selectedYear: _selectedYear,
              availableYears: _dataset.availableYears,
              rows: financialRows,
              isLoading: _isLoading,
              onYearChanged: (y) => setState(() => _selectedYear = y),
            )
          else if (_selectedTabIndex == 1)
            StaffSalesMatrixView(
              selectedYear: _selectedYear,
              availableYears: _dataset.availableYears,
              staffList: staffRows,
              isLoading: _isLoading,
              onYearChanged: (y) => setState(() => _selectedYear = y),
            )
          else
            ProductSalesMatrixView(
              years: _selectedProductYears,
              productList: productRows,
              isLoading: _isLoading,
              onPeriodChanged: (yrs) => setState(() => _selectedProductYears = yrs),
            ),
        ],
      ),
    );
  }
}
