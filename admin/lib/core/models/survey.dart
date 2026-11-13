import '../utils/json_parse_helper.dart';
import 'voucher.dart';

enum SurveyQuestionType {
  SINGLE_CHOICE,
  MULTI_CHOICE,
  TEXT,
}

extension SurveyQuestionTypeExt on SurveyQuestionType {
  String get value => name;

  String get displayName => switch (this) {
    SurveyQuestionType.SINGLE_CHOICE => 'Trắc nghiệm (1 đáp án)',
    SurveyQuestionType.MULTI_CHOICE => 'Trắc nghiệm (Nhiều đáp án)',
    SurveyQuestionType.TEXT => 'Tự luận / Ý kiến đóng góp',
  };

  bool get isChoiceBased =>
      this == SurveyQuestionType.SINGLE_CHOICE ||
      this == SurveyQuestionType.MULTI_CHOICE;

  static SurveyQuestionType fromString(String val) =>
      switch (val.trim().toUpperCase()) {
        'TEXT' => SurveyQuestionType.TEXT,
        // MULTIPLE_CHOICE / CHECKBOX / MULTI are defensive aliases; API uses MULTI_CHOICE.
        'MULTI_CHOICE' || 'MULTIPLE_CHOICE' || 'CHECKBOX' || 'MULTI' =>
          SurveyQuestionType.MULTI_CHOICE,
        _ => SurveyQuestionType.SINGLE_CHOICE,
      };
}

enum SurveyTargetType {
  ALL,
  BY_IDS,
  BY_INTEREST,
}

extension SurveyTargetTypeExt on SurveyTargetType {
  String get value => name;

  String get displayName => switch (this) {
    SurveyTargetType.ALL => 'Tất cả khách hàng (ALL)',
    SurveyTargetType.BY_IDS => 'Danh sách khách hàng chỉ định (BY_IDS)',
    SurveyTargetType.BY_INTEREST => 'Phân khúc sở thích công nghệ (BY_INTEREST)',
  };

  static SurveyTargetType fromString(String val) =>
      switch (val.trim().toUpperCase()) {
        'BY_IDS' => SurveyTargetType.BY_IDS,
        'BY_INTEREST' => SurveyTargetType.BY_INTEREST,
        _ => SurveyTargetType.ALL,
      };
}

class SurveyAdminList {
  final int surveyId;
  final String title;
  final String? description;
  final int? rewardVoucherId;
  final String? rewardVoucherCode;
  final String? rewardVoucherTitle;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? startAt;
  final DateTime? expiredAt;
  final int totalAssigned;
  final int totalCompleted;
  final double responseRatePercent;
  final bool hasResponses;
  final List<int> assignedUserIds;

  bool get isExpired => expiredAt != null && expiredAt!.isBefore(DateTime.now());
  bool get isUpcoming => !isExpired && isActive && startAt != null && startAt!.isAfter(DateTime.now());

  SurveyAdminList({
    required this.surveyId,
    required this.title,
    this.description,
    this.rewardVoucherId,
    this.rewardVoucherCode,
    this.rewardVoucherTitle,
    required this.isActive,
    required this.createdAt,
    this.startAt,
    this.expiredAt,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.responseRatePercent,
    required this.hasResponses,
    this.assignedUserIds = const [],
  });

  factory SurveyAdminList.fromJson(Map<String, dynamic> json) {
    final totalAssigned = JsonParseHelper.parseInt(json['totalAssigned']);
    final totalCompleted = JsonParseHelper.parseInt(json['totalCompleted']);

    return SurveyAdminList(
      surveyId: JsonParseHelper.parseInt(json['surveyId'] ?? json['id']),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      rewardVoucherId: JsonParseHelper.parseNullableInt(json['rewardVoucherId']),
      rewardVoucherCode: json['rewardVoucherCode']?.toString(),
      rewardVoucherTitle: json['rewardVoucherTitle']?.toString(),
      isActive: JsonParseHelper.parseBool(json['isActive'], fallback: true),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      startAt: JsonParseHelper.parseNullableDate(json['startAt']),
      expiredAt: JsonParseHelper.parseNullableDate(json['expiredAt']),
      totalAssigned: totalAssigned,
      totalCompleted: totalCompleted,
      responseRatePercent: _parseResponseRate(json, totalAssigned, totalCompleted),
      hasResponses: JsonParseHelper.parseBool(json['hasResponses']) || totalCompleted > 0,
      assignedUserIds: JsonParseHelper.parseIntList(json['assignedUserIds']),
    );
  }
}

class SurveyAdminDetail extends SurveyAdminList {
  final List<SurveyQuestionDetail> questions;
  final Voucher? rewardVoucher;

  SurveyAdminDetail({
    required super.surveyId,
    required super.title,
    super.description,
    super.rewardVoucherId,
    super.rewardVoucherCode,
    super.rewardVoucherTitle,
    required super.isActive,
    required super.createdAt,
    super.startAt,
    super.expiredAt,
    required super.totalAssigned,
    required super.totalCompleted,
    required super.responseRatePercent,
    required super.hasResponses,
    super.assignedUserIds,
    required this.questions,
    this.rewardVoucher,
  });

