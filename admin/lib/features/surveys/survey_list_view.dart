import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/survey.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class SurveyListView extends StatefulWidget {
  final Function(SurveyAdminList survey) onViewDetail;
  final Function(SurveyAdminDetail survey) onEdit;
  final Function(SurveyAdminList survey) onAssign;
  final Function(int surveyId) onViewStats;
  final VoidCallback onCreateNew;

  const SurveyListView({
    super.key,
    required this.onViewDetail,
    required this.onEdit,
    required this.onAssign,
    required this.onViewStats,
    required this.onCreateNew,
  });

  @override
  State<SurveyListView> createState() => _SurveyListViewState();
}

class _SurveyListViewState extends State<SurveyListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool? _isActiveFilter; // null = Tất cả, true = Đang mở, false = Tạm dừng
  bool? _hasRewardFilter; // null = Tất cả, true = Có thưởng, false = Không thưởng
  int _currentPage = 1;
  int _itemsPerPage = 10;

  late Future<SurveyPagedResult> _surveysFuture;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  void _loadSurveys() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _surveysFuture = apiService.getSurveys(
      search: _searchQuery,
      isActive: _isActiveFilter,
      hasReward: _hasRewardFilter,
      page: _currentPage,
      pageSize: _itemsPerPage,
      token: token,
    );
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

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<SurveyPagedResult>(
      future: _surveysFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final result = snapshot.data ?? SurveyPagedResult(items: [], totalItems: 0, page: 1, pageSize: 10, totalPages: 0);
        final surveys = result.items;

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Quản Lý Khảo Sát Thị Trường & CRM',
                subtitle: 'Tạo biểu mẫu thăm dò ý kiến, gắn voucher phần thưởng và phân tích tỷ lệ phản hồi khách hàng',
                action: AppButton(
                  label: 'Tạo Khảo Sát Mới',
                  icon: Icons.add_rounded,
                  onPressed: widget.onCreateNew,
                ),
              ),

              FilterBar(
                searchField: AppSearchField<SurveyAdminList>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo tiêu đề bài khảo sát...',
                  items: surveys,
                  searchFilter: (s, q) => s.title.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (s) => s.title,
                  itemSubtitle: (s) => 'Voucher: ${s.rewardVoucherCode ?? "Không có"} • Đã nộp: ${s.totalCompleted}/${s.totalAssigned}',
                  onSelected: (s) {
                    setState(() {
                      _searchQuery = s.title;
                      _currentPage = 1;
                      _loadSurveys();
                    });
                  },
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                      _loadSurveys();
                    });
                  },
                  onCleared: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                      _loadSurveys();
                    });
                  },
                ),
                filters: [
                  AppDropdown<bool?>(
                    value: _isActiveFilter,
                    labelText: 'Trạng thái nộp bài',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: true, child: Text('Đang mở nộp bài')),
                      DropdownMenuItem(value: false, child: Text('Đã tạm dừng')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _isActiveFilter = val;
                        _currentPage = 1;
                        _loadSurveys();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  AppDropdown<bool?>(
                    value: _hasRewardFilter,
                    labelText: 'Voucher phần thưởng',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả phần thưởng')),
                      DropdownMenuItem(value: true, child: Text('Có voucher thưởng')),
                      DropdownMenuItem(value: false, child: Text('Không có phần thưởng')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _hasRewardFilter = val;
                        _currentPage = 1;
                        _loadSurveys();
                      });
                    },
                  ),
                ],
              ),

              Flexible(
                fit: FlexFit.loose,
                child: DataTableContainer(
                  child: surveys.isEmpty
                      ? const EmptyState(
                          icon: Icons.poll_outlined,
                          title: 'Không tìm thấy bài khảo sát nào',
                          message: 'Thử thay đổi từ khóa tìm kiếm hoặc các bộ lọc trạng thái mở/tạm dừng.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 48,
                                      dataRowMaxHeight: 48,
                                      columnSpacing: 14,
                                      horizontalMargin: 14,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        DataColumn(label: Text('TIÊU ĐỀ KHẢO SÁT', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('VOUCHER THƯỞNG', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('ĐÃ PHÁT', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('ĐÃ NỘP BÀI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TỶ LỆ PHẢN HỒI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('NGÀY TẠO', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                      ],
                                      rows: surveys.map((s) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            // Title & Description Preview
                                            DataCell(
                                              SizedBox(
                                                width: 240,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s.title,
                                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (s.description != null && s.description!.isNotEmpty)
                                                      Text(
                                                        s.description!,
                                                        style: TextStyle(color: textSecondary, fontSize: 10),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Reward Voucher
                                            DataCell(_buildVoucherCell(s, isDark)),

                                            // Active Status
                                            DataCell(
                                              StatusBadge(
                                                label: s.isActive ? 'ĐANG MỞ' : 'TẠM DỪNG',
                                                isSuccess: s.isActive,
                                                isDanger: !s.isActive,
                                              ),
                                            ),

                                            // Total Assigned
                                            DataCell(Text('${s.totalAssigned}', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),

                                            // Total Completed
                                            DataCell(Text('${s.totalCompleted}', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12))),

                                            // Response Rate & Progress Bar
                                            DataCell(_buildResponseRateCell(s, textPrimary, textSecondary)),

                                            // Created At
                                            DataCell(Text('${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}', style: TextStyle(color: textSecondary, fontSize: 11))),

                                            // Compact Actions: [View] [⋯]
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                                    tooltip: 'Xem chi tiết',
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    onPressed: () => widget.onViewDetail(s),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert_rounded, size: 16),
                                                    tooltip: 'Thao tác khác',
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                    onSelected: (val) => _handleRowAction(val, s, apiService, authProvider.token),
                                                    itemBuilder: (ctx) => [
                                                      const PopupMenuItem(
                                                        value: 'EDIT',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit_outlined, size: 14),
                                                            SizedBox(width: 8),
                                                            Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'ASSIGN',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.send_rounded, size: 14),
                                                            SizedBox(width: 8),
                                                            Text('Phát khảo sát', style: TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'STATS',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.bar_chart_rounded, size: 14),
                                                            SizedBox(width: 8),
                                                            Text('Xem thống kê', style: TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'CLONE',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.copy_rounded, size: 14),
                                                            SizedBox(width: 8),
                                                            Text('Nhân bản', style: TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'TOGGLE',
                                                        child: Row(
                                                          children: [
                                                            Icon(s.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 14),
                                                            const SizedBox(width: 8),
                                                            Text(s.isActive ? 'Tạm dừng nhận bài' : 'Mở lại nộp bài', style: const TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'DELETE',
                                                        enabled: !s.hasResponses,
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_outline_rounded, size: 14, color: !s.hasResponses ? AppColors.danger : Colors.grey),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              !s.hasResponses ? 'Xóa khảo sát' : 'Xóa (Đã có phản hồi)',
                                                              style: TextStyle(fontSize: 12, color: !s.hasResponses ? AppColors.danger : Colors.grey),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (result.totalItems > 0)
                              AppPagination(
                                currentPage: _currentPage,
                                totalPages: result.totalPages,
                                totalItems: result.totalItems,
                                itemsPerPage: _itemsPerPage,
                                onPageChanged: (page) {
                                  setState(() {
                                    _currentPage = page;
                                    _loadSurveys();
                                  });
                                },
                                onItemsPerPageChanged: (items) {
                                  setState(() {
                                    _itemsPerPage = items;
                                    _currentPage = 1;
                                    _loadSurveys();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherCell(SurveyAdminList s, bool isDark) {
    if (s.rewardVoucherId == null || (s.rewardVoucherCode == null || s.rewardVoucherCode!.isEmpty)) {
      return Text('Không có phần thưởng', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11, fontStyle: FontStyle.italic));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            '${s.rewardVoucherCode}',
            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseRateCell(SurveyAdminList s, Color textPrimary, Color textSecondary) {
    final double rate = s.responseRatePercent.clamp(0.0, 100.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${s.responseRatePercent}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
            const SizedBox(width: 6),
            Text('(${s.totalCompleted}/${s.totalAssigned})', style: TextStyle(fontSize: 10, color: textSecondary)),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 75 ? AppColors.success : (rate >= 40 ? AppColors.primary : AppColors.warning),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRowAction(String action, SurveyAdminList s, ApiService apiService, String? token) async {
    switch (action) {
      case 'EDIT':
        final detail = await apiService.getSurveyById(s.surveyId, token: token);
        if (detail != null) {
          widget.onEdit(detail);
        }
        break;
      case 'ASSIGN':
        widget.onAssign(s);
        break;
      case 'STATS':
        widget.onViewStats(s.surveyId);
        break;
      case 'CLONE':
        final res = await apiService.cloneSurvey(s.surveyId, token: token);
        if (mounted) {
          _loadSurveys();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
          );
        }
        break;
      case 'TOGGLE':
        final res = await apiService.toggleSurveyActive(s.surveyId, token: token);
        if (mounted) {
          _loadSurveys();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res ? 'Đã đổi trạng thái khảo sát!' : 'Đổi trạng thái thất bại!')),
          );
        }
        break;
      case 'DELETE':
        if (s.hasResponses) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa khảo sát đã có phản hồi!'), backgroundColor: AppColors.danger),
          );
          return;
        }
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa bài khảo sát', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            content: Text('Bạn có chắc muốn xóa khảo sát "${s.title}" không?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa Khảo Sát', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final res = await apiService.deleteSurvey(s.surveyId, token: token);
          if (mounted) {
            _loadSurveys();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
            );
          }
        }
        break;
    }
  }
}
