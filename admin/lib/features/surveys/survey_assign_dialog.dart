import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_user.dart';
import '../../core/models/survey.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';

class SurveyAssignDialog extends StatefulWidget {
  final SurveyAdminList survey;
  final VoidCallback onAssigned;

  const SurveyAssignDialog({
    super.key,
    required this.survey,
    required this.onAssigned,
  });

  @override
  State<SurveyAssignDialog> createState() => _SurveyAssignDialogState();
}

class _SurveyAssignDialogState extends State<SurveyAssignDialog> {
  SurveyTargetType _targetType = SurveyTargetType.ALL;
  String _selectedTechInterest = 'Gaming';
  final List<int> _selectedUserIds = [];
  List<AppUser> _allUsers = [];
  bool _isLoadingUsers = false;
  bool _isSubmitting = false;

  static const List<String> techInterestOptions = [
    'Gaming',
    'Văn phòng & Học tập',
    'Lập trình & AI',
    'Âm thanh & Studio',
    'Smartwatch & Sức khỏe',
    'Nhiếp ảnh & Quay phim',
    'SmartHome & Đồ gia dụng',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final users = await apiService.getUsers(token: token);
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phát Khảo Sát',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                ),
                Text(
                  widget.survey.title,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),

            Text(
              'Chọn đối tượng nhận bài khảo sát:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 8),

            AppDropdown<SurveyTargetType>(
              value: _targetType,
              labelText: 'Hình thức nhắm mục tiêu (Target Type)',
              items: SurveyTargetType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _targetType = val);
                }
              },
            ),

            const SizedBox(height: 14),

            // BY_INTEREST
            if (_targetType == SurveyTargetType.BY_INTEREST) ...[
              Text(
                'Chọn phân khúc sở thích công nghệ:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 6),
              AppDropdown<String>(
                value: _selectedTechInterest,
                labelText: 'Sở thích công nghệ',
                items: techInterestOptions.map((interest) {
                  return DropdownMenuItem(
                    value: interest,
                    child: Text(interest, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTechInterest = val);
                  }
                },
              ),
            ],

            // BY_IDS
            if (_targetType == SurveyTargetType.BY_IDS) ...[
              Text(
                'Chọn danh sách khách hàng nhắm mục tiêu (${_selectedUserIds.length} đã chọn):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 6),
              if (_isLoadingUsers)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(6),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                  ),
                  child: ListView.separated(
                    itemCount: _allUsers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withOpacity(0.5)),
                    itemBuilder: (context, index) {
                      final u = _allUsers[index];
                      final int uid = int.tryParse(u.id) ?? 0;
                      final isChecked = _selectedUserIds.contains(uid);

                      return CheckboxListTile(
                        dense: true,
                        value: isChecked,
                        title: Text(u.fullName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        subtitle: Text('${u.email} • ID #${u.id}', style: TextStyle(fontSize: 11, color: textSecondary)),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              if (!_selectedUserIds.contains(uid)) _selectedUserIds.add(uid);
                            } else {
                              _selectedUserIds.remove(uid);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],

            if (_targetType == SurveyTargetType.ALL) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bài khảo sát sẽ được gửi tới tất cả khách hàng đang hoạt động trên hệ thống.',
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy',
          variant: AppButtonVariant.outline,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          label: _isSubmitting ? 'Đang gửi...' : 'Phát Khảo Sát',
          icon: Icons.send_rounded,
          onPressed: _isSubmitting ? null : _submitAssign,
        ),
      ],
    );
  }

  Future<void> _submitAssign() async {
    if (_targetType == SurveyTargetType.BY_IDS && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 khách hàng!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final req = AssignSurveyRequest(
      targetType: _targetType,
      userIds: _targetType == SurveyTargetType.BY_IDS ? _selectedUserIds : null,
      techInterest: _targetType == SurveyTargetType.BY_INTEREST ? _selectedTechInterest : null,
    );

    final res = await apiService.assignSurvey(widget.survey.surveyId, req, token: token);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      widget.onAssigned();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }
}
