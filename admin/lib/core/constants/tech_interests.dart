import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tùy chọn sở thích công nghệ chuẩn hóa theo enum `TechInterestType` của Backend.
class TechInterestOption {
  final String key;
  final String displayName;
  final String description;

  const TechInterestOption({
    required this.key,
    required this.displayName,
    this.description = '',
  });

  factory TechInterestOption.fromJson(Map<String, dynamic> json) {
    return TechInterestOption(
      key: (json['key'] ?? '').toString().trim(),
      displayName: (json['displayName'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
    );
  }
}

/// Danh mục & helper chuẩn hóa khóa/nhãn hiển thị sở thích công nghệ giữa Web khách hàng và Admin.
abstract final class TechInterestCatalog {
  static const String unsetLabel = 'Chưa cập nhật';

  static final RegExp _aiWordRegex = RegExp(r'\bAI\b', caseSensitive: false);

  /// Danh sách mặc định khớp 1-1 với `TechInterestType` trên API (dùng ngay khi chưa tải xong hoặc offline).
  static const List<TechInterestOption> defaults = [
    TechInterestOption(
      key: 'GAMING',
      displayName: 'Gaming & Đồ họa',
      description: 'Laptop Gaming, Chuột/Bàn phím cơ, Màn hình tần số quét cao',
    ),
    TechInterestOption(
      key: 'OFFICE_STUDY',
      displayName: 'Văn phòng & Học tập',
      description: 'Laptop mỏng nhẹ, Chuột công thái học, Bút trình chiếu',
    ),
    TechInterestOption(
      key: 'AUDIO_STUDIO',
      displayName: 'Âm thanh & Studio',
      description: 'Tai nghe chống ồn, Loa Bluetooth, Micro thu âm',
    ),
    TechInterestOption(
      key: 'CODING_AI',
      displayName: 'Lập trình & Trí tuệ nhân tạo (AI)',
      description: 'Workstation, Màn hình kép, Thiết bị AI & Server cá nhân',
    ),
    TechInterestOption(
      key: 'SMARTWATCH_HEALTH',
      displayName: 'Đồng hồ thông minh & Sức khỏe',
      description: 'Smartwatch, Vòng đeo thông minh, Cân sức khỏe điện tử',
    ),
    TechInterestOption(
      key: 'PHOTOGRAPHY_VIDEO',
      displayName: 'Nhiếp ảnh & Quay phim',
      description: 'Camera, Gimbal, Flycam, Đèn livestream & Phụ kiện quay',
    ),
    TechInterestOption(
      key: 'SMARTHOME',
      displayName: 'Nhà thông minh (SmartHome)',
      description: 'Robot hút bụi, Loa trợ lý ảo, Camera, Đèn cảm ứng',
    ),
    TechInterestOption(
      key: 'OTHER',
      displayName: 'Nhu cầu khác',
      description: 'Các nhu cầu thiết bị công nghệ phổ thông khác',
    ),
  ];

  /// Quy đổi giá trị lưu trong DB (enum key hoặc nhãn tiếng Việt cũ) về enum key chuẩn.
  static String? tryNormalizeKey(String? raw, {List<TechInterestOption>? options}) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final lower = clean.toLowerCase();
    final source = (options != null && options.isNotEmpty) ? options : defaults;

    for (final opt in source) {
      if (opt.key.toLowerCase() == lower || opt.displayName.toLowerCase() == lower) {
        return opt.key;
      }
    }
    if (!identical(source, defaults)) {
      for (final opt in defaults) {
        if (opt.key.toLowerCase() == lower || opt.displayName.toLowerCase() == lower) {
          return opt.key;
        }
      }
    }

    // Fallback nhận diện dữ liệu tiếng Việt cũ từng được Admin lưu trực tiếp trước khi đồng bộ
    final upper = clean.toUpperCase();
    if (upper.contains('GAMING') || upper.contains('ĐỒ HỌA')) return 'GAMING';
    if (upper.contains('OFFICE') || upper.contains('VĂN PHÒNG') || upper.contains('HỌC TẬP')) {
      return 'OFFICE_STUDY';
    }
    if (upper.contains('AUDIO') || upper.contains('STUDIO') || upper.contains('ÂM THANH')) {
      return 'AUDIO_STUDIO';
    }
    if (upper.contains('CODING') ||
        upper.contains('LẬP TRÌNH') ||
        upper.contains('TRÍ TUỆ NHÂN TẠO') ||
        _aiWordRegex.hasMatch(clean)) {
      return 'CODING_AI';
    }
    if (upper.contains('SMARTWATCH') ||
        upper.contains('HEALTH') ||
        upper.contains('ĐỒNG HỒ') ||
        upper.contains('SỨC KHỎE')) {
      return 'SMARTWATCH_HEALTH';
    }
    if (upper.contains('PHOTO') ||
        upper.contains('VIDEO') ||
        upper.contains('NHIẾP ẢNH') ||
        upper.contains('QUAY PHIM')) {
      return 'PHOTOGRAPHY_VIDEO';
    }
    if (upper.contains('SMARTHOME') ||
        upper.contains('SMART HOME') ||
        upper.contains('NHÀ THÔNG MINH') ||
        upper.contains('ĐỒ GIA DỤNG')) {
      return 'SMARTHOME';
    }
    if (upper == 'OTHER' || upper.contains('NHU CẦU KHÁC')) return 'OTHER';

    return null;
  }

  /// Trả về tên tiếng Việt thân thiện để hiển thị trên bảng, badge và dialog.
  static String displayLabel(String? raw, {List<TechInterestOption>? options}) {
    if (raw == null || raw.trim().isEmpty) return unsetLabel;

    final key = tryNormalizeKey(raw, options: options);
    if (key != null) {
      if (options != null) {
        for (final opt in options) {
          if (opt.key.toUpperCase() == key.toUpperCase() && opt.displayName.isNotEmpty) {
            return opt.displayName;
          }
        }
      }
      for (final opt in defaults) {
        if (opt.key == key) return opt.displayName;
      }
    }
    return raw.trim();
  }

  /// Kiểm tra khách hàng có khớp bộ lọc dropdown (theo enum key chuẩn hoặc "Chưa cập nhật").
  static bool matchesFilter(
    String? rawValue,
    String filterKey, {
    List<TechInterestOption>? options,
  }) {
    if (filterKey == unsetLabel) {
      return rawValue == null || rawValue.trim().isEmpty;
    }
    if (rawValue == null || rawValue.trim().isEmpty) return false;

    final normalized = tryNormalizeKey(rawValue, options: options);
    if (normalized != null && normalized.toUpperCase() == filterKey.toUpperCase()) {
      return true;
    }
    return rawValue.trim().toLowerCase() == filterKey.trim().toLowerCase();
  }

  /// Màu badge đồng bộ cho cả enum key lẫn dữ liệu chữ cũ.
  static Color badgeColor(String? raw, {List<TechInterestOption>? options}) {
    switch (tryNormalizeKey(raw, options: options)) {
      case 'GAMING':
        return Colors.purple;
      case 'CODING_AI':
        return Colors.indigo;
      case 'AUDIO_STUDIO':
        return Colors.teal;
      case 'SMARTWATCH_HEALTH':
        return Colors.orange;
      case 'PHOTOGRAPHY_VIDEO':
        return Colors.pink;
      case 'SMARTHOME':
        return Colors.cyan;
      case 'OTHER':
        return Colors.blueGrey;
      default:
        return AppColors.primary;
    }
  }
}

