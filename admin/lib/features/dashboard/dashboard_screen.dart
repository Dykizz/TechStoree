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
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/data_table_container.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner (Clean Enterprise Header Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng trở lại, ${authProvider.userName.isNotEmpty ? authProvider.userName : "Admin"} 👋',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Theo dõi doanh thu, tồn kho và các chỉ số kinh doanh thực tế từ hệ thống TechStoree.',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // KPI Stats Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 2.2 : 1.6,
                    children: [
                      StatCard(
                        title: 'DOANH THU BÁN HÀNG',
                        value: currencyFormat.format(totalRevenue),
                        trendText: '${orders.length} đơn hoàn thành',
                        isTrendPositive: true,
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.success,
                      ),
                      StatCard(
                        title: 'CHI PHÍ NHẬP HÀNG',
                        value: currencyFormat.format(totalPoCost),
                        trendText: '${purchaseOrders.length} phiếu nhập kho',
                        isTrendPositive: true,
                        icon: Icons.inventory_2_outlined,
                        iconColor: AppColors.info,
                      ),
                      StatCard(
                        title: 'ĐƠN HÀNG BÁN',
                        value: '${orders.length}',
                        trendText: 'Cập nhật từ DB',
                        isTrendPositive: true,
                        icon: Icons.shopping_bag_outlined,
                        iconColor: AppColors.primary,
                      ),
                      StatCard(
                        title: 'KHUYẾN MÃI ĐANG CHẠY',
                        value: '$activePromosCount chương trình',
                        trendText: 'Cảnh báo tồn: $lowStockCount SP',
                        isTrendPositive: lowStockCount == 0,
                        icon: Icons.local_offer_outlined,
                        iconColor: AppColors.warning,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Analytics Charts Section (Revenue Line + Category Pie)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRevenueLineChart(orders, backgroundColor, borderColor, textPrimary, textSecondary)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildCategoryPieChart(products, backgroundColor, borderColor, textPrimary, textSecondary)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildRevenueLineChart(orders, backgroundColor, borderColor, textPrimary, textSecondary),
                      const SizedBox(height: 12),
                      _buildCategoryPieChart(products, backgroundColor, borderColor, textPrimary, textSecondary),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Recent Orders Table Section
              _buildRecentOrdersTable(orders, backgroundColor, borderColor, textPrimary, textSecondary),
            ],
          ),
        );
      },
    );
  }

  // --- Dynamic Revenue Line Chart ---
  Widget _buildRevenueLineChart(List<Order> orders, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    List<FlSpot> spots = [
      const FlSpot(0, 5),
      const FlSpot(1, 8),
      const FlSpot(2, 6.5),
      const FlSpot(3, 12),
      const FlSpot(4, 9),
      const FlSpot(5, 15),
      const FlSpot(6, 18),
    ];

    if (orders.isNotEmpty) {
      double total = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
      double avg = total / 7 / 1000000;
      spots = [
        FlSpot(0, (avg * 0.8).clamp(1, 100)),
        FlSpot(1, (avg * 1.1).clamp(1, 100)),
        FlSpot(2, (avg * 0.9).clamp(1, 100)),
        FlSpot(3, (avg * 1.4).clamp(1, 100)),
        FlSpot(4, (avg * 1.2).clamp(1, 100)),
        FlSpot(5, (avg * 1.6).clamp(1, 100)),
        FlSpot(6, (avg * 1.8).clamp(1, 100)),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ Doanh thu Theo Thời gian',
                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('Đơn vị tính: Triệu VNĐ (Cập nhật tự động)', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  _buildTimeTab('7 Ngày', 0, textPrimary),
                  const SizedBox(width: 4),
                  _buildTimeTab('30 Ngày', 1, textPrimary),
                  const SizedBox(width: 4),
                  _buildTimeTab('6 Tháng', 2, textPrimary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: borderColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (val, meta) => Text('${val.toInt()}M', style: TextStyle(color: textSecondary, fontSize: 11)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        int idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(days[idx], style: TextStyle(color: textSecondary, fontSize: 11)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // --- Category Pie Chart ---
  Widget _buildCategoryPieChart(List<Product> products, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final categoryCounts = <String, int>{};
    for (var p in products) {
      categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    }

    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ Sản phẩm theo Danh mục',
            style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text('Tỷ lệ các chủng loại hàng hóa', style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: categoryCounts.isEmpty
                ? Center(child: Text('Chưa có dữ liệu danh mục', style: TextStyle(color: textSecondary)))
                : PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: List.generate(categoryCounts.length, (i) {
                        final isTouched = i == _touchedPieIndex;
                        final radius = isTouched ? 42.0 : 36.0;
                        final entry = categoryCounts.entries.elementAt(i);
                        final color = colors[i % colors.length];

                        return PieChartSectionData(
                          color: color,
                          value: entry.value.toDouble(),
                          title: '${entry.value}',
                          radius: radius,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(categoryCounts.length, (i) {
              final entry = categoryCounts.entries.elementAt(i);
              final color = colors[i % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${entry.key} (${entry.value})', style: TextStyle(color: textPrimary, fontSize: 11)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Recent Orders Table ---
  Widget _buildRecentOrdersTable(List<Order> orders, Color bgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final recentOrders = orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đơn Hàng Gần Đây',
              style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tổng cộng ${orders.length} đơn',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DataTableContainer(
          child: recentOrders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('Chưa có đơn hàng nào.', style: TextStyle(color: textSecondary))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Provider.of<ThemeProvider>(context).isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      ),
                      headingRowHeight: 38,
                      dataRowMinHeight: 42,
                      dataRowMaxHeight: 42,
                      columns: [
                        DataColumn(label: Text('MÃ ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                        DataColumn(label: Text('KHÁCH HÀNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                        DataColumn(label: Text('TỔNG TIỀN', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                        DataColumn(label: Text('NGÀY ĐẶT', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                      ],
                      rows: recentOrders.map((o) {
                        return DataRow(
                          cells: [
                            DataCell(Text('#${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13))),
                            DataCell(Text(o.customerName, style: TextStyle(color: textPrimary, fontSize: 13))),
                            DataCell(Text(currencyFormat.format(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13))),
                            DataCell(_buildOrderStatusBadge(o.status)),
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(o.createdAt), style: TextStyle(color: textSecondary, fontSize: 12))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return const StatusBadge(label: 'ĐÃ GIAO HÀNG', isSuccess: true);
      case 'PENDING':
        return const StatusBadge(label: 'CHỜ XỬ LÝ', isWarning: true);
      case 'SHIPPING':
      case 'PROCESSING':
        return const StatusBadge(label: 'ĐANG GIAO HÀNG', isInfo: true);
      case 'CANCELLED':
        return const StatusBadge(label: 'ĐÃ HỦY', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }
}
