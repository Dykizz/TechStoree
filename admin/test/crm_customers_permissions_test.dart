import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/constants/tech_interests.dart';
import 'package:techstore_admin/core/models/app_user.dart';
import 'package:techstore_admin/core/models/demographics_report.dart';
import 'package:techstore_admin/core/models/review.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/navigation_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/core/widgets/app_sidebar.dart';
import 'package:techstore_admin/core/widgets/main_layout.dart';
import 'package:techstore_admin/features/customers/customers_screen.dart';
import 'package:techstore_admin/features/dashboard/dashboard_screen.dart';
import 'package:techstore_admin/features/dashboard/models/dashboard_data.dart';
import 'package:techstore_admin/features/dashboard/services/dashboard_data_provider.dart';
import 'package:techstore_admin/features/reviews/widgets/review_data_table.dart';

class _FakeAuthProvider extends AuthProvider {
  final Set<String> _perms;
  final String _roleValue;
  final bool _isAdminValue;

  _FakeAuthProvider({
    required Set<String> permissions,
    String role = 'SURVEY_STAFF',
    bool isAdmin = false,
  })  : _perms = permissions.map((p) => p.toLowerCase()).toSet(),
        _roleValue = role,
        _isAdminValue = isAdmin;

  @override
  bool get isLoggedIn => true;

  @override
  String get userName => 'Nhân viên CRM';

  @override
  String get userEmail => 'survey01@techstoree.vn';

  @override
  String get userRole => _roleValue;

  @override
  List<String> get userRoles => [_roleValue];

  @override
  bool get isAdmin => _isAdminValue;

  @override
  String? get token => 'test-token';

  @override
  bool can(String permission) => _perms.contains(permission.trim().toLowerCase());
}

class _FakeCrmApiService extends ApiService {
  int getUsersCalls = 0;
  int getAllCustomersCalls = 0;
  int getDemographicsCalls = 0;
  int getReviewStatisticsCalls = 0;
  AppUser? createdCustomer;
  String? createdPassword;
  AppUser? updatedCustomer;
  String? toggledCustomerId;
  bool? toggledLockValue;

  final List<AppUser> customers;

  _FakeCrmApiService({List<AppUser>? initialCustomers})
      : customers = initialCustomers ??
            [
              AppUser(
                id: '5',
                userName: 'khachhang01',
                fullName: 'Nguyễn Văn Khách',
                email: 'khachhang01@gmail.com',
                role: 'USER',
                roles: const ['USER'],
                status: 'Hoạt động',
                isLocked: false,
                phone: '0987654321',
                techInterest: 'GAMING',
                dateOfBirth: DateTime(2000, 5, 10),
                address: 'Quận 1, TP.HCM',
                createdAt: DateTime(2026, 10, 18),
              ),
            ];

  @override
  Future<List<AppUser>> getUsers({String? token, bool? isStaffOnly}) async {
    getUsersCalls++;
    return const [];
  }

  @override
  Future<List<AppUser>> getAllCustomers({
    String? token,
    bool? isLocked,
    String? techInterest,
    String? search,
    bool throwOnError = false,
  }) async {
    getAllCustomersCalls++;
    return List<AppUser>.from(customers);
  }

  @override
  Future<List<TechInterestOption>> getTechInterests({
    String? token,
    bool forceRefresh = false,
  }) async {
    return TechInterestCatalog.defaults;
  }

  @override
  Future<DemographicsReport> getDemographicsReport({String? token}) async {
    getDemographicsCalls++;
    return DemographicsReport.fromUsers(customers);
  }

  @override
  Future<ApiResult> createCustomer(AppUser user, String password, {String? token}) async {
    createdCustomer = user;
    createdPassword = password;
    customers.add(user);
    return ApiResult(success: true, message: 'Tạo tài khoản khách hàng thành công!');
  }

  @override
  Future<ApiResult> updateCustomer(AppUser user, {String? token}) async {
    updatedCustomer = user;
    return ApiResult(success: true, message: 'Cập nhật thông tin khách hàng thành công!');
  }

  @override
  Future<bool> toggleCustomerLock(String customerId, {bool? isLocked, String? token}) async {
    toggledCustomerId = customerId;
    toggledLockValue = isLocked;
    return true;
  }

