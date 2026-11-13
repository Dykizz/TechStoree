import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tech_interests.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/survey.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../survey_helpers.dart';

class SurveyAssignCustomersDialog extends StatefulWidget {
  final SurveyAdminList survey;
  final VoidCallback onAssigned;

  const SurveyAssignCustomersDialog({
    super.key,
    required this.survey,
    required this.onAssigned,
  });

  @override
  State<SurveyAssignCustomersDialog> createState() => _SurveyAssignCustomersDialogState();
}

class _SurveyAssignCustomersDialogState extends State<SurveyAssignCustomersDialog> {
  SurveyTargetType _targetType = SurveyTargetType.ALL;
  List<TechInterestOption> _techInterests = TechInterestCatalog.defaults;
  String _selectedTechInterest = TechInterestCatalog.defaults.first.key;
  final List<int> _selectedUserIds = [];
  List<AppUser> _allCustomers = [];
  bool _isLoadingUsers = false;
  String? _usersLoadError;
  bool _isSubmitting = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUserIds.addAll(widget.survey.assignedUserIds);
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersLoadError = null;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      // Lấy toàn bộ khách hàng đang hoạt động qua mọi trang (loại trừ nhân viên/admin & tài khoản bị khóa)
      final usersFuture = apiService.getAllUsers(
        token: token,
        isStaffOnly: false,
        isLocked: false,
        throwOnError: true,
      );
      final interestsFuture = apiService
          .getTechInterests(token: token)
          .catchError((_) => TechInterestCatalog.defaults);
      final users = await usersFuture;
      final interests = await interestsFuture;
      if (mounted) {
        setState(() {
          _allCustomers = users.where((u) => !u.isLocked).toList();
          if (interests.isNotEmpty) {
            _techInterests = interests;
            if (!_techInterests.any((t) => t.key == _selectedTechInterest)) {
              _selectedTechInterest = _techInterests.first.key;
            }
          }
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usersLoadError = extractFriendlySurveyError(
            e,
            fallback: 'Không thể tải danh sách khách hàng.',
          );
          _isLoadingUsers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final filteredCustomers = _allCustomers.where((u) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = u.fullName.toLowerCase();
      final email = u.email.toLowerCase();
      final phone = u.phone.toLowerCase();
      final id = u.id;
      return name.contains(q) || email.contains(q) || phone.contains(q) || id == q;
    }).toList();

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
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
                  'Phát khảo sát tới khách hàng',
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
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Divider(),
            if (widget.survey.isUpcoming && widget.survey.startAt != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Khảo sát đang hẹn lịch mở từ ${AppDateFormatter.formatDateTime(widget.survey.startAt!)}. Khách hàng được chọn sẽ chỉ nhận và làm bài từ thời điểm này.',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            Text(
              'Chọn đối tượng nhận bài khảo sát:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 8),

            AppDropdown<SurveyTargetType>(
              value: _targetType,
              labelText: 'Hình thức nhắm mục tiêu',
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
                value: _techInterests.any((t) => t.key == _selectedTechInterest)
                    ? _selectedTechInterest
                    : null,
                labelText: 'Sở thích công nghệ',
                items: _techInterests.map((interest) {
                  return DropdownMenuItem(
                    value: interest.key,
                    child: Text(interest.displayName, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTechInterest = val);
                  }
                },
              ),
            ],

            // BY_IDS (Chỉ định danh sách khách hàng)
            if (_targetType == SurveyTargetType.BY_IDS) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chọn khách hàng (${_selectedUserIds.length} đã chọn):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        onPressed: () {
                          setState(() {
                            // Chọn tất cả khách hàng chưa nhận bài này
                            for (var c in _allCustomers) {
                              final uid = int.tryParse(c.id) ?? 0;
                              if (!widget.survey.assignedUserIds.contains(uid)) {
                                if (!_selectedUserIds.contains(uid)) {
                                  _selectedUserIds.add(uid);
                                }
                              }
                            }
                          });
                        },
                        child: const Text('Chọn chưa giao', style: TextStyle(fontSize: 11)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        onPressed: () => setState(() => _selectedUserIds.clear()),
                        child: const Text('Bỏ chọn', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Ô tìm kiếm khách hàng
              AppTextField(
                controller: _searchCtrl,
                hintText: 'Tìm theo họ tên, email, SĐT khách hàng...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),

              if (_isLoadingUsers)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_usersLoadError != null)
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.danger.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _usersLoadError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.danger),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Thử lại',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.outline,
                        onPressed: _fetchCustomers,
                      ),
                    ],
                  ),
                )
              else if (filteredCustomers.isEmpty)
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(6),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                  ),
                  child: Text(
                    _searchQuery.isEmpty ? 'Không có dữ liệu khách hàng nào.' : 'Không tìm thấy khách hàng phù hợp.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                )
              else
                Material(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final u = filteredCustomers[index];
                        final int uid = int.tryParse(u.id) ?? 0;
                        final isAlreadyAssigned = widget.survey.assignedUserIds.contains(uid);
                        final isChecked = _selectedUserIds.contains(uid);

                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.fullName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAlreadyAssigned) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Đã giao bài',
                                    style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${u.email} • ID #${u.id}${u.techInterest != null && u.techInterest!.trim().isNotEmpty ? " • Sở thích: ${TechInterestCatalog.displayLabel(u.techInterest, options: _techInterests)}" : ""}',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                ),
            ],

            if (_targetType == SurveyTargetType.ALL) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bài khảo sát sẽ được gửi tới tất cả khách hàng (Customer) đang hoạt động trên hệ thống.',
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
    ),
      actions: [
        AppButton(
          label: 'Hủy',
          variant: AppButtonVariant.outline,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          label: _isSubmitting ? 'Đang gửi...' : 'Phát khảo sát',
          icon: Icons.send_rounded,
          onPressed: _isSubmitting ? null : _submitAssign,
        ),
      ],
    );
  }

  Future<void> _submitAssign() async {
    if (_targetType == SurveyTargetType.BY_IDS && _selectedUserIds.isEmpty) {
      AppToast.warning(context, 'Vui lòng chọn ít nhất 1 khách hàng!');
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
      if (res.success) {
        Navigator.pop(context);
        widget.onAssigned();
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Phân phối khảo sát thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Phân phối khảo sát thất bại!');
      }
    }
  }
}
