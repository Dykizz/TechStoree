import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@techstoree.vn');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  bool _isObscure = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await authProvider.login(email, password);
    if (!success && mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo Branding
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'TechStoree Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Đăng nhập tài khoản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhập thông tin quản trị viên để truy cập hệ thống dashboard.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                AppTextField(
                  controller: _emailCtrl,
                  labelText: 'Địa chỉ Email (*)',
                  hintText: 'admin@techstoree.vn',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordCtrl,
                  labelText: 'Mật khẩu (*)',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _isObscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textSecondary,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
                const SizedBox(height: 12),

                // Remember me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                    Text(
                      'Ghi nhớ phiên đăng nhập',
                      style: TextStyle(color: textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Đăng Nhập Quản Trị',
                    icon: Icons.login_rounded,
                    isLoading: authProvider.isLoading,
                    onPressed: _handleLogin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
