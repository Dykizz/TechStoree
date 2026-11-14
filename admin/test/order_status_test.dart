import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/core/constants/order_status.dart';
import 'package:techstore_admin/core/models/order.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/widgets/order_status_badge.dart';
import 'package:techstore_admin/features/orders/widgets/order_status_tabs.dart';

Order _sampleOrder(String status) {
  return Order(
    orderId: 1,
    orderCode: 'ORD-20261114-0001',
    userId: 1,
    receiverName: 'Nguyễn Văn A',
    receiverPhone: '0901234567',
    shippingAddress: 'Hà Nội',
    orderStatus: status,
    paymentMethod: 'COD',
    paymentStatus: 'PENDING',
    subtotalAmount: 1000000,
    totalAmount: 1000000,
  );
}

void main() {
  test('OrderStatusCatalog and Order.orderStatusDisplay expose unified labels', () {
    const expected = <String, String>{
      'PENDING': 'Chờ xử lý',
      'CONFIRMED': 'Đã xác nhận',
      'SHIPPING': 'Đang vận chuyển',
      'DELIVERED': 'Đã giao hàng',
      'RETURNED': 'Hoàn hàng',
      'CANCELLED': 'Đã hủy',
    };

    expected.forEach((code, label) {
      expect(OrderStatusCatalog.labelOf(code), label);
      expect(OrderStatusCatalog.labelOf(code.toLowerCase()), label);
      expect(_sampleOrder(code).orderStatusDisplay, label);
    });

    expect(OrderStatusCatalog.labelOf('CUSTOM_UNKNOWN'), 'CUSTOM_UNKNOWN');

    final tabs = OrderStatusCatalog.buildFilterTabs();
    expect(
      tabs.map((t) => '${t['key']}:${t['label']}').toList(),
      [
        'ALL:Tất cả',
        'PENDING:Chờ xử lý',
        'CONFIRMED:Đã xác nhận',
        'SHIPPING:Đang vận chuyển',
        'DELIVERED:Đã giao hàng',
        'RETURNED:Hoàn hàng',
        'CANCELLED:Đã hủy',
      ],
    );
  });

  testWidgets('OrderStatusBadge and OrderStatusTabs render canonical status labels', (tester) async {
    final tabs = OrderStatusCatalog.buildFilterTabs();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderStatusTabs(
                  tabs: tabs,
                  selectedStatus: 'SHIPPING',
                  statusCounts: const {
                    'ALL': 6,
                    'PENDING': 1,
                    'CONFIRMED': 1,
                    'SHIPPING': 1,
                    'DELIVERED': 1,
                    'RETURNED': 1,
                    'CANCELLED': 1,
                  },
                  onStatusSelected: (_) {},
                ),
                const Wrap(
                  spacing: 8,
                  children: [
                    OrderStatusBadge(status: 'PENDING'),
                    OrderStatusBadge(status: 'CONFIRMED'),
                    OrderStatusBadge(status: 'SHIPPING'),
                    OrderStatusBadge(status: 'DELIVERED'),
                    OrderStatusBadge(status: 'RETURNED'),
                    OrderStatusBadge(status: 'CANCELLED'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đang vận chuyển'), findsNWidgets(2));
    expect(find.text('Đã giao hàng'), findsNWidgets(2));
    expect(find.text('Chờ xử lý'), findsNWidgets(2));
    expect(find.text('Đã xác nhận'), findsNWidgets(2));
    expect(find.text('Hoàn hàng'), findsNWidgets(2));
    expect(find.text('Đã hủy'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

