import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _usersFuture = apiService.getUsers(token: token);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<AppUser>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var users = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) =>
            u.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (_selectedRole != 'Tất cả') {
          users = users.where((u) => u.role == _selectedRole).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Search
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 240, maxWidth: 400),
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm người dùng theo họ tên hoặc email...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: backgroundColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Role Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: backgroundColor,
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        items: ['Tất cả', 'ADMIN', 'USER']
                            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedRole = val ?? 'Tất cả'),
                      ),
                    ),
                  ),

                  // Add User Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showCreateUserDialog(context, apiService, authProvider.token),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text('Thêm người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Users Data List Table
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isActive = !user.isLocked;

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              user.userName,
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Email: ${user.email} | SĐT: ${user.phone.isNotEmpty ? user.phone : 'N/A'}', style: TextStyle(color: textSecondary)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Role Chip & Change Dropdown
                                PopupMenuButton<String>(
                                  onSelected: (newRole) async {
                                    final success = await apiService.updateUserRole(user.id, newRole, token: authProvider.token);
                                    if (success) setState(() { _loadUsers(); });
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'ADMIN', child: Text('Chuyển thành ADMIN')),
                                    const PopupMenuItem(value: 'USER', child: Text('Chuyển thành USER')),
                                  ],
                                  child: Chip(
                                    label: Text(user.role),
                                    backgroundColor: user.role == 'ADMIN' ? AppColors.primary.withOpacity(0.15) : AppColors.info.withOpacity(0.15),
                                    labelStyle: TextStyle(color: user.role == 'ADMIN' ? AppColors.primary : AppColors.info, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Lock Status Chip
                                InkWell(
                                  onTap: () async {
                                    final success = await apiService.toggleUserLock(user.id, token: authProvider.token);
                                    if (success) setState(() { _loadUsers(); });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.successBg : AppColors.dangerBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isActive ? Icons.lock_open_rounded : Icons.lock_rounded, size: 14, color: isActive ? AppColors.success : AppColors.danger),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.status,
                                          style: TextStyle(
                                            color: isActive ? AppColors.success : AppColors.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context, ApiService apiService, String? token) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'USER';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo Tài Khoản Mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên (*)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email (*)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu (*)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò (*)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'USER', child: Text('Khách hàng (USER)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (ADMIN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ Họ tên, Email và Mật khẩu!'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                final newUser = AppUser(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  role: selectedRole,
                  status: 'Hoạt động',
                  isLocked: false,
                  phone: phoneCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                final result = await apiService.createUser(newUser, passwordCtrl.text.trim(), token: token);

                if (context.mounted) {
                  Navigator.pop(ctx);
                  if (result.success) {
                    setState(() { _loadUsers(); });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              },
              child: const Text('Tạo tài khoản', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

