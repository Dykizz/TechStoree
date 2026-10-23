import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import 'app_sidebar.dart';
import 'app_topbar.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/invoices/invoices_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../features/purchase_orders/purchase_orders_screen.dart';
import '../../features/promotions/promotions_screen.dart';
import '../../features/vouchers/vouchers_screen.dart';
import '../../features/surveys/surveys_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/staff/staff_screen.dart';
import '../../features/roles/roles_screen.dart';
import '../../features/settings/settings_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  bool _hasPermissionForRoute(int index, AuthProvider authProvider) {
    if (authProvider.isAdmin) return true;

    switch (index) {
      case 0: return true; // Tổng quan
      case 1: return authProvider.can('Products.View'); // Sản phẩm
      case 2: return authProvider.can('Orders.View'); // Đơn hàng
      case 3: return authProvider.can('Invoices.View'); // Hóa đơn
      case 4: return authProvider.can('Categories.View'); // Danh mục
      case 5: return authProvider.can('Suppliers.View'); // Nhà cung cấp
      case 6: return authProvider.can('PurchaseOrders.View'); // Phiếu nhập hàng
      case 7: return authProvider.can('Promotions.View'); // Khuyến mãi
      case 8: return authProvider.can('Vouchers.View'); // Vouchers
      case 9: return authProvider.can('Surveys.View'); // Khảo sát
      case 10: return authProvider.can('Customers.View') || authProvider.can('Users.View'); // Khách hàng
      case 11: return authProvider.can('Employees.View') || authProvider.can('Users.View'); // Nhân viên
      case 12: return authProvider.can('Roles.View'); // Vai trò & Phân quyền
      case 13: return false; // Cài đặt (Admin only)
      default: return false;
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProductsScreen();
      case 2:
        return const OrdersScreen();
      case 3:
        return const InvoicesScreen();
      case 4:
        return const CategoriesScreen();
      case 5:
        return const SuppliersScreen();
      case 6:
        return const PurchaseOrdersScreen();
      case 7:
        return const PromotionsScreen();
      case 8:
        return const VouchersScreen();
      case 9:
        return const SurveysScreen();
      case 10:
        return const CustomersScreen();
      case 11:
        return const StaffScreen();
      case 12:
        return const RolesScreen();
      case 13:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final titles = [
      'Tổng quan',
      'Sản phẩm',
      'Đơn hàng',
      'Hóa đơn',
      'Loại sản phẩm',
      'Nhà cung cấp',
      'Phiếu nhập hàng',
      'Khuyến mãi & Giảm giá',
      'Mã giảm giá Voucher',
      'Khảo sát thị trường',
      'Khách hàng',
      'Nhân viên',
      'Vai Trò & Phân Quyền',
      'Cài đặt hệ thống',
    ];

    final rawIndex = navProvider.currentIndex;
    final hasPermission = _hasPermissionForRoute(rawIndex, authProvider);

    if (!hasPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navProvider.currentIndex != 0) {
          navProvider.setIndex(0);
        }
      });
    }

    final currentIndex = (hasPermission && rawIndex < titles.length) ? rawIndex : 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 850;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: isCompact ? const Drawer(child: AppSidebar()) : null,
      body: Row(
        children: [
          // Sidebar Navigation (Desktop / Wide Window)
          if (!isCompact) const AppSidebar(),

          // Main Content Region
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                AppTopbar(title: titles[currentIndex]),

                // Screen View Body - re-queries and refreshes every time when navigating or refreshed
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('screen_${currentIndex}_${navProvider.refreshKey}'),
                    child: _buildScreen(currentIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

