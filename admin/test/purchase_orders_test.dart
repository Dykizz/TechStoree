import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/models/product.dart';
import 'package:techstore_admin/core/models/purchase_order.dart';
import 'package:techstore_admin/core/models/supplier.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/core/widgets/app_pagination.dart';
import 'package:techstore_admin/features/purchase_orders/dialog/purchase_order_detail_dialog.dart';
import 'package:techstore_admin/features/purchase_orders/dialog/purchase_order_form_dialog.dart';
import 'package:techstore_admin/features/purchase_orders/purchase_orders_screen.dart';
import 'package:techstore_admin/features/purchase_orders/widgets/purchase_order_data_table.dart';
import 'package:techstore_admin/features/purchase_orders/widgets/purchase_order_filter_bar.dart';
import 'package:techstore_admin/features/purchase_orders/widgets/purchase_order_quick_view_panel.dart';

class _FakePurchaseOrderApiService extends ApiService {
  final Future<PurchaseOrderPagedResult> Function({
    int page,
    int pageSize,
    String? status,
    int? supplierId,
    String? search,
  })? onGetPaged;

  final Future<List<Supplier>> Function()? onGetSuppliers;
  final Future<List<Product>> Function()? onGetProducts;
  final Future<PurchaseOrder?> Function(int id)? onGetById;
  final Future<ApiResult> Function(PurchaseOrder po)? onCreate;
  final Future<ApiResult> Function(int id, PurchaseOrder po)? onUpdate;
  final Future<ApiResult> Function(int id)? onDelete;

