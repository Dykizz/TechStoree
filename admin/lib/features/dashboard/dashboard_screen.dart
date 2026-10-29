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
      final res = await dataProvider.fetchDashboardData(
        period: period,
        token: authProvider.token,
        authProvider: authProvider,
      );
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

          if (_isLoading)
            _buildSkeletonLoading(backgroundColor, borderColor, isDark)
          else if (_errorMessage != null)
            _buildErrorState(textPrimary, backgroundColor, borderColor)
          else if (_dataResult != null)
            _buildDashboardContent(
              data: _dataResult!,
              authProvider: authProvider,
              navProvider: navProvider,
              isDark: isDark,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              adminName: adminName,
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent({
    required DashboardDataResult data,
    required AuthProvider authProvider,
    required NavigationProvider navProvider,
    required bool isDark,
    required Color backgroundColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String adminName,
  }) {
    final hasOrders = authProvider.can('Orders.View');
    final hasPOs = authProvider.can('PurchaseOrders.View');
    final hasProducts = authProvider.can('Products.View');
    final hasCategories = authProvider.can('Categories.View');
    final hasUsers = authProvider.can('Users.View');
    final hasSurveys = authProvider.can('Surveys.View');
    final hasPromotions = authProvider.can('Promotions.View');
    final hasVouchers = authProvider.can('Vouchers.View');
    final hasReviews = hasProducts;

    final kpiCards = <Widget>[
      if (hasOrders) ...[
        DashboardKpiCard(
          title: 'Doanh thu bán hàng',
          formattedValue: currencyFormat.format(data.revenue.current),
          kpi: data.revenue,
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
          formattedValue: '${data.ordersCount.current.toInt()} đơn',
          kpi: data.ordersCount,
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.primary,
          isDark: isDark,
          cardBg: backgroundColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => navProvider.setIndex(2),
        ),
      ],
      if (hasPOs)
        DashboardKpiCard(
          title: 'Chi phí nhập hàng',
          formattedValue: currencyFormat.format(data.importCost.current),
          kpi: data.importCost,
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
      if (hasOrders)
        DashboardKpiCard(
          title: 'Giá trị đơn TB (AOV)',
          formattedValue: currencyFormat.format(data.aov.current),
          kpi: data.aov,
          icon: Icons.analytics_outlined,
          iconColor: Colors.purple,
          isDark: isDark,
          cardBg: backgroundColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => navProvider.setIndex(2),
        ),
      if (hasUsers)
        DashboardKpiCard(
          title: 'Khách hàng mới',
          formattedValue: '${data.newCustomers.current.toInt()} KH',
          kpi: data.newCustomers,
          icon: Icons.people_outline_rounded,
          iconColor: Colors.teal,
          isDark: isDark,
          cardBg: backgroundColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => navProvider.setIndex(10),
        ),
      if (hasProducts)
        DashboardKpiCard(
          title: 'Biến thể cảnh báo tồn',
          formattedValue: '${data.variantAlerts.length} biến thể',
          subtitle: data.variantAlerts.isNotEmpty ? 'Cần kiểm tra nhập hàng' : 'Tồn kho ổn định',
          icon: Icons.warning_amber_rounded,
          iconColor: data.variantAlerts.isNotEmpty ? AppColors.warning : AppColors.success,
          isDark: isDark,
          cardBg: backgroundColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => navProvider.setIndex(1),
        ),
    ];

    final showTopProducts = hasOrders && hasProducts;
    final showCategoryAnalytics = hasCategories;
    final showInventoryAlerts = hasProducts;
    final showEngagement = hasSurveys || hasPromotions || hasVouchers || hasReviews;

    final hasAnyChartOrTable = hasOrders ||
        showTopProducts ||
        showCategoryAnalytics ||
        showInventoryAlerts ||
        showEngagement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ROW 1: KPI CARDS (Only show permitted KPI cards with responsive layout)
        if (kpiCards.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final total = kpiCards.length;

              // When 1 to 3 cards, use Wrap with clamped natural width (260 - 320px) to prevent unnatural stretching
              if (total <= 3) {
                final cardWidth = total == 1
                    ? 320.0
                    : ((maxW - ((total - 1) * 12)) / total).clamp(240.0, 320.0);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kpiCards
                      .map((c) => SizedBox(
                            width: cardWidth,
                            height: 104,
                            child: c,
                          ))
                      .toList(),
                );
              }

              // 4 cards: 4 columns on desktop, 2 on tablet, 1 on mobile
              if (total == 4) {
                final isDesktop = maxW >= 1100;
                final isMedium = maxW >= 650;
                final crossCount = isDesktop ? 4 : (isMedium ? 2 : 1);
                final ratio = isDesktop ? 2.5 : (isMedium ? 2.2 : 2.8);
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: ratio,
                  children: kpiCards,
                );
              }

              // 5 or 6 cards: Full grid
              final isDesktop = maxW >= 1150;
              final isMedium = maxW >= 700;
              final crossCount = isDesktop ? total.clamp(1, 6) : (isMedium ? 3 : 2);
              final ratio = isDesktop ? 1.72 : (isMedium ? 2.3 : 2.1);

              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: ratio,
                children: kpiCards,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // ROW 2: REVENUE TREND + ORDER & PAYMENT STATUS (Requires Orders.View)
        if (hasOrders) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1200;
              final revenueChart = RevenueTrendChart(
                points: data.trendPoints,
                showImportCostComparison: hasPOs,
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
              final statusChart = OrderPaymentStatusCharts(
                orderStatuses: data.orderStatusList,
                paymentStatuses: data.paymentStatusList,
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: revenueChart),
                    const SizedBox(width: 14),
                    Expanded(flex: 5, child: statusChart),
                  ],
                );
              }
              return Column(
                children: [
                  revenueChart,
                  const SizedBox(height: 14),
                  statusChart,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // ROW 3: TOP PRODUCTS + CATEGORY ANALYTICS
        if (showTopProducts || showCategoryAnalytics) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1200;
              final topProductsWidget = TopProductsWidget(
                topProducts: data.topProducts,
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onViewAll: () => navProvider.setIndex(1),
                onProductTap: (p) => navProvider.setIndex(1),
              );
              final categoryAnalyticsWidget = CategoryAnalyticsWidget(
                categoryMetrics: data.categoryMetrics,
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onViewAll: () => navProvider.setIndex(4),
              );

              if (showTopProducts && showCategoryAnalytics) {
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: topProductsWidget),
                      const SizedBox(width: 14),
                      Expanded(flex: 6, child: categoryAnalyticsWidget),
                    ],
                  );
                }
                return Column(
                  children: [
                    topProductsWidget,
                    const SizedBox(height: 14),
                    categoryAnalyticsWidget,
                  ],
                );
              } else if (showTopProducts) {
                return topProductsWidget;
              } else {
                return categoryAnalyticsWidget;
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // ROW 4: INVENTORY ALERTS + SURVEY & VOUCHER ENGAGEMENT
        if (showInventoryAlerts || showEngagement) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1200;
              final inventoryWidget = InventoryAlertsWidget(
                variantAlerts: data.variantAlerts,
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onViewAll: () => navProvider.setIndex(1),
                onImportPO: () => navProvider.setIndex(6),
              );
              final engagementWidget = EngagementSummaryWidget(
                surveyMetric: data.surveyMetric,
                promoMetric: data.promoVoucherMetric,
                reviewMetric: data.reviewMetric,
                showSurveys: hasSurveys,
                showPromotions: hasPromotions || hasVouchers,
                showReviews: hasReviews,
                onSurveyTap: () => navProvider.setIndex(9),
                onVoucherTap: () => navProvider.setIndex(8),
                isDark: isDark,
                cardBg: backgroundColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );

              if (showInventoryAlerts && showEngagement) {
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: inventoryWidget),
                      const SizedBox(width: 14),
                      Expanded(flex: 6, child: engagementWidget),
                    ],
                  );
                }
                return Column(
                  children: [
                    inventoryWidget,
                    const SizedBox(height: 14),
                    engagementWidget,
                  ],
                );
              } else if (showInventoryAlerts) {
                return inventoryWidget;
              } else {
                return engagementWidget;
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // ROW 5: RECENT ORDERS TABLE (Requires Orders.View)
        if (hasOrders) ...[
          RecentOrdersWidget(
            orders: data.recentOrders,
            isDark: isDark,
            cardBg: backgroundColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onViewAll: () => navProvider.setIndex(2),
            onOrderTap: (order) => navProvider.setIndex(2),
          ),
          const SizedBox(height: 16),
        ],

        // ROLE WORKSPACE HUB (When role does not have permission for sales charts & orders)
        if (!hasAnyChartOrTable) ...[
          _buildRoleWorkspaceHub(
            adminName: adminName,
            userRole: authProvider.userRole,
            authProvider: authProvider,
            navProvider: navProvider,
            cardBg: backgroundColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
            hasKpiCards: kpiCards.isNotEmpty,
          ),
        ],
      ],
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
            final ratio = isDesktop ? 1.72 : (isMedium ? 2.3 : 2.1);

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

  Widget _buildRoleWorkspaceHub({
    required String adminName,
    required String userRole,
    required AuthProvider authProvider,
    required NavigationProvider navProvider,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required bool hasKpiCards,
  }) {
    final permittedShortcuts = <({String title, String desc, IconData icon, Color color, int navIndex})>[];
    if (authProvider.can('Products.View')) {
      permittedShortcuts.add((
        title: 'Quản lý sản phẩm',
        desc: 'Kho hàng, danh mục giá & biến thể',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        navIndex: 1,
      ));
    }
    if (authProvider.can('Orders.View')) {
      permittedShortcuts.add((
        title: 'Quản lý đơn hàng',
        desc: 'Xử lý, giao nhận & cập nhật trạng thái',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF10B981),
        navIndex: 2,
      ));
      permittedShortcuts.add((
        title: 'Quản lý hóa đơn',
        desc: 'Hóa đơn bán lẻ & chứng từ thanh toán',
        icon: Icons.receipt_outlined,
        color: const Color(0xFF0EA5E9),
        navIndex: 3,
      ));
    }
    if (authProvider.can('Categories.View')) {
      permittedShortcuts.add((
        title: 'Loại sản phẩm',
        desc: 'Phân loại nhóm ngành hàng kinh doanh',
        icon: Icons.category_outlined,
        color: const Color(0xFF8B5CF6),
        navIndex: 4,
      ));
    }
    if (authProvider.can('Suppliers.View')) {
      permittedShortcuts.add((
        title: 'Nhà cung cấp',
        desc: 'Đối tác cung ứng linh kiện & thiết bị',
        icon: Icons.domain_outlined,
        color: const Color(0xFFF59E0B),
        navIndex: 5,
      ));
    }
    if (authProvider.can('PurchaseOrders.View')) {
      permittedShortcuts.add((
        title: 'Phiếu nhập hàng',
        desc: 'Nhập kho và hạch toán chi phí nhập',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF06B6D4),
        navIndex: 6,
      ));
    }
    if (authProvider.can('Promotions.View')) {
      permittedShortcuts.add((
        title: 'Khuyến mãi & giảm giá',
        desc: 'Chương trình chiết khấu & ưu đãi giá',
        icon: Icons.local_offer_outlined,
        color: const Color(0xFFEC4899),
        navIndex: 7,
      ));
    }
    if (authProvider.can('Vouchers.View')) {
      permittedShortcuts.add((
        title: 'Mã giảm giá Voucher',
        desc: 'Mã coupon ưu đãi và voucher tích điểm',
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFFF97316),
        navIndex: 8,
      ));
    }
    if (authProvider.can('Surveys.View')) {
      permittedShortcuts.add((
        title: 'Khảo sát thị trường',
        desc: 'Thăm dò ý kiến và phản hồi người dùng',
        icon: Icons.poll_outlined,
        color: const Color(0xFF8B5CF6),
        navIndex: 9,
      ));
    }
    if (authProvider.can('Users.View')) {
      permittedShortcuts.add((
        title: 'Quản lý khách hàng',
        desc: 'Hồ sơ người dùng & tài khoản khách hàng',
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF14B8A6),
        navIndex: 10,
      ));
      permittedShortcuts.add((
        title: 'Quản lý nhân viên',
        desc: 'Danh sách nhân sự & thông tin tài khoản',
        icon: Icons.badge_outlined,
        color: const Color(0xFF3B82F6),
        navIndex: 11,
      ));
    }
    if (authProvider.can('Roles.View')) {
      permittedShortcuts.add((
        title: 'Vai trò & Phân quyền',
        desc: 'Thiết lập ma trận quyền hạn tài khoản',
        icon: Icons.admin_panel_settings_outlined,
        color: const Color(0xFFEF4444),
        navIndex: 12,
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.6 : 0.8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Không gian làm việc: $adminName',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            userRole.isNotEmpty ? userRole : 'STAFF',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasKpiCards
                          ? 'Dữ liệu chỉ số được giới hạn theo vai trò của bạn. Bạn có thể truy cập nhanh các phân hệ nghiệp vụ được phân quyền dưới đây:'
                          : 'Bảng điều khiển kinh doanh tổng hợp được bảo vệ theo phân quyền người dùng. Truy cập nhanh các nghiệp vụ được phân quyền:',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
          const SizedBox(height: 18),

          // Shortcut modules grid
          if (permittedShortcuts.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 1050
                    ? ((constraints.maxWidth - 36) / 3).clamp(240.0, 360.0)
                    : (constraints.maxWidth >= 650 ? ((constraints.maxWidth - 16) / 2).clamp(240.0, 360.0) : double.infinity);

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: permittedShortcuts.map((item) {
                    return SizedBox(
                      width: itemWidth == double.infinity ? null : itemWidth,
                      child: InkWell(
                        onTap: () => navProvider.setIndex(item.navIndex),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: item.color.withValues(alpha: 0.25)),
                                ),
                                child: Icon(item.icon, size: 18, color: item.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.desc,
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tài khoản của bạn hiện chưa được cấp quyền thao tác phân hệ nghiệp vụ khác. Vui lòng liên hệ Quản trị viên (Admin) để được mở rộng quyền.',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
