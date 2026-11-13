import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';

/// Cụm nút Xem trước / Hủy / Lưu dùng chung ở đầu và chân màn hình biên soạn khảo sát.
class SurveyEditorActionButtons extends StatelessWidget {
  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onPreview;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const SurveyEditorActionButtons({
    super.key,
    required this.isEditing,
    required this.isSubmitting,
    required this.onPreview,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        AppButton(
          label: 'Xem trước',
          icon: Icons.visibility_outlined,
          variant: AppButtonVariant.outline,
          onPressed: isSubmitting ? null : onPreview,
        ),
        AppButton(
          label: 'Hủy',
          variant: AppButtonVariant.outline,
          onPressed: isSubmitting ? null : onCancel,
        ),
        AppButton(
          label: isSubmitting ? 'Đang lưu...' : (isEditing ? 'Lưu thay đổi' : 'Tạo khảo sát'),
          icon: Icons.check_rounded,
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

/// Header trên cùng của màn hình tạo/chỉnh sửa khảo sát kèm đường dẫn quay lại.
class SurveyEditorPageHeader extends StatelessWidget {
  final String backLabel;
  final bool isEditing;
  final int? surveyId;
  final bool isSubmitting;
  final VoidCallback onPreview;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyEditorPageHeader({
    super.key,
    required this.backLabel,
    required this.isEditing,
    this.surveyId,
    required this.isSubmitting,
    required this.onPreview,
    required this.onCancel,
    required this.onSubmit,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onCancel,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  backLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa bài khảo sát' : 'Tạo bài khảo sát mới',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing
                      ? 'Khảo sát #$surveyId'
                      : 'Khởi tạo thông tin và danh sách câu hỏi',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ],
            );
            final actions = SurveyEditorActionButtons(
              isEditing: isEditing,
              isSubmitting: isSubmitting,
              onPreview: onPreview,
              onCancel: onCancel,
              onSubmit: onSubmit,
            );
            if (constraints.maxWidth < 680) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Banner cảnh báo khóa cấu trúc câu hỏi khi bài khảo sát đã có người phản hồi.
class SurveyEditorRespondedNotice extends StatelessWidget {
  final Color textPrimary;

  const SurveyEditorRespondedNotice({
    super.key,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_outlined, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Khảo sát đã có phản hồi. Cấu trúc câu hỏi không thể chỉnh sửa để bảo đảm tính toàn vẹn dữ liệu.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh tác vụ cố định dưới đáy màn hình biên soạn khảo sát.
class SurveyEditorBottomBar extends StatelessWidget {
  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onPreview;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;

  const SurveyEditorBottomBar({
    super.key,
    required this.isEditing,
    required this.isSubmitting,
    required this.onPreview,
    required this.onCancel,
    required this.onSubmit,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hint = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: textPrimary.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isEditing
                      ? 'Lưu thay đổi để cập nhật thông tin khảo sát'
                      : 'Kiểm tra kỹ thông tin trước khi khởi tạo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          final actions = SurveyEditorActionButtons(
            isEditing: isEditing,
            isSubmitting: isSubmitting,
            onPreview: onPreview,
            onCancel: onCancel,
            onSubmit: onSubmit,
          );
          if (constraints.maxWidth < 680) {
            return Align(
              alignment: Alignment.centerRight,
              child: actions,
            );
          }
          return Row(
            children: [
              Expanded(child: hint),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}
