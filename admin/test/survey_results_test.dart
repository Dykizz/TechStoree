import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/models/survey.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/features/surveys/result/survey_results_view.dart';
import 'package:techstore_admin/features/surveys/result/survey_result_kpi_card.dart';

class _FakeSurveyApiService extends ApiService {
  Future<SurveyStatistics?> Function(int id) onGetStats;
  Future<(Uint8List?, String)> Function(int id)? onExportCsv;

  _FakeSurveyApiService({
    required this.onGetStats,
    this.onExportCsv,
  });

  @override
  Future<SurveyStatistics?> getSurveyStatistics(
    int id, {
    String? token,
    bool throwOnError = false,
  }) {
    return onGetStats(id);
  }

  @override
  Future<(Uint8List?, String)> exportSurveyCsv(int id, {String? token}) {
    if (onExportCsv != null) {
      return onExportCsv!(id);
    }
    lastErrorMessage = 'Không có dữ liệu CSV giả lập';
    return Future.value((null, ''));
  }
}

Widget _wrapStatisticsView(
  Widget child, {
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(child: child),
      ),
    ),
  );
}

SurveyStatistics _sampleStats({
  int surveyId = 1,
  String title = 'Khảo sát mức độ hài lòng',
  int totalAssigned = 10,
  int totalCompleted = 5,
  double responseRatePercent = 50.0,
  List<QuestionStatistics> questions = const [],
}) {
  return SurveyStatistics(
    surveyId: surveyId,
    title: title,
    totalAssigned: totalAssigned,
    totalCompleted: totalCompleted,
    responseRatePercent: responseRatePercent,
    questions: questions,
  );
}

