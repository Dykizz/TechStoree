import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';

/// Bảng 12 màu phân biệt rõ cho biểu đồ khảo sát (tránh trùng màu sớm khi có nhiều phương án).
const List<Color> kSurveyChartColors = [
  AppColors.primary,
  AppColors.success,
  AppColors.warning,
  AppColors.info,
  Colors.purple,
  Colors.orange,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.cyan,
  Colors.lime,
  Colors.brown,
];

/// Định dạng phần trăm gọn sạch và nhất quán giữa KPI, biểu đồ và bảng số liệu.
String formatSurveyPercent(double value) {
  final normalized = value == 0 ? 0.0 : value;
  final rounded = double.parse(normalized.toStringAsFixed(1));
  if (rounded == rounded.roundToDouble()) {
    return '${rounded.toInt()}%';
  }
  return '${rounded.toStringAsFixed(1)}%';
}

/// Hiển thị biểu đồ (tròn hoặc thanh ngang) kèm bảng số vote/tỷ lệ cho câu hỏi trắc nghiệm.
class SurveyResultChoiceChart extends StatefulWidget {
  final QuestionStatistics question;
  final int totalSurveyCompleted;
  final int totalVotes;
  final bool useBarChart;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyResultChoiceChart({
    super.key,
    required this.question,
    required this.totalSurveyCompleted,
    required this.totalVotes,
    required this.useBarChart,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<SurveyResultChoiceChart> createState() => _SurveyResultChoiceChartState();
}

class _SurveyResultChoiceChartState extends State<SurveyResultChoiceChart> {
  int? _touchedPieOrigIndex;

  @override
  void didUpdateWidget(covariant SurveyResultChoiceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.useBarChart != widget.useBarChart) {
      _touchedPieOrigIndex = null;
    } else if (_touchedPieOrigIndex != null &&
        _touchedPieOrigIndex! >= widget.question.optionStats.length) {
      _touchedPieOrigIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isMulti = q.questionType == SurveyQuestionType.MULTI_CHOICE;

    if (q.optionStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Chưa có phương án lựa chọn nào cho câu hỏi này.',
            style: TextStyle(fontSize: 12, color: widget.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    String? denominatorNote;
    if (isMulti) {
      denominatorNote = widget.useBarChart
          ? 'Câu hỏi chọn nhiều: tỷ lệ % tính trên ${q.totalAnswers} người trả lời câu này (tổng % có thể vượt quá 100%).'
          : 'Câu hỏi chọn nhiều: biểu đồ tròn thể hiện tỷ trọng lượt chọn; cột Tỷ lệ % tính theo ${q.totalAnswers} người trả lời.';
    } else if (q.totalAnswers > 0 && widget.totalSurveyCompleted > q.totalAnswers) {
      denominatorNote =
          'Tỷ lệ % tính trên ${q.totalAnswers}/${widget.totalSurveyCompleted} người trả lời câu hỏi này.';
    }

    final visualWidget = widget.useBarChart
        ? _buildHorizontalBars(q)
        : _buildPieChartWidget(q);
    final tableWidget = _buildOptionsTable(q);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (denominatorNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: isMulti ? const Color(0xFF0284C7) : widget.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    denominatorNote,
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: widget.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.useBarChart) Expanded(flex: 5, child: visualWidget) else visualWidget,
                  const SizedBox(width: 24),
                  Expanded(flex: widget.useBarChart ? 6 : 1, child: tableWidget),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.useBarChart) visualWidget else Center(child: visualWidget),
                const SizedBox(height: 16),
                tableWidget,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPieChartWidget(QuestionStatistics q) {
    if (widget.totalVotes == 0) {
      return Container(
        width: 180,
        height: 180,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.borderColor.withValues(alpha: 0.6), width: 2),
        ),
        child: Text(
          'Chưa có lượt chọn',
          style: TextStyle(fontSize: 11, color: widget.textSecondary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    final nonZeroEntries = q.optionStats.asMap().entries.where((e) => e.value.voteCount > 0).toList();

    return SizedBox(
      width: 180,
      height: 180,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              final int? nextTouchedIndex;
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                nextTouchedIndex = null;
              } else {
                final sliceIdx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                nextTouchedIndex = (sliceIdx >= 0 && sliceIdx < nonZeroEntries.length)
                    ? nonZeroEntries[sliceIdx].key
                    : null;
              }
              if (nextTouchedIndex != _touchedPieOrigIndex) {
                setState(() => _touchedPieOrigIndex = nextTouchedIndex);
              }
            },
          ),
          sectionsSpace: nonZeroEntries.length > 1 ? 2 : 0,
          centerSpaceRadius: 34,
          sections: nonZeroEntries.map((entry) {
            final origIdx = entry.key;
            final opt = entry.value;
            final color = kSurveyChartColors[origIdx % kSurveyChartColors.length];
            final isTouched = _touchedPieOrigIndex == origIdx;
            final voteShare = widget.totalVotes > 0 ? (opt.voteCount / widget.totalVotes * 100) : 0.0;
            final sliceTitle = voteShare < 5
                ? ''
                : (q.questionType == SurveyQuestionType.MULTI_CHOICE
                    ? '${opt.voteCount}'
                    : formatSurveyPercent(opt.percentage));

            return PieChartSectionData(
              color: color,
              value: opt.voteCount.toDouble(),
              title: sliceTitle,
              radius: isTouched ? 46 : 40,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHorizontalBars(QuestionStatistics q) {
    final trackColor = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.borderColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.totalVotes == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Chưa có lượt chọn cho các phương án bên dưới:',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: widget.textSecondary),
              ),
            ),
          ...q.optionStats.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final color = kSurveyChartColors[idx % kSurveyChartColors.length];
            final ratio = (opt.percentage / 100.0).clamp(0.0, 1.0);

            return Padding(
              padding: EdgeInsets.only(bottom: idx < q.optionStats.length - 1 ? 10 : 0),
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          opt.optionText,
                          style: TextStyle(fontSize: 12, color: widget.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${opt.voteCount} lượt • ${formatSurveyPercent(opt.percentage)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 8, width: double.infinity, color: trackColor),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(height: 8, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionsTable(QuestionStatistics q) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: widget.borderColor.withValues(alpha: 0.6), width: 1),
      children: [
        TableRow(
          decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'ĐÁP ÁN LỰA CHỌN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: widget.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'SỐ VOTE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: widget.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'TỶ LỆ %',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: widget.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        ...q.optionStats.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          final color = kSurveyChartColors[idx % kSurveyChartColors.length];
          final isHighlighted = _touchedPieOrigIndex == idx;

          return TableRow(
            decoration: isHighlighted
                ? BoxDecoration(color: color.withValues(alpha: widget.isDark ? 0.16 : 0.08))
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.optionText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                          color: widget.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${opt.voteCount}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  formatSurveyPercent(opt.percentage),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

