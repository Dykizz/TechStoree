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
    final roles = authProvider.userRoles;
    final isAdmin = roles.contains('ADMIN') || authProvider.userRole == 'ADMIN';
    if (isAdmin) return true;

    final isWarehouse = roles.contains('WAREHOUSE_STAFF') || authProvider.userRole == 'WAREHOUSE_STAFF';
    final isSales = roles.contains('SALES_STAFF') || authProvider.userRole == 'SALES_STAFF';
    final isSurvey = roles.contains('SURVEY_STAFF') || authProvider.userRole == 'SURVEY_STAFF';

    switch (index) {
      case 0: return true; // Tổng quan
      case 1: return authProvider.can('Products.View') || isWarehouse || isSales; // Sản phẩm
      case 2: return authProvider.can('Orders.View') || isSales; // Đơn hàng
      case 3: return authProvider.can('Orders.View') || isSales; // Hóa đơn
      case 4: return authProvider.can('Categories.View') || isWarehouse; // Danh mục
      case 5: return authProvider.can('Suppliers.View') || isWarehouse; // Nhà cung cấp
      case 6: return authProvider.can('PurchaseOrders.View') || isWarehouse; // Phiếu nhập hàng
      case 7: return authProvider.can('Promotions.View') || isSales; // Khuyến mãi
      case 8: return authProvider.can('Vouchers.View') || isSales; // Vouchers
      case 9: return authProvider.can('Surveys.View') || isSurvey; // Khảo sát
      case 10: return authProvider.can('Users.View') || isSales || isSurvey; // Khách hàng
      case 11: return authProvider.can('Users.View') || isAdmin; // Nhân viên
      case 12: return authProvider.can('Roles.View'); // Vai trò & Phân quyền
      case 13: return false; // Cài đặt (Admin only)
      default: return false;
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

    final screens = const [
      DashboardScreen(),
      ProductsScreen(),
      OrdersScreen(),
      InvoicesScreen(),
      CategoriesScreen(),
      SuppliersScreen(),
      PurchaseOrdersScreen(),
      PromotionsScreen(),
      VouchersScreen(),
      SurveysScreen(),
      CustomersScreen(),
      StaffScreen(),
      RolesScreen(),
      SettingsScreen(),
    ];

    final rawIndex = navProvider.currentIndex;
    final hasPermission = _hasPermissionForRoute(rawIndex, authProvider);

    if (!hasPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setIndex(0);
      });
    }

    final currentIndex = (hasPermission && rawIndex < screens.length) ? rawIndex : 0;
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

                // Screen View Body
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: screens,
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

