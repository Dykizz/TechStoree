import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Hiển thị bộ chọn khoảng ngày tháng dạng Popup Dialog (không toàn màn hình trên Desktop)
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String helpText = 'Chọn khoảng thời gian',
  String cancelText = 'Hủy',
  String confirmText = 'Áp dụng',
  String saveText = 'Chọn',
  double maxWidth = 480,
  double maxHeight = 560,
}) {
  final now = DateTime.now();
  final effectiveFirstDate = firstDate ?? DateTime(2023);
  final effectiveLastDate = lastDate ?? DateTime(now.year + 2);

  return showDateRangePicker(
    context: context,
    firstDate: effectiveFirstDate,
    lastDate: effectiveLastDate,
    initialDateRange: initialDateRange,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    saveText: saveText,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (pickerCtx, child) {
      if (child == null) return const SizedBox.shrink();

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Bấm ra ngoài vùng hộp thoại để đóng
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(pickerCtx).pop(),
              ),
            ),
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                        ),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
