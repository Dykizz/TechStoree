import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import 'models/dashboard_data.dart';
import 'services/dashboard_data_provider.dart';
import 'widgets/category_analytics_widget.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_kpi_card.dart';
import 'widgets/engagement_summary_widget.dart';
import 'widgets/inventory_alerts_widget.dart';
import 'widgets/order_payment_status_charts.dart';
import 'widgets/recent_orders_widget.dart';
import 'widgets/revenue_trend_chart.dart';
import 'widgets/top_products_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  DashboardTimeRangeType _selectedRangeType = DashboardTimeRangeType.last7Days;
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;
  DashboardDataResult? _dataResult;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = DashboardDataProvider(apiService: apiService);

    final period = DashboardTimePeriod.fromType(_selectedRangeType, customRange: _customDateRange);

    try {
      final res = await dataProvider.fetchDashboardData(period: period, token: authProvider.token);
      if (mounted) {
        setState(() {
          _dataResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải dữ liệu bảng điều khiển: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final adminName = authProvider.userName.isNotEmpty ? authProvider.userName : 'Admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER WITH GLOBAL DATE FILTER
          DashboardHeader(
            adminName: adminName,
            selectedRangeType: _selectedRangeType,
            customDateRange: _customDateRange,
            onRangeTypeChanged: (type) {
              setState(() => _selectedRangeType = type);
              _loadDashboardData();
            },
            onCustomDateRangeSelected: (range) {
              setState(() {
                _selectedRangeType = DashboardTimeRangeType.custom;
                _customDateRange = range;
              });
              _loadDashboardData();
            },
            onRefresh: _loadDashboardData,
            isLoading: _isLoading,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: backgroundColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),

          if (_isLoading) ...[
            _buildSkeletonLoading(backgroundColor, borderColor),
          ] else if (_errorMessage != null) ...[
            _buildErrorState(textPrimary, backgroundColor, borderColor),
          ] else if (_dataResult != null) ...[
            // ROW 1: KPI CARDS (6 Summary Cards Grid with Responsive Aspect Ratio)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1500;
                final isMedium = constraints.maxWidth >= 950;
                final crossCount = isWide ? 6 : (isMedium ? 3 : 2);
                final ratio = isWide ? 1.65 : (isMedium ? 2.2 : 1.7);

                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    DashboardKpiCard(
                      title: 'Doanh thu bán hàng',
                      formattedValue: currencyFormat.format(_dataResult!.revenue.current),
                      kpi: _dataResult!.revenue,
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.success,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    DashboardKpiCard(
                      title: 'Số lượng đơn hàng',
                      formattedValue: '${_dataResult!.ordersCount.current.toInt()} đơn',
                      kpi: _dataResult!.ordersCount,
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.primary,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    DashboardKpiCard(
                      title: 'Chi phí nhập hàng',
                      formattedValue: currencyFormat.format(_dataResult!.importCost.current),
                      kpi: _dataResult!.importCost,
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.info,
                      isNeutralTrend: true,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    DashboardKpiCard(
                      title: 'Giá trị đơn TB (AOV)',
                      formattedValue: currencyFormat.format(_dataResult!.aov.current),
                      kpi: _dataResult!.aov,
                      icon: Icons.analytics_outlined,
                      iconColor: Colors.purple,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    DashboardKpiCard(
                      title: 'Khách hàng mới',
                      formattedValue: '${_dataResult!.newCustomers.current.toInt()} KH',
                      kpi: _dataResult!.newCustomers,
                      icon: Icons.people_outline_rounded,
                      iconColor: Colors.teal,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    DashboardKpiCard(
                      title: 'Biến thể cảnh báo tồn',
                      formattedValue: '${_dataResult!.variantAlerts.length} biến thể',
                      subtitle: _dataResult!.variantAlerts.isNotEmpty ? 'Cần kiểm tra nhập hàng' : 'Tồn kho ổn định',
                      icon: Icons.warning_amber_rounded,
                      iconColor: _dataResult!.variantAlerts.isNotEmpty ? AppColors.warning : AppColors.success,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ROW 2: REVENUE TREND + ORDER & PAYMENT STATUS ANALYTICS
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1200;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: RevenueTrendChart(
                          points: _dataResult!.trendPoints,
                          showImportCostComparison: true,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: OrderPaymentStatusCharts(
                          orderStatuses: _dataResult!.orderStatusList,
                          paymentStatuses: _dataResult!.paymentStatusList,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    RevenueTrendChart(
                      points: _dataResult!.trendPoints,
                      showImportCostComparison: true,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),
                    OrderPaymentStatusCharts(
                      orderStatuses: _dataResult!.orderStatusList,
                      paymentStatuses: _dataResult!.paymentStatusList,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ROW 3: TOP PRODUCTS + CATEGORY ANALYTICS
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1200;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: TopProductsWidget(
                          topProducts: _dataResult!.topProducts,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 6,
                        child: CategoryAnalyticsWidget(
                          categoryMetrics: _dataResult!.categoryMetrics,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    TopProductsWidget(
                      topProducts: _dataResult!.topProducts,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),
                    CategoryAnalyticsWidget(
                      categoryMetrics: _dataResult!.categoryMetrics,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ROW 4: INVENTORY ALERTS + SURVEY & VOUCHER ENGAGEMENT
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1200;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: InventoryAlertsWidget(
                          variantAlerts: _dataResult!.variantAlerts,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 6,
                        child: EngagementSummaryWidget(
                          surveyMetric: _dataResult!.surveyMetric,
                          promoMetric: _dataResult!.promoVoucherMetric,
                          isDark: isDark,
                          cardBg: backgroundColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    InventoryAlertsWidget(
                      variantAlerts: _dataResult!.variantAlerts,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),
                    EngagementSummaryWidget(
                      surveyMetric: _dataResult!.surveyMetric,
                      promoMetric: _dataResult!.promoVoucherMetric,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ROW 5: RECENT ORDERS TABLE (Full Width)
            RecentOrdersWidget(
              orders: _dataResult!.recentOrders,
              isDark: isDark,
              cardBg: backgroundColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(Color cardBg, Color borderColor) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildErrorState(Color textPrimary, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
