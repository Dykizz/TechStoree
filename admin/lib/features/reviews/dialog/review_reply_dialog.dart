import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/review.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';

/// Hộp thoại xem chi tiết đánh giá và soạn / chỉnh sửa / xóa phản hồi từ cửa hàng.
class ReviewReplyDialog extends StatefulWidget {
  final ReviewItem review;
  final bool canReply;
  final VoidCallback onReplySubmitted;

  const ReviewReplyDialog({
    super.key,
    required this.review,
    required this.canReply,
    required this.onReplySubmitted,
  });

  @override
  State<ReviewReplyDialog> createState() => _ReviewReplyDialogState();
}

class _ReviewReplyDialogState extends State<ReviewReplyDialog> {
  late final TextEditingController _replyCtrl;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  static const List<String> _quickReplies = [
    'Dạ TechStoree cảm ơn quý khách đã tin tưởng và đánh giá tích cực ạ! Chúc quý khách có trải nghiệm tuyệt vời cùng sản phẩm!',
    'Dạ Shop rất tiếc về trải nghiệm chưa ưng ý này ạ! Đội ngũ CSKH xin phép liên hệ hỗ trợ đổi trả/bảo hành ngay lập tức cho bạn nhé!',
    'Sản phẩm được bảo hành chính hãng 12 tháng tại TechStoree, nếu có bất kỳ lỗi kỹ thuật nào shop hỗ trợ 1 đổi 1 ngay ạ!',
  ];

