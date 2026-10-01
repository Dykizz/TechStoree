import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/purchase_order.dart';
import '../../core/models/promotion.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  int _selectedTimeRange = 0; // 0: 7 ngày, 1: 30 ngày, 2: 6 tháng
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder(
      future: Future.wait([
        apiService.getProducts(token: authProvider.token),
        apiService.getOrders(token: authProvider.token),
        apiService.getPurchaseOrders(token: authProvider.token),
        apiService.getPromotions(token: authProvider.token),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final products = (snapshot.data?[0] as List<Product>?) ?? [];
        final orders = (snapshot.data?[1] as List<Order>?) ?? [];
        final purchaseOrders = (snapshot.data?[2] as List<PurchaseOrder>?) ?? [];
        final promotions = (snapshot.data?[3] as List<Promotion>?) ?? [];

        final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        final totalPoCost = purchaseOrders.fold<double>(0, (sum, po) => sum + po.totalCost);
        final lowStockCount = products.where((p) => p.stock <= 10).length;
        final activePromosCount = promotions.where((p) => p.status == 'ACTIVE').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng trở lại, ${authProvider.userName.isNotEmpty ? authProvider.userName : "Admin"}! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Theo dõi doanh thu, tồn kho và các chỉ số kinh doanh thực tế từ hệ thống TechStoree.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // KPI Stats Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.6 : 1.4,
                    children: [
                      StatCard(
                        title: 'DOANH THU BÁN HÀNG',
                        value: currencyFormat.format(totalRevenue),
                        trendText: '${orders.length} đơn hoàn thành',
                        isTrendPositive: true,
                        icon: Icons.payments_rounded,
                        iconColor: AppColors.success,
                      ),
                      StatCard(
                        title: 'TỔNG CHI PHÍ NHẬP HÀNG',
                        value: currencyFormat.format(totalPoCost),
                        trendText: '${purchaseOrders.length} phiếu nhập kho',
                        isTrendPositive: true,
                        icon: Icons.inventory_rounded,
                        iconColor: AppColors.info,
                      ),
                      StatCard(
                        title: 'ĐƠN HÀNG BÁN',
                        value: '${orders.length}',
                        trendText: 'Cập nhật từ DB',
                        isTrendPositive: true,
                        icon: Icons.shopping_bag_rounded,
                        iconColor: AppColors.primary,
                      ),
                      StatCard(
                        title: 'KHUYẾN MÃI ĐANG CHẠY',
                        value: '$activePromosCount chương trình',
                        trendText: 'Tồn cảnh báo: $lowStockCount SP',
                        isTrendPositive: lowStockCount == 0,
                        icon: Icons.local_offer_rounded,
                        iconColor: AppColors.warning,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Charts Section 1: Dynamic Line Chart + Pie Chart
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 950;
                  final revenueLineChart = _buildRevenueLineChart(orders, backgroundColor, borderColor, textPrimary, textSecondary, isDark);
                  final categoryPieChart = _buildCategoryPieChart(products, backgroundColor, borderColor, textPrimary, textSecondary);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: revenueLineChart),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: categoryPieChart),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      revenueLineChart,
                      const SizedBox(height: 24),
                      categoryPieChart,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Charts Section 2: Bar Chart + Recent Orders
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 950;
                  final compareBarChart = _buildCompareBarChart(totalRevenue, totalPoCost, backgroundColor, borderColor, textPrimary, textSecondary);
                  final recentOrdersList = _buildRecentOrdersList(orders, backgroundColor, borderColor, textPrimary, textSecondary);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: compareBarChart),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: recentOrdersList),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      compareBarChart,
                      const SizedBox(height: 24),
                      recentOrdersList,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Dynamic Line Chart: Tính toán trực tiếp theo thời gian đơn hàng thực tế ---
  Widget _buildRevenueLineChart(List<Order> orders, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    final now = DateTime.now();
    final weekdayTotals = List<double>.filled(7, 0.0);

    for (var o in orders) {
      final diffDays = now.difference(o.createdAt).inDays;
      if (diffDays <= 7) {
        final weekdayIndex = (o.createdAt.weekday - 1) % 7;
        weekdayTotals[weekdayIndex] += (o.totalAmount / 1000000); // triệu VNĐ
      }
    }

    double maxRevenue = 10;
    for (var val in weekdayTotals) {
      if (val > maxRevenue) maxRevenue = val;
    }
    maxRevenue = (maxRevenue * 1.2).ceilToDouble();

    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), weekdayTotals[i]));
    }

    bool hasData = orders.isNotEmpty && weekdayTotals.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ Thống kê Doanh thu Đơn hàng (Thực tế)',
                    style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Tính tổng giá trị đơn hàng phát sinh theo ngày trong tuần', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),

              // Time Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeTab('7 ngày', 0, textPrimary),
                    _buildTimeTab('30 ngày', 1, textPrimary),
                    _buildTimeTab('6 tháng', 2, textPrimary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 280,
            child: !hasData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 48, color: textSecondary),
                        const SizedBox(height: 8),
                        Text('Chưa có dữ liệu phát sinh đơn hàng trong tuần này', style: TextStyle(color: textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxRevenue / 4).clamp(1, 100),
                        getDrawingHorizontalLine: (value) => FlLine(color: borderColor, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500);
                              switch (value.toInt()) {
                                case 0: return const Text('T2', style: style);
                                case 1: return const Text('T3', style: style);
                                case 2: return const Text('T4', style: style);
                                case 3: return const Text('T5', style: style);
                                case 4: return const Text('T6', style: style);
                                case 5: return const Text('T7', style: style);
                                case 6: return const Text('CN', style: style);
                              }
                              return const Text('', style: style);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxRevenue / 4).clamp(1, 100),
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(1)}M',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxRevenue,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${(spot.y * 1000000).toInt()} ₫',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: AppColors.primaryGradient,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String label, int index, Color textPrimary) {
    bool isSelected = _selectedTimeRange == index;
    return InkWell(
      onTap: () => setState(() => _selectedTimeRange = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- Dynamic Pie Chart: Cơ cấu sản phẩm thực tế theo danh mục ---
  Widget _buildCategoryPieChart(List<Product> products, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final categoryCounts = <String, int>{};
    for (var p in products) {
      categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];

    bool hasProducts = products.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ Sản phẩm theo Danh mục',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Tỷ trọng các nhóm hàng chính trong kho', style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          SizedBox(
            height: 200,
            child: !hasProducts
                ? const Center(child: Text('Chưa có sản phẩm trong hệ thống.'))
                : PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 45,
                      sections: categoryCounts.entries.toList().asMap().entries.map((entry) {
                        final idx = entry.key;
                        final catEntry = entry.value;
                        final isTouched = idx == _touchedPieIndex;
                        final fontSize = isTouched ? 14.0 : 12.0;
                        final radius = isTouched ? 55.0 : 45.0;
                        final color = colors[idx % colors.length];

                        return PieChartSectionData(
                          color: color,
                          value: catEntry.value.toDouble(),
                          title: '${catEntry.value}',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          if (hasProducts)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categoryCounts.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final catEntry = entry.value;
                final color = colors[idx % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${catEntry.key} (${catEntry.value})', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Dynamic Bar Chart: So sánh Nhập Hàng vs Doanh Thu Thực tế ---
  Widget _buildCompareBarChart(double revenue, double poCost, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final revenueMillions = (revenue / 1000000);
    final poCostMillions = (poCost / 1000000);
    final maxVal = (revenueMillions > poCostMillions ? revenueMillions : poCostMillions).clamp(10.0, 1000.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê Nhập Kho vs Bán Hàng',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('So sánh Tổng doanh thu bán và Chi phí nhập kho thực tế', style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(toY: poCostMillions > 0 ? poCostMillions : 0.5, color: AppColors.info, width: 26, borderRadius: BorderRadius.circular(6)),
                      BarChartRodData(toY: revenueMillions > 0 ? revenueMillions : 0.5, color: AppColors.success, width: 26, borderRadius: BorderRadius.circular(6)),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Tổng hợp tài chính hiện tại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('Chi phí nhập (${currencyFormat.format(poCost)})', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('Doanh thu bán (${currencyFormat.format(revenue)})', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Dynamic Recent Orders List ---
  Widget _buildRecentOrdersList(List<Order> orders, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng bán gần đây',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
            ],
          ),
          const SizedBox(height: 12),

          orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có đơn hàng nào trong hệ thống.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text('Khách hàng: ${order.customerName}', style: TextStyle(color: textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(order.totalAmount),
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              _buildStatusBadge(order.status),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'Completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Hoàn thành';
        break;
      case 'Processing':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        label = 'Đang xử lý';
        break;
      case 'Pending':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Chờ duyệt';
        break;
      default:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
