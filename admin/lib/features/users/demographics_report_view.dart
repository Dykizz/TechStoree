import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/demographics_report.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';

/// Màn hình Báo Cáo Phân Tích Nhân Khẩu Học & Sở Thích Công Nghệ Khách Hàng (CRM)
/// 100% dữ liệu động từ backend:
/// 1. KPI tổng quan (Tổng KH, Tỷ lệ cập nhật ngày sinh, Tỷ lệ cập nhật sở thích, Nhóm tuổi chủ lực)
/// 2. Phân bố độ tuổi khách hàng (< 18, 18-24, 25-35, > 35, Chưa rõ) qua Bar Chart / Pie Chart
/// 3. Phân khúc sở thích công nghệ qua Donut Chart và danh sách xếp hạng thị phần
class DemographicsReportView extends StatefulWidget {
  final VoidCallback? onBack;
  final bool showBackHeader;

  const DemographicsReportView({
    super.key,
    this.onBack,
    this.showBackHeader = false,
  });

  @override
  State<DemographicsReportView> createState() => _DemographicsReportViewState();
}

class _DemographicsReportViewState extends State<DemographicsReportView> {
  late Future<DemographicsReport> _reportFuture;
  int _touchedAgeIndex = -1;
  int _touchedInterestIndex = -1;
  bool _useBarChartForAge = true;

