import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/survey.dart';
import '../../core/models/voucher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/smooth_loading_wrapper.dart';
import '../../core/widgets/status_badge.dart';
import 'survey_helpers.dart';

class SurveyDetailView extends StatefulWidget {
  final int surveyId;
  final String backLabel;
  final VoidCallback onBack;
  final Function(SurveyAdminDetail survey) onEdit;
  final Function(SurveyAdminList survey) onAssign;
  final Function(int surveyId) onViewStats;
  final void Function({bool reloadDetail}) onSurveyChanged;
  final int refreshTrigger;

  const SurveyDetailView({
    super.key,
    required this.surveyId,
    this.backLabel = 'Danh sách khảo sát',
    required this.onBack,
    required this.onEdit,
    required this.onAssign,
    required this.onViewStats,
    required this.onSurveyChanged,
    this.refreshTrigger = 0,
  });

  @override
  State<SurveyDetailView> createState() => _SurveyDetailViewState();
}

class _SurveyDetailViewState extends State<SurveyDetailView> {
  late Future<SurveyAdminDetail?> _detailFuture;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void didUpdateWidget(covariant SurveyDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.surveyId != oldWidget.surveyId || widget.refreshTrigger != oldWidget.refreshTrigger) {
      setState(_loadDetail);
    }
  }

  void _loadDetail() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _detailFuture = apiService.getSurveyById(widget.surveyId, token: token, throwOnError: true);
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final token = authProvider.token;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return CachedFutureBuilder<SurveyAdminDetail?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        if (isWaiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppTokens.space16),
            child: SmoothLoadingWrapper(
              isLoading: true,
              hasData: false,
              initialMinHeight: 420,
              child: SizedBox.shrink(),
            ),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return buildSurveyFallbackView(
            headerTitle: 'Chi tiết bài khảo sát',
            textPrimary: textPrimary,
            onBack: widget.onBack,
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải chi tiết bài khảo sát',
            message: extractFriendlySurveyError(snapshot.error),
            action: AppButton(
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              onPressed: () => setState(_loadDetail),
            ),
          );
        }

        final survey = snapshot.data;
        if (survey == null) {
          return buildSurveyFallbackView(
            headerTitle: 'Chi tiết bài khảo sát',
            textPrimary: textPrimary,
            onBack: widget.onBack,
            icon: Icons.assignment_late_rounded,
            title: 'Không tìm thấy bài khảo sát',
            message: 'Bài khảo sát này có thể đã bị xóa hoặc không còn tồn tại trên hệ thống.',
            action: AppButton(
              label: 'Quay lại danh sách',
              variant: AppButtonVariant.outline,
              onPressed: widget.onBack,
            ),
          );
        }

        return SmoothLoadingWrapper(
          isLoading: isWaiting || _isActionBusy,
          hasData: true,
          blockInteraction: _isActionBusy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.hasError)
                  buildSurveyErrorBanner(
                    error: snapshot.error,
                    onRetry: () => setState(_loadDetail),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                // Breadcrumb & Action Header
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(widget.backLabel, style: const TextStyle(fontSize: 12)),
                    ),
                    const Text(' / ', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(
                        'Chi tiết #${survey.surveyId}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Page Header + Status Badge (full-width title)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            survey.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã ID khảo sát: #${survey.surveyId} • Khởi tạo: ${AppDateFormatter.formatDate(survey.createdAt)}',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(
                      label: survey.isExpired
                          ? 'ĐÃ HẾT HẠN'
                          : (!survey.isActive
                              ? 'TẠM DỪNG'
                              : (survey.isUpcoming ? 'CHỜ MỞ THEO LỊCH' : 'ĐANG MỞ NỘP BÀI')),
                      isSuccess: !survey.isExpired && survey.isActive && !survey.isUpcoming,
                      isDanger: survey.isExpired,
                      isWarning: !survey.isExpired && !survey.isActive,
                      isInfo: survey.isUpcoming,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Bar
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (authProvider.can('Surveys.Assign'))
                      AppButton(
                        label: 'Phát khảo sát',
                        icon: Icons.send_rounded,
                        onPressed: _isActionBusy ? null : () => widget.onAssign(survey),
                      ),
                    AppButton(
                      label: 'Thống kê',
                      icon: Icons.bar_chart_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: _isActionBusy ? null : () => widget.onViewStats(survey.surveyId),
                    ),
                    AppButton(
                      label: _isActionBusy ? 'Đang xử lý...' : 'Xuất báo cáo',
                      icon: Icons.file_download_outlined,
                      variant: AppButtonVariant.outline,
                      onPressed: _isActionBusy ? null : () => _exportReport(apiService, token, survey.surveyId),
                    ),
                    if (authProvider.can('Surveys.Update'))
                      AppButton(
                        label: 'Chỉnh sửa',
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.outline,
                        onPressed: _isActionBusy ? null : () => widget.onEdit(survey),
                      ),
                    if (authProvider.can('Surveys.Create'))
                      AppButton(
                        label: 'Nhân bản',
                        icon: Icons.copy_rounded,
                        variant: AppButtonVariant.outline,
                        onPressed: _isActionBusy ? null : () => _confirmClone(apiService, token, survey),
                      ),
                    if (authProvider.can('Surveys.Update'))
                      AppButton(
                        label: survey.isActive ? 'Tạm dừng' : 'Mở nhận bài',
                        icon: survey.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        variant: AppButtonVariant.outline,
                        onPressed: _isActionBusy ? null : () => _toggleActive(apiService, token, survey),
                      ),
                    if (authProvider.can('Surveys.Delete'))
                      Tooltip(
                        message: survey.hasResponses ? 'Không thể xóa khảo sát đã có phản hồi' : 'Xóa bài khảo sát',
                        child: AppButton(
                          label: 'Xóa',
                          icon: Icons.delete_outline_rounded,
                          variant: AppButtonVariant.danger,
                          onPressed: (survey.hasResponses || _isActionBusy)
                              ? null
                              : () => _confirmDelete(apiService, token, survey),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // SECTION A: GENERAL INFORMATION
                _buildSectionTitle('A. THÔNG TIN CHUNG KHẢO SÁT', textSecondary),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (survey.description != null && survey.description!.trim().isNotEmpty) ...[
                        Text('Mô tả nội dung:', style: TextStyle(fontSize: 11, color: textSecondary)),
                        const SizedBox(height: 2),
                        Text(survey.description!, style: TextStyle(fontSize: 12, color: textPrimary)),
                        const Divider(height: 24),
                      ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = constraints.maxWidth;
                        final cols = maxW >= 860 ? 5 : (maxW >= 540 ? 3 : 2);
                        const spacing = 16.0;
                        final tileWidth = (maxW - spacing * (cols - 1)) / cols;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: 12,
                          children: [
                            _buildInfoTile(tileWidth, 'Tổng phát bài', '${survey.totalAssigned} KH', textPrimary, textSecondary),
                            _buildInfoTile(tileWidth, 'Đã nộp bài', '${survey.totalCompleted} KH', textPrimary, textSecondary),
                            _buildInfoTile(tileWidth, 'Tỷ lệ phản hồi', '${survey.responseRatePercent}%', AppColors.primary, textSecondary, isBold: true),
                            _buildInfoTile(
                              tileWidth,
                              'Ngày bắt đầu',
                              survey.startAt != null ? AppDateFormatter.formatDateTime(survey.startAt!) : 'Mở ngay',
                              survey.isUpcoming ? AppColors.info : textPrimary,
                              textSecondary,
                            ),
                            _buildInfoTile(
                              tileWidth,
                              'Hạn chót',
                              survey.expiredAt != null ? AppDateFormatter.formatDateTime(survey.expiredAt!) : 'Không giới hạn',
                              survey.isExpired ? AppColors.danger : (survey.expiredAt != null ? AppColors.warning : textPrimary),
                              textSecondary,
                            ),
                            _buildInfoTile(
                              tileWidth,
                              'Cấu trúc câu hỏi',
                              survey.hasResponses ? 'Đã khóa (Có phản hồi)' : 'Được phép chỉnh sửa',
                              survey.hasResponses ? AppColors.warning : AppColors.success,
                              textSecondary,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION B: REWARD VOUCHER SECTION
              _buildSectionTitle('B. VOUCHER PHẦN THƯỞNG KHI NỘP BÀI', textSecondary),
              const SizedBox(height: 8),
              _buildRewardVoucherCard(survey.rewardVoucher, survey.rewardVoucherCode, survey.rewardVoucherTitle, isDark, cardBg, borderColor, textPrimary, textSecondary),

              const SizedBox(height: 20),

              // SECTION C: QUESTIONS SECTION
              _buildSectionTitle('C. DANH SÁCH CÂU HỎI ĐỘNG (${survey.questions.length} CÂU)', textSecondary),
              const SizedBox(height: 8),
              if (survey.questions.isEmpty)
                const EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'Chưa có câu hỏi nào',
                  message: 'Bài khảo sát này chưa có danh sách câu hỏi nào.',
                )
              else
                ...survey.questions.map((q) => _buildQuestionCard(q, isDark, cardBg, borderColor, textPrimary, textSecondary)),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
    );
  }

  Widget _buildInfoTile(double width, String label, String value, Color valueColor, Color labelColor, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildRewardVoucherCard(Voucher? voucher, String? code, String? title, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    if (voucher == null && (code == null || code.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_outlined, color: Colors.grey, size: 24),
            const SizedBox(width: 12),
            Text('Không có voucher thưởng cho bài khảo sát này.', style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  voucher?.code ?? code ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  voucher?.title ?? title ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              if (voucher != null)
                StatusBadge(
                  label: voucher.isActive ? 'VOUCHER HOẠT ĐỘNG' : 'TẠM TẮT',
                  isSuccess: voucher.isActive,
                  isDanger: !voucher.isActive,
                ),
            ],
          ),
          if (voucher != null) ...[
            const Divider(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _buildVoucherMeta('Loại giảm giá', voucher.isPercentage ? 'Giảm ${voucher.discountValue.toInt()}%' : 'Giảm ${currencyFormat.format(voucher.discountValue)}', textPrimary, textSecondary),
                if (voucher.minOrderValue > 0)
                  _buildVoucherMeta('Đơn tối thiểu', currencyFormat.format(voucher.minOrderValue), textPrimary, textSecondary),
                if (voucher.maxDiscountAmount != null)
                  _buildVoucherMeta('Giảm tối đa', currencyFormat.format(voucher.maxDiscountAmount), textPrimary, textSecondary),
                _buildVoucherMeta('Lượt dùng / Giới hạn', '${voucher.usedCount} / ${voucher.usageLimit ?? "Không giới hạn"}', textPrimary, textSecondary),
                _buildVoucherMeta('Thời hạn voucher', '${AppDateFormatter.formatDate(voucher.startDate)} - ${AppDateFormatter.formatDate(voucher.endDate)}', textPrimary, textSecondary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherMeta(String label, String value, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
      ],
    );
  }

  Widget _buildQuestionCard(SurveyQuestionDetail q, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: Text('${q.orderNum}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.questionText,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              if (q.isRequired)
                const _ContainerBadge(label: 'Bắt buộc', color: AppColors.danger)
              else
                const _ContainerBadge(label: 'Tùy chọn', color: Colors.grey),
              const SizedBox(width: 6),
              _ContainerBadge(
                label: q.questionType.displayName,
                color: q.questionType == SurveyQuestionType.MULTI_CHOICE
                    ? const Color(0xFF0284C7)
                    : (q.questionType == SurveyQuestionType.SINGLE_CHOICE
                        ? AppColors.primary
                        : AppColors.warning),
              ),
            ],
          ),

          if (q.questionType.isChoiceBased && q.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: q.options.map((opt) {
                  final isMulti = q.questionType == SurveyQuestionType.MULTI_CHOICE;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isMulti
                              ? Icons.check_box_outline_blank
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: isMulti
                              ? const Color(0xFF0284C7)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(opt.optionText, style: TextStyle(fontSize: 12, color: textPrimary))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleActive(ApiService apiService, String? token, SurveyAdminDetail survey) async {
    if (_isActionBusy) return;
    final action = survey.isActive ? 'tạm dừng' : 'mở lại';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $action nhận bài', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn $action nhận bài cho khảo sát "${survey.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác Nhận'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isActionBusy = true);
    try {
      final res = await apiService.toggleSurveyActive(survey.surveyId, token: token);
      if (!mounted) return;
      if (res) {
        setState(_loadDetail);
        widget.onSurveyChanged(reloadDetail: false);
        AppToast.success(context, 'Đã $action khảo sát thành công!');
      } else {
        final errMsg = apiService.lastErrorMessage.isNotEmpty ? apiService.lastErrorMessage : 'Thao tác thất bại!';
        AppToast.error(context, errMsg);
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _confirmClone(ApiService apiService, String? token, SurveyAdminDetail survey) async {
    if (_isActionBusy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhân bản khảo sát', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Tạo một bản sao mới từ khảo sát "${survey.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nhân Bản'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isActionBusy = true);
    try {
      final res = await apiService.cloneSurvey(survey.surveyId, token: token);
      if (!mounted) return;
      if (res.success) {
        widget.onSurveyChanged(reloadDetail: false);
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Nhân bản khảo sát thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Nhân bản khảo sát thất bại!');
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _confirmDelete(ApiService apiService, String? token, SurveyAdminDetail survey) async {
    if (_isActionBusy) return;
    if (survey.hasResponses) {
      AppToast.warning(context, 'Không thể xóa khảo sát đã có phản hồi!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa bài khảo sát', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Hành động này không thể hoàn tác. Xóa khảo sát "${survey.title}"?'),
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

    if (confirm != true || !mounted) return;
    setState(() => _isActionBusy = true);
    try {
      final res = await apiService.deleteSurvey(survey.surveyId, token: token);
      if (!mounted) return;
      if (res.success) {
        widget.onSurveyChanged(reloadDetail: false);
        widget.onBack();
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Xóa khảo sát thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Xóa khảo sát thất bại!');
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _exportReport(ApiService apiService, String? token, int surveyId) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);
    try {
      await exportSurveyCsvReport(
        context: context,
        surveyId: surveyId,
        apiService: apiService,
        token: token,
      );
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }
}

class _ContainerBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ContainerBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
