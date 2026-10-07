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
import '../../features/categories/categories_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../features/purchase_orders/purchase_orders_screen.dart';
import '../../features/promotions/promotions_screen.dart';
import '../../features/vouchers/vouchers_screen.dart';
import '../../features/surveys/surveys_screen.dart';
import '../../features/users/users_screen.dart';
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
      case 1: return isWarehouse || isSales; // Sản phẩm
      case 2: return isSales; // Đơn hàng
      case 3: return isWarehouse; // Danh mục
      case 4: return isWarehouse; // Nhà cung cấp
      case 5: return isWarehouse; // Phiếu nhập hàng
      case 6: return isSales; // Khuyến mãi
      case 7: return isSales; // Vouchers
      case 8: return isSurvey; // Khảo sát
      case 9: return isSales || isSurvey; // Khách hàng / Users
      case 10: return false; // Cài đặt (Admin only)
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
      'Danh mục',
      'Nhà cung cấp',
      'Phiếu nhập hàng',
      'Khuyến mãi & Giảm giá',
      'Mã giảm giá Voucher',
      'Khảo sát thị trường',
      'Khách hàng / User',
      'Cài đặt hệ thống',
    ];

    final screens = const [
      DashboardScreen(),
      ProductsScreen(),
      OrdersScreen(),
      CategoriesScreen(),
      SuppliersScreen(),
      PurchaseOrdersScreen(),
      PromotionsScreen(),
      VouchersScreen(),
      SurveysScreen(),
      UsersScreen(),
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