  // Bảng màu trực quan hiện đại cho các phân khúc
  static const List<Color> _palette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF0D9488), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFF97316), // Orange
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    setState(() {
      _reportFuture = apiService.getDemographicsReport(token: token);
    });
  }

  Color _getColorForIndex(int index) => _palette[index % _palette.length];

  IconData _getInterestIcon(String key) {
    final upper = key.toUpperCase();
    if (upper.contains('GAMING')) return Icons.sports_esports_rounded;
    if (upper.contains('OFFICE') || upper.contains('VĂN PHÒNG')) return Icons.laptop_chromebook_rounded;
    if (upper.contains('CODING') || upper.contains('AI') || upper.contains('LẬP TRÌNH')) return Icons.terminal_rounded;
    if (upper.contains('AUDIO') || upper.contains('ÂM THANH')) return Icons.headphones_rounded;
    if (upper.contains('WATCH') || upper.contains('ĐỒNG HỒ') || upper.contains('HEALTH')) return Icons.watch_rounded;
    if (upper.contains('PHOTO') || upper.contains('VIDEO') || upper.contains('NHIẾP ẢNH')) return Icons.camera_alt_rounded;
    if (upper.contains('HOME') || upper.contains('NHÀ THÔNG MINH')) return Icons.home_mini_rounded;
    return Icons.devices_other_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<DemographicsReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Không thể tải báo cáo nhân khẩu học',
              message: 'Đã xảy ra sự cố khi tải dữ liệu. Vui lòng thử lại.',
              action: AppButton(
                label: 'Tải lại dữ liệu',
                icon: Icons.refresh_rounded,
                onPressed: _loadReport,
              ),
            ),
          );
        }

        final report = snapshot.data!;
        if (report.totalCustomers == 0) {
          return Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Chưa có dữ liệu khách hàng',
              message: 'Hệ thống chưa ghi nhận thông tin khách hàng nào để tạo báo cáo nhân khẩu học.',
              action: AppButton(
                label: 'Tải lại',
                icon: Icons.refresh_rounded,
                onPressed: _loadReport,
              ),
            ),
          );
        }

        final dobRate = report.totalCustomers > 0
            ? (report.customersWithBirthDate / report.totalCustomers * 100).toStringAsFixed(1)
            : '0.0';
        final interestRate = report.totalCustomers > 0
            ? (report.customersWithInterest / report.totalCustomers * 100).toStringAsFixed(1)
            : '0.0';

        // Tìm nhóm tuổi chủ lực thực tế (không lấy nhóm chưa cập nhật)
        final validAges = report.ageGroups.where((g) => g.groupKey != 'UNKNOWN' && g.count > 0).toList();
        validAges.sort((a, b) => b.count.compareTo(a.count));
        final topAge = validAges.isNotEmpty ? validAges.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header nếu mở dạng subview
              if (widget.showBackHeader && widget.onBack != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: widget.onBack,
                        tooltip: 'Quay lại',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quay lại danh sách khách hàng',
                        style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // Page Title & Action Bar
              PageHeader(
                title: 'Báo Cáo Phân Tích Nhân Khẩu Học & Thị Hiếu',
                subtitle: 'Thống kê phân bố độ tuổi và phân khúc sở thích thiết bị công nghệ của khách hàng CRM',
                action: Row(
                  children: [
                    AppButton(
                      label: 'Làm mới dữ liệu',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: _loadReport,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTokens.space16),

              // 1. KPI Metric Summary Cards (Dữ liệu động 100%)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final isMedium = constraints.maxWidth > 600;
                  final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 2.4 : 2.8,
                    children: [
                      _buildMetricCard(
                        title: 'Tổng khách hàng',
                        value: '${report.totalCustomers}',
                        subtext: 'Khách hàng có tài khoản hệ thống',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF2563EB),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildMetricCard(
                        title: 'Độ phủ ngày sinh',
                        value: '$dobRate%',
                        subtext: '${report.customersWithBirthDate}/${report.totalCustomers} khách hàng đã điền',
                        icon: Icons.cake_rounded,
                        color: const Color(0xFF10B981),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildMetricCard(
                        title: 'Độ phủ sở thích',
                        value: '$interestRate%',
                        subtext: '${report.customersWithInterest}/${report.totalCustomers} khách hàng đã chọn',
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF8B5CF6),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildMetricCard(
                        title: 'Nhóm tuổi chủ lực',
                        value: topAge != null ? topAge.groupName : 'N/A',
                        subtext: topAge != null ? '${topAge.count} KH (${topAge.percentage}%)' : '',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFFF59E0B),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppTokens.space24),

              // 2. PHẦN 1: PHÂN BỐ ĐỘ TUỔI KHÁCH HÀNG (Dữ liệu động 100%)
              Container(
                padding: const EdgeInsets.all(AppTokens.space20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1. Phân Bố Độ Tuổi Khách Hàng (Age Demographics)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thống kê số lượng và tỷ lệ % phân tầng độ tuổi của khách hàng',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Switch xem Cột hoặc Tròn
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              _buildChartTypeTab(
                                label: 'Cột',
                                icon: Icons.bar_chart_rounded,
                                isSelected: _useBarChartForAge,
                                isDark: isDark,
                                onTap: () => setState(() => _useBarChartForAge = true),
                              ),
                              _buildChartTypeTab(
                                label: 'Tròn',
                                icon: Icons.pie_chart_rounded,
                                isSelected: !_useBarChartForAge,
                                isDark: isDark,
                                onTap: () => setState(() => _useBarChartForAge = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTokens.space20),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 850;

                        final chartWidget = _useBarChartForAge
                            ? _buildAgeBarChart(report.ageGroups, isDark, textSecondary)
                            : _buildAgePieChart(report.ageGroups, isDark, textPrimary, textSecondary);

                        final detailWidget = _buildAgeDetailsList(report.ageGroups, isDark, textPrimary, textSecondary, borderColor);

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: chartWidget),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: detailWidget),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              chartWidget,
                              const SizedBox(height: 20),
                              detailWidget,
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTokens.space24),

              // 3. PHẦN 2: PHÂN KHÚC SỞ THÍCH CÔNG NGHỆ (Dữ liệu động 100%)
              Container(
                padding: const EdgeInsets.all(AppTokens.space20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.devices_rounded, color: Color(0xFF8B5CF6), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2. Phân Khúc Sở Thích Công Nghệ (Tech Preferences)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Thị phần các danh mục sản phẩm công nghệ theo thị hiếu khách hàng',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTokens.space20),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 850;

                        final pieWidget = _buildInterestsPieChart(report.interests, isDark, textPrimary, textSecondary);
                        final listWidget = _buildInterestsList(report.interests, isDark, textPrimary, textSecondary, borderColor);

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: pieWidget),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: listWidget),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              pieWidget,
                              const SizedBox(height: 20),
                              listWidget,
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SUB WIDGETS ---

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtext.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: TextStyle(fontSize: 10, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BIỂU ĐỒ ĐỘ TUỔI ---

  Widget _buildAgeBarChart(List<AgeGroupReport> ageGroups, bool isDark, Color textSecondary) {
    if (ageGroups.isEmpty) {
      return const SizedBox(height: 260, child: Center(child: Text('Chưa có dữ liệu độ tuổi')));
    }

    final maxCount = ageGroups.map((g) => g.count).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxCount == 0 ? 5.0 : (maxCount * 1.25).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biểu đồ số lượng khách hàng theo nhóm tuổi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = ageGroups[groupIndex];
                    return BarTooltipItem(
                      '${item.groupName}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [
                        TextSpan(
                          text: '${item.count} khách hàng (${item.percentage}%)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.normal),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, meta) {
                      if (val == meta.max || val == 0) return const SizedBox();
                      return Text(
                        val.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= ageGroups.length) return const SizedBox();
                      final shortName = _shortenAgeLabel(ageGroups[idx].groupName);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          shortName,
                          style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).clamp(1.0, 100.0),
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  strokeWidth: 1,
                ),
              ),
              barGroups: ageGroups.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final color = _getColorForIndex(idx);

                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: item.count.toDouble(),
                      color: color,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: color.withOpacity(0.08),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _shortenAgeLabel(String name) {
    if (name.contains('< 18') || name.contains('Dưới 18')) return '< 18';
    if (name.contains('18 - 24')) return '18 - 24';
    if (name.contains('25 - 35')) return '25 - 35';
    if (name.contains('> 35') || name.contains('Trên 35')) return '> 35';
    if (name.contains('Chưa')) return 'Chưa rõ';
    return name;
  }

  Widget _buildAgePieChart(List<AgeGroupReport> ageGroups, bool isDark, Color textPrimary, Color textSecondary) {
    final validGroups = ageGroups.where((g) => g.count > 0).toList();
    if (validGroups.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: Text('Chưa có dữ liệu độ tuổi')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biểu đồ tròn tỷ lệ phần trăm phân bố độ tuổi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedAgeIndex = -1;
                            return;
                          }
                          _touchedAgeIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: validGroups.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final g = entry.value;
                      final isTouched = idx == _touchedAgeIndex;
                      final color = _getColorForIndex(idx);

                      return PieChartSectionData(
                        color: color,
                        value: g.count.toDouble(),
                        title: '${g.percentage.toStringAsFixed(0)}%',
                        radius: isTouched ? 50 : 42,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: validGroups.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final g = entry.value;
                    final color = _getColorForIndex(idx);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              g.groupName,
                              style: TextStyle(fontSize: 11, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${g.count} (${g.percentage}%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeDetailsList(List<AgeGroupReport> ageGroups, bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    final activeGroups = ageGroups.where((g) => g.count > 0).toList();
    if (activeGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Chưa có dữ liệu độ tuổi khách hàng', style: TextStyle(fontSize: 12, color: textSecondary))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết phân bố các nhóm độ tuổi thực tế',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 10),
        ...activeGroups.asMap().entries.map((entry) {
          final idx = entry.key;
          final g = entry.value;
          final color = _getColorForIndex(idx);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        g.groupName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ),
                    Text(
                      '${g.count} khách hàng',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${g.percentage}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (g.percentage / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- BIỂU ĐỒ SỞ THÍCH CÔNG NGHỆ ---

  Widget _buildInterestsPieChart(List<InterestGroupReport> interests, bool isDark, Color textPrimary, Color textSecondary) {
    final valid = interests.where((i) => i.count > 0).toList();
    if (valid.isEmpty) {
      return const SizedBox(height: 260, child: Center(child: Text('Chưa có dữ liệu sở thích')));
    }

    final totalCount = valid.fold<int>(0, (a, b) => a + b.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thị phần các danh mục công nghệ ưa chuộng',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedInterestIndex = -1;
                          return;
                        }
                        _touchedInterestIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: valid.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isTouched = idx == _touchedInterestIndex;
                    final color = _getColorForIndex(idx);

                    return PieChartSectionData(
                      color: color,
                      value: item.count.toDouble(),
                      title: isTouched ? '${item.percentage}%' : '',
                      radius: isTouched ? 45 : 36,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Nhãn trung tâm Donut
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _touchedInterestIndex >= 0 && _touchedInterestIndex < valid.length
                        ? '${valid[_touchedInterestIndex].count}'
                        : '$totalCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _touchedInterestIndex >= 0 && _touchedInterestIndex < valid.length
                          ? _getColorForIndex(_touchedInterestIndex)
                          : textPrimary,
                    ),
                  ),
                  Text(
                    _touchedInterestIndex >= 0 && _touchedInterestIndex < valid.length
                        ? valid[_touchedInterestIndex].name
                        : 'Lượt lựa chọn',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsList(List<InterestGroupReport> interests, bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    final activeInterests = interests.where((i) => i.count > 0).toList();
    if (activeInterests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Chưa có dữ liệu sở thích công nghệ', style: TextStyle(fontSize: 12, color: textSecondary))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xếp hạng phân khúc sở thích theo số lượng khách hàng thực tế',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 10),
        ...activeInterests.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final color = _getColorForIndex(idx);
          final icon = _getInterestIcon(item.key);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ),
                    Text(
                      '${item.count} KH',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.percentage}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (item.percentage / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
