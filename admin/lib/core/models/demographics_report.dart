import 'app_user.dart';

/// Mô hình báo cáo phân tích nhân khẩu học khách hàng
/// Bao gồm phân bố độ tuổi và phân khúc sở thích công nghệ
class DemographicsReport {
  final int totalCustomers;
  final int customersWithBirthDate;
  final int customersWithInterest;
  final List<AgeGroupReport> ageGroups;
  final List<InterestGroupReport> interests;

  DemographicsReport({
    required this.totalCustomers,
    required this.customersWithBirthDate,
    required this.customersWithInterest,
    required this.ageGroups,
    required this.interests,
  });

  factory DemographicsReport.fromJson(Map<String, dynamic> json) {
    return DemographicsReport(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      customersWithBirthDate: (json['customersWithBirthDate'] as num?)?.toInt() ?? 0,
      customersWithInterest: (json['customersWithInterest'] as num?)?.toInt() ?? 0,
      ageGroups: (json['ageGroups'] as List?)
              ?.map((e) => AgeGroupReport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List?)
              ?.map((e) => InterestGroupReport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory DemographicsReport.fromUsers(List<AppUser> users) {
    final customers = users.where((u) =>
        u.role.toUpperCase() == 'USER' &&
        (u.roles.isEmpty || u.roles.every((r) => r.toUpperCase() == 'USER'))).toList();

    final total = customers.length;
    final withDob = customers.where((u) => u.dateOfBirth != null).length;
    final withInterest = customers.where((u) => u.techInterest != null && u.techInterest!.trim().isNotEmpty).length;

    // Phân nhóm độ tuổi
    int under18 = 0;
    int age18To24 = 0;
    int age25To35 = 0;
    int over35 = 0;
    int unknownAge = 0;

    final now = DateTime.now();
    for (final c in customers) {
      if (c.dateOfBirth == null) {
        unknownAge++;
        continue;
      }
      final dob = c.dateOfBirth!;
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      if (age < 18) {
        under18++;
      } else if (age <= 24) {
        age18To24++;
      } else if (age <= 35) {
        age25To35++;
      } else {
        over35++;
      }
    }

    final ageGroups = [
      AgeGroupReport(
        groupKey: 'UNDER_18',
        groupName: 'Dưới 18 tuổi',
        count: under18,
        percentage: total > 0 ? double.parse(((under18 / total) * 100).toStringAsFixed(1)) : 0.0,
      ),
      AgeGroupReport(
        groupKey: 'AGE_18_TO_24',
        groupName: '18 - 24 tuổi',
        count: age18To24,
        percentage: total > 0 ? double.parse(((age18To24 / total) * 100).toStringAsFixed(1)) : 0.0,
      ),
      AgeGroupReport(
        groupKey: 'AGE_25_TO_35',
        groupName: '25 - 35 tuổi',
        count: age25To35,
        percentage: total > 0 ? double.parse(((age25To35 / total) * 100).toStringAsFixed(1)) : 0.0,
      ),
      AgeGroupReport(
        groupKey: 'OVER_35',
        groupName: 'Trên 35 tuổi',
        count: over35,
        percentage: total > 0 ? double.parse(((over35 / total) * 100).toStringAsFixed(1)) : 0.0,
      ),
      if (unknownAge > 0)
        AgeGroupReport(
          groupKey: 'UNKNOWN',
          groupName: 'Chưa cập nhật ngày sinh',
          count: unknownAge,
          percentage: total > 0 ? double.parse(((unknownAge / total) * 100).toStringAsFixed(1)) : 0.0,
        ),
    ];

    // Phân nhóm sở thích công nghệ chuẩn hóa từ dữ liệu thực tế
    String normalizeInterestName(String raw) {
      final upper = raw.toUpperCase();
      if (upper.contains('GAMING')) return 'Gaming & Đồ họa';
      if (upper.contains('VĂN PHÒNG') || upper.contains('OFFICE')) return 'Văn phòng & Học tập';
      if (upper.contains('CODING') || upper.contains('AI') || upper.contains('LẬP TRÌNH')) return 'Lập trình & AI';
      if (upper.contains('AUDIO') || upper.contains('ÂM THANH') || upper.contains('STUDIO')) return 'Âm thanh & Studio';
      if (upper.contains('WATCH') || upper.contains('HEALTH') || upper.contains('ĐỒNG HỒ') || upper.contains('SỨC KHỎE')) return 'Smartwatch & Sức khỏe';
      if (upper.contains('PHOTO') || upper.contains('VIDEO') || upper.contains('NHIẾP ẢNH') || upper.contains('QUAY PHIM')) return 'Nhiếp ảnh & Quay phim';
      if (upper.contains('HOME') || upper.contains('NHÀ THÔNG MINH')) return 'Nhà thông minh (SmartHome)';
      return raw.trim();
    }

    final Map<String, int> interestMap = {};
    int notSetCount = 0;

    for (final c in customers) {
      final rawInterest = c.techInterest?.trim();
      if (rawInterest == null || rawInterest.isEmpty) {
        notSetCount++;
      } else {
        final normalized = normalizeInterestName(rawInterest);
        interestMap[normalized] = (interestMap[normalized] ?? 0) + 1;
      }
    }

    final interests = interestMap.entries.map((entry) {
      return InterestGroupReport(
        key: entry.key,
        name: entry.key,
        count: entry.value,
        percentage: total > 0 ? double.parse(((entry.value / total) * 100).toStringAsFixed(1)) : 0.0,
      );
    }).toList();

    interests.sort((a, b) => b.count.compareTo(a.count));

    if (notSetCount > 0) {
      interests.add(InterestGroupReport(
        key: 'NOT_SET',
        name: 'Chưa cập nhật sở thích',
        count: notSetCount,
        percentage: total > 0 ? double.parse(((notSetCount / total) * 100).toStringAsFixed(1)) : 0.0,
      ));
    }

    return DemographicsReport(
      totalCustomers: total,
      customersWithBirthDate: withDob,
      customersWithInterest: withInterest,
      ageGroups: ageGroups,
      interests: interests,
    );
  }
}

class AgeGroupReport {
  final String groupKey;
  final String groupName;
  final int count;
  final double percentage;

  AgeGroupReport({
    required this.groupKey,
    required this.groupName,
    required this.count,
    required this.percentage,
  });

  factory AgeGroupReport.fromJson(Map<String, dynamic> json) {
    return AgeGroupReport(
      groupKey: json['groupKey']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InterestGroupReport {
  final String key;
  final String name;
  final int count;
  final double percentage;

  InterestGroupReport({
    required this.key,
    required this.name,
    required this.count,
    required this.percentage,
  });

  factory InterestGroupReport.fromJson(Map<String, dynamic> json) {
    return InterestGroupReport(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
