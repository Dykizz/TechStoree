import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/models/invoice.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/navigation_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';
import 'package:techstore_admin/features/invoices/invoices_screen.dart';
import 'package:techstore_admin/features/invoices/widgets/invoice_detail_dialog.dart';

void main() {
  group('Invoice Model Tests', () {
    test('Invoice.fromJson should parse correctly', () {
      final json = {
        'invoiceId': 10,
        'invoiceCode': 'INV-TEST-001',
        'orderId': 25,
        'orderCode': 'ORD-TEST-001',
        'userId': 5,
        'customerName': 'Nguyễn Văn Test',
        'totalAmount': 15000000.0,
        'status': 'PAID',
        'paymentMethod': 'VNPAY',
        'paidAt': '2026-10-18T10:00:00.000Z',
        'createdAt': '2026-10-18T09:30:00.000Z',
        'note': 'Hóa đơn mẫu kiểm thử',
      };

      final invoice = Invoice.fromJson(json);

      expect(invoice.invoiceId, 10);
      expect(invoice.invoiceCode, 'INV-TEST-001');
      expect(invoice.orderId, 25);
      expect(invoice.orderCode, 'ORD-TEST-001');
      expect(invoice.userId, 5);
      expect(invoice.customerName, 'Nguyễn Văn Test');
      expect(invoice.totalAmount, 15000000.0);
      expect(invoice.status, 'PAID');
      expect(invoice.paymentMethod, 'VNPAY');
      expect(invoice.isPaid, isTrue);
      expect(invoice.isUnpaid, isFalse);
      expect(invoice.isCancelled, isFalse);
      expect(invoice.statusLabel, 'Đã thanh toán');
      expect(invoice.paymentMethodLabel, 'Cổng VNPay');
      expect(invoice.note, 'Hóa đơn mẫu kiểm thử');
    });

    test('Invoice.toJson should serialize correctly', () {
      final invoice = Invoice(
        invoiceId: 1,
        invoiceCode: 'INV-001',
        orderId: 2,
        orderCode: 'ORD-002',
        userId: 3,
        customerName: 'Trần Thị A',
        totalAmount: 500000.0,
        status: 'UNPAID',
        paymentMethod: 'COD',
        createdAt: DateTime(2026, 10, 18, 12, 0),
        note: 'Giao hàng buổi sáng',
      );

      final json = invoice.toJson();

      expect(json['invoiceId'], 1);
      expect(json['invoiceCode'], 'INV-001');
      expect(json['status'], 'UNPAID');
      expect(invoice.isUnpaid, isTrue);
      expect(invoice.statusLabel, 'Chờ thanh toán');
      expect(invoice.paymentMethodLabel, 'Thanh toán COD');
    });

    test('Invoice.getSampleInvoices provides rich sample data', () {
      final samples = Invoice.getSampleInvoices();
      expect(samples.isNotEmpty, isTrue);
      expect(samples.any((i) => i.isPaid), isTrue);
      expect(samples.any((i) => i.isUnpaid), isTrue);
      expect(samples.any((i) => i.isCancelled), isTrue);
    });
  });

  group('InvoiceApiService Tests', () {
    test('getAllInvoices fallback returns filtered sample invoices', () async {
      final apiService = ApiService();

      // Test status filter
      final paidResult = await apiService.getAllInvoices(status: 'PAID');
      expect(paidResult.items.isNotEmpty, isTrue);
      expect(paidResult.items.every((i) => i.isPaid), isTrue);

      // Test search filter
      final searchResult = await apiService.getAllInvoices(search: 'Trần Thị Bình');
      expect(searchResult.items.length, 1);
      expect(searchResult.items.first.customerName, 'Trần Thị Bình');

      // Test paymentMethod filter
      final codResult = await apiService.getAllInvoices(paymentMethod: 'COD');
      expect(codResult.items.isNotEmpty, isTrue);
      expect(codResult.items.every((i) => i.paymentMethod == 'COD'), isTrue);
    });

    test('getInvoiceById and getInvoiceByOrderId fallback tests', () async {
      final apiService = ApiService();

      final inv = await apiService.getInvoiceById(1);
      expect(inv, isNotNull);
      expect(inv!.invoiceId, 1);

      final invByOrder = await apiService.getInvoiceByOrderId(2);
      expect(invByOrder, isNotNull);
      expect(invByOrder!.orderId, 2);
    });
  });

  group('Invoice UI Widget Tests', () {
    testWidgets('InvoiceDetailDialog renders receipt correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final invoice = Invoice.getSampleInvoices().first;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InvoiceDetailDialog(invoice: invoice),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Chi tiết hóa đơn bán hàng'), findsOneWidget);
      expect(find.text(invoice.invoiceCode), findsWidgets);
      expect(find.text('TechStoree Vietnam'), findsOneWidget);
      expect(find.text(invoice.customerName), findsOneWidget);
      expect(find.text('In hóa đơn / Xuất PDF'), findsOneWidget);
    });

    testWidgets('InvoicesScreen renders table and metric cards', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InvoicesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quản lý Hóa đơn'), findsOneWidget);
      expect(find.text('TỔNG HÓA ĐƠN'), findsOneWidget);
      expect(find.text('ĐÃ THANH TOÁN'), findsOneWidget);
      expect(find.text('CHỜ THANH TOÁN'), findsOneWidget);
      expect(find.text('ĐÃ HỦY'), findsOneWidget);
      expect(find.text('MÃ HÓA ĐƠN'), findsOneWidget);
      expect(find.text('ĐƠN HÀNG'), findsOneWidget);
      expect(find.text('KHÁCH HÀNG'), findsOneWidget);
    });
  });
}
