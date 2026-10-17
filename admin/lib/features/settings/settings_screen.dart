import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          const PageHeader(
            title: 'Cài Đặt Hệ Thống Administrator',
            subtitle: 'Cấu hình địa chỉ API Backend, trạng thái kết nối và giao diện ứng dụng',
          ),

          // API Connection Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kết Nối Máy Chủ API Web',
                      style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(
                      label: apiService.isConnected ? 'ĐÃ KẾT NỐI SERVER' : 'CHƯA KẾT NỐI SERVER',
                      isSuccess: apiService.isConnected,
                      isWarning: !apiService.isConnected,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Thay đổi đường dẫn API khi chuyển đổi giữa môi trường Localhost Docker hoặc Server Cloud.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _urlCtrl,
                  labelText: 'Base URL Endpoint Web API',
                  hintText: 'http://localhost:5000/api',
                  prefixIcon: Icons.dns_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AppButton(
                      label: 'Lưu & Kiểm Tra Kết Nối',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: apiService.isLoading,
                      onPressed: () async {
                        final url = _urlCtrl.text.trim();
                        if (url.isNotEmpty) {
                          apiService.setBaseUrl(url);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật Base URL API. Đang kiểm tra kết nối...'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Interface & Appearance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giao Diện Ứng Dụng',
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tùy chỉnh chế độ hiển thị giao diện Sáng / Tối phù hợp làm việc.',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Chế độ Tối (Dark Theme)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tối ưu mắt khi sử dụng trong môi trường thiếu sáng', style: TextStyle(fontSize: 12)),
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
