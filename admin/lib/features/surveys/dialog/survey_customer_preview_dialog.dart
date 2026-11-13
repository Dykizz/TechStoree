import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';
import '../../../core/models/voucher.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../editor/survey_editor_drafts.dart';

/// Mở hộp thoại mô phỏng giao diện làm bài khảo sát ở phía khách hàng để Admin kiểm tra trước khi lưu.
Future<void> showSurveyCustomerPreviewDialog(
  BuildContext context, {
  required String title,
  required String description,
  Voucher? rewardVoucher,
  DateTime? startAt,
  DateTime? expiredAt,
  required List<SurveyQuestionDraft> questions,
}) async {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
  final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
  final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  final Map<int, int?> singleSelections = {};
  final Map<int, Set<int>> multiSelections = {};

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xem trước giao diện khách hàng',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 640,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: borderColor),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.trim().isNotEmpty
                                ? title.trim()
                                : '(Chưa nhập tiêu đề khảo sát)',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                          if (description.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(description.trim(), style: TextStyle(fontSize: 13, color: textSecondary)),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (rewardVoucher != null)
                                _buildPreviewChip(
                                  icon: Icons.card_giftcard_rounded,
                                  color: AppColors.success,
                                  label: 'Quà thưởng: ${formatSurveyVoucherLabel(rewardVoucher)}',
                                ),
                              if (startAt != null)
                                _buildPreviewChip(
                                  icon: Icons.event_available_outlined,
                                  color: AppColors.info,
                                  label: 'Mở từ: ${AppDateFormatter.formatDateTime(startAt)}',
                                ),
                              if (expiredAt != null)
                                _buildPreviewChip(
                                  icon: Icons.timer_outlined,
                                  color: AppColors.warning,
                                  label: 'Hạn nộp: ${AppDateFormatter.formatDateTime(expiredAt)}',
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...questions.asMap().entries.map((entry) {
                            final qIdx = entry.key;
                            final q = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${qIdx + 1}. ${q.textCtrl.text.trim().isNotEmpty ? q.textCtrl.text.trim() : "(Chưa nhập nội dung câu hỏi)"}',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                        ),
                                      ),
                                      if (q.isRequired)
                                        const Text(
                                          ' *',
                                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (q.type == SurveyQuestionType.SINGLE_CHOICE)
                                    RadioGroup<int>(
                                      groupValue: singleSelections[q.localId],
                                      onChanged: (val) => setModalState(() => singleSelections[q.localId] = val),
                                      child: Column(
                                        children: q.options.asMap().entries.map((optEntry) {
                                          final optIdx = optEntry.key;
                                          final optText = optEntry.value.textCtrl.text.trim();
                                          return RadioListTile<int>(
                                            value: optIdx,
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            activeColor: AppColors.primary,
                                            title: Text(
                                              optText.isNotEmpty ? optText : 'Đáp án ${optIdx + 1}',
                                              style: TextStyle(fontSize: 12, color: textPrimary),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  else if (q.type == SurveyQuestionType.MULTI_CHOICE)
                                    ...q.options.asMap().entries.map((optEntry) {
                                      final optIdx = optEntry.key;
                                      final optText = optEntry.value.textCtrl.text.trim();
                                      final selectedSet = multiSelections.putIfAbsent(q.localId, () => <int>{});
                                      return CheckboxListTile(
                                        value: selectedSet.contains(optIdx),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        activeColor: AppColors.primary,
                                        onChanged: (checked) {
                                          setModalState(() {
                                            if (checked == true) {
                                              selectedSet.add(optIdx);
                                            } else {
                                              selectedSet.remove(optIdx);
                                            }
                                          });
                                        },
                                        title: Text(
                                          optText.isNotEmpty ? optText : 'Đáp án ${optIdx + 1}',
                                          style: TextStyle(fontSize: 12, color: textPrimary),
                                        ),
                                      );
                                    })
                                  else
                                    TextField(
                                      maxLines: 3,
                                      style: TextStyle(fontSize: 12, color: textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Khách hàng nhập ý kiến tự luận...',
                                        hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        contentPadding: const EdgeInsets.all(10),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              AppButton(
                label: 'Đóng xem trước',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildPreviewChip({
  required IconData icon,
  required Color color,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

