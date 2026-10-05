import 'voucher.dart';

enum SurveyQuestionType {
  SINGLE_CHOICE,
  TEXT,
}

extension SurveyQuestionTypeExt on SurveyQuestionType {
  String get value {
    switch (this) {
      case SurveyQuestionType.SINGLE_CHOICE:
        return 'SINGLE_CHOICE';
      case SurveyQuestionType.TEXT:
        return 'TEXT';
    }
  }

  String get displayName {
    switch (this) {
      case SurveyQuestionType.SINGLE_CHOICE:
        return 'Trắc nghiệm (1 đáp án)';
      case SurveyQuestionType.TEXT:
        return 'Tự luận / Ý kiến đóng góp';
    }
  }

  static SurveyQuestionType fromString(String val) {
    if (val.toUpperCase() == 'TEXT') {
      return SurveyQuestionType.TEXT;
    }
    return SurveyQuestionType.SINGLE_CHOICE;
  }
}

enum SurveyTargetType {
  ALL,
  BY_IDS,
  BY_INTEREST,
}

extension SurveyTargetTypeExt on SurveyTargetType {
  String get value {
    switch (this) {
      case SurveyTargetType.ALL:
        return 'ALL';
      case SurveyTargetType.BY_IDS:
        return 'BY_IDS';
      case SurveyTargetType.BY_INTEREST:
        return 'BY_INTEREST';
    }
  }

  String get displayName {
    switch (this) {
      case SurveyTargetType.ALL:
        return 'Tất cả khách hàng (ALL)';
      case SurveyTargetType.BY_IDS:
        return 'Danh sách khách hàng chỉ định (BY_IDS)';
      case SurveyTargetType.BY_INTEREST:
        return 'Phân khúc sở thích công nghệ (BY_INTEREST)';
    }
  }