  _FakePurchaseOrderApiService({
    this.onGetPaged,
    this.onGetSuppliers,
    this.onGetProducts,
    this.onGetById,
    this.onCreate,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Future<PurchaseOrderPagedResult> getPurchaseOrdersPaged({
    int page = 1,
    int pageSize = 10,
    String? token,
    String? status,
    int? supplierId,
    String? search,
    String sortBy = 'createdAt',
    bool isAscending = false,
    bool throwOnError = false,
  }) {
    if (onGetPaged != null) {
      return onGetPaged!(
        page: page,
        pageSize: pageSize,
        status: status,
        supplierId: supplierId,
        search: search,
      );
    }
    return Future.value(
      PurchaseOrderPagedResult(
        items: const [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<List<Supplier>> getSuppliers({
    String? token,
    String? status = 'all',
  }) {
    if (onGetSuppliers != null) return onGetSuppliers!();
    return Future.value(const []);
  }

  @override
  Future<PurchaseOrder?> getPurchaseOrderById(int id, {String? token}) {
    if (onGetById != null) return onGetById!(id);
    return Future.value(null);
  }

  @override
  Future<List<Product>> getProductsWithVariants({String? token}) {
    if (onGetProducts != null) return onGetProducts!();
    return Future.value(const []);
  }

  @override
  Future<ApiResult> createPurchaseOrder(PurchaseOrder po, {String? token}) {
    if (onCreate != null) return onCreate!(po);
    return Future.value(ApiResult(success: true, message: 'OK'));
  }

  @override
  Future<ApiResult> updatePurchaseOrder(
    int id,
    PurchaseOrder po, {
    String? token,
  }) {
    if (onUpdate != null) return onUpdate!(id, po);
    return Future.value(ApiResult(success: true, message: 'OK'));
  }

  @override
  Future<ApiResult> deletePurchaseOrder(int id, {String? token}) {
    if (onDelete != null) return onDelete!(id);
    return Future.value(ApiResult(success: true, message: 'Đã xóa'));
  }
}

Widget _wrapWithProviders(
  Widget child, {
  required ApiService apiService,
  List<String> permissions = const [
    'PurchaseOrders.View',
    'PurchaseOrders.Create',
    'PurchaseOrders.Update',
  ],
}) {
  final auth = AuthProvider()..updatePermissions(permissions);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(
      home: Scaffold(body: SizedBox.expand(child: child)),
    ),
  );
}

List<Supplier> _sampleSuppliers() => [
      Supplier(
        id: '1',
        name: 'Công ty Công Nghệ ABC',
        code: 'SUP-01',
        phone: '0901234567',
        email: 'abc@supplier.vn',
        address: 'TP.HCM',
        isActive: true,
      ),
      Supplier(
        id: '2',
        name: 'Nhà Phân Phối Cũ',
        code: 'SUP-02',
        phone: '0909999999',
        email: 'old@supplier.vn',
        address: 'Hà Nội',
        isActive: false,
      ),
    ];

PurchaseOrder _samplePo({
  int id = 1,
  String code = 'PO-2026-001',
  String status = 'DRAFT',
  List<PurchaseOrderItem> items = const [],
}) {
  return PurchaseOrder(
    purchaseOrderId: id,
    poCode: code,
    supplierId: 1,
    supplierName: 'Công ty Công Nghệ ABC',
    createdByUserId: 10,
    createdByName: 'Nguyễn Văn A',
    totalCost: 30000000,
    totalItems: items.isNotEmpty ? items.length : 1,
    status: status,
    note: 'Đợt nhập tháng 11',
    createdAt: DateTime(2026, 11, 10, 9, 30),
    items: items,
  );
}

PurchaseOrderItem _sampleItem() => PurchaseOrderItem(
      poItemId: 101,
      variantId: 10,
      productId: 100,
      productName: 'Laptop Gaming Pro',
      variantName: 'RTX 4060 / 16GB',
      importPrice: 15000000,
      quantity: 2,
    );

void main() {
  test('PurchaseOrderFormDialog.buildVariantOptions skips variantless products and tracks isActive', () {
    final products = [
      Product(
        id: '1',
        name: 'SP Không Biến Thể',
        sku: 'SKU-0',
        category: 'Laptop',
        price: 1000000,
        status: 'In Stock',
        imageUrl: '',
        variants: const [],
      ),
      Product(
        id: '2',
        name: 'Laptop Active',
        sku: 'SKU-2',
        category: 'Laptop',
        price: 15000000,
        status: 'In Stock',
        imageUrl: '',
        isActive: true,
        variants: [
          ProductVariant(
            variantId: 10,
            productId: 2,
            variantNameAttr: '16GB RAM',
            price: 15000000,
            stockQuantity: 5,
            isActive: true,
          ),
          ProductVariant(
            variantId: 20,
            productId: 2,
            variantNameAttr: '8GB Ngưng KD',
            price: 12000000,
            stockQuantity: 1,
            isActive: false,
          ),
        ],
      ),
      Product(
        id: '3',
        name: 'Laptop Cha Ngưng KD',
        sku: 'SKU-3',
        category: 'Laptop',
        price: 20000000,
        status: 'Ngừng bán',
        imageUrl: '',
        isActive: false,
        variants: [
          ProductVariant(
            variantId: 30,
            productId: 3,
            variantNameAttr: '32GB',
            price: 20000000,
            stockQuantity: 2,
            isActive: true,
          ),
        ],
      ),
    ];

    final options = PurchaseOrderFormDialog.buildVariantOptions(products);
    expect(options.length, 3);
    expect(options.any((o) => o.productId == 1), isFalse);
    expect(options.firstWhere((o) => o.variantId == 10).isActive, isTrue);
    expect(options.firstWhere((o) => o.variantId == 20).isActive, isFalse);
    expect(options.firstWhere((o) => o.variantId == 30).isActive, isFalse);
  });

  testWidgets('Rigid 2-column layout shows placeholder initially, opens quick view on row tap, and closes on ESC', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final summaryPo = _samplePo(id: 1, code: 'PO-2026-001', items: const []);
    final detailPo = _samplePo(
      id: 1,
      code: 'PO-2026-001',
      items: [_sampleItem()],
    );

    final fakeApi = _FakePurchaseOrderApiService(
      onGetSuppliers: () async => _sampleSuppliers(),
      onGetPaged: ({page = 1, pageSize = 10, status, supplierId, search}) async =>
          PurchaseOrderPagedResult(
            items: [summaryPo],
            totalCount: 1,
            page: page,
            pageSize: pageSize,
          ),
      onGetById: (id) async => detailPo,
    );

    await tester.pumpWidget(
      _wrapWithProviders(const PurchaseOrdersScreen(), apiService: fakeApi),
    );
    await tester.pumpAndSettle();

    // 2 cột cứng: Bảng bên trái & Placeholder bên phải cùng xuất hiện ngay từ đầu
    expect(find.byType(PurchaseOrderDataTable), findsOneWidget);
    expect(find.byType(PurchaseOrderQuickViewPlaceholder), findsOneWidget);
    expect(find.text('Chưa chọn phiếu nhập'), findsOneWidget);

    // Nhấp dòng -> chuyển sang QuickViewPanel nhưng bảng vẫn giữ nguyên bên trái
    await tester.tap(find.text('PO-2026-001'));
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseOrderQuickViewPanel), findsOneWidget);
    expect(find.byType(PurchaseOrderDataTable), findsOneWidget);
    expect(find.text('MẶT HÀNG NHẬP (1)'), findsOneWidget);
    expect(find.textContaining('Tổng số lượng nhập'), findsNothing);
    expect(find.text('Xem đầy đủ'), findsOneWidget);
    expect(find.text('Sửa nháp'), findsOneWidget);
    expect(find.text('Xóa nháp'), findsNothing);
    expect(find.text('Hoàn thành'), findsNothing);
    expect(find.textContaining('CANCLE'), findsNothing);

    // Bấm ESC -> đóng Quick View về lại placeholder
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseOrderQuickViewPlaceholder), findsOneWidget);
    expect(find.byType(PurchaseOrderQuickViewPanel), findsNothing);
  });

