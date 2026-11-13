import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/review.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/data_table_container.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/scrollable_table_wrapper.dart';
import '../../../core/widgets/smooth_loading_wrapper.dart';

/// Bảng dữ liệu 5 cột hiển thị danh sách đánh giá, trạng thái tải/lỗi và thanh phân trang.
class ReviewDataTable extends StatelessWidget {
  final Future<ReviewPagedResult> reviewsFuture;
  final Object? reviewsError;
  final bool isActionBusy;
  final int currentPage;
  final int itemsPerPage;
  final String Function(Object? error) formatError;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;
  final void Function(ReviewItem review, {required bool canReply}) onOpenReplyDialog;
  final Future<void> Function(ReviewItem review) onToggleHideReview;

  const ReviewDataTable({
    super.key,
    required this.reviewsFuture,
    required this.reviewsError,
    required this.isActionBusy,
    required this.currentPage,
    required this.itemsPerPage,
    required this.formatError,
    required this.onRetry,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
    required this.onOpenReplyDialog,
    required this.onToggleHideReview,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return CachedFutureBuilder<ReviewPagedResult>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final hasData = snapshot.hasData;
        final result = snapshot.data;
        final reviews = result?.items ?? [];
        final totalCount = result?.totalCount ?? 0;
        final totalPages = result?.totalPages ?? 1;
        final activeError = snapshot.error ?? reviewsError;
        final hasError = !isWaiting && activeError != null;

        return SmoothLoadingWrapper(
          isLoading: isWaiting || isActionBusy,
          hasData: hasData,
          blockInteraction: isActionBusy,
          initialMinHeight: 400,
          child: DataTableContainer(
            child: hasError && (!hasData || reviews.isEmpty)
                ? EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Không thể tải danh sách đánh giá',
                    message: formatError(activeError),
                    action: AppButton(
                      label: 'Thử lại',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  )
                : reviews.isEmpty
                    ? const EmptyState(
                        icon: Icons.rate_review_outlined,
                        title: 'Không tìm thấy đánh giá nào',
                        message: 'Không có đánh giá phù hợp với tiêu chí lọc hiện tại.',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasError)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.08),
                                border: Border(bottom: BorderSide(color: AppColors.danger.withValues(alpha: 0.25))),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formatError(activeError),
                                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: onRetry,
                                    child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ScrollableTableWrapper(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowHeight: 38,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 56,
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              ),
                              columns: [
                                DataColumn(label: Text('Sản phẩm & Biến thể', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Khách hàng & Ngày', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                              ],
                              rows: _buildTableRows(reviews, isDark, textPrimary, textSecondary, authProvider),
                            ),
                          ),

                          // Bảng phân trang
                          if (totalCount > 0)
                            AppPagination(
                              currentPage: currentPage,
                              totalPages: totalPages,
                              totalItems: totalCount,
                              itemsPerPage: itemsPerPage,
                              onPageChanged: onPageChanged,
                              onItemsPerPageChanged: onItemsPerPageChanged,
                            ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  List<DataRow> _buildTableRows(
    List<ReviewItem> reviews,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    AuthProvider authProvider,
  ) {
    final rows = <DataRow>[];
    final canReply = authProvider.can('Reviews.Reply');
    final canHide = authProvider.can('Reviews.Hide');

    for (final review in reviews) {
      final trimmedFull = review.fullName.trim();
      final trimmedUser = review.username.trim();
      final displayName = trimmedFull.isNotEmpty
          ? trimmedFull
          : (trimmedUser.isNotEmpty ? trimmedUser : 'Khách hàng');

      rows.add(
        DataRow(
          onSelectChanged: (_) => onOpenReplyDialog(review, canReply: canReply),
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
            }
            if (review.isHidden) {
              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFFEF2F2);
            }
            if (states.contains(WidgetState.hovered)) {
              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
            }
            return null;
          }),
          cells: [
            // 1. Sản phẩm & Biến thể
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 32,
                        height: 32,
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: review.productImageUrl != null && review.productImageUrl!.trim().isNotEmpty
                            ? Image.network(
                                review.productImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, size: 16),
                              )
                            : const Icon(Icons.inventory_2_outlined, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.productName,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            review.variantName.isNotEmpty ? review.variantName : 'Phân loại mặc định',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Khách hàng & Ngày
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#${review.reviewId}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textSecondary)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(AppDateFormatter.formatDateTime(review.createdAt), style: TextStyle(fontSize: 10.5, color: textSecondary)),
                  ],
                ),
              ),
            ),

            // 3. Đánh giá (Số sao)
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (index) {
                    final starVal = index + 1;
                    if (review.rating >= starVal) {
                      return const Icon(Icons.star_rounded, size: 14, color: Colors.amber);
                    } else if (review.rating >= starVal - 0.5) {
                      return const Icon(Icons.star_half_rounded, size: 14, color: Colors.amber);
                    } else {
                      return Icon(Icons.star_outline_rounded, size: 14, color: Colors.grey.shade400);
                    }
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '${review.rating.toStringAsFixed(1)} ★',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                  ),
                ],
              ),
            ),

            // 4. Trạng thái
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: review.isHidden ? AppColors.dangerBg : AppColors.successBg,
                  border: Border.all(color: review.isHidden ? AppColors.dangerBorder : AppColors.successBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  review.isHidden ? 'Đã ẩn' : 'Công khai',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: review.isHidden ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ),

            // 5. Thao tác
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReply)
                    Tooltip(
                      message: review.hasReply ? 'Sửa phản hồi' : 'Gửi phản hồi',
                      child: IconButton(
                        icon: Icon(
                          review.hasReply ? Icons.edit_note_rounded : Icons.reply_rounded,
                          size: 16,
                          color: review.hasReply ? textSecondary : AppColors.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: isActionBusy ? null : () => onOpenReplyDialog(review, canReply: true),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Xem chi tiết đánh giá',
                      child: IconButton(
                        icon: Icon(Icons.rate_review_outlined, size: 16, color: textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: isActionBusy ? null : () => onOpenReplyDialog(review, canReply: false),
                      ),
                    ),
                  if (canHide) ...[
                    const SizedBox(width: 2),
                    Tooltip(
                      message: review.isHidden ? 'Hiện lại đánh giá' : 'Ẩn đánh giá này',
                      child: IconButton(
                        icon: Icon(
                          review.isHidden ? Icons.visibility_off_rounded : Icons.visibility_outlined,
                          size: 16,
                          color: review.isHidden ? AppColors.danger : textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: isActionBusy ? null : () => onToggleHideReview(review),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }
}

