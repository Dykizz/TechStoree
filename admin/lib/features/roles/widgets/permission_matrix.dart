import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../models/rbac_models.dart';

class PermissionMatrix extends StatelessWidget {
  final RoleModel selectedRole;
  final Set<String> currentPermissions;
  final Function(String key, bool enabled) onTogglePermission;
  final Function(String moduleId, bool selectAll) onToggleRowModule;
  final Function(bool selectAll) onToggleGlobalSelectAll;
  final VoidCallback onSaveChanges;
  final VoidCallback onResetChanges;
  final bool isDirty;
  final bool isSaving;

  const PermissionMatrix({
    super.key,
    required this.selectedRole,
    required this.currentPermissions,
    required this.onTogglePermission,
    required this.onToggleRowModule,
    required this.onToggleGlobalSelectAll,
    required this.onSaveChanges,
    required this.onResetChanges,
    this.isDirty = false,
    this.isSaving = false,
  });

  /// Check if all permissions across all modules are selected
  bool get isGlobalAllSelected {
    for (var module in MockRbacData.modules) {
      for (var action in PermissionAction.values) {
        final key = MockRbacData.buildKey(module.id, action);
        if (!currentPermissions.contains(key)) return false;
      }
    }
    return true;
  }

  /// Check if all permissions for a specific row/module are selected
  bool isRowAllSelected(String moduleId) {
    for (var action in PermissionAction.values) {
      final key = MockRbacData.buildKey(moduleId, action);
      if (!currentPermissions.contains(key)) return false;
    }
    return true;
  }

  /// Count enabled permissions for a specific row/module
  int countRowPermissions(String moduleId) {
    int count = 0;
    for (var action in PermissionAction.values) {
      final key = MockRbacData.buildKey(moduleId, action);
      if (currentPermissions.contains(key)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final tableHeaderBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    final totalCount = MockRbacData.modules.length * PermissionAction.values.length;
    final activeCount = currentPermissions.length;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                // Role Title Badge & Summary
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedRole.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(selectedRole.icon, color: selectedRole.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ma Trận Phân Quyền: ${selectedRole.name}',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedRole.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              selectedRole.code,
                              style: TextStyle(
                                color: selectedRole.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (isDirty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 10, color: AppColors.warning),
                                  SizedBox(width: 3),
                                  Text(
                                    'Chưa lưu',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đang cấp $activeCount / $totalCount quyền chi tiết trong hệ thống',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Revert changes button
                if (isDirty) ...[
                  OutlinedButton.icon(
                    onPressed: onResetChanges,
                    icon: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('Hoàn tác'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Save button
                AppButton(
                  label: 'Lưu thay đổi',
                  icon: Icons.save_rounded,
                  isLoading: isSaving,
                  onPressed: isDirty ? onSaveChanges : null,
                ),
              ],
            ),
          ),

          // Permission Grid Table
          Expanded(
            child: SingleChildScrollView(
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: borderColor,
                ),
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: borderColor, width: 0.8),
                    verticalInside: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 0.5),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3.2), // Module Name & Desc
                    1: FlexColumnWidth(1.2), // Read
                    2: FlexColumnWidth(1.2), // Create
                    3: FlexColumnWidth(1.2), // Update
                    4: FlexColumnWidth(1.2), // Delete
                    5: FlexColumnWidth(1.4), // Select All Row
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
                    TableRow(
                      decoration: BoxDecoration(color: tableHeaderBg),
                      children: [
                        // Header Module Name & Global Select All
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(
                                'PHÂN HỆ / MODULE',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions Header
                        for (var action in PermissionAction.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    action.label.split(' ')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    action.label.split(' ')[1],
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Global Select All Header Column
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Tooltip(
                              message: 'Bật/Tắt toàn bộ tất cả quyền của tất cả Phân hệ',
                              child: InkWell(
                                onTap: () => onToggleGlobalSelectAll(!isGlobalAllSelected),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: isGlobalAllSelected,
                                          activeColor: selectedRole.color,
                                          onChanged: (val) => onToggleGlobalSelectAll(val ?? false),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'TẤT CẢ',
                                        style: TextStyle(
                                          color: selectedRole.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Table Body Rows (7 Modules)
                    for (var module in MockRbacData.modules)
                      TableRow(
                        children: [
                          // Column 0: Module Title & Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(module.icon, size: 18, color: textPrimary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.name,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        module.description,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Column 1-4: Checkboxes for Read, Create, Update, Delete
                          for (var action in PermissionAction.values)
                            Builder(
                              builder: (context) {
                                final key = MockRbacData.buildKey(module.id, action);
                                final isChecked = currentPermissions.contains(key);
                                return Center(
                                  child: InkWell(
                                    onTap: () => onTogglePermission(key, !isChecked),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Transform.scale(
                                        scale: 1.1,
                                        child: Checkbox(
                                          value: isChecked,
                                          activeColor: selectedRole.color,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (val) => onTogglePermission(key, val ?? false),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Column 5: Row Select All Checkbox
                          Builder(
                            builder: (context) {
                              final rowSelected = isRowAllSelected(module.id);
                              final rowCount = countRowPermissions(module.id);
                              return Center(
                                child: InkWell(
                                  onTap: () => onToggleRowModule(module.id, !rowSelected),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: rowSelected,
                                          activeColor: selectedRole.color,
                                          onChanged: (val) => onToggleRowModule(module.id, val ?? false),
                                        ),
                                        Text(
                                          '$rowCount/4',
                                          style: TextStyle(
                                            color: rowSelected ? selectedRole.color : textSecondary,
                                            fontSize: 10,
                                            fontWeight: rowSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
