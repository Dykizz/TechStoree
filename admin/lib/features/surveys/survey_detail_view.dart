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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class SurveyDetailView extends StatefulWidget {
  final int surveyId;
  final VoidCallback onBack;
  final Function(SurveyAdminDetail survey) onEdit;
  final Function(SurveyAdminList survey) onAssign;
  final Function(int surveyId) onViewStats;
  final VoidCallback onSurveyChanged;

  const SurveyDetailView({
    super.key,
    required this.surveyId,
    required this.onBack,
    required this.onEdit,
    required this.onAssign,
    required this.onViewStats,
    required this.onSurveyChanged,
  });

  @override
  State<SurveyDetailView> createState() => _SurveyDetailViewState();
}

class _SurveyDetailViewState extends State<SurveyDetailView> {
  late Future<SurveyAdminDetail?> _detailFuture;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _detailFuture = apiService.getSurveyById(widget.surveyId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final token = Provider.of<AuthProvider>(context).token;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return FutureBuilder<SurveyAdminDetail?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final survey = snapshot.data;
        if (survey == null) {
          return Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
                    const SizedBox(width: 8),
                    Text('Chi tiết bài khảo sát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                  ],
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.assignment_late_rounded,
                    title: 'Không tìm thấy bài khảo sát',
                    message: 'Bài khảo sát này có thể đã bị xóa hoặc không còn tồn tại trên hệ thống.',
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb & Action Header
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Danh sách khảo sát', style: TextStyle(fontSize: 12)),
                  ),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      survey.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Page Header with Actions
              PageHeader(
                title: survey.title,
                subtitle: 'Mã ID khảo sát: #${survey.surveyId} • Khởi tạo: ${survey.createdAt.day}/${survey.createdAt.month}/${survey.createdAt.year}',
                action: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Phát Khảo Sát',
                      icon: Icons.send_rounded,
                      onPressed: () => widget.onAssign(survey),
                    ),
                    AppButton(
                      label: 'Thống Kê',
                      icon: Icons.bar_chart_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => widget.onViewStats(survey.surveyId),
                    ),
                    AppButton(
                      label: 'Chỉnh Sửa',
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.outline,
                      onPressed: () => widget.onEdit(survey),
                    ),
                    AppButton(
                      label: 'Nhân Bản',
                      icon: Icons.copy_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _confirmClone(context, apiService, token, survey),
                    ),
                    AppButton(
                      label: survey.isActive ? 'Tạm Dừng' : 'Mở Nhận Bài',
                      icon: survey.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _toggleActive(apiService, token, survey),
                    ),
                    Tooltip(
                      message: survey.hasResponses ? 'Không thể xóa khảo sát đã có phản hồi' : 'Xóa bài khảo sát',
                      child: AppButton(
                        label: 'Xóa',
                        icon: Icons.delete_outline_rounded,
                        variant: AppButtonVariant.danger,
                        onPressed: survey.hasResponses ? null : () => _confirmDelete(context, apiService, token, survey),
                      ),
                    ),
                  ],
                ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tiêu đề khảo sát:', style: TextStyle(fontSize: 11, color: textSecondary)),
                              Text(survey.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: survey.isActive ? 'ĐANG MỞ NỘP BÀI' : 'TẠM DỪNG',
                          isSuccess: survey.isActive,
                          isDanger: !survey.isActive,
                        ),
                      ],
                    ),
                    if (survey.description != null && survey.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Mô tả nội dung:', style: TextStyle(fontSize: 11, color: textSecondary)),
                      Text(survey.description!, style: TextStyle(fontSize: 12, color: textPrimary)),
                    ],
                    const Divider(height: 24),
                    Row(
                      children: [
                        _buildInfoTile('Tổng phát bài', '${survey.totalAssigned} KH', textPrimary, textSecondary),
                        _buildInfoTile('Đã nộp bài', '${survey.totalCompleted} KH', textPrimary, textSecondary),
                        _buildInfoTile('Tỷ lệ phản hồi', '${survey.responseRatePercent}%', AppColors.primary, textSecondary, isBold: true),
                        _buildInfoTile('Cấu trúc câu hỏi', survey.hasResponses ? 'Đã khóa (Có phản hồi)' : 'Được phép chỉnh sửa', survey.hasResponses ? AppColors.warning : AppColors.success, textSecondary),
                      ],
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

  Widget _buildInfoTile(String label, String value, Color valueColor, Color labelColor, {bool isBold = false}) {
    return Expanded(
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
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
              StatusBadge(
                label: (voucher?.isActive == true) ? 'VOUCHER HOẠT ĐỘNG' : 'TẠM TẮT',
                isSuccess: voucher?.isActive == true,
                isDanger: voucher?.isActive != true,
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
                _buildVoucherMeta('Thời hạn voucher', '${voucher.startDate.day}/${voucher.startDate.month} - ${voucher.endDate.day}/${voucher.endDate.month}/${voucher.endDate.year}', textPrimary, textSecondary),
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
                const ContainerBadge(label: 'Bắt buộc', color: AppColors.danger)
              else
                const ContainerBadge(label: 'Tùy chọn', color: Colors.grey),
              const SizedBox(width: 6),
              ContainerBadge(label: q.questionType.displayName, color: AppColors.primary),
            ],
          ),

          if (q.questionType == SurveyQuestionType.SINGLE_CHOICE && q.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: q.options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(opt.optionText, style: TextStyle(fontSize: 12, color: textPrimary))),
                        if (opt.voteCount > 0)
                          Text('${opt.voteCount} vote (${opt.percentage}%)', style: TextStyle(fontSize: 11, color: textSecondary)),
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

    if (confirm == true) {
      final res = await apiService.toggleSurveyActive(survey.surveyId, token: token);
      if (mounted) {
        _loadDetail();
        widget.onSurveyChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res ? 'Đã $action khảo sát thành công!' : 'Thao tác thất bại!')),
        );
      }
    }
  }

  Future<void> _confirmClone(BuildContext context, ApiService apiService, String? token, SurveyAdminDetail survey) async {
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

    if (confirm == true) {
      final res = await apiService.cloneSurvey(survey.surveyId, token: token);
      if (mounted) {
        widget.onSurveyChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, ApiService apiService, String? token, SurveyAdminDetail survey) async {
    if (survey.hasResponses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa khảo sát đã có phản hồi!'), backgroundColor: AppColors.danger),
      );
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

    if (confirm == true) {
      final res = await apiService.deleteSurvey(survey.surveyId, token: token);
      if (mounted) {
        widget.onSurveyChanged();
        if (res.success) {
          widget.onBack();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }
}

class ContainerBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ContainerBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
