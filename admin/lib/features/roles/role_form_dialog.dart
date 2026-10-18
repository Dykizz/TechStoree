import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/role.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';

class RoleFormDialog extends StatefulWidget {
  final ApiService apiService;
  final String? token;
  final RoleModel? existingRole;
  final List<ModulePermissionsModel> permissionModules;
  final VoidCallback onSuccess;

  const RoleFormDialog({
    super.key,
    required this.apiService,
    required this.token,
    this.existingRole,
    required this.permissionModules,
    required this.onSuccess,
  });

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;

  bool _isAutoCode = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Selected permission IDs for new role
  final Set<String> _selectedPermissionIds = {};

  bool get isEditing => widget.existingRole != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRole?.roleName ?? '');
    _codeController = TextEditingController(text: widget.existingRole?.roleId ?? '');
    _descController = TextEditingController(text: widget.existingRole?.description ?? '');

    if (isEditing) {
      _isAutoCode = false;
      _selectedPermissionIds.addAll(widget.existingRole!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Tự động sinh roleId chuẩn UPPERCASE từ tên tiếng Việt
  String _slugify(String input) {
    if (input.trim().isEmpty) return '';
    var str = input.trim();
    // Bỏ dấu tiếng Việt
    const vietnamese = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'A': 'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
      'd': 'đ',
      'D': 'Đ',
      'e': 'éèẻẽẹêếềểễệ',
      'E': 'ÉÈẺẼẸÊẾỀỂỄỆ',
      'i': 'íìỉĩị',
      'I': 'ÍÌỈĨỊ',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'O': 'ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
      'u': 'úùủũụưứừửữự',
      'U': 'ÚÙỦŨỤƯỨỪỬỮỰ',
      'y': 'ýỳỷỹỵ',
      'Y': 'ÝỲỶỸỴ',
    };
    for (var entry in vietnamese.entries) {
      for (var rune in entry.value.runes) {
        str = str.replaceAll(String.fromCharCode(rune), entry.key);
      }
    }
    // Giữ chữ cái và số, thay khoảng trắng bằng gạch dưới
    str = str.replaceAll(RegExp(r'[^a-zA-Z0-9\s_]'), '');
    str = str.replaceAll(RegExp(r'\s+'), '_');
    var code = str.toUpperCase();
    if (!code.startsWith('ROLE_')) {
      code = 'ROLE_$code';
    }
    if (code.length > 50) {
      code = code.substring(0, 50);
    }
    return code;
  }

  void _onNameChanged(String val) {
    if (!isEditing && _isAutoCode) {
      final generated = _slugify(val);
      setState(() {
        _codeController.text = generated;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final desc = _descController.text.trim();

    if (isEditing) {
      // Khi PUT /roles/{id}: Cần gửi kèm permissions hiện tại để không bị mất quyền
      final result = await widget.apiService.updateRole(
        widget.existingRole!.roleId,
        roleName: name,
        description: desc.isNotEmpty ? desc : null,
        permissions: widget.existingRole!.permissions,
        token: widget.token,
      );

      if (!mounted) return;
      if (result.success) {
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.message;
        });
      }
    } else {
      // POST /roles
      final result = await widget.apiService.createRole(
        roleName: name,
        roleId: code.isNotEmpty ? code : null,
        description: desc.isNotEmpty ? desc : null,
        permissions: _selectedPermissionIds.toList(),
        token: widget.token,
      );

      if (!mounted) return;
      if (result.success) {
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_moderator_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Chỉnh Sửa Vai Trò: ${widget.existingRole?.roleName}'
                              : 'Thêm Vai Trò Mới',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Cập nhật tên và mô tả vai trò trong hệ thống'
                              : 'Khởi tạo vai trò mới và phân quyền ban đầu',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Error banner if any
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Name
                      Text(
                        'Tên vai trò (*)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        onChanged: _onNameChanged,
                        maxLength: 100,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'VD: Nhân viên Chăm sóc khách hàng, Kiểm toán viên...',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Tên vai trò không được để trống';
                          }
                          final lower = val.trim().toLowerCase();
                          if (lower == 'admin' || lower == 'quản trị viên' || lower == 'khách hàng' || lower == 'user' || lower == 'customer') {
                            return 'Tên vai trò này đã được dành riêng cho hệ thống';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Role Code (roleId)
                      Row(
                        children: [
                          Text(
                            'Mã định danh (Role ID)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEditing
                                ? '(Không thể thay đổi)'
                                : '(Tùy chọn, tự động viết HOA, tối đa 50 ký tự)',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _codeController,
                        enabled: !isEditing,
                        maxLength: 50,
                        onChanged: (_) {
                          _isAutoCode = false;
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: isEditing ? textSecondary : textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Bỏ trống để hệ thống tự sinh mã GUID',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: isEditing,
                          fillColor: isEditing ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)) : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (val) {
                          if (!isEditing && val != null && val.trim().isNotEmpty) {
                            final code = val.trim().toUpperCase();
                            if (code == 'ADMIN' || code == 'USER' || code == 'CUSTOMER') {
                              return 'Mã vai trò "$code" là định danh dành riêng của hệ thống';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        'Mô tả vai trò',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLength: 255,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Mô tả ngắn gọn phạm vi trách nhiệm và mục đích của vai trò này...',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),

                      if (!isEditing) ...[
                        const SizedBox(height: 18),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 14),

                        // Initial Permissions Selection Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phân quyền ban đầu (${_selectedPermissionIds.length} đã chọn)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      for (var m in widget.permissionModules) {
                                        for (var p in m.permissions) {
                                          _selectedPermissionIds.add(p.permissionId);
                                        }
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Chọn tất cả', style: TextStyle(fontSize: 11.5)),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPermissionIds.clear();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Bỏ chọn', style: TextStyle(fontSize: 11.5)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Module accordions
                        ...widget.permissionModules.map((module) {
                          final selectedInModule = module.permissions
                              .where((p) => _selectedPermissionIds.contains(p.permissionId))
                              .length;
                          final isAllSelected = selectedInModule == module.permissions.length &&
                              module.permissions.isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                              color: isDark ? const Color(0xFF131A26) : const Color(0xFFFAFAFA),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              dense: true,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      module.module,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selectedInModule > 0
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$selectedInModule/${module.permissions.length}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: selectedInModule > 0 ? AppColors.primary : textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: isAllSelected,
                                    tristate: selectedInModule > 0 && !isAllSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          for (var p in module.permissions) {
                                            _selectedPermissionIds.add(p.permissionId);
                                          }
                                        } else {
                                          for (var p in module.permissions) {
                                            _selectedPermissionIds.remove(p.permissionId);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              children: module.permissions.map((perm) {
                                final isChecked = _selectedPermissionIds.contains(perm.permissionId);
                                return CheckboxListTile(
                                  value: isChecked,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          perm.permissionName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (perm.isReserved)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.warningBorder),
                                          ),
                                          child: const Text(
                                            'Chưa áp dụng',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    perm.description ?? perm.permissionId,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedPermissionIds.add(perm.permissionId);
                                      } else {
                                        _selectedPermissionIds.remove(perm.permissionId);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Hủy bỏ',
                    variant: AppButtonVariant.secondary,
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: isEditing ? 'Lưu thay đổi' : 'Tạo vai trò',
                    variant: AppButtonVariant.primary,
                    icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
