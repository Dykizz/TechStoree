import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/order.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'Tất cả';
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 8;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final bgSubtle = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return FutureBuilder<List<Order>>(
      future: apiService.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var orders = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((o) =>
            o.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.customerEmail.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        if (_selectedStatus != 'Tất cả') {
          orders = orders.where((o) => o.status == _selectedStatus).toList();
        }

        final totalItems = orders.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedOrders = totalItems == 0
            ? <Order>[]
            : orders.skip(startIndex).take(_itemsPerPage).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Quản lý Đơn hàng',
                subtitle: 'Theo dõi, xử lý và cập nhật trạng thái đơn hàng của khách hàng TechStoree',
              ),

              // Filter Controls Bar
              FilterBar(
                searchField: AppSearchField<Order>(
                  controller: _searchCtrl,
                  hintText: 'Tìm kiếm mã đơn, tên khách hàng, email...',
                  items: snapshot.data ?? [],
                  searchFilter: (o, q) => o.orderNumber.toLowerCase().contains(q.toLowerCase()) ||
                      o.customerName.toLowerCase().contains(q.toLowerCase()) ||
                      o.customerEmail.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (o) => '#${o.orderNumber} - ${o.customerName}',
                  itemSubtitle: (o) => '${currencyFormat.format(o.totalAmount)} • ${o.status}',
                  onSelected: (o) => setState(() => _searchQuery = o.orderNumber),
                  onSubmitted: (val) => setState(() => _searchQuery = val),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
                filters: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tất cả', 'Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled']
                          .map((status) {
                        final isSelected = _selectedStatus == status;
                        String label = status;
                        if (status == 'Pending') label = 'Chờ xử lý';
                        if (status == 'Processing') label = 'Đang xử lý';
                        if (status == 'Shipped') label = 'Vận chuyển';
                        if (status == 'Completed') label = 'Hoàn thành';
                        if (status == 'Cancelled') label = 'Đã hủy';

                        return Padding(
                          padding: const EdgeInsets.only(right: AppTokens.space8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: bgSubtle,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                            ),
                            onSelected: (_) => setState(() {
                              _selectedStatus = status;
                              _currentPage = 1;
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              // Orders List Table Container
              Flexible(
                fit: FlexFit.loose,
                child: orders.isEmpty
                    ? const DataTableContainer(
                        child: EmptyState(
                          title: 'Chưa có đơn hàng nào',
                          message: 'Không tìm thấy đơn hàng thuộc trạng thái đã chọn.',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      )
                    : DataTableContainer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: DataTable(
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 42,
                                      dataRowMaxHeight: 42,
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Mã đơn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                        DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                                      ],
                                      rows: paginatedOrders.map((order) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(
                                              Text(
                                                order.orderNumber,
                                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                                              ),
                                            ),
                                            DataCell(
                                              Text(order.customerName, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                                            ),
                                            DataCell(
                                              Text(order.customerEmail, style: TextStyle(color: textSecondary, fontSize: 11)),
                                            ),
                                            DataCell(
                                              Text(dateFormat.format(order.createdAt), style: TextStyle(color: textSecondary, fontSize: 11)),
                                            ),
                                            DataCell(
                                              Text(
                                                currencyFormat.format(order.totalAmount),
                                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                              ),
                                            ),
                                            DataCell(_renderBadge(order.status)),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (totalItems > 0)
                              AppPagination(
                                currentPage: safePage,
                                totalPages: totalPages,
                                totalItems: totalItems,
                                itemsPerPage: _itemsPerPage,
                                onPageChanged: (page) => setState(() => _currentPage = page),
                                onItemsPerPageChanged: (items) {
                                  setState(() {
                                    _itemsPerPage = items;
                                    _currentPage = 1;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _renderBadge(String status) {
    switch (status) {
      case 'Completed':
        return const StatusBadge(label: 'Hoàn thành', isSuccess: true);
      case 'Processing':
        return const StatusBadge(label: 'Đang xử lý', isInfo: true);
      case 'Shipped':
        return const StatusBadge(label: 'Đã giao vận chuyển', isInfo: true);
      case 'Pending':
        return const StatusBadge(label: 'Chờ xử lý', isWarning: true);
      default:
        return const StatusBadge(label: 'Đã hủy', isDanger: true);
    }
  }
}