  @override
  void initState() {
    super.initState();
    _replyCtrl = TextEditingController(text: widget.review.replyContent ?? '');
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply(ApiService apiService, String? token) async {
    if (!widget.canReply || _isSubmitting || _isDeleting) return;
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      AppToast.warning(context, 'Vui lòng nhập nội dung phản hồi!');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await apiService.replyReview(widget.review.reviewId, text, token: token);
      if (!mounted) return;

      if (res.success) {
        widget.onReplySubmitted();
        Navigator.pop(context);
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Đã lưu phản hồi thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Thao tác thất bại!');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteReply(ApiService apiService, String? token) async {
    if (!widget.canReply || _isSubmitting || _isDeleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Xác nhận xóa phản hồi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        content: const Text('Bạn có chắc muốn xóa phản hồi của cửa hàng đối với đánh giá này không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false)),
          AppButton(label: 'Xóa phản hồi', variant: AppButtonVariant.danger, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final res = await apiService.deleteReply(widget.review.reviewId, token: token);
      if (!mounted) return;

      if (res.success) {
        widget.onReplySubmitted();
        Navigator.pop(context);
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Đã xóa phản hồi!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Thao tác thất bại!');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    final review = widget.review;
    final isBusy = _isSubmitting || _isDeleting;

    return PopScope(
      canPop: !isBusy,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: dialogBg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(review, isBusy, textPrimary, textSecondary),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewCustomerSummaryCard(
                        review: review,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                      const SizedBox(height: 18),
                      _buildReplySection(review, isBusy, textPrimary, textSecondary, cardBg, cardBorder),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildFooter(review, isBusy, apiService, authProvider.token),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ReviewItem review,
    bool isBusy,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.canReply
                      ? 'Phản hồi đánh giá #${review.reviewId}'
                      : 'Chi tiết đánh giá #${review.reviewId}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                ),
                Text(
                  widget.canReply
                      ? 'Gửi phản hồi chính thức từ TechStoree đến khách hàng'
                      : 'Chế độ xem chi tiết (chỉ tài khoản có quyền phản hồi mới chỉnh sửa được)',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: isBusy ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySection(
    ReviewItem review,
    bool isBusy,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nội dung phản hồi từ TechStoree:',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
        ),
        const SizedBox(height: 4),
        if (widget.canReply) ...[
          Text(
            'Khách hàng sẽ nhìn thấy câu trả lời này trực tiếp bên dưới đánh giá của họ.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replyCtrl,
            maxLines: 4,
            maxLength: 1000,
            autofocus: true,
            enabled: !isBusy,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Nhập nội dung phản hồi chân thành, chu đáo từ TechStoree...',
              hintStyle: TextStyle(fontSize: 12.5, color: textSecondary.withValues(alpha: 0.6)),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gợi ý câu trả lời nhanh:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _quickReplies.map((reply) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Tooltip(
                  message: reply,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: isBusy
                        ? null
                        : () {
                            setState(() {
                              _replyCtrl.text = reply;
                              _replyCtrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: _replyCtrl.text.length),
                              );
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reply,
                              style: TextStyle(fontSize: 11.5, color: textPrimary, height: 1.35),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder),
            ),
            child: Text(
              review.hasReply ? review.replyContent!.trim() : '(Cửa hàng chưa gửi phản hồi cho đánh giá này)',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: review.hasReply ? FontStyle.normal : FontStyle.italic,
                color: review.hasReply ? textPrimary : textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(
    ReviewItem review,
    bool isBusy,
    ApiService apiService,
    String? token,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (widget.canReply && review.hasReply) ...[
            AppButton(
              label: _isDeleting ? 'Đang xóa...' : 'Xóa phản hồi',
              variant: AppButtonVariant.danger,
              icon: Icons.delete_outline_rounded,
              onPressed: isBusy ? null : () => _deleteReply(apiService, token),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                AppButton(
                  label: 'Đóng',
                  variant: AppButtonVariant.outline,
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                ),
                if (widget.canReply)
                  AppButton(
                    label: _isSubmitting ? 'Đang lưu...' : (review.hasReply ? 'Cập nhật phản hồi' : 'Gửi phản hồi'),
                    icon: Icons.send_rounded,
                    variant: AppButtonVariant.primary,
                    isLoading: _isSubmitting,
                    onPressed: isBusy ? null : () => _submitReply(apiService, token),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCustomerSummaryCard extends StatelessWidget {
  final ReviewItem review;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _ReviewCustomerSummaryCard({
    required this.review,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedFull = review.fullName.trim();
    final trimmedUser = review.username.trim();
    final displayName = trimmedFull.isNotEmpty
        ? trimmedFull
        : (trimmedUser.isNotEmpty ? trimmedUser : 'Khách hàng');
    final avatarInitial = trimmedFull.isNotEmpty
        ? trimmedFull.substring(0, 1).toUpperCase()
        : (trimmedUser.isNotEmpty ? trimmedUser.substring(0, 1).toUpperCase() : '?');
    final formattedDate = AppDateFormatter.formatDateTime(review.createdAt);
    final metaLine = trimmedUser.isNotEmpty ? '$formattedDate • @$trimmedUser' : formattedDate;
    final validImageUrls = review.imageUrls.where((url) => url.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng sản phẩm & đơn hàng
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: review.productImageUrl != null && review.productImageUrl!.trim().isNotEmpty
                      ? Image.network(
                          review.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_outlined, size: 20),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Phân loại: ${review.variantName.isNotEmpty ? review.variantName : "Mặc định"} • Đơn hàng: #${review.orderCode}',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),

          // Khách hàng & Số sao
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  avatarInitial,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      metaLine,
                      style: TextStyle(fontSize: 10.5, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: review.isPositive
                      ? Colors.amber.withValues(alpha: 0.15)
                      : (review.isNegative ? AppColors.danger.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: review.isPositive ? Colors.amber.shade700 : (review.isNegative ? AppColors.danger : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating.toStringAsFixed(1)} ★',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: review.isPositive ? Colors.amber.shade900 : (review.isNegative ? AppColors.danger : textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Câu nhận xét của khách
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border(
                left: BorderSide(
                  color: review.isPositive ? Colors.amber : (review.isNegative ? AppColors.danger : AppColors.primary),
                  width: 3.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.comment != null && review.comment!.trim().isNotEmpty
                      ? '"${review.comment}"'
                      : '(Khách hàng không để lại nhận xét chữ, chỉ gửi đánh giá sao)',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: review.comment != null && review.comment!.trim().isNotEmpty ? textPrimary : textSecondary,
                    height: 1.4,
                  ),
                ),
                if (validImageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: validImageUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.withValues(alpha: 0.12),
                          child: Image.network(
                            url,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