  @override
  Future<SurveyPagedResult> getSurveys({
    String? search,
    bool? isActive,
    bool? hasReward,
    int page = 1,
    int pageSize = 10,
    String? token,
    bool throwOnError = false,
  }) async {
    return SurveyPagedResult(
      items: const [],
      totalItems: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
    );
  }

  @override
  Future<CustomerReviewOverviewMetric> getReviewStatistics({int? productId, String? token}) async {
    getReviewStatisticsCalls++;
    return CustomerReviewOverviewMetric.empty();
  }
}

Widget _wrapWithProviders({
  required Widget child,
  required AuthProvider authProvider,
  required ApiService apiService,
  NavigationProvider? navProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<NavigationProvider>.value(
        value: navProvider ?? NavigationProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

const _surveyStaffPermissions = <String>{
  'Surveys.View',
  'Surveys.Create',
  'Surveys.Update',
  'Surveys.Delete',
  'Surveys.Assign',
  'Customers.View',
  'Customers.Create',
  'Customers.Update',
  'Customers.Lock',
  'Reviews.View',
  'Reviews.Reply',
  'Reviews.Hide',
};

void main() {
  testWidgets('SURVEY_STAFF sidebar shows Customers & Reviews and hides Staff', (tester) async {
    final auth = _FakeAuthProvider(permissions: _surveyStaffPermissions);
    final api = _FakeCrmApiService();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const SizedBox(height: 800, child: AppSidebar()),
        authProvider: auth,
        apiService: api,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khách hàng'), findsOneWidget);
    expect(find.text('Đánh giá sản phẩm'), findsOneWidget);
    expect(find.text('Khảo sát thị trường'), findsOneWidget);
    expect(find.text('Nhân viên'), findsNothing);
    expect(find.text('Vai trò & phân quyền'), findsNothing);
  });

  testWidgets('MainLayout allows Customers (10) and blocks Staff (11) for SURVEY_STAFF', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _FakeAuthProvider(permissions: _surveyStaffPermissions);
    final api = _FakeCrmApiService();
    final nav = NavigationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<NavigationProvider>.value(value: nav),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ApiService>.value(value: api),
        ],
        child: const MaterialApp(home: MainLayout()),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Customers (index 10)
    nav.setIndex(10);
    await tester.pumpAndSettle();
    expect(find.byType(CustomersScreen), findsOneWidget);
    expect(api.getAllCustomersCalls, greaterThanOrEqualTo(1));
    expect(api.getUsersCalls, 0);

    // Attempt to navigate to Staff (index 11) -> redirected back to index 0
    nav.setIndex(11);
    await tester.pumpAndSettle();
    expect(nav.currentIndex, 0);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('CustomersScreen supports View, Create, Update, Lock, and Demographics via /customers APIs', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _FakeAuthProvider(permissions: _surveyStaffPermissions);
    final api = _FakeCrmApiService();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const CustomersScreen(),
        authProvider: auth,
        apiService: api,
      ),
    );
    await tester.pumpAndSettle();

    // B01: Customer list loaded via getAllCustomers (not getUsers)
    expect(api.getAllCustomersCalls, 1);
    expect(api.getUsersCalls, 0);
    expect(find.text('Nguyễn Văn Khách'), findsOneWidget);

    // B02: Create Customer button & dialog -> calls createCustomer
    expect(find.text('Thêm khách hàng'), findsOneWidget);
    await tester.tap(find.text('Thêm khách hàng'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Họ và tên (*)'), 'Trần Thị Mới');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tên đăng nhập (*)'), 'khachmoi02');
    await tester.enterText(find.widgetWithText(TextFormField, 'Địa chỉ Email (*)'), 'khachmoi02@gmail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu khởi tạo (*)'), 'MatKhau123');
    await tester.tap(find.text('Tạo khách hàng'));
    await tester.pumpAndSettle();

    expect(api.createdCustomer, isNotNull);
    expect(api.createdCustomer!.email, 'khachmoi02@gmail.com');
    expect(api.createdCustomer!.roles, const ['USER']);

    // B03: Edit Customer button -> calls updateCustomer
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Họ và tên (*)'), 'Nguyễn Văn Khách Đã Sửa');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(api.updatedCustomer, isNotNull);
    expect(api.updatedCustomer!.fullName, 'Nguyễn Văn Khách Đã Sửa');

    // B05: Lock Customer button -> calls toggleCustomerLock
    await tester.tap(find.byIcon(Icons.lock_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khóa ngay'));
    await tester.pumpAndSettle();

    expect(api.toggledCustomerId, '5');
    expect(api.toggledLockValue, isTrue);

    // Wait for top-right floating toast to auto-dismiss before tapping header button
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // B23: Demographics report -> calls getDemographicsReport
    await tester.tap(find.text('Báo cáo nhân khẩu học'));
    await tester.pumpAndSettle();
    expect(api.getDemographicsCalls, 1);
  });

  testWidgets('DashboardScreen renders Customers shortcut and hides Staff shortcut when only Customers.View is granted', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _FakeAuthProvider(permissions: const {'Customers.View'});
    final api = _FakeCrmApiService();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const SingleChildScrollView(child: DashboardScreen()),
        authProvider: auth,
        apiService: api,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý khách hàng'), findsOneWidget);
    expect(find.text('Quản lý nhân viên'), findsNothing);
    expect(api.getAllCustomersCalls, 1);
    expect(api.getUsersCalls, 0);
  });

  test('DashboardDataProvider uses getAllCustomers & Reviews.View for SURVEY_STAFF without calling getUsers', () async {
    final auth = _FakeAuthProvider(permissions: _surveyStaffPermissions);
    final api = _FakeCrmApiService();
    final provider = DashboardDataProvider(apiService: api);

    final result = await provider.fetchDashboardData(
      period: DashboardTimePeriod.fromType(DashboardTimeRangeType.last30Days),
      token: 'test-token',
      authProvider: auth,
    );

    expect(api.getAllCustomersCalls, 1);
    expect(api.getUsersCalls, 0);
    expect(api.getReviewStatisticsCalls, 1);
    expect(result.newCustomers.current, greaterThanOrEqualTo(0));
  });

  testWidgets('ReviewDataTable shows reply and hide/show controls for SURVEY_STAFF with Reviews.Hide', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _FakeAuthProvider(permissions: _surveyStaffPermissions);
    final api = _FakeCrmApiService();
    ReviewItem? hiddenTarget;

    final sampleReview = ReviewItem(
      reviewId: 3,
      userId: 5,
      username: 'khachhang01',
      fullName: 'Nguyễn Văn Khách',
      email: 'khachhang01@gmail.com',
      productId: 1,
      productName: 'ASUS Zenbook 14 OLED',
      orderItemId: 10,
      orderId: 1,
      orderCode: 'ORD-001',
      variantId: 1,
      variantName: 'Ultra 5 / 16GB',
      rating: 4.5,
      comment: 'Sản phẩm tốt',
      isHidden: false,
      createdAt: DateTime(2026, 11, 1),
    );

    await tester.pumpWidget(
      _wrapWithProviders(
        authProvider: auth,
        apiService: api,
        child: ReviewDataTable(
          reviewsFuture: Future.value(
            ReviewPagedResult(items: [sampleReview], totalCount: 1, page: 1, pageSize: 10),
          ),
          reviewsError: null,
          isActionBusy: false,
          currentPage: 1,
          itemsPerPage: 10,
          formatError: (_) => '',
          onRetry: () {},
          onPageChanged: (_) {},
          onItemsPerPageChanged: (_) {},
          onOpenReplyDialog: (_, {required canReply}) {},
          onToggleHideReview: (review) async {
            hiddenTarget = review;
          },
          onDeleteReview: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(hiddenTarget?.reviewId, 3);
  });

  test('AuthProvider offline fallback for SURVEY_STAFF grants Customers.* and Reviews.Hide without Users.View', () async {
    final auth = AuthProvider();
    final loggedIn = await auth.login(
      'survey01@techstoree.vn',
      'staff123',
      baseUrl: 'http://127.0.0.1:59999/api',
    );

    expect(loggedIn, isTrue);
    expect(auth.can('Customers.View'), isTrue);
    expect(auth.can('Customers.Create'), isTrue);
    expect(auth.can('Customers.Update'), isTrue);
    expect(auth.can('Customers.Lock'), isTrue);
    expect(auth.can('Reviews.Hide'), isTrue);
    expect(auth.can('Users.View'), isFalse);
    expect(auth.can('Employees.View'), isFalse);
  });
}