  factory SurveyAdminDetail.fromJson(Map<String, dynamic> json) {
    final base = SurveyAdminList.fromJson(json);
    final rawVoucher = json['rewardVoucher'];
    final Voucher? voucher = rawVoucher is Map
        ? Voucher.fromJson(
            rawVoucher is Map<String, dynamic>
                ? rawVoucher
                : Map<String, dynamic>.from(rawVoucher),
          )
        : null;

    return SurveyAdminDetail(
      surveyId: base.surveyId,
      title: base.title,
      description: base.description,
      rewardVoucherId: base.rewardVoucherId,
      rewardVoucherCode: base.rewardVoucherCode,
      rewardVoucherTitle: base.rewardVoucherTitle,
      isActive: base.isActive,
      createdAt: base.createdAt,
      startAt: base.startAt,
      expiredAt: base.expiredAt,
      totalAssigned: base.totalAssigned,
      totalCompleted: base.totalCompleted,
      responseRatePercent: base.responseRatePercent,
      hasResponses: base.hasResponses,
      assignedUserIds: base.assignedUserIds,
      questions: JsonParseHelper.parseJsonList(json['questions'], SurveyQuestionDetail.fromJson),
      rewardVoucher: voucher,
    );
  }
}

class SurveyQuestionDetail {
  final int questionId;
  final String questionText;
  final SurveyQuestionType questionType;
  final bool isRequired;
  final int orderNum;
  final int totalAnswers;
  final List<SurveyOption> options;
  final List<TextAnswer> textAnswers;

  SurveyQuestionDetail({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.isRequired,
    required this.orderNum,
    required this.totalAnswers,
    required this.options,
    required this.textAnswers,
  });

  factory SurveyQuestionDetail.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionDetail(
      questionId: JsonParseHelper.parseInt(json['questionId'] ?? json['id']),
      questionText: (json['questionText'] ?? '').toString(),
      questionType: SurveyQuestionTypeExt.fromString(
        (json['questionType'] ?? 'SINGLE_CHOICE').toString(),
      ),
      isRequired: JsonParseHelper.parseBool(json['isRequired'], fallback: true),
      orderNum: JsonParseHelper.parseInt(json['orderNum'], 1),
      totalAnswers: JsonParseHelper.parseInt(json['totalAnswers']),
      options: JsonParseHelper.parseJsonList(json['options'], SurveyOption.fromJson),
      textAnswers: JsonParseHelper.parseJsonList(json['textAnswers'], TextAnswer.fromJson),
    );
  }
}

class SurveyOption {
  final int optionId;
  final String optionText;
  final int orderNum;
  final int voteCount;
  final double percentage;

  SurveyOption({
    required this.optionId,
    required this.optionText,
    required this.orderNum,
    required this.voteCount,
    required this.percentage,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      optionId: JsonParseHelper.parseInt(json['optionId'] ?? json['id']),
      optionText: (json['optionText'] ?? '').toString(),
      orderNum: JsonParseHelper.parseInt(json['orderNum'], 1),
      voteCount: JsonParseHelper.parseInt(json['voteCount']),
      percentage: JsonParseHelper.parseDouble(json['percentage']),
    );
  }
}

class TextAnswer {
  final String text;
  final String customerName;
  final DateTime submittedAt;

  TextAnswer({
    required this.text,
    required this.customerName,
    required this.submittedAt,
  });

