import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';
import '../../../core/models/voucher.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import 'survey_editor_drafts.dart';

/// Card nhập thông tin chung, voucher phần thưởng, trạng thái mở và lịch trình khảo sát.
class SurveyEditorInfoCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final SurveyAdminDetail? existingSurvey;
  final bool hasResponses;

  final List<Voucher> availableVouchers;
  final bool isLoadingVouchers;
  final String? voucherLoadError;
  final int? selectedRewardVoucherId;
  final ValueChanged<int?> onVoucherChanged;
  final VoidCallback onRetryLoadVouchers;

  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  final DateTime? startAt;
  final ValueChanged<DateTime?> onStartAtChanged;

  final DateTime? expiredAt;
  final ValueChanged<DateTime?> onExpiredAtChanged;

  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyEditorInfoCard({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.existingSurvey,
    required this.hasResponses,
    required this.availableVouchers,
    required this.isLoadingVouchers,
    required this.voucherLoadError,
    required this.selectedRewardVoucherId,
    required this.onVoucherChanged,
    required this.onRetryLoadVouchers,
    required this.isActive,
    required this.onActiveChanged,
    required this.startAt,
    required this.onStartAtChanged,
    required this.expiredAt,
    required this.onExpiredAtChanged,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chung',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: titleCtrl,
            labelText: 'Tiêu đề khảo sát (*)',
            hintText: 'VD: Thăm dò nhu cầu tai nghe Sony WH-1000XM6...',
            validator: (val) {
              final trimmed = val?.trim() ?? '';
              if (trimmed.isEmpty) return 'Tiêu đề không được để trống!';
              if (trimmed.length > kMaxSurveyTitleLength) {
                return 'Tiêu đề không được vượt quá $kMaxSurveyTitleLength ký tự!';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: descCtrl,
            labelText: 'Mô tả khảo sát',
            hintText: 'Nhập mô tả chi tiết chương trình khảo sát thị trường...',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _buildVoucherAndActiveRow(),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildSchedulePickerRow(
            icon: Icons.event_available_outlined,
            accentColor: AppColors.info,
            title: 'Thời điểm bắt đầu mở nhận bài (Lên lịch)',
            subtitle: startAt == null
                ? 'Chưa đặt lịch mở (Khảo sát mở ngay sau khi lưu)'
                : 'Mở tự động từ: ${AppDateFormatter.formatDateTime(startAt!)}',
            hasValue: startAt != null,
            clearTooltip: 'Xóa lịch bắt đầu (Mở ngay)',
            pickLabel: startAt == null ? 'Đặt lịch mở' : 'Đổi thời gian',
            readOnlyReason: hasResponses ? 'Khảo sát đã có phản hồi, không thể đổi lịch bắt đầu' : null,
            onClear: () => onStartAtChanged(null),
            onPick: () => _handlePickStartAt(context),
          ),
          const SizedBox(height: 12),
          _buildSchedulePickerRow(
            icon: Icons.timer_outlined,
            accentColor: AppColors.warning,
            title: 'Hạn chót kết thúc nhận bài (Tự động đóng)',
            subtitle: expiredAt == null
                ? 'Chưa thiết lập hạn chót (Khảo sát chạy không thời hạn)'
                : 'Tự động đóng vào: ${AppDateFormatter.formatDateTime(expiredAt!)}',
            hasValue: expiredAt != null,
            clearTooltip: 'Hủy hẹn giờ (Chạy không thời hạn)',
            pickLabel: expiredAt == null ? 'Đặt hạn chót' : 'Đổi thời gian',
            onClear: () => onExpiredAtChanged(null),
            onPick: () => _handlePickExpiredAt(context),
          ),
          const SizedBox(height: 12),
          _buildScheduleStatusBanner(),
        ],
      ),
    );
  }

  Widget _buildVoucherAndActiveRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final existingVoucher = existingSurvey?.rewardVoucher;
        final List<Voucher> allVouchers = [...availableVouchers];
        if (existingVoucher != null &&
            !allVouchers.any((v) => v.voucherId == existingVoucher.voucherId)) {
          allVouchers.insert(0, existingVoucher);
        }
        final List<Voucher> displayVouchers = allVouchers.where((v) {
          return !isSurveyVoucherUnavailable(v) ||
              v.voucherId == selectedRewardVoucherId ||
              v.voucherId == existingSurvey?.rewardVoucherId;
        }).toList();

        final hasMissingSelectedId = selectedRewardVoucherId != null &&
            !displayVouchers.any((v) => v.voucherId == selectedRewardVoucherId);
        final voucherChangedOnResponded = hasResponses &&
            selectedRewardVoucherId != existingSurvey?.rewardVoucherId;

        final voucherSelector = isLoadingVouchers
            ? const SizedBox(
                height: 40,
                child: Center(child: LinearProgressIndicator(color: AppColors.primary)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown<int?>(
                    value: selectedRewardVoucherId,
                    labelText: 'Voucher thưởng khi hoàn thành',
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Không có phần thưởng',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                      if (hasMissingSelectedId)
                        DropdownMenuItem<int?>(
                          value: selectedRewardVoucherId,
                          child: Text(
                            '${existingSurvey?.rewardVoucherCode ?? "Voucher #$selectedRewardVoucherId"}'
                            '${existingSurvey?.rewardVoucherTitle != null ? " - ${existingSurvey!.rewardVoucherTitle}" : ""} (Đang gắn)',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ...displayVouchers.map((v) {
                        final unavailable = isSurveyVoucherUnavailable(v);
                        return DropdownMenuItem<int?>(
                          value: v.voucherId,
                          child: Text(
                            formatSurveyVoucherLabel(v),
                            style: TextStyle(
                              fontSize: 12,
                              color: unavailable ? AppColors.warning : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: onVoucherChanged,
                  ),
                  if (voucherChangedOnResponded)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Khảo sát đã có phản hồi: thay đổi voucher chỉ áp dụng cho người nộp bài sau.',
                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (voucherLoadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              voucherLoadError!,
                              style: const TextStyle(fontSize: 11, color: AppColors.warning),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: onRetryLoadVouchers,
                            child: const Text('Tải lại', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                ],
              );

        final toggleWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mở nhận phản hồi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isActive,
              activeThumbColor: AppColors.primary,
              onChanged: onActiveChanged,
            ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: voucherSelector),
              const SizedBox(width: 24),
              toggleWidget,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            voucherSelector,
            const SizedBox(height: 12),
            toggleWidget,
          ],
        );
      },
    );
  }

  Future<void> _handlePickStartAt(BuildContext context) async {
    final candidate = await _pickScheduleDateTime(
      context: context,
      currentValue: startAt,
      defaultOffset: const Duration(hours: 1),
    );
    if (candidate == null || !context.mounted) return;
    if (!candidate.isAfter(DateTime.now())) {
      AppToast.warning(
        context,
        'Thời điểm bắt đầu đặt lịch phải lớn hơn hiện tại! Nếu muốn mở ngay, hãy xóa lịch.',
      );
      return;
    }
    if (expiredAt != null && !candidate.isBefore(expiredAt!)) {
      AppToast.warning(context, 'Thời điểm bắt đầu phải nhỏ hơn hạn chót kết thúc!');
      return;
    }
    onStartAtChanged(candidate);
  }

  Future<void> _handlePickExpiredAt(BuildContext context) async {
    final candidate = await _pickScheduleDateTime(
      context: context,
      currentValue: expiredAt,
      defaultOffset: const Duration(days: 7),
    );
    if (candidate == null || !context.mounted) return;
    if (!candidate.isAfter(DateTime.now())) {
      AppToast.warning(context, 'Hạn chót phải lớn hơn thời điểm hiện tại!');
      return;
    }
    if (startAt != null && !candidate.isAfter(startAt!)) {
      AppToast.warning(context, 'Hạn chót phải lớn hơn thời điểm bắt đầu mở khảo sát!');
      return;
    }
    onExpiredAtChanged(candidate);
  }

  Future<DateTime?> _pickScheduleDateTime({
    required BuildContext context,
    required DateTime? currentValue,
    required Duration defaultOffset,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fallbackDateTime = now.add(defaultOffset);
    final rawInitial = currentValue ?? fallbackDateTime;
    final lastDate = DateTime(now.year + 3, now.month, now.day);
    var safeInitial = rawInitial.isBefore(today)
        ? DateTime(fallbackDateTime.year, fallbackDateTime.month, fallbackDateTime.day)
        : DateTime(rawInitial.year, rawInitial.month, rawInitial.day);
    if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: today,
      lastDate: lastDate,
    );
    if (pickedDate == null || !context.mounted) return null;

    final timeRef = (currentValue != null && currentValue.isAfter(now))
        ? currentValue
        : fallbackDateTime;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: timeRef.hour, minute: timeRef.minute),
    );
    if (pickedTime == null || !context.mounted) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Widget _buildSchedulePickerRow({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required bool hasValue,
    required String clearTooltip,
    required String pickLabel,
    String? readOnlyReason,
    required VoidCallback onClear,
    required VoidCallback onPick,
  }) {
    final isLocked = readOnlyReason != null;
    return Row(
      children: [
        Icon(icon, size: 18, color: hasValue ? accentColor : textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: hasValue ? accentColor : textSecondary,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (hasValue && !isLocked)
          IconButton(
            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
            tooltip: clearTooltip,
            onPressed: onClear,
          ),
        const SizedBox(width: 4),
        Tooltip(
          message: readOnlyReason ?? '',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                color: (isLocked ? Colors.grey : AppColors.primary).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: isLocked ? Colors.grey : AppColors.primary,
            ),
            label: Text(
              pickLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLocked ? Colors.grey : AppColors.primary,
              ),
            ),
            onPressed: isLocked ? null : onPick,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStatusBanner() {
    final now = DateTime.now();
    late final Color color;
    late final IconData icon;
    late final String message;

    if (expiredAt != null && !expiredAt!.isAfter(now)) {
      color = AppColors.danger;
      icon = Icons.event_busy_rounded;
      message = 'Trạng thái dự kiến: ĐÃ HẾT HẠN (Hạn chót ${AppDateFormatter.formatDateTime(expiredAt!)} đã qua).';
    } else if (!isActive) {
      color = AppColors.warning;
      icon = Icons.pause_circle_outline_rounded;
      message = startAt != null && startAt!.isAfter(now)
          ? 'Đang tắt "Mở nhận phản hồi": bài sẽ ở trạng thái TẠM DỪNG và KHÔNG tự mở vào lúc ${AppDateFormatter.formatDateTime(startAt!)} cho đến khi bạn bật lại.'
          : 'Đang tắt "Mở nhận phản hồi": khách hàng sẽ không nhìn thấy hoặc nộp bài khảo sát này.';
    } else if (startAt != null && startAt!.isAfter(now)) {
      color = AppColors.info;
      icon = Icons.schedule_rounded;
      message = 'Trạng thái dự kiến: CHỜ MỞ THEO LỊCH — có thể phát trước cho khách, hệ thống sẽ tự mở hiển thị & nộp bài từ ${AppDateFormatter.formatDateTime(startAt!)}.';
    } else {
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
      message = 'Trạng thái dự kiến: ĐANG MỞ — khách hàng được phân công có thể nhận và nộp bài ngay sau khi lưu.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