void main() {
  testWidgets('Initial error, retry recovery, and reload error banner visibility', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var attempt = 0;
    final fakeApi = _FakeSurveyApiService(
      onGetStats: (_) async {
        attempt++;
        if (attempt == 1) {
          throw Exception('Mất kết nối máy chủ');
        }
        if (attempt == 2 || attempt == 4) {
          return _sampleStats();
        }
        throw Exception('Lỗi timeout khi tải lại');
      },
    );

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 1, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải dữ liệu thống kê'), findsOneWidget);
    expect(find.text('Mất kết nối máy chủ'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.byType(SurveyResultKpiCard), findsNWidgets(3));
    expect(find.text('50%'), findsOneWidget);

    // Reload fails after cached data already exists -> banner must appear above cached KPIs
    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();

    expect(find.text('Lỗi timeout khi tải lại'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    // Retry from banner clears banner on success
    await tester.tap(find.text('Tải lại').first);
    await tester.pumpAndSettle();

    expect(find.text('Lỗi timeout khi tải lại'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('didUpdateWidget isolates cache across different surveyId values', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeApi = _FakeSurveyApiService(
      onGetStats: (id) async {
        if (id == 1) return _sampleStats(surveyId: 1, title: 'Khảo sát A');
        if (id == 2) throw Exception('Không tìm thấy khảo sát B');
        return _sampleStats(surveyId: 3, title: 'Khảo sát C', totalAssigned: 20, totalCompleted: 2, responseRatePercent: 10);
      },
    );

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 1, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khảo sát A'), findsOneWidget);

    // Switch to failing surveyId = 2 without external ValueKey -> must NOT leak Khảo sát A
    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 2, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khảo sát A'), findsNothing);
    expect(find.text('Không tìm thấy khảo sát B'), findsOneWidget);

    // Switch to succeeding surveyId = 3
    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 3, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khảo sát C'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zero-response survey keeps option table visible and handles empty questions', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final zeroVoteStats = _sampleStats(
      totalAssigned: 0,
      totalCompleted: 0,
      responseRatePercent: 0,
      questions: [
        QuestionStatistics(
          questionId: 10,
          questionText: 'Bạn ưu tiên tiêu chí nào?',
          questionType: SurveyQuestionType.SINGLE_CHOICE,
          totalAnswers: 0,
          optionStats: [
            OptionStatistics(optionId: 1, optionText: 'Giá bán', voteCount: 0, percentage: 0),
            OptionStatistics(optionId: 2, optionText: 'Bảo hành', voteCount: 0, percentage: 0),
          ],
          textAnswers: const [],
        ),
      ],
    );

    final fakeApi = _FakeSurveyApiService(
      onGetStats: (id) async => id == 99
          ? _sampleStats(surveyId: 99, totalAssigned: 0, totalCompleted: 0, responseRatePercent: 0, questions: const [])
          : zeroVoteStats,
    );

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 1, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lượt phát bài'), findsOneWidget);
    expect(find.text('Chưa có lượt chọn'), findsOneWidget);
    expect(find.text('Giá bán'), findsWidgets);
    expect(find.text('Bảo hành'), findsWidgets);

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 99, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khảo sát chưa tạo câu hỏi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PieChart handles 10 options, <5% slice, 0-vote filter, MULTI_CHOICE bars & toggle', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final tenOptions = List.generate(
      10,
      (i) => OptionStatistics(
        optionId: i + 1,
        optionText: 'Lựa chọn ${i + 1}',
        voteCount: i == 0 ? 1 : (i == 1 ? 99 : 0),
        percentage: i == 0 ? 1.0 : (i == 1 ? 99.0 : 0.0),
      ),
    );

    final stats = _sampleStats(
      totalAssigned: 200,
      totalCompleted: 150,
      responseRatePercent: 75.0,
      questions: [
        QuestionStatistics(
          questionId: 1,
          questionText: 'Câu hỏi trắc nghiệm 10 lựa chọn',
          questionType: SurveyQuestionType.SINGLE_CHOICE,
          totalAnswers: 100,
          optionStats: tenOptions,
          textAnswers: const [],
        ),
        QuestionStatistics(
          questionId: 2,
          questionText: 'Bạn quan tâm sản phẩm nào?',
          questionType: SurveyQuestionType.MULTI_CHOICE,
          totalAnswers: 10,
          optionStats: [
            OptionStatistics(optionId: 21, optionText: 'Laptop', voteCount: 8, percentage: 80.0),
            OptionStatistics(optionId: 22, optionText: 'Tai nghe', voteCount: 9, percentage: 90.0),
            OptionStatistics(optionId: 23, optionText: 'Chuột', voteCount: 0, percentage: 0.0),
          ],
          textAnswers: const [],
        ),
      ],
    );

    final fakeApi = _FakeSurveyApiService(onGetStats: (_) async => stats);

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 1, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    // Q1 defaults to PieChart, Q2 defaults to horizontal bars
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Lựa chọn 10'), findsOneWidget);
    expect(find.text('Tỷ lệ % tính trên 100/150 người trả lời câu hỏi này.'), findsOneWidget);
    expect(find.text('10 người (17 lượt chọn)'), findsOneWidget);
    expect(find.text('8 lượt • 80%'), findsOneWidget);
    expect(find.text('9 lượt • 90%'), findsOneWidget);

    // Hover over PieChart slice -> highlights table without adding extra callout text below chart
    final pieCenter = tester.getCenter(find.byType(PieChart).first);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(Offset(pieCenter.dx - 55, pieCenter.dy));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lựa chọn 2: 99 lượt'), findsNothing);

    // Toggle Q2 to PieChart
    final tronBtn = find.text('Tròn').last;
    await tester.ensureVisible(tronBtn);
    await tester.tap(tronBtn);
    await tester.pumpAndSettle();
    expect(find.byType(PieChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TEXT question syncs real answer count, searches, and expands/collapses >5 items', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final answers = List.generate(
      7,
      (i) => TextAnswer(
        text: i == 6 ? 'Góp ý đặc biệt về giao hàng' : 'Nhận xét số ${i + 1}',
        customerName: i == 6 ? 'Trần Thị B' : 'Khách hàng ${i + 1}',
        submittedAt: DateTime(2026, 11, 10, 10, i),
      ),
    );

    final stats = _sampleStats(
      questions: [
        QuestionStatistics(
          questionId: 3,
          questionText: 'Ý kiến đóng góp thêm',
          questionType: SurveyQuestionType.TEXT,
          totalAnswers: 99, // Intentional mismatch test vs textAnswers.length (7)
          optionStats: const [],
          textAnswers: answers,
        ),
        QuestionStatistics(
          questionId: 4,
          questionText: 'Câu tự luận trống',
          questionType: SurveyQuestionType.TEXT,
          totalAnswers: 0,
          optionStats: const [],
          textAnswers: const [],
        ),
      ],
    );

    final fakeApi = _FakeSurveyApiService(onGetStats: (_) async => stats);

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(surveyId: 1, onBack: () {}),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 phản hồi'), findsOneWidget);
    expect(find.text('0 phản hồi'), findsOneWidget);
    expect(find.text('Chưa có ý kiến phản hồi nào cho câu tự luận này.'), findsOneWidget);
    expect(find.text('Nhận xét số 1'), findsOneWidget);
    expect(find.text('Góp ý đặc biệt về giao hàng'), findsNothing);

    await tester.tap(find.text('Xem tất cả (7 phản hồi)'));
    await tester.pumpAndSettle();
    expect(find.text('Góp ý đặc biệt về giao hàng'), findsOneWidget);

    final collapseBtn = find.text('Thu gọn danh sách');
    await tester.ensureVisible(collapseBtn);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();
    expect(find.text('Góp ý đặc biệt về giao hàng'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Trần Thị B');
    await tester.pumpAndSettle();
    expect(find.text('Góp ý đặc biệt về giao hàng'), findsOneWidget);
    expect(find.text('Nhận xét số 1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'khong_ton_tai');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy phản hồi phù hợp với từ khóa.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Responsive layout handles long text across 1280px, 650px, and 420px without overflow', (tester) async {
    final longTitle = 'Khảo sát trải nghiệm khách hàng rất dài ' * 4;
    final longQuestion = 'Câu hỏi chi tiết về chất lượng đóng gói và giao hàng ' * 3;
    final stats = _sampleStats(
      title: longTitle,
      questions: [
        QuestionStatistics(
          questionId: 1,
          questionText: longQuestion,
          questionType: SurveyQuestionType.SINGLE_CHOICE,
          totalAnswers: 5,
          optionStats: [
            OptionStatistics(optionId: 1, optionText: 'Lựa chọn tên rất dài để kiểm tra xuống dòng an toàn', voteCount: 5, percentage: 100.0),
            OptionStatistics(optionId: 2, optionText: 'Không có ý kiến', voteCount: 0, percentage: 0.0),
          ],
          textAnswers: const [],
        ),
      ],
    );
    final fakeApi = _FakeSurveyApiService(onGetStats: (_) async => stats);

    for (final width in [1280.0, 650.0, 420.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _wrapStatisticsView(
          SurveyResultsView(surveyId: 1, onBack: () {}),
          apiService: fakeApi,
        ),
      );
      await tester.pumpAndSettle();
      final err = tester.takeException();
      expect(err, isNull, reason: 'No overflow at width $width -> $err');
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets('Export CSV locks duplicate clicks while allowing Back button navigation', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var backPressed = false;
    var exportCalls = 0;
    final exportCompleter = Completer<(Uint8List?, String)>();

    final fakeApi = _FakeSurveyApiService(
      onGetStats: (_) async => _sampleStats(),
      onExportCsv: (_) {
        exportCalls++;
        return exportCompleter.future;
      },
    );

    await tester.pumpWidget(
      _wrapStatisticsView(
        SurveyResultsView(
          surveyId: 1,
          onBack: () => backPressed = true,
        ),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xuất báo cáo (CSV)'));
    await tester.pump();

    expect(exportCalls, 1);
    expect(find.text('Đang xuất file...'), findsOneWidget);

    // Duplicate click while exporting must not trigger another export call
    await tester.tap(find.text('Đang xuất file...'));
    await tester.pump();
    expect(exportCalls, 1);

    // Back button must still remain interactive during export
    await tester.tap(find.text('Danh sách khảo sát'));
    await tester.pump();
    expect(backPressed, isTrue);

    fakeApi.lastErrorMessage = 'Đã hủy tải thử nghiệm';
    exportCompleter.complete((null, ''));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

