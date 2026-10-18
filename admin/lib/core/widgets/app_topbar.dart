import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class AppTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;

  const AppTopbar({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isCompact = MediaQuery.of(context).size.width < 850;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isCompact)
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 18),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          Row(
            children: [
              Text(
                'Admin',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('/', style: TextStyle(color: textSecondary, fontSize: 12)),
              ),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 16,
              color: textSecondary,
            ),
            tooltip: isDark ? 'Chuyển Chế độ Sáng' : 'Chuyển Chế độ Tối',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }
}
