import 'package:flutter_test/flutter_test.dart';
import 'package:techstore_admin/core/models/survey.dart';

void main() {
  group('SurveyQuestionType MULTI_CHOICE Enum Tests', () {
    test('MULTI_CHOICE enum values and properties are correct', () {
      const type = SurveyQuestionType.MULTI_CHOICE;
      expect(type.value, equals('MULTI_CHOICE'));
      expect(type.displayName, contains('Nhiều đáp án'));
      expect(type.isChoiceBased, isTrue);

      const singleType = SurveyQuestionType.SINGLE_CHOICE;
      expect(singleType.value, equals('SINGLE_CHOICE'));
      expect(singleType.displayName, contains('1 đáp án'));
      expect(singleType.isChoiceBased, isTrue);

      const textType = SurveyQuestionType.TEXT;
      expect(textType.value, equals('TEXT'));
      expect(textType.isChoiceBased, isFalse);
    });

    test('SurveyQuestionTypeExt.fromString correctly parses multi-choice variants', () {
      expect(SurveyQuestionTypeExt.fromString('MULTI_CHOICE'), equals(SurveyQuestionType.MULTI_CHOICE));
      expect(SurveyQuestionTypeExt.fromString('MULTIPLE_CHOICE'), equals(SurveyQuestionType.MULTI_CHOICE));
      expect(SurveyQuestionTypeExt.fromString('CHECKBOX'), equals(SurveyQuestionType.MULTI_CHOICE));
      expect(SurveyQuestionTypeExt.fromString('multi_choice'), equals(SurveyQuestionType.MULTI_CHOICE));
      expect(SurveyQuestionTypeExt.fromString('TEXT'), equals(SurveyQuestionType.TEXT));
      expect(SurveyQuestionTypeExt.fromString('SINGLE_CHOICE'), equals(SurveyQuestionType.SINGLE_CHOICE));
      expect(SurveyQuestionTypeExt.fromString('UNKNOWN'), equals(SurveyQuestionType.SINGLE_CHOICE));
    });
  });

  group('CreateSurveyQuestion with MULTI_CHOICE serialization', () {
    test('CreateSurveyQuestion serializes options when type is MULTI_CHOICE', () {
      final question = CreateSurveyQuestion(
        questionText: 'Bạn đang quan tâm đến những dòng phụ kiện nào?',
        questionType: SurveyQuestionType.MULTI_CHOICE,
        isRequired: true,
        orderNum: 1,
        options: [
          CreateSurveyOption(optionText: 'Bàn phím cơ', orderNum: 1),
          CreateSurveyOption(optionText: 'Chuột không dây', orderNum: 2),
          CreateSurveyOption(optionText: 'Tai nghe chống ồn', orderNum: 3),
        ],
      );

      final json = question.toJson();
      expect(json['questionText'], equals('Bạn đang quan tâm đến những dòng phụ kiện nào?'));
      expect(json['questionType'], equals('MULTI_CHOICE'));
      expect(json['isRequired'], isTrue);
      expect(json['orderNum'], equals(1));
      expect(json['options'], isNotNull);

      final optionsList = json['options'] as List;
      expect(optionsList.length, equals(3));
      expect(optionsList[0]['optionText'], equals('Bàn phím cơ'));
      expect(optionsList[1]['optionText'], equals('Chuột không dây'));
      expect(optionsList[2]['optionText'], equals('Tai nghe chống ồn'));
    });

    test('CreateSurveyQuestion does not serialize options for TEXT question', () {
      final textQuestion = CreateSurveyQuestion(
        questionText: 'Góp ý thêm cho dịch vụ của chúng tôi',
        questionType: SurveyQuestionType.TEXT,
        isRequired: false,
        orderNum: 2,
        options: [
          CreateSurveyOption(optionText: 'Không liên quan', orderNum: 1),
        ],
      );

      final json = textQuestion.toJson();
      expect(json['questionType'], equals('TEXT'));
      expect(json['options'], isNull);
    });

    test('CreateSurveyRequest embeds MULTI_CHOICE questions correctly', () {
      final req = CreateSurveyRequest(
        title: 'Khảo sát nhu cầu thiết bị công nghệ 2026',
        description: 'Thu thập ý kiến khách hàng về hệ sinh thái sản phẩm mới',
        rewardVoucherId: 2,
        isActive: true,
        questions: [
          CreateSurveyQuestion(
            questionText: 'Thiết bị nào bạn thường dùng hàng ngày?',
            questionType: SurveyQuestionType.MULTI_CHOICE,
            isRequired: true,
            orderNum: 1,
            options: [
              CreateSurveyOption(optionText: 'Laptop', orderNum: 1),
              CreateSurveyOption(optionText: 'Smartphone', orderNum: 2),
              CreateSurveyOption(optionText: 'Tablet', orderNum: 3),
            ],
          ),
        ],
      );

      final json = req.toJson();
      expect(json['title'], equals('Khảo sát nhu cầu thiết bị công nghệ 2026'));
      expect(json['questions'], isList);
      final questionsList = json['questions'] as List;
      expect(questionsList.length, equals(1));
      expect(questionsList[0]['questionType'], equals('MULTI_CHOICE'));
      expect(questionsList[0]['options'], isList);
      expect((questionsList[0]['options'] as List).length, equals(3));
    });
  });

  group('SurveyQuestionDetail and QuestionStatistics MULTI_CHOICE Deserialization', () {
    test('SurveyQuestionDetail parses MULTI_CHOICE type and options', () {
      final json = {
        'questionId': 101,
        'questionText': 'Các tính năng bạn mong muốn được nâng cấp?',
        'questionType': 'MULTI_CHOICE',
        'isRequired': true,
        'orderNum': 1,
        'totalAnswers': 15,
        'options': [
          {'optionId': 1, 'optionText': 'Sạc nhanh 100W', 'orderNum': 1, 'voteCount': 10, 'percentage': 66.7},
          {'optionId': 2, 'optionText': 'Pin dung lượng 6000mAh', 'orderNum': 2, 'voteCount': 8, 'percentage': 53.3},
        ],
      };

      final detail = SurveyQuestionDetail.fromJson(json);
      expect(detail.questionId, equals(101));
      expect(detail.questionType, equals(SurveyQuestionType.MULTI_CHOICE));
      expect(detail.options.length, equals(2));
      expect(detail.options[0].optionText, equals('Sạc nhanh 100W'));
      expect(detail.options[0].voteCount, equals(10));
    });

    test('QuestionStatistics parses MULTI_CHOICE stats', () {
      final json = {
        'questionId': 202,
        'questionText': 'Bạn đã từng mua sản phẩm nào tại TechStore?',
        'questionType': 'MULTI_CHOICE',
        'totalAnswers': 50,
        'optionStats': [
          {'optionId': 1, 'optionText': 'Laptop Asus', 'voteCount': 30, 'percentage': 60.0},
          {'optionId': 2, 'optionText': 'Tai nghe Sony', 'voteCount': 25, 'percentage': 50.0},
        ],
      };

      final stats = QuestionStatistics.fromJson(json);
      expect(stats.questionId, equals(202));
      expect(stats.questionType, equals(SurveyQuestionType.MULTI_CHOICE));
      expect(stats.optionStats.length, equals(2));
      expect(stats.optionStats[0].optionText, equals('Laptop Asus'));
      expect(stats.optionStats[0].percentage, equals(60.0));
      expect(stats.optionStats[1].percentage, equals(50.0));
    });
  });
}
