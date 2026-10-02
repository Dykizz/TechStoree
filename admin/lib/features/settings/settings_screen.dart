import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _urlCtrl = TextEditingController(text: apiService.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài Đặt Hệ Thống Administrator',
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // API Connection Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.api_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Cấu hình kết nối Backend ASP.NET Core REST API',
                      style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Cấu hình địa chỉ RESTful API endpoint (.NET 10 Web API)',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlCtrl,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'http://localhost:5000/api',
                          filled: true,
                          fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        apiService.setBaseUrl(_urlCtrl.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật URL Backend API thành công!')),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Lưu & Kết Nối'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Settings Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_rounded, color: AppColors.accent, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Giao Diện & Chuẩn Hiển Thị',
                      style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: Text('Chế độ Tối (Dark Mode)', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tối ưu mắt cho quản trị viên khi làm việc vào ban đêm', style: TextStyle(color: textSecondary)),
                    value: themeProvider.isDarkMode,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => themeProvider.toggleTheme(),
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
