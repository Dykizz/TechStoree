import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/survey.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';

class SurveyStatisticsView extends StatefulWidget {
  final int surveyId;
  final VoidCallback onBack;

  const SurveyStatisticsView({
    super.key,
    required this.surveyId,
    required this.onBack,
  });

  @override
  State<SurveyStatisticsView> createState() => _SurveyStatisticsViewState();
}

class _SurveyStatisticsViewState extends State<SurveyStatisticsView> {
  late Future<SurveyStatistics?> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _statsFuture = apiService.getSurveyStatistics(widget.surveyId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return FutureBuilder<SurveyStatistics?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final stats = snapshot.data;
        if (stats == null) {
          return Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    Text('Báo cáo thống kê khảo sát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                  ],
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'Không tìm thấy dữ liệu thống kê',
                    message: 'Bài khảo sát chưa thể tải báo cáo kết quả hoặc chưa có dữ liệu.',
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb & Action Header
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Danh sách khảo sát', style: TextStyle(fontSize: 12)),
                  ),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      'Báo cáo thống kê: ${stats.title}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppButton(
                    label: 'Tải lại',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => setState(() => _loadStats()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              PageHeader(
                title: 'Báo Cáo Thống Kê & Phân Tích Kết Quả Khảo Sát',
                subtitle: stats.title,
              ),

              // KPI Cards Row
              Row(
                children: [
                  Expanded(child: _buildKpiCard('Đã Phát Khảo Sát', '${stats.totalAssigned}', Icons.send_rounded, AppColors.info, isDark, cardBg, borderColor, textPrimary, textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('Hoàn Thành Nộp Bài', '${stats.totalCompleted}', Icons.check_circle_rounded, AppColors.success, isDark, cardBg, borderColor, textPrimary, textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('Tỷ Lệ Phản Hồi (%)', '${stats.responseRatePercent}%', Icons.pie_chart_rounded, AppColors.primary, isDark, cardBg, borderColor, textPrimary, textSecondary)),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'PHÂN TÍCH CHI TIẾT THEO CÂU HỎI (${stats.questions.length} CÂU)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),

              if (stats.questions.isEmpty)
                const EmptyState(
                  icon: Icons.help_outline_rounded,
                  title: 'Khảo sát chưa tạo câu hỏi',
                  message: 'Chưa có câu hỏi nào được lưu cho bài khảo sát này.',
                )
              else
                ...stats.questions.map((q) => _buildQuestionStatCard(q, isDark, cardBg, borderColor, textPrimary, textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStatCard(QuestionStatistics q, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    final chartColors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Question
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  q.questionType == SurveyQuestionType.SINGLE_CHOICE ? 'TRẮC NGHIỆM' : 'TỰ LUẬN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.questionText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${q.totalAnswers} câu trả lời',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SINGLE_CHOICE Visual Chart & Data Table
          if (q.questionType == SurveyQuestionType.SINGLE_CHOICE) ...[
            if (q.totalAnswers == 0 || q.optionStats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('Chưa có đáp án nào được gửi cho câu hỏi này.', style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic)),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: q.optionStats.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final opt = entry.value;
                          final color = chartColors[idx % chartColors.length];
                          return PieChartSectionData(
                            color: color,
                            value: opt.voteCount.toDouble(),
                            title: '${opt.percentage.toStringAsFixed(0)}%',
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Option Statistics Table
                  Expanded(
                    child: Column(
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                          },
                          border: TableBorder.all(color: borderColor.withOpacity(0.6), width: 1),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              children: [
                                Padding(padding: const EdgeInsets.all(8), child: Text('ĐÁP ÁN LỰA CHỌN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textSecondary))),
                                Padding(padding: const EdgeInsets.all(8), child: Text('SỐ VOTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textSecondary), textAlign: TextAlign.center)),
                                Padding(padding: const EdgeInsets.all(8), child: Text('TỶ LỆ %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textSecondary), textAlign: TextAlign.center)),
                              ],
                            ),
                            ...q.optionStats.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final opt = entry.value;
                              final color = chartColors[idx % chartColors.length];
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(opt.optionText, style: TextStyle(fontSize: 12, color: textPrimary))),
                                      ],
                                    ),
                                  ),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('${opt.voteCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), textAlign: TextAlign.center)),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('${opt.percentage}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center)),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],

          // TEXT Answers List
          if (q.questionType == SurveyQuestionType.TEXT) ...[
            if (q.textAnswers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('Chưa có ý kiến phản hồi nào cho câu tự luận này.', style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic)),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: q.textAnswers.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withOpacity(0.5)),
                  itemBuilder: (context, idx) {
                    final item = q.textAnswers[idx];
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_circle_outlined, size: 16, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(item.customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                              const Spacer(),
                              Text(
                                '${item.submittedAt.day}/${item.submittedAt.month}/${item.submittedAt.year} ${item.submittedAt.hour}:${item.submittedAt.minute}',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.text, style: TextStyle(fontSize: 12, color: textPrimary)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

