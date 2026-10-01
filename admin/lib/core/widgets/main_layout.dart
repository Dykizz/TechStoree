import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
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
import '../../features/users/users_screen.dart';
import '../../features/settings/settings_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final titles = [
      'Tổng Quan Báo Cáo',
      'Quản Lý Sản Phẩm',
      'Quản Lý Đơn Hàng',
      'Danh Mục Sản Phẩm',
      'Quản Lý Nhà Cung Cấp',
      'Quản Lý Phiếu Nhập Hàng',
      'Khuyến Mãi & Giảm Giá',
      'Quản Lý Người Dùng',
      'Cài Đặt Hệ Thống',
    ];

    final screens = const [
      DashboardScreen(),
      ProductsScreen(),
      OrdersScreen(),
      CategoriesScreen(),
      SuppliersScreen(),
      PurchaseOrdersScreen(),
      PromotionsScreen(),
      UsersScreen(),
      SettingsScreen(),
    ];

    final currentIndex = navProvider.currentIndex < screens.length ? navProvider.currentIndex : 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 850;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: isCompact ? const Drawer(child: AppSidebar()) : null,
      body: Row(
        children: [
          // Sidebar Navigation (Desktop / Wide Window)
          if (!isCompact) const AppSidebar(),

          // Main Screen Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                AppTopbar(title: titles[currentIndex]),

                // Content View
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
