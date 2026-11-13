import 'package:intl/intl.dart';

/// Chuẩn hóa định dạng hiển thị ngày/giờ theo giờ địa phương và chuyển đổi khoảng lọc sang UTC cho API.
class AppDateFormatter {
  AppDateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static DateTime _asLocal(DateTime value) => value.isUtc ? value.toLocal() : value;

  /// Định dạng ngày chuẩn `dd/MM/yyyy` theo giờ địa phương.
  static String formatDate(DateTime value) => _dateFormat.format(_asLocal(value));

  /// Định dạng giờ chuẩn `HH:mm` theo giờ địa phương.
  static String formatTime(DateTime value) => _timeFormat.format(_asLocal(value));

  /// Định dạng ngày giờ chuẩn `dd/MM/yyyy HH:mm` theo giờ địa phương.
  static String formatDateTime(DateTime value) => _dateTimeFormat.format(_asLocal(value));

  /// Quy đổi ngày bắt đầu bộ lọc (00:00:00.000 giờ địa phương) sang chuỗi ISO UTC (`...Z`).
  static String toApiRangeStartUtcIso(DateTime date) {
    final local = _asLocal(date);
    return DateTime(local.year, local.month, local.day, 0, 0, 0, 0)
        .toUtc()
        .toIso8601String();
  }

  /// Quy đổi ngày kết thúc bộ lọc (23:59:59.999 giờ địa phương) sang chuỗi ISO UTC (`...Z`).
  static String toApiRangeEndUtcIso(DateTime date) {
    final local = _asLocal(date);
    return DateTime(local.year, local.month, local.day, 23, 59, 59, 999)
        .toUtc()
        .toIso8601String();
  }
}

