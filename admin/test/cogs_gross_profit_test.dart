import 'package:flutter_test/flutter_test.dart';
import 'package:techstore_admin/core/models/order.dart';
import 'package:techstore_admin/core/models/product.dart';
import 'package:techstore_admin/core/models/purchase_order.dart';
import 'package:techstore_admin/features/statistics/models/statistics_models.dart';
import 'package:techstore_admin/features/statistics/services/statistics_service.dart';

void main() {
  test('ProductVariant parses costPrice and lastImportPrice without exposing in toJson', () {
    final variant = ProductVariant.fromJson({
      'variantId': 19,
      'productId': 14,
      'variantName': '256GB',
      'price': 64990000,
      'costPrice': 52000000,
      'lastImportPrice': 51500000,
      'stockQuantity': 15,
    });

    expect(variant.price, 64990000);
    expect(variant.costPrice, 52000000);
    expect(variant.lastImportPrice, 51500000);
    expect(variant.toJson().containsKey('costPrice'), isFalse);
  });

  test('Order computes effectiveTotalCost and grossProfit from totalCostPrice or item snapshots', () {
    final fromBaseDto = Order.fromJson({
      'orderId': 1,
      'orderCode': 'ORD-01',
      'userId': 2,
      'receiverName': 'Nguyen Van A',
      'receiverPhone': '0900000001',
      'shippingAddress': 'HCM',
      'orderStatus': 'DELIVERED',
      'paymentMethod': 'COD',
      'paymentStatus': 'PAID',
      'subtotalAmount': 25000000,
      'voucherDiscountAmount': 1000000,
      'totalAmount': 24000000,
      'totalCostPrice': 18500000,
    });

    expect(fromBaseDto.effectiveTotalCost, 18500000);
    expect(fromBaseDto.grossProfit, 5500000);

    final fromDetailDto = Order.fromJson({
      'orderId': 2,
      'orderCode': 'ORD-02',
      'userId': 2,
      'receiverName': 'Nguyen Van B',
      'receiverPhone': '0900000002',
      'shippingAddress': 'HN',
      'orderStatus': 'CONFIRMED',
      'paymentMethod': 'VNPAY',
      'paymentStatus': 'PAID',
      'subtotalAmount': 10000000,
      'totalAmount': 10000000,
      'items': [
        {
          'orderItemId': 10,
          'orderId': 2,
          'variantId': 4,
          'productName': 'Sony WH-1000XM5',
          'variantName': 'Den',
          'originalPrice': 6000000,
          'unitPrice': 5000000,
          'costPrice': 3600000,
          'quantity': 2,
          'totalPrice': 10000000,
        },
      ],
    });

    expect(fromDetailDto.items.first.costPrice, 3600000);
    expect(fromDetailDto.items.first.totalCost, 7200000);
    expect(fromDetailDto.items.first.grossProfit, 2800000);
    expect(fromDetailDto.effectiveTotalCost, 7200000);
    expect(fromDetailDto.grossProfit, 2800000);
  });

  test('StatisticsService separates COGS/GrossProfit from PO cashflow and excludes CANCELLED & RETURNED', () {
    final dataset = StatisticsDataset(
      orders: [
        // Đơn hợp lệ Q1: Doanh thu 20M, COGS 14M -> Lãi gộp 6M
        Order(
          orderId: 1,
          orderCode: 'ORD-1',
          userId: 1,
          receiverName: 'A',
          receiverPhone: '0901',
          shippingAddress: 'HCM',
          orderStatus: 'DELIVERED',
          paymentMethod: 'COD',
          paymentStatus: 'PAID',
          subtotalAmount: 20000000,
          totalAmount: 20000000,
          totalCostPrice: 14000000,
          createdAt: DateTime(2026, 2, 10),
        ),
        // Đơn đã hủy Q1 -> Bị loại
        Order(
          orderId: 2,
          orderCode: 'ORD-2',
          userId: 1,
          receiverName: 'B',
          receiverPhone: '0902',
          shippingAddress: 'HCM',
          orderStatus: 'CANCELLED',
          paymentMethod: 'COD',
          paymentStatus: 'PENDING',
          subtotalAmount: 50000000,
          totalAmount: 50000000,
          totalCostPrice: 35000000,
          createdAt: DateTime(2026, 2, 12),
        ),
        // Đơn hoàn hàng Q1 -> Bị loại
        Order(
          orderId: 3,
          orderCode: 'ORD-3',
          userId: 1,
          receiverName: 'C',
          receiverPhone: '0903',
          shippingAddress: 'HCM',
          orderStatus: 'RETURNED',
          paymentMethod: 'VNPAY',
          paymentStatus: 'REFUNDED',
          subtotalAmount: 10000000,
          totalAmount: 10000000,
          totalCostPrice: 7000000,
          createdAt: DateTime(2026, 2, 15),
        ),
      ],
      purchaseOrders: [
        // PO COMPLETED Q1: chi 100M nhập tồn kho
        PurchaseOrder(
          purchaseOrderId: 1,
          poCode: 'PO-1',
          supplierId: 1,
          totalCost: 100000000,
          totalItems: 1,
          status: 'COMPLETED',
          createdAt: DateTime(2026, 1, 5),
        ),
        // PO DRAFT Q1: không tính chi phí nhập kho
        PurchaseOrder(
          purchaseOrderId: 2,
          poCode: 'PO-2',
          supplierId: 1,
          totalCost: 30000000,
          totalItems: 1,
          status: 'DRAFT',
          createdAt: DateTime(2026, 1, 6),
        ),
      ],
      products: const [],
      staffList: const [],
      availableYears: const [2026],
    );

    final matrix = StatisticsService.calculateFinancialMatrix(dataset: dataset, year: 2026);
    expect(matrix.length, 4);

    final revRow = matrix.firstWhere((r) => r.metricType == FinancialMetricType.revenue);
    final cogsRow = matrix.firstWhere((r) => r.metricType == FinancialMetricType.cogs);
    final profitRow = matrix.firstWhere((r) => r.metricType == FinancialMetricType.grossProfit);
    final importRow = matrix.firstWhere((r) => r.metricType == FinancialMetricType.importCost);

    expect(revRow.q1, 20000000);
    expect(cogsRow.q1, 14000000);
    expect(profitRow.q1, 6000000); // 20M - 14M (không bị âm 80M do nhập kho 100M)
    expect(importRow.q1, 100000000); // Chỉ tính PO COMPLETED

    final kpi = StatisticsService.calculateFinancialSummaryKpi(dataset: dataset, year: 2026);
    expect(kpi.totalRevenue, 20000000);
    expect(kpi.totalExpense, 14000000);
    expect(kpi.totalImportCost, 100000000);
    expect(kpi.netProfit, 6000000);
    expect(kpi.profitMargin, closeTo(30.0, 0.001));
  });
}
