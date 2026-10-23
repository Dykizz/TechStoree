import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/navigation_provider.dart';
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

  int _currentRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final requestId = ++_currentRequestId;
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
      if (mounted && requestId == _currentRequestId) {
        setState(() {
          _dataResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _currentRequestId) {
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
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
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
            _buildSkeletonLoading(backgroundColor, borderColor, isDark),
          ] else if (_errorMessage != null) ...[
            _buildErrorState(textPrimary, backgroundColor, borderColor),
          ] else if (_dataResult != null) ...[
            // ROW 1: KPI CARDS (Compact, Sleek 1-Row on Desktop, ~92px height)
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1150;
                final isMedium = constraints.maxWidth >= 700;
                final crossCount = isDesktop ? 6 : (isMedium ? 3 : 2);
                final ratio = isDesktop ? 2.15 : (isMedium ? 3.35 : 3.0);

                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
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
                      onTap: () => navProvider.setIndex(2),
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
                      onTap: () => navProvider.setIndex(2),
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
                      onTap: () => navProvider.setIndex(6),
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
                      onTap: () => navProvider.setIndex(2),
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
                      onTap: () => navProvider.setIndex(10),
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
                      onTap: () => navProvider.setIndex(1),
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
                          onViewAll: () => navProvider.setIndex(1),
                          onProductTap: (p) => navProvider.setIndex(1),
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
                          onViewAll: () => navProvider.setIndex(4),
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
                      onViewAll: () => navProvider.setIndex(1),
                      onProductTap: (p) => navProvider.setIndex(1),
                    ),
                    const SizedBox(height: 14),
                    CategoryAnalyticsWidget(
                      categoryMetrics: _dataResult!.categoryMetrics,
                      isDark: isDark,
                      cardBg: backgroundColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onViewAll: () => navProvider.setIndex(4),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ROW 4: INVENTORY ALERTS + SURVEY & VOUCHER ENGAGEMENT (WITH CSAT REVIEWS)
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
                          onViewAll: () => navProvider.setIndex(1),
                          onImportPO: () => navProvider.setIndex(6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 6,
                        child: EngagementSummaryWidget(
                          surveyMetric: _dataResult!.surveyMetric,
                          promoMetric: _dataResult!.promoVoucherMetric,
                          reviewMetric: _dataResult!.reviewMetric,
                          onSurveyTap: () => navProvider.setIndex(9),
                          onVoucherTap: () => navProvider.setIndex(8),
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
                      onViewAll: () => navProvider.setIndex(1),
                      onImportPO: () => navProvider.setIndex(6),
                    ),
                    const SizedBox(height: 14),
                    EngagementSummaryWidget(
                      surveyMetric: _dataResult!.surveyMetric,
                      promoMetric: _dataResult!.promoVoucherMetric,
                      reviewMetric: _dataResult!.reviewMetric,
                      onSurveyTap: () => navProvider.setIndex(9),
                      onVoucherTap: () => navProvider.setIndex(8),
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

            // ROW 5: RECENT ORDERS TABLE (Full Width with Clickable Drill-down)
            RecentOrdersWidget(
              orders: _dataResult!.recentOrders,
              isDark: isDark,
              cardBg: backgroundColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onViewAll: () => navProvider.setIndex(2),
              onOrderTap: (order) => navProvider.setIndex(2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(Color cardBg, Color borderColor, bool isDark) {
    final shimmerLine = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton KPI Cards (6 items)
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1150;
            final isMedium = constraints.maxWidth >= 700;
            final crossCount = isDesktop ? 6 : (isMedium ? 3 : 2);
            final ratio = isDesktop ? 2.15 : (isMedium ? 3.35 : 3.0);

            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: ratio,
              children: List.generate(6, (i) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(color: shimmerLine, borderRadius: BorderRadius.circular(7)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(color: shimmerLine, borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 90,
                        height: 16,
                        decoration: BoxDecoration(color: shimmerLine, borderRadius: BorderRadius.circular(4)),
                      ),
                      Container(
                        width: 70,
                        height: 11,
                        decoration: BoxDecoration(color: shimmerLine.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),

        // Skeleton Chart Section (2 items)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1200;
            final content = [
              Container(
                height: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 180, height: 16, decoration: BoxDecoration(color: shimmerLine, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 11, decoration: BoxDecoration(color: shimmerLine.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary.withValues(alpha: 0.7)),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Container(
                height: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 16, decoration: BoxDecoration(color: shimmerLine, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 90, height: 11, decoration: BoxDecoration(color: shimmerLine.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: shimmerLine, width: 14),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ];

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 7, child: content[0]),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: content[1]),
                ],
              );
            }
            return Column(
              children: [
                content[0],
                const SizedBox(height: 14),
                content[1],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(Color textPrimary, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
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
