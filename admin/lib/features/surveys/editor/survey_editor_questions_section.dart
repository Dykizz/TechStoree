import 'package:flutter/material.dart';
import '../../../core/models/survey.dart';
import '../../../core/widgets/app_button.dart';
import 'survey_editor_drafts.dart';
import 'survey_editor_question_card.dart';

/// Khu vực hiển thị tiêu đề mục câu hỏi, nút thêm câu hỏi và danh sách kéo-thả sắp xếp thứ tự.
class SurveyEditorQuestionsSection extends StatelessWidget {
  final List<SurveyQuestionDraft> questions;
  final bool hasResponses;
  final int? focusedQuestionIndex;
  final VoidCallback onAddQuestion;
  final void Function(int oldIndex, int newIndex) onReorderQuestions;
  final void Function(int index, bool hasFocus) onQuestionFocusChange;
  final void Function(int index, bool val) onQuestionRequiredChanged;
  final void Function(int index, SurveyQuestionType val) onQuestionTypeChanged;
  final ValueChanged<int> onDuplicateQuestion;
  final void Function(int index, int delta) onMoveQuestion;
  final ValueChanged<int> onDeleteQuestion;
  final ValueChanged<SurveyQuestionDraft> onAddOption;
  final void Function(SurveyQuestionDraft q, int optIdx, int delta) onMoveOption;
  final void Function(SurveyQuestionDraft q, int optIdx) onRemoveOption;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyEditorQuestionsSection({
    super.key,
    required this.questions,
    required this.hasResponses,
    required this.focusedQuestionIndex,
    required this.onAddQuestion,
    required this.onReorderQuestions,
    required this.onQuestionFocusChange,
    required this.onQuestionRequiredChanged,
    required this.onQuestionTypeChanged,
    required this.onDuplicateQuestion,
    required this.onMoveQuestion,
    required this.onDeleteQuestion,
    required this.onAddOption,
    required this.onMoveOption,
    required this.onRemoveOption,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final canDrag = !hasResponses && questions.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Câu hỏi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                Text(
                  '${questions.length} câu hỏi${canDrag ? " • Kéo biểu tượng ⋮⋮ để sắp xếp lại" : ""}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
            const Spacer(),
            if (!hasResponses)
              AppButton(
                label: 'Thêm câu hỏi',
                icon: Icons.add_rounded,
                variant: AppButtonVariant.outline,
                onPressed: onAddQuestion,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!canDrag)
          Column(
            children: List.generate(
              questions.length,
              (idx) => _buildQuestionCardAt(idx, canDrag: false),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: questions.length,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
            onReorderItem: onReorderQuestions,
            itemBuilder: (context, idx) => _buildQuestionCardAt(idx, canDrag: true),
          ),
      ],
    );
  }

  Widget _buildQuestionCardAt(int index, {required bool canDrag}) {
    final q = questions[index];
    return SurveyEditorQuestionCard(
      key: ValueKey('question_${q.localId}'),
      index: index,
      totalQuestions: questions.length,
      question: q,
      hasResponses: hasResponses,
      isFocused: focusedQuestionIndex == index,
      canDrag: canDrag,
      onFocusChange: (hasFocus) => onQuestionFocusChange(index, hasFocus),
      onRequiredChanged: (val) => onQuestionRequiredChanged(index, val),
      onTypeChanged: (val) => onQuestionTypeChanged(index, val),
      onDuplicate: () => onDuplicateQuestion(index),
      onMoveUp: () => onMoveQuestion(index, -1),
      onMoveDown: () => onMoveQuestion(index, 1),
      onDelete: () => onDeleteQuestion(index),
      onAddOption: () => onAddOption(q),
      onMoveOption: (optIdx, delta) => onMoveOption(q, optIdx, delta),
      onRemoveOption: (optIdx) => onRemoveOption(q, optIdx),
      isDark: isDark,
      cardBg: cardBg,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
  }
}

