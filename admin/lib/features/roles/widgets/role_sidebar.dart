import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/rbac_models.dart';

class RoleSidebar extends StatelessWidget {
  final List<RoleModel> roles;
  final String selectedRoleCode;
  final Map<String, Set<String>> rolePermissions;
  final ValueChanged<String> onSelectRole;

  const RoleSidebar({
    super.key,
    required this.roles,
    required this.selectedRoleCode,
    required this.rolePermissions,
    required this.onSelectRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh Sách Vai Trò',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chọn vai trò để thiết lập quyền',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Role List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: roles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final role = roles[index];
                final isSelected = role.code == selectedRoleCode;
                final activeCount = rolePermissions[role.code]?.length ?? 0;
                final totalCount = MockRbacData.modules.length * PermissionAction.values.length;

                return InkWell(
                  onTap: () => onSelectRole(role.code),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? role.color.withValues(alpha: isDark ? 0.2 : 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? role.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role Icon Avatar
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: role.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            role.icon,
                            size: 18,
                            color: role.color,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Role Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      role.name,
                                      style: TextStyle(
                                        color: isSelected ? role.color : textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      role.code,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$activeCount/$totalCount quyền',
                                    style: TextStyle(
                                      color: isSelected ? role.color : textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Selected indicator arrow
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: role.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
