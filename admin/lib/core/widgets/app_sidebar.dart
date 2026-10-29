import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkSidebar : AppColors.lightSidebar;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isAdmin = authProvider.isAdmin;

    final allNavItems = [
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Tổng quan', index: 0),
      _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Sản phẩm', index: 1),
      _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Đơn hàng', index: 2),
      _NavItem(icon: Icons.receipt_outlined, activeIcon: Icons.receipt_rounded, label: 'Hóa đơn', index: 3),
      _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category_rounded, label: 'Loại sản phẩm', index: 4),
      _NavItem(icon: Icons.domain_outlined, activeIcon: Icons.domain_rounded, label: 'Nhà cung cấp', index: 5),
      _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Phiếu nhập hàng', index: 6),
      _NavItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer_rounded, label: 'Khuyến mãi & giảm giá', index: 7),
      _NavItem(icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number_rounded, label: 'Mã giảm giá voucher', index: 8),
      _NavItem(icon: Icons.poll_outlined, activeIcon: Icons.poll_rounded, label: 'Khảo sát thị trường', index: 9),
      _NavItem(icon: Icons.rate_review_outlined, activeIcon: Icons.rate_review_rounded, label: 'Đánh giá sản phẩm', index: 14),
      _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Khách hàng', index: 10),
      _NavItem(icon: Icons.badge_outlined, activeIcon: Icons.badge_rounded, label: 'Nhân viên', index: 11),
      _NavItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings_rounded, label: 'Vai trò & phân quyền', index: 12),
      _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Cài đặt hệ thống', index: 13),
    ];

    final navItems = allNavItems.where((item) {
      if (isAdmin) return true;
      switch (item.index) {
        case 0: return true; // Let everyone see Dashboard
        case 1: return authProvider.can('Products.View');
        case 2: return authProvider.can('Orders.View');
        case 3: return authProvider.can('Invoices.View');
        case 4: return authProvider.can('Categories.View');
        case 5: return authProvider.can('Suppliers.View');
        case 6: return authProvider.can('PurchaseOrders.View');
        case 7: return authProvider.can('Promotions.View');
        case 8: return authProvider.can('Vouchers.View');
        case 9: return authProvider.can('Surveys.View');
        case 14: return authProvider.can('Reviews.View');
        case 10: return authProvider.can('Customers.View') || authProvider.can('Users.View');
        case 11: return authProvider.can('Employees.View') || authProvider.can('Users.View');
        case 12: return authProvider.can('Roles.View');
        case 13: return false; // Only ADMIN
        default: return false;
      }
    }).toList();

    final isCollapsed = navProvider.isSidebarCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 68 : 240,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header Branding & Collapse Toggle Button
          Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed) ...[
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'TechStoree',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            authProvider.userRole,
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Thu gọn thanh bên',
                    waitDuration: const Duration(milliseconds: 200),
                    preferBelow: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => navProvider.toggleSidebar(),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(Icons.menu_open_rounded, size: 18, color: textSecondary),
                      ),
                    ),
                  ),
                ] else ...[
                  Tooltip(
                    message: 'Mở rộng thanh bên',
                    waitDuration: const Duration(milliseconds: 200),
                    preferBelow: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => navProvider.toggleSidebar(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          const SizedBox(height: 6),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 8,
                vertical: 4,
              ),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = navProvider.currentIndex == item.index;

                final itemTile = Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      navProvider.setIndex(item.index);
                      if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                        Navigator.of(context).pop();
                      }
                    },
                    hoverColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                    child: Container(
                      height: 38,
                      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(
                                color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
                                width: 1,
                              )
                            : null,
                      ),
                      alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
                      child: isCollapsed
                          ? Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 19,
                              color: isSelected ? (isDark ? Colors.white : AppColors.primary) : textSecondary,
                            )
                          : Row(
                              children: [
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: 18,
                                  color: isSelected ? (isDark ? Colors.white : AppColors.primary) : textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected ? textPrimary : textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Tooltip(
                    message: item.label,
                    waitDuration: const Duration(milliseconds: 100),
                    preferBelow: false,
                    verticalOffset: 0,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : const Color(0xFF334155),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: itemTile,
                  ),
                );
              },
            ),
          ),

          Divider(height: 1, color: borderColor),

          // User Profile Row at Bottom
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 6 : 10, vertical: 8),
            child: isCollapsed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: '${authProvider.userName} (${authProvider.userRole})',
                        preferBelow: false,
                        waitDuration: const Duration(milliseconds: 100),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          child: Text(
                            authProvider.userName.isNotEmpty ? authProvider.userName[0].toUpperCase() : 'A',
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Tooltip(
                        message: 'Đăng xuất',
                        preferBelow: false,
                        child: IconButton(
                          icon: Icon(Icons.logout_rounded, size: 16, color: textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _showLogoutDialog(context, authProvider),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        child: Text(
                          authProvider.userName.isNotEmpty ? authProvider.userName[0].toUpperCase() : 'A',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.userName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              authProvider.userEmail,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout_rounded, size: 15, color: textSecondary),
                        tooltip: 'Đăng xuất',
                        onPressed: () => _showLogoutDialog(context, authProvider),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<NavigationProvider>(context, listen: false).reset();
              authProvider.logout();
            },
            child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}
