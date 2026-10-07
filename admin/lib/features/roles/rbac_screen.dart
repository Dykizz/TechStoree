import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/page_header.dart';
import 'models/rbac_models.dart';
import 'widgets/permission_matrix.dart';
import 'widgets/role_sidebar.dart';

class RbacScreen extends StatefulWidget {
  const RbacScreen({super.key});

  @override
  State<RbacScreen> createState() => _RbacScreenState();
}

class _RbacScreenState extends State<RbacScreen> {
  // Currently selected role code
  String _selectedRoleCode = 'SALES_STAFF';

  // Map of role code -> Set of active permission keys
  late Map<String, Set<String>> _rolePermissions;

  // Saved original snapshot to support Revert/Reset changes
  late Map<String, Set<String>> _savedSnapshot;

  // Track dirty roles
  final Set<String> _dirtyRoles = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final initial = MockRbacData.getInitialRolePermissions();
    _rolePermissions = {};
    _savedSnapshot = {};

    initial.forEach((roleCode, permissions) {
      _rolePermissions[roleCode] = Set<String>.from(permissions);
      _savedSnapshot[roleCode] = Set<String>.from(permissions);
    });
  }

  /// Check if the currently selected role has unsaved changes
  bool get _isCurrentRoleDirty => _dirtyRoles.contains(_selectedRoleCode);

  /// Get RoleModel for selected role code
  RoleModel get _selectedRole {
    return MockRbacData.roles.firstWhere(
      (r) => r.code == _selectedRoleCode,
      orElse: () => MockRbacData.roles.first,
    );
  }

  /// Toggle an individual permission key (e.g. "products:read")
  void _onTogglePermission(String key, bool enabled) {
    setState(() {
      final currentSet = _rolePermissions[_selectedRoleCode] ?? <String>{};
      if (enabled) {
        currentSet.add(key);
      } else {
        currentSet.remove(key);
      }
      _checkDirtyState();
    });
  }

  /// Toggle all permissions for a specific module row (e.g. "products")
  void _onToggleRowModule(String moduleId, bool selectAll) {
    setState(() {
      final currentSet = _rolePermissions[_selectedRoleCode] ?? <String>{};
      for (var action in PermissionAction.values) {
        final key = MockRbacData.buildKey(moduleId, action);
        if (selectAll) {
          currentSet.add(key);
        } else {
          currentSet.remove(key);
        }
      }
      _checkDirtyState();
    });
  }

  /// Toggle all permissions across all 7 modules
  void _onToggleGlobalSelectAll(bool selectAll) {
    setState(() {
      final currentSet = _rolePermissions[_selectedRoleCode] ?? <String>{};
      if (selectAll) {
        for (var module in MockRbacData.modules) {
          for (var action in PermissionAction.values) {
            currentSet.add(MockRbacData.buildKey(module.id, action));
          }
        }
      } else {
        currentSet.clear();
      }
      _checkDirtyState();
    });
  }

  /// Check if current role's permissions differ from saved snapshot
  void _checkDirtyState() {
    final current = _rolePermissions[_selectedRoleCode] ?? <String>{};
    final saved = _savedSnapshot[_selectedRoleCode] ?? <String>{};

    final isDifferent = current.length != saved.length || !current.containsAll(saved);
    if (isDifferent) {
      _dirtyRoles.add(_selectedRoleCode);
    } else {
      _dirtyRoles.remove(_selectedRoleCode);
    }
  }

  /// Revert changes for current role to saved snapshot
  void _onResetChanges() {
    setState(() {
      final saved = _savedSnapshot[_selectedRoleCode] ?? <String>{};
      _rolePermissions[_selectedRoleCode] = Set<String>.from(saved);
      _dirtyRoles.remove(_selectedRoleCode);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã hoàn tác các thay đổi phân quyền cho vai trò ${_selectedRole.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Trigger mock API call with console log payload & SnackBar UI notification
  Future<void> _onSaveChanges() async {
    setState(() {
      _isSaving = true;
    });

    final selectedPermissionsList = (_rolePermissions[_selectedRoleCode] ?? <String>{}).toList()..sort();

    // Construct mock API payload
    final apiPayload = {
      'role_id': _selectedRole.id,
      'role_code': _selectedRole.code,
      'role_name': _selectedRole.name,
      'updated_at': DateTime.now().toIso8601String(),
      'permissions': selectedPermissionsList,
    };

    // Print formatted payload to console as requested
    // ignore: avoid_print
    print('====================================================');
    // ignore: avoid_print
    print('[MOCK API CALL] PUT /api/roles/${_selectedRole.id}/permissions');
    // ignore: avoid_print
    print('PAYLOAD: ${const JsonEncoder.withIndent('  ').convert(apiPayload)}');
    // ignore: avoid_print
    print('====================================================');

    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      // Update saved snapshot
      _savedSnapshot[_selectedRoleCode] = Set<String>.from(selectedPermissionsList);
      _dirtyRoles.remove(_selectedRoleCode);
      _isSaving = false;
    });

    // Show feedback SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lưu thành công! Cập nhật ${selectedPermissionsList.length} quyền cho vai trò ${_selectedRole.name}. Payload đã ghi vào console log API.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 850;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          PageHeader(
            title: 'Quản Lý Vai Trò & Phân Quyền (Dynamic RBAC)',
            subtitle:
                'Thiết lập phân quyền chi tiết (CRUD) theo từng Vai trò người dùng (Admin, Bán hàng, Kho, Khảo sát, User)',
            action: _dirtyRoles.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          'Có ${_dirtyRoles.length} vai trò chưa lưu',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // Main Body: Split View or Compact View
          Expanded(
            child: isCompact ? _buildCompactLayout() : _buildSplitViewLayout(),
          ),
        ],
      ),
    );
  }

  /// Desktop / Wide screen Split View Layout
  Widget _buildSplitViewLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sidebar: Role List
        RoleSidebar(
          roles: MockRbacData.roles,
          selectedRoleCode: _selectedRoleCode,
          rolePermissions: _rolePermissions,
          onSelectRole: (roleCode) {
            setState(() {
              _selectedRoleCode = roleCode;
            });
          },
        ),

        const SizedBox(width: 16),

        // Right Content Area: Permission Matrix Table
        Expanded(
          child: PermissionMatrix(
            selectedRole: _selectedRole,
            currentPermissions: _rolePermissions[_selectedRoleCode] ?? <String>{},
            onTogglePermission: _onTogglePermission,
            onToggleRowModule: _onToggleRowModule,
            onToggleGlobalSelectAll: _onToggleGlobalSelectAll,
            onSaveChanges: _onSaveChanges,
            onResetChanges: _onResetChanges,
            isDirty: _isCurrentRoleDirty,
            isSaving: _isSaving,
          ),
        ),
      ],
    );
  }

  /// Tablet / Mobile Compact Layout
  Widget _buildCompactLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Column(
      children: [
        // Top Horizontal Role Selector
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MockRbacData.roles.map((role) {
                final isSelected = role.code == _selectedRoleCode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    avatar: Icon(role.icon, size: 16, color: isSelected ? Colors.white : role.color),
                    label: Text(role.name),
                    selected: isSelected,
                    selectedColor: role.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRoleCode = role.code;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Permission Matrix
        Expanded(
          child: PermissionMatrix(
            selectedRole: _selectedRole,
            currentPermissions: _rolePermissions[_selectedRoleCode] ?? <String>{},
            onTogglePermission: _onTogglePermission,
            onToggleRowModule: _onToggleRowModule,
            onToggleGlobalSelectAll: _onToggleGlobalSelectAll,
            onSaveChanges: _onSaveChanges,
            onResetChanges: _onResetChanges,
            isDirty: _isCurrentRoleDirty,
            isSaving: _isSaving,
          ),
        ),
      ],
    );
  }
}
