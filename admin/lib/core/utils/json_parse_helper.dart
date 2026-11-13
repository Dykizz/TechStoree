/// Tiện ích parse dữ liệu JSON dùng chung cho các model để đồng nhất
/// null-safety, ép kiểu linh hoạt và khả năng chịu lỗi.
class JsonParseHelper {
  JsonParseHelper._();

  /// Parse số nguyên từ int/num/String (kể cả chuỗi thập phân như `"10.0"`).
  static int parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    final str = val.toString();
    return int.tryParse(str) ?? double.tryParse(str)?.toInt() ?? fallback;
  }

  /// Parse số nguyên nullable từ int/num/String.
  static int? parseNullableInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    final str = val.toString();
    return int.tryParse(str) ?? double.tryParse(str)?.toInt();
  }

  /// Parse số thực từ double/num/String.
  static double parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  /// Parse số thực nullable từ double/num/String.
  static double? parseNullableDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  /// Parse bool hỗ trợ cả boolean, số (`!= 0`) và chuỗi `'true'`/`'1'`/`'false'`/`'0'`.
  static bool parseBool(dynamic val, {bool fallback = false}) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final lower = val.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  /// Parse ngày giờ bắt buộc; trả về [fallback] (mặc định `DateTime.now()`) nếu null/lỗi.
  static DateTime parseDate(
    dynamic val, {
    DateTime? fallback,
    bool toLocal = true,
  }) {
    final defaultDate = fallback ?? DateTime.now();
    if (val == null) return defaultDate;
    final parsed = DateTime.tryParse(val.toString());
    if (parsed == null) return defaultDate;
    return toLocal ? parsed.toLocal() : parsed;
  }

  /// Parse ngày giờ nullable; trả về `null` nếu thiếu hoặc sai định dạng.
  static DateTime? parseNullableDate(
    dynamic val, {
    bool toLocal = true,
  }) {
    if (val == null) return null;
    final parsed = DateTime.tryParse(val.toString());
    if (parsed == null) return null;
    return toLocal ? parsed.toLocal() : parsed;
  }

  /// Parse ngày dương lịch thuần (VD: dateOfBirth) giữ nguyên ngày/tháng/năm không dịch theo múi giờ.
  static DateTime? parseNullableDateOnly(dynamic val) {
    if (val == null) return null;
    final parsed = DateTime.tryParse(val.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Chuyển ngày dương lịch thuần sang `YYYY-MM-DDT00:00:00.000Z` để đồng bộ với client & Backend.
  static String toUtcDateOnlyIsoString(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }

  /// Parse danh sách số nguyên an toàn, bỏ qua các phần tử null hoặc không hợp lệ.
  static List<int> parseIntList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map(parseNullableInt).whereType<int>().toList();
  }

  /// Parse danh sách chuỗi an toàn; trả về danh sách rỗng nếu không phải `List`.
  static List<String> parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  /// Parse danh sách object từ JSON `List<Map>`, bỏ qua phần tử không phải `Map`.
  static List<T> parseJsonList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  /// Parse `Map<String, String>` từ JSON `Map`.
  static Map<String, String> parseStringMap(dynamic raw) {
    if (raw is! Map) return {};
    final Map<String, String> result = {};
    raw.forEach((k, v) {
      result[k.toString()] = v.toString();
    });
    return result;
  }

  /// Parse `Map<String, int>` từ JSON `Map`, tùy chọn chuẩn hóa key viết hoa.
  static Map<String, int> parseIntMap(
    dynamic raw, {
    bool uppercaseKeys = false,
  }) {
    if (raw is! Map) return {};
    final Map<String, int> result = {};
    raw.forEach((k, v) {
      final key = uppercaseKeys ? k.toString().toUpperCase() : k.toString();
      result[key] = parseInt(v);
    });
    return result;
  }
}