  testWidgets('Quick View retry recovers from error, delete draft wording is clean, and COMPLETE keeps loaded items', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final summaryPo = _samplePo(id: 7, code: 'PO-2026-007', items: const []);
    final detailPo = _samplePo(
      id: 7,
      code: 'PO-2026-007',
      items: [_sampleItem()],
    );

    var byIdAttempts = 0;
    PurchaseOrder? submittedUpdatePo;
    int? deletedId;

    final fakeApi = _FakePurchaseOrderApiService(
      onGetSuppliers: () async => _sampleSuppliers(),
      onGetPaged: ({page = 1, pageSize = 10, status, supplierId, search}) async =>
          PurchaseOrderPagedResult(
            items: [summaryPo],
            totalCount: 1,
            page: page,
            pageSize: pageSize,
          ),
      onGetById: (id) async {
        byIdAttempts++;
        if (byIdAttempts == 1) {
          throw Exception('Lỗi mạng tạm thời');
        }
        return detailPo;
      },
      onUpdate: (id, po) async {
        submittedUpdatePo = po;
        return ApiResult(success: true, message: 'Hoàn thành thành công');
      },
      onDelete: (id) async {
        deletedId = id;
        return ApiResult(success: true, message: 'Đã xóa phiếu nháp');
      },
    );

    await tester.pumpWidget(
      _wrapWithProviders(const PurchaseOrdersScreen(), apiService: fakeApi),
    );
    await tester.pumpAndSettle();

    // Lần 1 mở quick view bị lỗi -> hiện nút Thử lại
    await tester.tap(find.text('PO-2026-007'));
    await tester.pumpAndSettle();

    expect(find.text('Lỗi kết nối khi tải chi tiết mặt hàng.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('MẶT HÀNG NHẬP (1)'), findsOneWidget);

    // Thao tác xóa phiếu nháp ở cột Thao tác trên bảng dùng nhãn xác nhận rõ ràng, không còn 'CANCLE'
    await tester.ensureVisible(find.byTooltip('Xóa phiếu nháp'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xóa phiếu nháp'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận xóa phiếu nháp'), findsOneWidget);
    expect(find.textContaining('CANCLE'), findsNothing);
    await tester.tap(find.text('Hủy bỏ'));
    await tester.pumpAndSettle();
    expect(deletedId, isNull);

    // Hoàn thành phiếu từ bảng -> vẫn sử dụng đầy đủ items đã cache từ Quick View (không gửi mảng rỗng)
    await tester.ensureVisible(find.byTooltip('Hoàn thành phiếu (COMPLETE)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hoàn thành phiếu (COMPLETE)'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận Hoàn thành (COMPLETE)'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hoàn thành'),
      ),
    );
    await tester.pumpAndSettle();

    expect(submittedUpdatePo, isNotNull);
    expect(submittedUpdatePo!.status, 'COMPLETE');
    expect(submittedUpdatePo!.items.length, 1);
    expect(submittedUpdatePo!.items.first.variantId, 10);

    // Đợi timer của AppToast kết thúc sạch
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('PurchaseOrderFormDialog blocks inactive variants, rejects empty quantity, and submits valid items', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    PurchaseOrder? createdPo;
    final fakeApi = _FakePurchaseOrderApiService(
      onCreate: (po) async {
        createdPo = po;
        return ApiResult(success: true, message: 'Tạo thành công');
      },
    );

    final variantOptions = [
      const PurchaseOrderVariantOption(
        variantId: 10,
        productId: 2,
        productName: 'Laptop Active',
        variantName: '16GB RAM',
        fullName: 'Laptop Active (16GB RAM)',
        defaultPrice: 15000000,
        stockQuantity: 5,
        isActive: true,
      ),
      const PurchaseOrderVariantOption(
        variantId: 20,
        productId: 2,
        productName: 'Laptop Inactive',
        variantName: 'Ngưng KD',
        fullName: 'Laptop Inactive (Ngưng KD)',
        defaultPrice: 10000000,
        stockQuantity: 1,
        isActive: false,
      ),
    ];

    await tester.pumpWidget(
      _wrapWithProviders(
        Builder(
          builder: (context) => PurchaseOrderFormDialog(
            existingPo: null,
            suppliers: _sampleSuppliers(),
            variantOptions: variantOptions,
            apiService: fakeApi,
            token: 'token',
            onSaved: () {},
          ),
        ),
        apiService: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    // Gõ từ khóa 'Laptop': chỉ biến thể active hiển thị trong dropdown gợi ý
    final searchField = find.widgetWithText(
      TextFormField,
      'Tìm kiếm sản phẩm hoặc biến thể...',
    );
    await tester.enterText(searchField, 'Laptop');
    await tester.pumpAndSettle();

    expect(find.text('Laptop Active (16GB RAM)'), findsOneWidget);
    expect(find.text('Laptop Inactive (Ngưng KD)'), findsNothing);

    // Thêm biến thể active vào phiếu
    await tester.tap(find.text('Laptop Active (16GB RAM)'));
    await tester.pumpAndSettle();

    // Xóa trống ô SL -> không cho lưu với lỗi số lượng > 0
    final qtyField = find.widgetWithText(TextFormField, 'SL');
    await tester.enterText(qtyField, '');
    await tester.pump();
    await tester.tap(find.text('Tạo phiếu nhập hàng'));
    await tester.pump();

    expect(createdPo, isNull);
    expect(
      find.text('Số lượng nhập của "Laptop Active (16GB RAM)" phải lớn hơn 0.'),
      findsOneWidget,
    );

    // Nhập SL hợp lệ = 3 -> lưu thành công
    await tester.enterText(qtyField, '3');
    await tester.pump();
    await tester.tap(find.text('Tạo phiếu nhập hàng'));
    await tester.pumpAndSettle();

    expect(createdPo, isNotNull);
    expect(createdPo!.items.length, 1);
    expect(createdPo!.items.first.quantity, 3);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('PurchaseOrderDetailDialog renders long content cleanly without overflow and shows delete draft label', (tester) async {
    tester.view.physicalSize = const Size(520, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final longPo = PurchaseOrder(
      purchaseOrderId: 99,
      poCode: 'PO-2026-LONG-CODE-000000000099',
      supplierId: 1,
      supplierName: 'Công ty Cổ phần Thương mại và Dịch vụ Công nghệ Rất Dài Việt Nam',
      createdByUserId: 5,
      createdByName: 'Nguyễn Trần Bảo Khanh - Quản lý Kho Tổng Miền Nam',
      totalCost: 45000000,
      totalItems: 1,
      status: 'DRAFT',
      note: 'Ghi chú kiểm thử khả năng xuống dòng trên dialog kích thước hẹp',
      createdAt: DateTime(2026, 11, 14, 8, 15),
      items: [_sampleItem()],
    );

    await tester.pumpWidget(
      _wrapWithProviders(
        PurchaseOrderDetailDialog(
          purchaseOrder: longPo,
          onCancel: () {},
          onComplete: () {},
        ),
        apiService: _FakePurchaseOrderApiService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xóa phiếu nháp'), findsOneWidget);
    expect(find.text('Hoàn thành & Nhập kho'), findsOneWidget);
    expect(find.textContaining('CANCLE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('Purchase Orders Stateful E2E Flows', () {
    testWidgets(
      'Flow A: Create DRAFT -> stock unchanged -> search -> Quick View -> edit draft -> Detail Dialog complete -> stock incremented & immutable',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final backend = _InMemoryPoBackend(
          initialVariantStock: 5,
          initialOrders: [
            _samplePo(
              id: 1,
              code: 'PO-2026-SEED-001',
              status: 'COMPLETE',
              items: [_sampleItem()],
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            const PurchaseOrdersScreen(),
            apiService: backend.apiService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PO-2026-SEED-001'), findsOneWidget);

        // 1. Tạo phiếu nhập DRAFT mới từ UI
        await tester.tap(find.text('Tạo phiếu nhập hàng mới'));
        await tester.pumpAndSettle();

        final variantSearchField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(
            TextFormField,
            'Tìm kiếm sản phẩm hoặc biến thể...',
          ),
        );
        await tester.enterText(variantSearchField, 'Laptop');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laptop Active (16GB RAM)'));
        await tester.pumpAndSettle();

        final qtyField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(TextFormField, 'SL'),
        );
        await tester.enterText(qtyField, '4');
        await tester.pump();

        final noteField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(
            TextFormField,
            'Ghi chú phiếu nhập (Số hóa đơn, đợt nhập, người phụ trách...)',
          ),
        );
        await tester.enterText(noteField, 'Nháp đợt 1');
        await tester.pump();

        await tester.tap(find.text('Tạo phiếu nhập hàng'));
        await tester.pumpAndSettle();

        // Tồn kho giữ nguyên vì là DRAFT, danh sách hiển thị mã mới PO-2026-NEW-2
        expect(backend.stockOf(10), 5);
        expect(find.text('PO-2026-NEW-2'), findsOneWidget);

        // 2. Tìm kiếm phiếu vừa tạo trên Filter Bar
        final filterSearchField = find.descendant(
          of: find.byType(PurchaseOrderFilterBar),
          matching: find.byType(TextField),
        );
        await tester.enterText(filterSearchField, 'PO-2026-NEW-2');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        final matchingTableRow = find.descendant(
          of: find.byType(PurchaseOrderDataTable),
          matching: find.text('PO-2026-NEW-2'),
        );
        expect(matchingTableRow, findsOneWidget);
        expect(find.text('PO-2026-SEED-001'), findsNothing);

        // 3. Nhấp dòng để mở Quick View -> Sửa nháp (SL 4 -> 6, cập nhật ghi chú)
        await tester.tap(matchingTableRow);
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseOrderQuickViewPanel), findsOneWidget);
        expect(find.text('Sửa nháp'), findsOneWidget);

        await tester.tap(find.text('Sửa nháp'));
        await tester.pumpAndSettle();

        final editQtyField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(TextFormField, 'SL'),
        );
        await tester.enterText(editQtyField, '6');
        await tester.pump();

        final editNoteField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(
            TextFormField,
            'Ghi chú phiếu nhập (Số hóa đơn, đợt nhập, người phụ trách...)',
          ),
        );
        await tester.enterText(editNoteField, 'Đã sửa SL thành 6');
        await tester.pump();

        await tester.tap(find.text('Cập nhật phiếu nhập'));
        await tester.pumpAndSettle();

        // Sau sửa nháp tồn kho vẫn = 5
        expect(backend.stockOf(10), 5);
        expect(backend.orders.firstWhere((o) => o.poCode == 'PO-2026-NEW-2').items.first.quantity, 6);

        // 4. Chọn lại dòng đã sửa -> Mở Xem đầy đủ -> Hoàn thành & Nhập kho -> xác nhận
        await tester.tap(matchingTableRow);
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseOrderQuickViewPanel), findsOneWidget);

        await tester.tap(find.text('Xem đầy đủ'));
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseOrderDetailDialog), findsOneWidget);

        await tester.tap(find.text('Hoàn thành & Nhập kho'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận Hoàn thành (COMPLETE)'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog).last,
            matching: find.text('Hoàn thành'),
          ),
        );
        await tester.pumpAndSettle();

        // Tồn kho tăng 5 + 6 = 11; mở lại Quick View xác nhận phiếu đã COMPLETE bất biến
        expect(backend.stockOf(10), 11);
        await tester.tap(matchingTableRow);
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseOrderQuickViewPanel), findsOneWidget);
        expect(find.text('Sửa nháp'), findsNothing);
        expect(find.text('Xóa nháp'), findsNothing);
        expect(find.text('Hoàn thành'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'Flow B: Delete last DRAFT on page 2 steps back cleanly to page 1 without changing stock',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final seeded = List<PurchaseOrder>.generate(11, (idx) {
          final id = 11 - idx;
          return PurchaseOrder(
            purchaseOrderId: id,
            poCode: id == 1 ? 'PO-2026-PAGE2-DRAFT' : 'PO-2026-P1-${id.toString().padLeft(2, '0')}',
            supplierId: 1,
            supplierName: 'Công ty Công Nghệ ABC',
            createdByUserId: 10,
            createdByName: 'Nguyễn Văn A',
            totalCost: 15000000,
            totalItems: 1,
            status: id == 1 ? 'DRAFT' : 'COMPLETE',
            note: 'Phiếu #$id',
            createdAt: DateTime(2026, 11, 1, 8, 0).add(Duration(hours: id)),
            items: [
              PurchaseOrderItem(
                poItemId: id,
                variantId: 10,
                productId: 2,
                productName: 'Laptop Active',
                variantName: '16GB RAM',
                importPrice: 15000000,
                quantity: 1,
              ),
            ],
          );
        });

        final backend = _InMemoryPoBackend(
          initialVariantStock: 5,
          initialOrders: seeded,
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            const PurchaseOrdersScreen(),
            apiService: backend.apiService,
          ),
        );
        await tester.pumpAndSettle();

        // Trang 1 hiển thị PO-2026-P1-11, chuyển sang trang 2 để thấy PO-2026-PAGE2-DRAFT
        expect(find.text('PO-2026-P1-11'), findsOneWidget);
        expect(find.text('PO-2026-PAGE2-DRAFT'), findsNothing);

        await tester.tap(
          find.descendant(
            of: find.byType(AppPagination),
            matching: find.text('2'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PO-2026-PAGE2-DRAFT'), findsOneWidget);

        // Mở Quick View phiếu nháp duy nhất ở trang 2 (chỉ hiện Xem đầy đủ & Sửa nháp) và Xóa nháp từ cột Thao tác trên bảng
        await tester.tap(find.text('PO-2026-PAGE2-DRAFT'));
        await tester.pumpAndSettle();
        expect(find.text('Sửa nháp'), findsOneWidget);
        expect(find.text('Xóa nháp'), findsNothing);
        expect(find.text('Hoàn thành'), findsNothing);

        await tester.ensureVisible(find.byTooltip('Xóa phiếu nháp'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Xóa phiếu nháp'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận xóa phiếu nháp'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Xóa phiếu nháp'),
          ),
        );
        await tester.pumpAndSettle();

        // Xóa item cuối trang 2 -> tự động lùi về trang 1, đóng Quick View, tồn kho giữ nguyên = 5
        expect(backend.orders.any((o) => o.poCode == 'PO-2026-PAGE2-DRAFT'), isFalse);
        expect(backend.stockOf(10), 5);
        expect(find.text('PO-2026-P1-11'), findsOneWidget);
        expect(find.byType(PurchaseOrderQuickViewPlaceholder), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'Flow C: Create PO directly with COMPLETE status maps payload to COMPLETED and increments stock immediately',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final backend = _InMemoryPoBackend(
          initialVariantStock: 5,
          initialOrders: const [],
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            const PurchaseOrdersScreen(),
            apiService: backend.apiService,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tạo phiếu nhập hàng mới'));
        await tester.pumpAndSettle();

        final variantSearchField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(
            TextFormField,
            'Tìm kiếm sản phẩm hoặc biến thể...',
          ),
        );
        await tester.enterText(variantSearchField, 'Laptop');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laptop Active (16GB RAM)'));
        await tester.pumpAndSettle();

        final qtyField = find.descendant(
          of: find.byType(PurchaseOrderFormDialog),
          matching: find.widgetWithText(TextFormField, 'SL'),
        );
        await tester.enterText(qtyField, '4');
        await tester.pump();

        // Chuyển trạng thái sang COMPLETE (Hoàn thành & Nhập kho ngay)
        await tester.tap(
          find.descendant(
            of: find.byType(PurchaseOrderFormDialog),
            matching: find.text('DRAFT (Bản nháp - Lưu tạm)'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('COMPLETE (Hoàn thành & Nhập kho ngay)').last,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tạo phiếu nhập hàng'));
        await tester.pumpAndSettle();

        expect(backend.createdPayloads.length, 1);
        expect(backend.createdPayloads.first['status'], 'COMPLETED');
        expect(backend.stockOf(10), 9);
        expect(find.text('PO-2026-NEW-1'), findsOneWidget);

        // Mở Quick View: phiếu COMPLETE không có Sửa nháp / Xóa nháp / Hoàn thành
        await tester.tap(find.text('PO-2026-NEW-1'));
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseOrderQuickViewPanel), findsOneWidget);
        expect(find.text('Sửa nháp'), findsNothing);
        expect(find.text('Xóa nháp'), findsNothing);
        expect(find.text('Hoàn thành'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'Quick View hugs content when PO has 1 item and keeps action footer inside viewport',
      (tester) async {
        final compactCompletePo = PurchaseOrder(
          purchaseOrderId: 100,
          poCode: 'PO-2026-COMP-1',
          supplierId: 1,
          supplierName: 'NCC ABC',
          createdByUserId: 10,
          createdByName: 'Admin',
          totalCost: 15000000,
          totalItems: 1,
          status: 'COMPLETE',
          note: '',
          createdAt: DateTime(2026, 11, 10, 9, 30),
          items: [
            PurchaseOrderItem(
              poItemId: 199,
              variantId: 10,
              productId: 100,
              productName: 'Chuột Logitech',
              variantName: 'Đen',
              importPrice: 1500000,
              quantity: 1,
            ),
          ],
        );
        final shortPo = _samplePo(
          id: 101,
          code: 'PO-2026-SHORT-1',
          status: 'DRAFT',
          items: [_sampleItem()],
        );
        final manyItems = List<PurchaseOrderItem>.generate(
          12,
          (i) => PurchaseOrderItem(
            poItemId: 200 + i,
            variantId: 10 + i,
            productId: 100 + i,
            productName: 'Sản phẩm dài #$i',
            variantName: 'Phiên bản $i',
            importPrice: 1000000,
            quantity: 2,
          ),
        );
        final longPo = _samplePo(
          id: 102,
          code: 'PO-2026-LONG-12',
          status: 'DRAFT',
          items: manyItems,
        );

        final backend = _InMemoryPoBackend(
          initialVariantStock: 5,
          initialOrders: [compactCompletePo, shortPo, longPo],
        );

        // A. Màn hình desktop 1280x900:
        // kiểm chứng panel ít hàng co sát nội dung (< 580), không bị kéo giãn thành 580/640.
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _wrapWithProviders(
            const PurchaseOrdersScreen(),
            apiService: backend.apiService,
          ),
        );
        await tester.pumpAndSettle();

        final placeholderSize = tester.getSize(
          find.byType(PurchaseOrderQuickViewPlaceholder),
        );
        expect(placeholderSize.height, lessThanOrEqualTo(380));

        await tester.tap(find.text('PO-2026-COMP-1'));
        await tester.pumpAndSettle();

        final compactPanelSize = tester.getSize(
          find.byType(PurchaseOrderQuickViewPanel),
        );
        expect(compactPanelSize.height, lessThan(580));
        expect(
          tester.getBottomRight(find.text('Xem đầy đủ')).dy,
          lessThan(900),
        );
        expect(tester.takeException(), isNull);

        // B. Màn hình laptop thấp 1280x768:
        // phiếu DRAFT 1 dòng & 12 dòng đều nằm gọn trong viewport 768px, footer chỉ giữ Xem đầy đủ + Sửa nháp.
        tester.view.physicalSize = const Size(1280, 768);
        await tester.pumpAndSettle();

        await tester.tap(find.text('PO-2026-SHORT-1'));
        await tester.pumpAndSettle();

        final shortPanelSize = tester.getSize(
          find.byType(PurchaseOrderQuickViewPanel),
        );
        expect(shortPanelSize.height, lessThan(560));
        expect(find.text('Xóa nháp'), findsNothing);
        expect(find.text('Hoàn thành'), findsNothing);
        expect(
          tester.getBottomRight(find.byType(PurchaseOrderQuickViewPanel)).dy,
          lessThanOrEqualTo(768),
        );
        expect(
          tester.getBottomRight(find.text('Xem đầy đủ')).dy,
          lessThan(768),
        );
        expect(
          tester.getBottomRight(find.text('Sửa nháp')).dy,
          lessThan(768),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('PO-2026-LONG-12'));
        await tester.pumpAndSettle();

        final longPanelSize = tester.getSize(
          find.byType(PurchaseOrderQuickViewPanel),
        );
        expect(
          longPanelSize.height,
          greaterThanOrEqualTo(shortPanelSize.height),
        );
        expect(
          tester.getBottomRight(find.byType(PurchaseOrderQuickViewPanel)).dy,
          lessThanOrEqualTo(768),
        );
        expect(
          tester.getBottomRight(find.text('Xem đầy đủ')).dy,
          lessThan(768),
        );
        expect(
          tester.getBottomRight(find.text('Sửa nháp')).dy,
          lessThan(768),
        );
        expect(tester.takeException(), isNull);

        // C. Màn hình desktop cao 1280x1080:
        // phiếu 12 dòng mở rộng vượt trần cũ 580px (> 700px), phiếu 1 dòng vẫn co gọn sát nội dung,
        // và nút Xem đầy đủ + Sửa nháp luôn nằm trong viewport 1080px.
        tester.view.physicalSize = const Size(1280, 1080);
        await tester.pumpAndSettle();

        final longPanelSize1080 = tester.getSize(
          find.byType(PurchaseOrderQuickViewPanel),
        );
        expect(longPanelSize1080.height, greaterThan(700));
        expect(
          tester.getBottomRight(find.text('Xem đầy đủ')).dy,
          lessThan(1080),
        );
        expect(
          tester.getBottomRight(find.text('Sửa nháp')).dy,
          lessThan(1080),
        );

        await tester.tap(find.text('PO-2026-SHORT-1'));
        await tester.pumpAndSettle();

        final shortPanelSize1080 = tester.getSize(
          find.byType(PurchaseOrderQuickViewPanel),
        );
        expect(
          shortPanelSize1080.height,
          lessThan(longPanelSize1080.height - 100),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _InMemoryPoBackend {
  final List<PurchaseOrder> orders = [];
  final Map<int, int> _variantStocks = {};
  final List<Map<String, dynamic>> createdPayloads = [];
  int _nextId = 1;

  _InMemoryPoBackend({
    required int initialVariantStock,
    required List<PurchaseOrder> initialOrders,
  }) {
    _variantStocks[10] = initialVariantStock;
    orders.addAll(initialOrders);
    for (final po in orders) {
      if (po.purchaseOrderId >= _nextId) {
        _nextId = po.purchaseOrderId + 1;
      }
    }
  }

  int stockOf(int variantId) => _variantStocks[variantId] ?? 0;

  late final ApiService apiService = _FakePurchaseOrderApiService(
    onGetSuppliers: () async => _sampleSuppliers(),
    onGetProducts: () async => [
      Product(
        id: '2',
        name: 'Laptop Active',
        sku: 'SKU-2',
        category: 'Laptop',
        price: 15000000,
        status: 'In Stock',
        imageUrl: '',
        isActive: true,
        variants: [
          ProductVariant(
            variantId: 10,
            productId: 2,
            variantNameAttr: '16GB RAM',
            price: 15000000,
            stockQuantity: stockOf(10),
            isActive: true,
          ),
        ],
      ),
    ],
    onGetPaged: ({
      int page = 1,
      int pageSize = 10,
      String? status,
      int? supplierId,
      String? search,
    }) async {
      final filtered = orders.where((po) {
        final normStatus = (status ?? '').trim().toUpperCase();
        if (normStatus.isNotEmpty && normStatus != 'ALL' && normStatus != 'TẤT CẢ') {
          final targetIsComp =
              normStatus == 'COMPLETE' || normStatus == 'COMPLETED';
          if (targetIsComp) {
            if (!po.isComplete) return false;
          } else if (po.status.toUpperCase() != normStatus) {
            return false;
          }
        }
        if (supplierId != null && supplierId > 0 && po.supplierId != supplierId) {
          return false;
        }
        if (search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          final inCode = po.poCode.toLowerCase().contains(q);
          final inNote = po.note.toLowerCase().contains(q);
          final inSup = po.supplierName.toLowerCase().contains(q);
          if (!inCode && !inNote && !inSup) return false;
        }
        return true;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final start = (page - 1) * pageSize;
      final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
      final slice = start < filtered.length
          ? filtered
              .sublist(start, end)
              .map(
                (po) => PurchaseOrder(
                  purchaseOrderId: po.purchaseOrderId,
                  poCode: po.poCode,
                  supplierId: po.supplierId,
                  supplierName: po.supplierName,
                  createdByUserId: po.createdByUserId,
                  createdByName: po.createdByName,
                  totalCost: po.totalCost,
                  totalItems: po.items.length,
                  status: po.status,
                  note: po.note,
                  createdAt: po.createdAt,
                  items: const [],
                ),
              )
              .toList()
          : const <PurchaseOrder>[];

      return PurchaseOrderPagedResult(
        items: slice,
        totalCount: filtered.length,
        page: page,
        pageSize: pageSize,
      );
    },
    onGetById: (id) async {
      for (final po in orders) {
        if (po.purchaseOrderId == id) return po;
      }
      return null;
    },
    onCreate: (po) async {
      createdPayloads.add(po.toCreateJson());
      final id = _nextId++;
      final isComp = po.isComplete;
      final normalizedStatus = isComp ? 'COMPLETE' : 'DRAFT';
      final totalCost = po.items.fold<double>(0, (sum, i) => sum + i.totalPrice);
      final created = PurchaseOrder(
        purchaseOrderId: id,
        poCode: 'PO-2026-NEW-$id',
        supplierId: po.supplierId,
        supplierName: _sampleSuppliers()
            .firstWhere(
              (s) => int.tryParse(s.id) == po.supplierId,
              orElse: () => _sampleSuppliers().first,
            )
            .name,
        createdByUserId: 1,
        createdByName: 'Admin',
        totalCost: totalCost,
        totalItems: po.items.length,
        status: normalizedStatus,
        note: po.note,
        createdAt: DateTime(2026, 11, 14, 12, 0).add(Duration(minutes: id)),
        items: po.items,
      );
      orders.add(created);
      if (isComp) {
        for (final item in po.items) {
          _variantStocks[item.variantId] =
              (_variantStocks[item.variantId] ?? 0) + item.quantity;
        }
      }
      return ApiResult(success: true, message: 'Tạo phiếu nhập thành công');
    },
    onUpdate: (id, po) async {
      final idx = orders.indexWhere((o) => o.purchaseOrderId == id);
      if (idx == -1) {
        return ApiResult(success: false, message: 'Không tìm thấy phiếu nhập');
      }
      final existing = orders[idx];
      if (!existing.isDraft) {
        return ApiResult(
          success: false,
          message: 'Phiếu nhập đã hoàn thành, không được chỉnh sửa',
        );
      }
      final isComp = po.isComplete;
      final totalCost = po.items.fold<double>(0, (sum, i) => sum + i.totalPrice);
      orders[idx] = PurchaseOrder(
        purchaseOrderId: existing.purchaseOrderId,
        poCode: existing.poCode,
        supplierId: po.supplierId,
        supplierName: existing.supplierName,
        createdByUserId: existing.createdByUserId,
        createdByName: existing.createdByName,
        totalCost: totalCost,
        totalItems: po.items.length,
        status: isComp ? 'COMPLETE' : 'DRAFT',
        note: po.note,
        createdAt: existing.createdAt,
        items: po.items,
      );
      if (isComp) {
        for (final item in po.items) {
          _variantStocks[item.variantId] =
              (_variantStocks[item.variantId] ?? 0) + item.quantity;
        }
      }
      return ApiResult(success: true, message: 'Cập nhật phiếu nhập thành công');
    },
    onDelete: (id) async {
      final idx = orders.indexWhere((o) => o.purchaseOrderId == id);
      if (idx == -1) {
        return ApiResult(success: false, message: 'Không tìm thấy phiếu nhập');
      }
      if (!orders[idx].isDraft) {
        return ApiResult(success: false, message: 'Chỉ được phép xóa bản nháp');
      }
      orders.removeAt(idx);
      return ApiResult(success: true, message: 'Xóa phiếu nhập thành công');
    },
  );
}