  static SurveyTargetType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'BY_IDS':
        return SurveyTargetType.BY_IDS;
      case 'BY_INTEREST':
        return SurveyTargetType.BY_INTEREST;
      default:
        return SurveyTargetType.ALL;
    }
  }
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
  final int totalAssigned;
  final int totalCompleted;
  final double responseRatePercent;
  final bool hasResponses;

  SurveyAdminList({
    required this.surveyId,
    required this.title,
    this.description,
    this.rewardVoucherId,
    this.rewardVoucherCode,
    this.rewardVoucherTitle,
    required this.isActive,
    required this.createdAt,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.responseRatePercent,
    required this.hasResponses,
  });

  factory SurveyAdminList.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    final totalAssigned = (json['totalAssigned'] ?? 0) as int;
    final totalCompleted = (json['totalCompleted'] ?? 0) as int;
    double responseRate = 0.0;
    if (json['responseRatePercent'] != null) {
      responseRate = (json['responseRatePercent'] as num).toDouble();
    } else if (totalAssigned > 0) {
      responseRate = (totalCompleted / totalAssigned * 100);
    }

    final bool hasResp = json['hasResponses'] == true || totalCompleted > 0;

    return SurveyAdminList(
      surveyId: (json['surveyId'] ?? json['id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      rewardVoucherId: json['rewardVoucherId'] != null ? (json['rewardVoucherId'] as num).toInt() : null,
      rewardVoucherCode: json['rewardVoucherCode']?.toString(),
      rewardVoucherTitle: json['rewardVoucherTitle']?.toString(),
      isActive: (json['isActive'] ?? true) as bool,
      createdAt: parseDate(json['createdAt']),
      totalAssigned: totalAssigned,
      totalCompleted: totalCompleted,
      responseRatePercent: double.parse(responseRate.toStringAsFixed(1)),
      hasResponses: hasResp,
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
    required super.totalAssigned,
    required super.totalCompleted,
    required super.responseRatePercent,
    required super.hasResponses,
    required this.questions,
    this.rewardVoucher,
  });

  factory SurveyAdminDetail.fromJson(Map<String, dynamic> json) {
    final base = SurveyAdminList.fromJson(json);
    List<SurveyQuestionDetail> questions = [];
    if (json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((q) => SurveyQuestionDetail.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    Voucher? voucher;
    if (json['rewardVoucher'] is Map<String, dynamic>) {
      voucher = Voucher.fromJson(json['rewardVoucher'] as Map<String, dynamic>);
    }

    return SurveyAdminDetail(
      surveyId: base.surveyId,
      title: base.title,
      description: base.description,
      rewardVoucherId: base.rewardVoucherId,
      rewardVoucherCode: base.rewardVoucherCode,
      rewardVoucherTitle: base.rewardVoucherTitle,
      isActive: base.isActive,
      createdAt: base.createdAt,
      totalAssigned: base.totalAssigned,
      totalCompleted: base.totalCompleted,
      responseRatePercent: base.responseRatePercent,
      hasResponses: base.hasResponses,
      questions: questions,
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
    List<SurveyOption> options = [];
    if (json['options'] is List) {
      options = (json['options'] as List)
          .map((o) => SurveyOption.fromJson(o as Map<String, dynamic>))
          .toList();
    }

    List<TextAnswer> textAnswers = [];
    if (json['textAnswers'] is List) {
      textAnswers = (json['textAnswers'] as List)
          .map((t) => TextAnswer.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return SurveyQuestionDetail(
      questionId: (json['questionId'] ?? json['id'] ?? 0) as int,
      questionText: (json['questionText'] ?? '').toString(),
      questionType: SurveyQuestionTypeExt.fromString((json['questionType'] ?? 'SINGLE_CHOICE').toString()),
      isRequired: (json['isRequired'] ?? true) as bool,
      orderNum: (json['orderNum'] ?? 1) as int,
      totalAnswers: (json['totalAnswers'] ?? 0) as int,
      options: options,
      textAnswers: textAnswers,
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
      optionId: (json['optionId'] ?? json['id'] ?? 0) as int,
      optionText: (json['optionText'] ?? '').toString(),
      orderNum: (json['orderNum'] ?? 1) as int,
      voteCount: (json['voteCount'] ?? 0) as int,
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : 0.0,
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
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();
    }

    return TextAnswer(
      text: (json['text'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Khách hàng').toString(),
      submittedAt: parseDate(json['submittedAt']),
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
    List<QuestionStatistics> questions = [];
    if (json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((q) => QuestionStatistics.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    final totalAssigned = (json['totalAssigned'] ?? 0) as int;
    final totalCompleted = (json['totalCompleted'] ?? 0) as int;
    double responseRate = 0.0;
    if (json['responseRatePercent'] != null) {
      responseRate = (json['responseRatePercent'] as num).toDouble();
    } else if (totalAssigned > 0) {
      responseRate = (totalCompleted / totalAssigned * 100);
    }

    return SurveyStatistics(
      surveyId: (json['surveyId'] ?? json['id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      totalAssigned: totalAssigned,
      totalCompleted: totalCompleted,
      responseRatePercent: double.parse(responseRate.toStringAsFixed(1)),
      questions: questions,
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
    List<OptionStatistics> optionStats = [];
    if (json['optionStats'] is List) {
      optionStats = (json['optionStats'] as List)
          .map((o) => OptionStatistics.fromJson(o as Map<String, dynamic>))
          .toList();
    }

    List<TextAnswer> textAnswers = [];
    if (json['textAnswers'] is List) {
      textAnswers = (json['textAnswers'] as List)
          .map((t) => TextAnswer.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return QuestionStatistics(
      questionId: (json['questionId'] ?? json['id'] ?? 0) as int,
      questionText: (json['questionText'] ?? '').toString(),
      questionType: SurveyQuestionTypeExt.fromString((json['questionType'] ?? 'SINGLE_CHOICE').toString()),
      totalAnswers: (json['totalAnswers'] ?? 0) as int,
      optionStats: optionStats,
      textAnswers: textAnswers,
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
      optionId: (json['optionId'] ?? json['id'] ?? 0) as int,
      optionText: (json['optionText'] ?? '').toString(),
      voteCount: (json['voteCount'] ?? 0) as int,
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : 0.0,
    );
  }
}

class CreateSurveyRequest {
  final String title;
  final String? description;
  final int? rewardVoucherId;
  final bool isActive;
  final List<CreateSurveyQuestion> questions;

  CreateSurveyRequest({
    required this.title,
    this.description,
    this.rewardVoucherId,
    this.isActive = true,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'rewardVoucherId': rewardVoucherId,
      'isActive': isActive,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
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
    if (questionType == SurveyQuestionType.SINGLE_CHOICE && options != null) {
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
  final List<CreateSurveyQuestion>? questions;

  UpdateSurveyRequest({
    required this.title,
    this.description,
    this.rewardVoucherId,
    required this.isActive,
    this.questions,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'rewardVoucherId': rewardVoucherId,
      'isActive': isActive,
    };
    if (questions != null) {
      data['questions'] = questions!.map((q) => q.toJson()).toList();
    }
    return data;
  }
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
