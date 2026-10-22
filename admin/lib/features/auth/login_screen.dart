import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/navigation_provider.dart';
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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isObscure = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Logic 3: Tự động xóa thông báo lỗi khi người dùng bắt đầu gõ lại
    _emailCtrl.addListener(_onFieldChanged);
    _passwordCtrl.addListener(_onFieldChanged);

    // Logic 4: Tự động tải thông tin đăng nhập đã lưu từ phiên trước
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_onFieldChanged);
    _passwordCtrl.removeListener(_onFieldChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
      authProvider.clearError();
    }
  }

  // Logic 4: Đọc file lưu thông tin tài khoản cục bộ
  Future<void> _loadSavedCredentials() async {
    try {
      final file = File('.saved_login.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        if (mounted && data is Map) {
          setState(() {
            _emailCtrl.text = data['email']?.toString() ?? 'admin@techstoree.vn';
            _passwordCtrl.text = data['password']?.toString() ?? 'admin123';
            _rememberMe = data['rememberMe'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('[Login] Không thể đọc file lưu đăng nhập: $e');
    }
  }

  // Logic 4: Ghi nhớ hoặc xóa thông tin tài khoản
  Future<void> _persistCredentials(String email, String password, bool remember) async {
    try {
      final file = File('.saved_login.json');
      if (remember) {
        final data = json.encode({
          'email': email,
          'password': password,
          'rememberMe': true,
        });
        await file.writeAsString(data);
      } else {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('[Login] Không thể lưu file đăng nhập: $e');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Logic 5: Kiểm tra validation phía Client
    if (email.isEmpty || password.isEmpty) {
      _showWarning('Vui lòng nhập đầy đủ Email và Mật khẩu!');
      return;
    }

    // Logic 5: Kiểm tra định dạng Email chuẩn
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showWarning('Địa chỉ Email không đúng định dạng (Ví dụ: admin@techstoree.vn)!');
      return;
    }

    // Logic 5: Kiểm tra độ dài mật khẩu tối thiểu
    if (password.length < 6) {
      _showWarning('Mật khẩu tài khoản phải có tối thiểu 6 ký tự!');
      return;
    }

    final success = await authProvider.login(email, password);
    if (success) {
      // Logic 4: Lưu thông tin khi đăng nhập thành công nếu có chọn ghi nhớ
      await _persistCredentials(email, password, _rememberMe);
      navProvider.reset();
    } else if (mounted) {
      final msg = authProvider.errorMessage ?? 'Email hoặc mật khẩu không chính xác!';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
          // Logic 1: Hỗ trợ phím Enter để đăng nhập trên toàn bộ form
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.enter): _handleLogin,
            },
            child: Container(
              width: 430,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                // Giao diện: Card đăng nhập có đổ bóng 3D mềm mại (BoxShadow)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Logo & Tên hệ thống
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'TechStoree',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
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
                  const SizedBox(height: 20),

                  // Banner thông báo lỗi nếu đăng nhập thất bại
                  if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  // Logic 1: Khi nhấn Enter ở ô Email -> Nhảy focus sang ô Mật khẩu
                  AppTextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocusNode,
                    labelText: 'Địa chỉ Email (*)',
                    hintText: 'admin@techstoree.vn',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Logic 1: Khi nhấn Enter ở ô Mật khẩu -> Thực hiện Đăng nhập
                  AppTextField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocusNode,
                    labelText: 'Mật khẩu (*)',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _isObscure,
                    onFieldSubmitted: (_) => _handleLogin(),
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

                  // Remember me Checkbox (Logic 4)
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                      Text(
                        'Ghi nhớ đăng nhập',
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Đăng nhập quản trị',
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
      ),
    );
  }
}
