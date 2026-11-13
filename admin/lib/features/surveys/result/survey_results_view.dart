import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/survey.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/smooth_loading_wrapper.dart';
import '../survey_helpers.dart';
import 'survey_result_choice_chart.dart';
import 'survey_result_kpi_card.dart';
import 'survey_result_question_card.dart';

/// Màn hình báo cáo thống kê tổng quan và phân tích kết quả từng câu hỏi khảo sát.
class SurveyResultsView extends StatefulWidget {
  final int surveyId;
  final String backLabel;
  final VoidCallback onBack;

  const SurveyResultsView({
    super.key,
    required this.surveyId,
    this.backLabel = 'Danh sách khảo sát',
    required this.onBack,
  });

  @override
  State<SurveyResultsView> createState() => _SurveyResultsViewState();
}

class _SurveyResultsViewState extends State<SurveyResultsView> {
  late Future<SurveyStatistics?> _statsFuture;
  bool _hasLoadedData = false;
  Object? _reloadError;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant SurveyResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.surveyId != oldWidget.surveyId) {
      _hasLoadedData = false;
      _reloadError = null;
      _loadStats();
    }
  }

  void _loadStats() {
    _reloadError = null;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final requestFuture = apiService.getSurveyStatistics(widget.surveyId, token: token, throwOnError: true);

    late final Future<SurveyStatistics?> trackedFuture;
    trackedFuture = requestFuture.then(
      (data) {
        if (mounted && identical(_statsFuture, trackedFuture)) {
          setState(() {
            _hasLoadedData = data != null;
            _reloadError = null;
          });
        }
        return data;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted && identical(_statsFuture, trackedFuture) && _hasLoadedData) {
          setState(() => _reloadError = error);
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _statsFuture = trackedFuture;
    // Bảo vệ Zone khỏi báo lỗi unhandled nếu Future lỗi trước khi frame build kế tiếp đăng ký listener.
    trackedFuture.ignore();
  }

  Future<void> _exportCsv(int surveyId) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      await exportSurveyCsvReport(
        context: context,
        surveyId: surveyId,
        apiService: apiService,
        token: token,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return CachedFutureBuilder<SurveyStatistics?>(
      key: ValueKey(widget.surveyId),
      future: _statsFuture,
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        if (isWaiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppTokens.space16),
            child: SmoothLoadingWrapper(
              isLoading: true,
              hasData: false,
              initialMinHeight: 420,
              child: SizedBox.shrink(),
            ),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return buildSurveyFallbackView(
            headerTitle: 'Báo cáo thống kê khảo sát',
            textPrimary: textPrimary,
            onBack: widget.onBack,
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải dữ liệu thống kê',
            message: extractFriendlySurveyError(snapshot.error),
            action: AppButton(
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              onPressed: () => setState(_loadStats),
            ),
          );
        }

        final stats = snapshot.data;
        if (stats == null) {
          return buildSurveyFallbackView(
            headerTitle: 'Báo cáo thống kê khảo sát',
            textPrimary: textPrimary,
            onBack: widget.onBack,
            icon: Icons.bar_chart_rounded,
            title: 'Không tìm thấy dữ liệu thống kê',
            message: 'Bài khảo sát chưa có dữ liệu thống kê.',
            action: AppButton(
              label: 'Quay lại',
              variant: AppButtonVariant.outline,
              onPressed: widget.onBack,
            ),
          );
        }

        final activeReloadError = _reloadError ?? (snapshot.hasError ? snapshot.error : null);

        return SmoothLoadingWrapper(
          isLoading: isWaiting || _isExporting,
          hasData: true,
          blockInteraction: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeReloadError != null)
                  buildSurveyErrorBanner(
                    error: activeReloadError,
                    onRetry: () => setState(_loadStats),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),

                // Breadcrumb & Action Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final backBtn = TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        widget.backLabel,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                    final reloadBtn = AppButton(
                      label: isWaiting ? 'Đang tải...' : 'Tải lại',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: (isWaiting || _isExporting) ? null : () => setState(_loadStats),
                    );
                    final titleCrumb = Text(
                      'Báo cáo thống kê: ${stats.title}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    );

                    if (constraints.maxWidth >= 520) {
                      return Row(
                        children: [
                          backBtn,
                          const Text(' / ', style: TextStyle(color: Colors.grey)),
                          Expanded(child: titleCrumb),
                          const SizedBox(width: 12),
                          reloadBtn,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: backBtn),
                            const SizedBox(width: 8),
                            reloadBtn,
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: titleCrumb,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                PageHeader(
                  title: 'Báo cáo thống kê & phân tích kết quả khảo sát',
                  subtitle: stats.title,
                  action: AppButton(
                    label: _isExporting ? 'Đang xuất file...' : 'Xuất báo cáo (CSV)',
                    icon: Icons.download_rounded,
                    onPressed: _isExporting ? null : () => _exportCsv(stats.surveyId),
                  ),
                ),

                _buildKpiCards(stats, isDark, cardBg, borderColor, textPrimary, textSecondary),

                const SizedBox(height: 20),

                Text(
                  'Phân tích chi tiết theo câu hỏi (${stats.questions.length} câu)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                if (stats.questions.isEmpty)
                  const EmptyState(
                    icon: Icons.help_outline_rounded,
                    title: 'Khảo sát chưa tạo câu hỏi',
                    message: 'Chưa có câu hỏi nào được lưu cho bài khảo sát này.',
                  )
                else
                  ...stats.questions.map(
                    (q) => SurveyResultQuestionCard(
                      question: q,
                      totalSurveyCompleted: stats.totalCompleted,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCards(
    SurveyStatistics stats,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cards = [
          SurveyResultKpiCard(
            title: 'Đã phát khảo sát',
            value: '${stats.totalAssigned}',
            subtext: 'Khách hàng được chỉ định tham gia',
            icon: Icons.send_rounded,
            iconColor: AppColors.info,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SurveyResultKpiCard(
            title: 'Hoàn thành nộp bài',
            value: '${stats.totalCompleted}',
            subtext: stats.totalAssigned > 0
                ? 'Trên tổng ${stats.totalAssigned} lượt phát'
                : 'Chưa có lượt phát bài',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SurveyResultKpiCard(
            title: 'Tỷ lệ phản hồi',
            value: formatSurveyPercent(stats.responseRatePercent),
            subtext: 'Mức độ hoàn tất khảo sát',
            icon: Icons.pie_chart_rounded,
            iconColor: AppColors.primary,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ];

        if (maxW >= 780) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            ),
          );
        }

        final cols = maxW >= 500 ? 2 : 1;
        const spacing = 12.0;
        final itemW = (maxW - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: itemW, child: c)).toList(),
        );
      },
    );
  }
}

