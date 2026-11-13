import 'package:flutter/material.dart';
import 'app_date_formatter.dart';

/// Tiện ích xử lý các mốc thời gian chọn nhanh (Date Presets) và phân tích chuỗi tiền tệ
class DatePresetHelper {
  DatePresetHelper._();

  /// Tính toán khoảng DateTimeRange tương ứng với preset đã chọn
  static DateTimeRange? getRangeForPreset(String preset) {
    final now = DateTime.now();

    switch (preset) {
      case 'TODAY':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'YESTERDAY':
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day);
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'LAST_7_DAYS':
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'THIS_MONTH':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'ALL':
      default:
        return null;
    }
  }

  /// Danh sách mục chọn chuẩn cho Dropdown lọc theo mốc thời gian
  static List<DropdownMenuItem<String>> buildDropdownItems({
    DateTimeRange? selectedDateRange,
    String selectedDatePreset = 'ALL',
  }) {
    final customLabel = (selectedDateRange != null && selectedDatePreset == 'CUSTOM')
        ? '${AppDateFormatter.formatDate(selectedDateRange.start)} - ${AppDateFormatter.formatDate(selectedDateRange.end)}'
        : 'Tùy chọn ngày...';

    return [
      const DropdownMenuItem(value: 'ALL', child: Text('Thời gian: Tất cả')),
      const DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
      const DropdownMenuItem(value: 'YESTERDAY', child: Text('Hôm qua')),
      const DropdownMenuItem(value: 'LAST_7_DAYS', child: Text('7 ngày qua')),
      const DropdownMenuItem(value: 'THIS_MONTH', child: Text('Tháng này')),
      DropdownMenuItem(value: 'CUSTOM', child: Text(customLabel)),
    ];
  }

  /// Chuyển đổi chuỗi số tiền đã định dạng (VD: "1,000,000") thành double
  static double? parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    return clean.isNotEmpty ? double.tryParse(clean) : null;
  }
}

