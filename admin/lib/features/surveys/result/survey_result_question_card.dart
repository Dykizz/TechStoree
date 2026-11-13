import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';
import 'survey_result_choice_chart.dart';
import 'survey_result_text_answers_panel.dart';

/// Thẻ hiển thị kết quả phân tích chi tiết của một câu hỏi trong báo cáo khảo sát.
class SurveyResultQuestionCard extends StatefulWidget {
  final QuestionStatistics question;
  final int totalSurveyCompleted;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyResultQuestionCard({
    super.key,
    required this.question,
    required this.totalSurveyCompleted,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<SurveyResultQuestionCard> createState() => _SurveyResultQuestionCardState();
}

class _SurveyResultQuestionCardState extends State<SurveyResultQuestionCard> {
  late bool _useBarChart;

  @override
  void initState() {
    super.initState();
    _useBarChart = widget.question.questionType == SurveyQuestionType.MULTI_CHOICE;
  }

  @override
  void didUpdateWidget(covariant SurveyResultQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.question.questionType != widget.question.questionType) {
      _useBarChart = widget.question.questionType == SurveyQuestionType.MULTI_CHOICE;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final totalVotes = q.optionStats.fold<int>(0, (sum, o) => sum + o.voteCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(q, totalVotes),
          const SizedBox(height: 14),
          if (q.questionType.isChoiceBased)
            SurveyResultChoiceChart(
              question: q,
              totalSurveyCompleted: widget.totalSurveyCompleted,
              totalVotes: totalVotes,
              useBarChart: _useBarChart,
              isDark: widget.isDark,
              borderColor: widget.borderColor,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
            ),
          if (q.questionType == SurveyQuestionType.TEXT)
            SurveyResultTextAnswersPanel(
              questionId: q.questionId,
              textAnswers: q.textAnswers,
              isDark: widget.isDark,
              borderColor: widget.borderColor,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(QuestionStatistics q, int totalVotes) {
    final isMulti = q.questionType == SurveyQuestionType.MULTI_CHOICE;
    final typeLabel = switch (q.questionType) {
      SurveyQuestionType.SINGLE_CHOICE => 'TRẮC NGHIỆM (1 ĐÁP ÁN)',
      SurveyQuestionType.MULTI_CHOICE => 'TRẮC NGHIỆM NHIỀU ĐÁP ÁN',
      SurveyQuestionType.TEXT => 'TỰ LUẬN',
    };
    final countLabel = switch (q.questionType) {
      SurveyQuestionType.TEXT => '${q.textAnswers.length} phản hồi',
      SurveyQuestionType.MULTI_CHOICE => '${q.totalAnswers} người ($totalVotes lượt chọn)',
      SurveyQuestionType.SINGLE_CHOICE => '${q.totalAnswers} người trả lời',
    };

    final showToggle = q.questionType.isChoiceBased && q.optionStats.isNotEmpty;
    final typeChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        typeLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isMulti ? const Color(0xFF0284C7) : widget.textSecondary,
        ),
      ),
    );
    final countBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        countLabel,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
    final titleText = Text(
      q.questionText,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.textPrimary),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              typeChip,
              const SizedBox(width: 8),
              Expanded(child: titleText),
              const SizedBox(width: 8),
              countBadge,
              if (showToggle) ...[
                const SizedBox(width: 8),
                _buildChartModeToggle(),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                typeChip,
                countBadge,
                if (showToggle) _buildChartModeToggle(),
              ],
            ),
            const SizedBox(height: 8),
            titleText,
          ],
        );
      },
    );
  }

  Widget _buildChartModeToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartTab(
            label: 'Tròn',
            icon: Icons.pie_chart_rounded,
            isSelected: !_useBarChart,
            onTap: () => setState(() => _useBarChart = false),
          ),
          _buildChartTab(
            label: 'Cột',
            icon: Icons.bar_chart_rounded,
            isSelected: _useBarChart,
            onTap: () => setState(() => _useBarChart = true),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : widget.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : widget.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

