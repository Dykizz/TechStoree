import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import 'survey_editor_drafts.dart';

/// Card chỉnh sửa nội dung, loại câu hỏi và danh sách đáp án cho một câu hỏi khảo sát.
class SurveyEditorQuestionCard extends StatelessWidget {
  final int index;
  final int totalQuestions;
  final SurveyQuestionDraft question;
  final bool hasResponses;
  final bool isFocused;
  final bool canDrag;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<bool> onRequiredChanged;
  final ValueChanged<SurveyQuestionType> onTypeChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onAddOption;
  final void Function(int optionIndex, int delta) onMoveOption;
  final ValueChanged<int> onRemoveOption;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyEditorQuestionCard({
    super.key,
    required this.index,
    required this.totalQuestions,
    required this.question,
    required this.hasResponses,
    required this.isFocused,
    required this.canDrag,
    required this.onFocusChange,
    required this.onRequiredChanged,
    required this.onTypeChanged,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
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
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: onFocusChange,
      child: Container(
        key: question.cardKey,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused ? AppColors.primary : borderColor,
            width: isFocused ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildMainFields(),
            const SizedBox(height: 14),
            if (question.type.isChoiceBased) _buildChoiceOptionsSection(),
            if (question.type == SurveyQuestionType.TEXT) _buildTextPreviewBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (canDrag)
          ReorderableDragStartListener(
            index: index,
            child: Tooltip(
              message: 'Kéo để sắp xếp lại câu hỏi',
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_indicator_rounded, size: 18, color: textSecondary),
                ),
              ),
            ),
          ),
        Icon(Icons.quiz_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.75)),
        const SizedBox(width: 6),
        Text(
          'Câu ${index + 1}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bắt buộc',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
            ),
            const SizedBox(width: 4),
            Switch(
              value: question.isRequired,
              activeThumbColor: AppColors.primary,
              onChanged: hasResponses ? null : onRequiredChanged,
            ),
          ],
        ),
        const SizedBox(width: 4),
        if (!hasResponses)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
            tooltip: 'Tùy chọn câu hỏi',
            onSelected: (val) {
              switch (val) {
                case 'DUPLICATE':
                  onDuplicate();
                  break;
                case 'UP':
                  onMoveUp();
                  break;
                case 'DOWN':
                  onMoveDown();
                  break;
                case 'DELETE':
                  if (totalQuestions > 1) onDelete();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'DUPLICATE',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14),
                    SizedBox(width: 8),
                    Text('Nhân bản câu hỏi', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'UP',
                enabled: index > 0,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 14),
                    SizedBox(width: 8),
                    Text('Di chuyển lên', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'DOWN',
                enabled: index < totalQuestions - 1,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 14),
                    SizedBox(width: 8),
                    Text('Di chuyển xuống', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'DELETE',
                enabled: totalQuestions > 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 14,
                      color: totalQuestions > 1 ? AppColors.danger : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Xóa câu hỏi',
                      style: TextStyle(
                        fontSize: 12,
                        color: totalQuestions > 1 ? AppColors.danger : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 750;
        final textInput = AppTextField(
          controller: question.textCtrl,
          readOnly: hasResponses,
          labelText: 'Nội dung câu hỏi (*)',
          hintText: 'VD: Mức giá bạn sẵn sàng chi trả cho sản phẩm là bao nhiêu?',
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nội dung câu hỏi không được để trống!';
            }
            return null;
          },
        );

        final typeDropdown = AppDropdown<SurveyQuestionType>(
          value: question.type,
          labelText: 'Loại câu hỏi',
          items: SurveyQuestionType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: hasResponses
              ? null
              : (val) {
                  if (val != null) onTypeChanged(val);
                },
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: textInput),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: typeDropdown),
            ],
          );
        }

        return Column(
          children: [
            textInput,
            const SizedBox(height: 10),
            typeDropdown,
          ],
        );
      },
    );
  }

  Widget _buildChoiceOptionsSection() {
    final isMulti = question.type == SurveyQuestionType.MULTI_CHOICE;
    const multiBlue = Color(0xFF0284C7);
    final accent = isMulti ? multiBlue : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isMulti
                  ? 'Lựa chọn đáp án (Nhiều đáp án - Hộp kiểm Checkbox)'
                  : 'Lựa chọn đáp án (Một đáp án - Nút tròn Radio)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isMulti ? 'Cho phép chọn nhiều' : 'Chỉ chọn một',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...question.options.asMap().entries.map(
              (optEntry) => _buildOptionRow(optEntry.key, optEntry.value, isMulti),
            ),
        const SizedBox(height: 6),
        if (!hasResponses)
          TextButton.icon(
            onPressed: onAddOption,
            icon: const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
            label: const Text(
              'Thêm đáp án',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionRow(int optIdx, SurveyOptionDraft opt, bool isMulti) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 38),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Icon(
              isMulti
                  ? Icons.check_box_outline_blank_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: isMulti
                  ? const Color(0xFF0284C7)
                  : AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextField(
              controller: opt.textCtrl,
              readOnly: hasResponses,
              hintText: 'Đáp án ${optIdx + 1}',
              validator: (val) {
                if (!question.type.isChoiceBased) return null;
                final trimmed = val?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Đáp án không được để trống!';
                }
                if (trimmed.length > kMaxSurveyOptionLength) {
                  return 'Đáp án không được vượt quá $kMaxSurveyOptionLength ký tự!';
                }
                if (isDuplicateSurveyOptionText(question, optIdx, trimmed)) {
                  return 'Đáp án bị trùng nội dung với lựa chọn khác!';
                }
                return null;
              },
            ),
          ),
          if (!hasResponses) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_upward_rounded, size: 14, color: textSecondary),
                    tooltip: 'Lên',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: optIdx > 0 ? () => onMoveOption(optIdx, -1) : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_downward_rounded, size: 14, color: textSecondary),
                    tooltip: 'Xuống',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: optIdx < question.options.length - 1
                        ? () => onMoveOption(optIdx, 1)
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: question.options.length > 2 ? AppColors.danger : Colors.grey,
                    ),
                    tooltip: 'Xóa đáp án',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: question.options.length > 2 ? () => onRemoveOption(optIdx) : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextPreviewBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '[ Khách hàng sẽ điền ý kiến đóng góp dạng văn bản tự luận tại đây ]',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: textSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