  factory TextAnswer.fromJson(Map<String, dynamic> json) {
    return TextAnswer(
      text: (json['text'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Khách hàng').toString(),
      submittedAt: JsonParseHelper.parseDate(json['submittedAt']),
    );
  }
}

class SurveyStatistics {
  final int surveyId;
  final String title;
  final int totalAssigned;
  final int totalCompleted;
  final double responseRatePercent;
  final List<QuestionStatistics> questions;

  SurveyStatistics({
    required this.surveyId,
    required this.title,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.responseRatePercent,
    required this.questions,
  });

  factory SurveyStatistics.fromJson(Map<String, dynamic> json) {
    final totalAssigned = JsonParseHelper.parseInt(json['totalAssigned']);
    final totalCompleted = JsonParseHelper.parseInt(json['totalCompleted']);

    return SurveyStatistics(
      surveyId: JsonParseHelper.parseInt(json['surveyId'] ?? json['id']),
      title: (json['title'] ?? '').toString(),
      totalAssigned: totalAssigned,
      totalCompleted: totalCompleted,
      responseRatePercent: _parseResponseRate(json, totalAssigned, totalCompleted),
      questions: JsonParseHelper.parseJsonList(json['questions'], QuestionStatistics.fromJson),
    );
  }
}

class QuestionStatistics {
  final int questionId;
  final String questionText;
  final SurveyQuestionType questionType;
  final int totalAnswers;
  final List<OptionStatistics> optionStats;
  final List<TextAnswer> textAnswers;

  QuestionStatistics({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.totalAnswers,
    required this.optionStats,
    required this.textAnswers,
  });

  factory QuestionStatistics.fromJson(Map<String, dynamic> json) {
    return QuestionStatistics(
      questionId: JsonParseHelper.parseInt(json['questionId'] ?? json['id']),
      questionText: (json['questionText'] ?? '').toString(),
      questionType: SurveyQuestionTypeExt.fromString(
        (json['questionType'] ?? 'SINGLE_CHOICE').toString(),
      ),
      totalAnswers: JsonParseHelper.parseInt(json['totalAnswers']),
      optionStats: JsonParseHelper.parseJsonList(json['optionStats'], OptionStatistics.fromJson),
      textAnswers: JsonParseHelper.parseJsonList(json['textAnswers'], TextAnswer.fromJson),
    );
  }
}

class OptionStatistics {
  final int optionId;
  final String optionText;
  final int voteCount;
  final double percentage;

  OptionStatistics({
    required this.optionId,
    required this.optionText,
    required this.voteCount,
    required this.percentage,
  });

  factory OptionStatistics.fromJson(Map<String, dynamic> json) {
    return OptionStatistics(
      optionId: JsonParseHelper.parseInt(json['optionId'] ?? json['id']),
      optionText: (json['optionText'] ?? '').toString(),
      voteCount: JsonParseHelper.parseInt(json['voteCount']),
      percentage: JsonParseHelper.parseDouble(json['percentage']),
    );
  }
}

class CreateSurveyRequest {
  final String title;
  final String? description;
  final int? rewardVoucherId;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? expiredAt;
  final List<CreateSurveyQuestion> questions;

  CreateSurveyRequest({
    required this.title,
    this.description,
    this.rewardVoucherId,
    this.isActive = true,
    this.startAt,
    this.expiredAt,
    required this.questions,
  });

  Map<String, dynamic> toJson() => _buildSurveyPayload(
    title: title,
    description: description,
    rewardVoucherId: rewardVoucherId,
    isActive: isActive,
    startAt: startAt,
    expiredAt: expiredAt,
    questions: questions,
  );
}

class CreateSurveyQuestion {
  final String questionText;
  final SurveyQuestionType questionType;
  final bool isRequired;
  final int orderNum;
  final List<CreateSurveyOption>? options;

  CreateSurveyQuestion({
    required this.questionText,
    required this.questionType,
    required this.isRequired,
    required this.orderNum,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'questionText': questionText,
      'questionType': questionType.value,
      'isRequired': isRequired,
      'orderNum': orderNum,
    };
    if (questionType.isChoiceBased && options != null) {
      data['options'] = options!.map((o) => o.toJson()).toList();
    }
    return data;
  }
}

class CreateSurveyOption {
  final String optionText;
  final int orderNum;

  CreateSurveyOption({
    required this.optionText,
    required this.orderNum,
  });

  Map<String, dynamic> toJson() {
    return {
      'optionText': optionText,
      'orderNum': orderNum,
    };
  }
}

class UpdateSurveyRequest {
  final String title;
  final String? description;
  final int? rewardVoucherId;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? expiredAt;
  final List<CreateSurveyQuestion>? questions;

  UpdateSurveyRequest({
    required this.title,
    this.description,
    this.rewardVoucherId,
    required this.isActive,
    this.startAt,
    this.expiredAt,
    this.questions,
  });

  Map<String, dynamic> toJson() => _buildSurveyPayload(
    title: title,
    description: description,
    rewardVoucherId: rewardVoucherId,
    isActive: isActive,
    startAt: startAt,
    expiredAt: expiredAt,
    questions: questions,
  );
}

class AssignSurveyRequest {
  final SurveyTargetType targetType;
  final List<int>? userIds;
  final String? techInterest;

  AssignSurveyRequest({
    required this.targetType,
    this.userIds,
    this.techInterest,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'targetType': targetType.value,
    };
    if (targetType == SurveyTargetType.BY_IDS && userIds != null) {
      data['userIds'] = userIds;
    }
    if (targetType == SurveyTargetType.BY_INTEREST && techInterest != null) {
      data['techInterest'] = techInterest;
    }
    return data;
  }
}

double _parseResponseRate(
  Map<String, dynamic> json,
  int totalAssigned,
  int totalCompleted,
) {
  double rate = 0.0;
  if (json['responseRatePercent'] != null) {
    rate = JsonParseHelper.parseDouble(json['responseRatePercent']);
  } else if (totalAssigned > 0) {
    rate = totalCompleted / totalAssigned * 100;
  }
  return double.parse(rate.toStringAsFixed(1));
}

Map<String, dynamic> _buildSurveyPayload({
  required String title,
  String? description,
  int? rewardVoucherId,
  required bool isActive,
  DateTime? startAt,
  DateTime? expiredAt,
  List<CreateSurveyQuestion>? questions,
}) {
  final Map<String, dynamic> data = {
    'title': title,
    'description': description,
    'rewardVoucherId': rewardVoucherId,
    'isActive': isActive,
    'startAt': startAt?.toUtc().toIso8601String(),
    'expiredAt': expiredAt?.toUtc().toIso8601String(),
  };
  if (questions != null) {
    data['questions'] = questions.map((q) => q.toJson()).toList();
  }
  return data;
}
