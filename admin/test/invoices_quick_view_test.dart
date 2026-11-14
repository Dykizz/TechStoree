import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/models/invoice.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/features/invoices/invoices_screen.dart';
import 'package:techstore_admin/features/invoices/widgets/invoice_quick_view_panel.dart';

class _FakeInvoiceApiService extends ApiService {
  final List<Invoice> invoices;

  _FakeInvoiceApiService(this.invoices);

  @override
  Future<({
    List<Invoice> items,
    int page,
    int pageSize,
    int totalItems,
    int totalPages,
    bool hasPreviousPage,
    bool hasNextPage,
  })> getAllInvoices({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    String? search,
    String? advancedQuery,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    bool isAscending = false,
    String? token,
  }) async {
    return (
      items: invoices,
      page: 1,
      pageSize: pageSize,
      totalItems: invoices.length,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  @override
  Future<InvoiceStatistics?> getInvoiceStatistics({String? token}) async {
    return const InvoiceStatistics();
  }
}

Invoice _sampleInvoice({
  required int id,
  required String code,
  required int itemCount,
}) {
  final items = List<InvoiceItem>.generate(
    itemCount,
    (idx) => InvoiceItem(
      orderItemId: id * 100 + idx,
      productName: 'Laptop Demo #$idx',
      variantName: '16GB / 512GB',
      imageUrl: '',
      unitPrice: 15000000,
      quantity: 1,
      totalPrice: 15000000,
    ),
  );

  return Invoice(
    invoiceId: id,
    invoiceCode: code,
    orderId: id,
    orderCode: 'ORD-20261114-00$id',
    userId: 1,
    customerName: 'Nguyễn Văn A',
    totalAmount: 15000000.0 * itemCount,
    status: 'PAID',
    paymentMethod: 'COD',
    createdAt: DateTime(2026, 11, 14, 10, id),
    receiverPhone: '0901234567',
    shippingAddress: 'TP.HCM',
    subtotalAmount: 15000000.0 * itemCount,
    items: items,
  );
}

void main() {
  testWidgets(
    'InvoicesScreen Quick View hugs short content, caps tall content, and keeps footer inside viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final shortInv = _sampleInvoice(
        id: 1,
        code: 'INV-ORD-SHORT-1',
        itemCount: 1,
      );
      final longInv = _sampleInvoice(
        id: 2,
        code: 'INV-ORD-LONG-12',
        itemCount: 12,
      );

      final api = _FakeInvoiceApiService([shortInv, longInv]);
      final auth = AuthProvider()..updatePermissions(const ['Invoices.View']);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ApiService>.value(value: api),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox.expand(child: InvoicesScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Placeholder không bị ép cao 640px
      final placeholderSize = tester.getSize(
        find.byType(InvoiceQuickViewPlaceholder),
      );
      expect(placeholderSize.height, lessThanOrEqualTo(380));

      // 1. Màn hình thấp 1280x768 -> cả hóa đơn ngắn và dài đều giữ nút footer nằm gọn trong viewport 768px
      await tester.tap(find.text('INV-ORD-SHORT-1'));
      await tester.pumpAndSettle();

      final shortPanelSize = tester.getSize(find.byType(InvoiceQuickViewPanel));
      expect(
        tester.getBottomRight(find.byType(InvoiceQuickViewPanel)).dy,
        lessThanOrEqualTo(768),
      );
      expect(
        tester.getBottomRight(find.text('Xem đầy đủ')).dy,
        lessThan(768),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('INV-ORD-LONG-12'));
      await tester.pumpAndSettle();

      final longPanelSize768 = tester.getSize(
        find.byType(InvoiceQuickViewPanel),
      );
      expect(
        longPanelSize768.height,
        greaterThanOrEqualTo(shortPanelSize.height),
      );
      expect(
        tester.getBottomRight(find.byType(InvoiceQuickViewPanel)).dy,
        lessThanOrEqualTo(768),
      );
      expect(
        tester.getBottomRight(find.text('In HĐ')).dy,
        lessThan(768),
      );
      expect(tester.takeException(), isNull);

      // 2. Màn hình desktop cao (1280x1080) -> hóa đơn dài mở rộng vượt trần cũ 560px để tận dụng chiều cao,
      // trong khi hóa đơn 1 mặt hàng tự co gọn sát nội dung (< dài ít nhất 100px)
      tester.view.physicalSize = const Size(1280, 1080);
      await tester.pumpAndSettle();

      final longPanelSize1080 = tester.getSize(
        find.byType(InvoiceQuickViewPanel),
      );
      expect(longPanelSize1080.height, greaterThan(700));
      expect(
        tester.getBottomRight(find.text('Xem đầy đủ')).dy,
        lessThan(1080),
      );
      expect(
        tester.getBottomRight(find.text('In HĐ')).dy,
        lessThan(1080),
      );

      await tester.tap(find.text('INV-ORD-SHORT-1'));
      await tester.pumpAndSettle();

      final shortPanelSize1080 = tester.getSize(
        find.byType(InvoiceQuickViewPanel),
      );
      expect(
        shortPanelSize1080.height,
        lessThan(longPanelSize1080.height - 100),
      );
      expect(shortPanelSize1080.height, lessThan(650));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'InvoicesScreen Quick View expands smoothly when scrolling down a tall table',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final invoices = <Invoice>[
        _sampleInvoice(id: 1, code: 'INV-ORD-TALL-LONG', itemCount: 12),
        for (int i = 2; i <= 10; i++)
          _sampleInvoice(id: i, code: 'INV-ORD-ROW-$i', itemCount: 1),
      ];

      final api = _FakeInvoiceApiService(invoices);
      final auth = AuthProvider()..updatePermissions(const ['Invoices.View']);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ApiService>.value(value: api),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox.expand(child: InvoicesScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('INV-ORD-TALL-LONG'));
      await tester.pumpAndSettle();

      final heightBeforeScroll = tester
          .getSize(find.byType(InvoiceQuickViewPanel))
          .height;

      final outerScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(outerScroll, const Offset(0, -180));
      await tester.pumpAndSettle();

      final heightAfterScroll = tester
          .getSize(find.byType(InvoiceQuickViewPanel))
          .height;

      expect(heightAfterScroll, greaterThan(heightBeforeScroll));
      expect(
        tester.getBottomRight(find.text('Xem đầy đủ')).dy,
        lessThan(768),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

