import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy');
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
    _usersFuture = apiService.getUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
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
              Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 16),

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
                        items: ['Tất cả', 'Admin', 'Staff', 'Customer']
                            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedRole = val ?? 'Tất cả'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add User Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showUserDialog(context, apiService),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                    label: const Text('Thêm Người Dùng', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        final isActive = user.status == 'Hoạt động';

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
                                Chip(
                                  label: Text(user.role),
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.successBg : AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.status,
                                    style: TextStyle(
                                      color: isActive ? AppColors.success : AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                                  onPressed: () => _showUserDialog(context, apiService, user: user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  onPressed: () => _showDeleteUserConfirm(context, apiService, user),
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

  void _showUserDialog(BuildContext context, ApiService apiService, {AppUser? user}) {
    final isEditing = user != null;
    final nameCtrl = TextEditingController(text: isEditing ? user.userName : '');
    final emailCtrl = TextEditingController(text: isEditing ? user.email : '');
    final phoneCtrl = TextEditingController(text: isEditing ? user.phone : '');
    String role = isEditing ? user.role : 'Customer';
    String status = isEditing ? user.status : 'Hoạt động';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh Sửa Người Dùng' : 'Thêm Người Dùng Mới', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Phân quyền', border: OutlineInputBorder()),
                        items: ['Admin', 'Manager', 'Staff', 'Customer']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => role = val ?? 'Customer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                        items: ['Hoạt động', 'Tạm khóa']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => status = val ?? 'Hoạt động'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;

                final newUser = AppUser(
                  id: isEditing ? user.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  userName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  role: role,
                  status: status,
                  phone: phoneCtrl.text.trim(),
                  createdAt: isEditing ? user.createdAt : DateTime.now(),
                );

                if (isEditing) {
                  await apiService.updateUser(newUser);
                } else {
                  await apiService.createUser(newUser);
                }

                if (context.mounted) {
                  Navigator.pop(ctx);
                  setState(() {
                    _loadUsers();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'Đã cập nhật thông tin người dùng!' : 'Đã thêm người dùng mới!')),
                  );
                }
              },
              child: Text(isEditing ? 'Cập Nhật' : 'Lưu Người Dùng', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserConfirm(BuildContext context, ApiService apiService, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "${user.userName}" (${user.email}) không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await apiService.deleteUser(user.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {
                  _loadUsers();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa người dùng thành công!')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
