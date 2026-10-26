import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/review.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Filter States
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _selectedStatusTab = 'all'; // 'all', 'pending', 'replied', 'negative', 'hidden'
  double? _selectedRating; // null = all, 5.0, 4.0, 3.0, 2.0, 1.0
  int? _filteredProductId;
  String? _filteredProductName;
  bool _onlyWithImages = false;

  // Data Futures
  late Future<ReviewPagedResult> _reviewsFuture;
  late Future<ReviewStatistics?> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    // Map status tab to query filter params
    bool? hasReply;
    bool? isHidden;
    double? minRating;
    double? maxRating;

    if (_selectedStatusTab == 'pending') {
      hasReply = false;
      isHidden = false;
    } else if (_selectedStatusTab == 'replied') {
      hasReply = true;
      isHidden = false;
    } else if (_selectedStatusTab == 'negative') {
      maxRating = 2.0;
      isHidden = false;
    } else if (_selectedStatusTab == 'hidden') {
      isHidden = true;
    }

    _reviewsFuture = apiService.getAdminReviews(
      page: _currentPage,
      pageSize: _itemsPerPage,
      productId: _filteredProductId,
      rating: _selectedRating,
      minRating: minRating,
      maxRating: maxRating,
      hasReply: hasReply,
      isHidden: isHidden,
      hasImages: _onlyWithImages ? true : null,
      search: _searchCtrl.text.trim(),
      sortBy: 'created_at',
      isAscending: false,
      token: token,
    );

    _statsFuture = apiService.getDetailedReviewStatistics(token: token);
  }

  void _refreshList({bool resetPage = false}) {
    setState(() {
      if (resetPage) _currentPage = 1;
      _loadData();
    });
  }

  void _filterByProduct(int productId, String productName) {
    setState(() {
      _filteredProductId = productId;
      _filteredProductName = productName;
      _currentPage = 1;
      _loadData();
    });
  }

  void _clearProductFilter() {
    setState(() {
      _filteredProductId = null;
      _filteredProductName = null;
      _currentPage = 1;
      _loadData();
    });
  }

  void _openReplyDialog(ReviewItem review) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReviewReplyDialog(
        review: review,
        dateFormat: _dateFormat,
        onReplySubmitted: () => _refreshList(),
      ),
    );
  }

  Future<void> _toggleHideReview(ReviewItem review, ApiService apiService, String? token) async {
    final willHide = !review.isHidden;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          willHide ? 'Ẩn đánh giá' : 'Hiện lại đánh giá',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        content: Text(
          willHide
              ? 'Bạn có chắc muốn ẩn đánh giá này khỏi website công khai? Đánh giá này sẽ không còn hiển thị với khách hàng.'
              : 'Bạn có chắc muốn kích hoạt hiển thị lại đánh giá này lên website không?',
        ),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false)),
          AppButton(
            label: willHide ? 'Ẩn đánh giá' : 'Hiển thị lại',
            variant: willHide ? AppButtonVariant.danger : AppButtonVariant.primary,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await apiService.toggleHideReview(review.reviewId, willHide, token: token);
    if (!mounted) return;

    if (res.success) {
      _refreshList();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Thao tác thành công!' : 'Thất bại!')),
        backgroundColor: res.success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  void _showImageLightbox(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 320,
                  height: 240,
                  color: Colors.black87,
                  alignment: Alignment.center,
                  child: const Text('Không thể tải hình ảnh', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PAGE HEADER
          PageHeader(
            title: 'Quản lý đánh giá sản phẩm',
            subtitle: 'Theo dõi phản hồi khách hàng, kiểm soát chất lượng sản phẩm và chăm sóc khách hàng',
            action: AppButton(
              label: 'Làm mới',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () => _refreshList(),
            ),
          ),

          // 2. WIDGET TOP 5 TỐT NHẤT & TOP 5 CẦN LƯU Ý
          FutureBuilder<ReviewStatistics?>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return _buildRankingsSection(stats, isDark, textPrimary, textSecondary, cardBg, cardBorder);
            },
          ),

          const SizedBox(height: AppTokens.space16),

          // 3. THANH TABS LỌC TRẠNG THÁI
          FutureBuilder<ReviewStatistics?>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return _buildStatusTabBar(stats, isDark, textPrimary, textSecondary, cardBg, cardBorder);
            },
          ),

          // 4. BỘ LỌC ĐA CHIỀU (SEARCH + DROPDOWN RATING + FILTER CHIPS)
          FilterBar(
            searchField: SizedBox(
              width: 320,
              child: AppTextField(
                controller: _searchCtrl,
                hintText: 'Tìm theo tên khách, sản phẩm, nhận xét...',
                prefixIcon: Icons.search_rounded,
                onFieldSubmitted: (_) => _refreshList(resetPage: true),
              ),
            ),
            filters: [
              // Dropdown lọc số sao
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double?>(
                    value: _selectedRating,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500),
                    dropdownColor: cardBg,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả số sao')),
                      DropdownMenuItem(value: 5.0, child: Text('⭐⭐⭐⭐⭐ (5 sao)')),
                      DropdownMenuItem(value: 4.0, child: Text('⭐⭐⭐⭐ (4 sao)')),
                      DropdownMenuItem(value: 3.0, child: Text('⭐⭐⭐ (3 sao)')),
                      DropdownMenuItem(value: 2.0, child: Text('⭐⭐ (2 sao)')),
                      DropdownMenuItem(value: 1.0, child: Text('⭐ (1 sao)')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedRating = val;
                        _currentPage = 1;
                        _loadData();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Có ảnh đính kèm
              FilterChip(
                label: const Text('Có ảnh đính kèm', style: TextStyle(fontSize: 11.5)),
                selected: _onlyWithImages,
                onSelected: (val) {
                  setState(() {
                    _onlyWithImages = val;
                    _currentPage = 1;
                    _loadData();
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: _onlyWithImages ? AppColors.primary : cardBorder),
                ),
              ),
            ],
          ),

          // Hiển thị Chip đang lọc theo sản phẩm cụ thể (nếu có)
          if (_filteredProductId != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Text('Đang lọc đánh giá của: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Chip(
                    label: Text(
                      _filteredProductName ?? 'Sản phẩm #$_filteredProductId',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: _clearProductFilter,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 5. BẢNG DỮ LIỆU ĐÁNH GIÁ (DATA TABLE + INLINE COLLAPSIBLE REPLY CHAT BOX)
          FutureBuilder<ReviewPagedResult>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final result = snapshot.data;
              final reviews = result?.items ?? [];
              final totalCount = result?.totalCount ?? 0;
              final totalPages = result?.totalPages ?? 1;

              return DataTableContainer(
                child: reviews.isEmpty
                    ? const EmptyState(
                        icon: Icons.rate_review_outlined,
                        title: 'Không tìm thấy đánh giá nào',
                        message: 'Không có đánh giá phù hợp với tiêu chí lọc hiện tại.',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScrollableTableWrapper(
                            child: DataTable(
                              headingRowHeight: 42,
                              dataRowMinHeight: 68,
                              dataRowMaxHeight: 88,
                              columnSpacing: 18,
                              horizontalMargin: 16,
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              ),
                              columns: [
                                DataColumn(label: Text('Mã / Ngày', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Sản phẩm & Biến thể', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Số sao', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Nhận xét của khách', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Phản hồi từ Shop', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 12))),
                              ],
                              rows: _buildTableRows(reviews, isDark, textPrimary, textSecondary, authProvider, apiService),
                            ),
                          ),

                          // Bảng phân trang
                          if (totalCount > 0)
                            AppPagination(
                              currentPage: _currentPage,
                              totalPages: totalPages,
                              totalItems: totalCount,
                              itemsPerPage: _itemsPerPage,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                  _loadData();
                                });
                              },
                              onItemsPerPageChanged: (size) {
                                setState(() {
                                  _itemsPerPage = size;
                                  _currentPage = 1;
                                  _loadData();
                                });
                              },
                            ),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET TOP 5 ĐÁNH GIÁ TỐT & TIÊU CỰC
  // ==========================================
  Widget _buildRankingsSection(
    ReviewStatistics? stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    final topProducts = stats?.topRatedProducts ?? [];
    final lowestProducts = stats?.lowestRatedProducts ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final children = [
          // Card 1: 🏆 Top 5 Đánh giá Tốt nhất
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top 5 sản phẩm đánh giá tốt nhất',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                            ),
                            Text(
                              'Được khách hàng yêu thích và đánh giá sao cao nhất',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  if (topProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Chưa có dữ liệu xếp hạng đánh giá', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                      ),
                    )
                  else
                    ...topProducts.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      return _buildRankingItem(rank, item, isPositive: true, textPrimary: textPrimary, textSecondary: textSecondary);
                    }),
                ],
              ),
            ),
          ),

          if (!isMobile) const SizedBox(width: 16) else const SizedBox(height: 16),

          // Card 2: ⚠️ Top 5 Cần Lưu Ý (Đánh giá thấp / Tiêu cực)
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top 5 sản phẩm cần lưu ý (đánh giá thấp)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                            ),
                            Text(
                              'Sản phẩm có nhiều phản ánh tiêu cực (1-2★) cần kiểm tra chất lượng',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  if (lowestProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Chưa có sản phẩm nào bị đánh giá tiêu cực', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                      ),
                    )
                  else
                    ...lowestProducts.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      return _buildRankingItem(rank, item, isPositive: false, textPrimary: textPrimary, textSecondary: textSecondary);
                    }),
                ],
              ),
            ),
          ),
        ];

        return isMobile ? Column(children: children) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }

  Widget _buildRankingItem(
    int rank,
    ProductRatingRanking item, {
    required bool isPositive,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color rankBadgeColor;
    if (rank == 1) {
      rankBadgeColor = Colors.amber;
    } else if (rank == 2) {
      rankBadgeColor = const Color(0xFF94A3B8); // Bạc
    } else if (rank == 3) {
      rankBadgeColor = const Color(0xFFCD7F32); // Đồng
    } else {
      rankBadgeColor = Colors.grey.shade400;
    }

    return InkWell(
      onTap: () => _filterByProduct(item.productId, item.productName),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Huy hiệu Rank #1, #2, #3
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankBadgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: rankBadgeColor),
              ),
            ),
            const SizedBox(width: 8),

            // Ảnh thumbnail SP
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 32,
                height: 32,
                color: Colors.grey.withValues(alpha: 0.1),
                child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
                    ? Image.network(
                        item.productImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 16),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 16),
              ),
            ),
            const SizedBox(width: 10),

            // Tên SP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isPositive
                        ? '${item.totalReviews} lượt đánh giá (${item.positiveReviewCount} khen)'
                        : '${item.totalReviews} đánh giá • ${item.negativeReviewCount} khách chê (1-2★)',
                    style: TextStyle(fontSize: 10.5, color: isPositive ? textSecondary : AppColors.danger),
                  ),
                ],
              ),
            ),

            // Badge Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isPositive ? Colors.amber.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 13, color: isPositive ? Colors.amber.shade700 : AppColors.danger),
                  const SizedBox(width: 3),
                  Text(
                    item.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? Colors.amber.shade800 : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS TAB BAR
  // ==========================================
  Widget _buildStatusTabBar(
    ReviewStatistics? stats,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    final allCount = stats?.totalReviews ?? 0;
    final repliedCount = stats?.totalReplied ?? 0;
    final pendingCount = (allCount - repliedCount).clamp(0, allCount);
    final hiddenCount = stats?.totalHidden ?? 0;

    final tabs = [
      {'key': 'all', 'label': 'Tất cả', 'count': allCount, 'color': AppColors.primary},
      {'key': 'pending', 'label': 'Chờ phản hồi', 'count': pendingCount, 'color': AppColors.warning},
      {'key': 'replied', 'label': 'Đã phản hồi', 'count': repliedCount, 'color': AppColors.success},
      {'key': 'negative', 'label': 'Đánh giá thấp (1-2★)', 'count': null, 'color': AppColors.danger},
      {'key': 'hidden', 'label': 'Đã ẩn', 'count': hiddenCount, 'color': textSecondary},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final key = tab['key'] as String;
            final label = tab['label'] as String;
            final count = tab['count'] as int?;
            final color = tab['color'] as Color;
            final isSelected = _selectedStatusTab == key;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  if (_selectedStatusTab != key) {
                    setState(() {
                      _selectedStatusTab = key;
                      _currentPage = 1;
                      _loadData();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? (isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.12)) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? (isDark ? Colors.white : color) : textSecondary,
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? color : (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG DỮ LIỆU ĐÁNH GIÁ (DATA ROWS)
  // ==========================================
  List<DataRow> _buildTableRows(
    List<ReviewItem> reviews,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    AuthProvider authProvider,
    ApiService apiService,
  ) {
    final rows = <DataRow>[];

    for (final review in reviews) {
      final canReply = authProvider.can('Reviews.Reply');
      final canHide = authProvider.can('Reviews.Hide');

      rows.add(
        DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (review.isHidden) {
              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFFEF2F2);
            }
            if (states.contains(WidgetState.hovered)) {
              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
            }
            return null;
          }),
          cells: [
            // 1. Mã / Ngày
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${review.reviewId}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textSecondary)),
                  Text(_dateFormat.format(review.createdAt), style: TextStyle(fontSize: 10.5, color: textSecondary)),
                ],
              ),
            ),

            // 2. Sản phẩm & Biến thể
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 34,
                        height: 34,
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: review.productImageUrl != null && review.productImageUrl!.isNotEmpty
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
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
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

            // 3. Khách hàng
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.fullName.isNotEmpty ? review.fullName : review.username,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                  ),
                  Text('@${review.username}', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                ],
              ),
            ),

            // 4. Số sao
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (index) {
                    final starVal = index + 1;
                    if (review.rating >= starVal) {
                      return const Icon(Icons.star_rounded, size: 15, color: Colors.amber);
                    } else if (review.rating >= starVal - 0.5) {
                      return const Icon(Icons.star_half_rounded, size: 15, color: Colors.amber);
                    } else {
                      return Icon(Icons.star_outline_rounded, size: 15, color: Colors.grey.shade400);
                    }
                  }),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                  ),
                ],
              ),
            ),

            // 5. Nhận xét của khách
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: review.comment ?? '',
                      child: Text(
                        review.comment != null && review.comment!.trim().isNotEmpty
                            ? review.comment!
                            : '— (Không có nhận xét chữ)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: review.comment != null && review.comment!.trim().isNotEmpty ? textPrimary : textSecondary,
                          fontWeight: review.comment != null && review.comment!.trim().isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (review.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: review.imageUrls.take(3).map((url) {
                          return GestureDetector(
                            onTap: () => _showImageLightbox(url),
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 6. Phản hồi từ Shop
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review.hasReply) ...[
                      Tooltip(
                        message: review.replyContent ?? '',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.reply_rounded, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  review.replyContent!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                        ),
                        child: const Text(
                          'Chờ phản hồi',
                          style: TextStyle(fontSize: 10.5, color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 7. Trạng thái
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: review.isHidden ? AppColors.dangerBg : AppColors.successBg,
                  border: Border.all(color: review.isHidden ? AppColors.dangerBorder : AppColors.successBorder),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  review.isHidden ? 'Đã ẩn' : 'Công khai',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: review.isHidden ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ),

            // 8. Thao tác
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReply)
                    AppButton(
                      label: review.hasReply ? 'Sửa' : 'Phản hồi',
                      icon: review.hasReply ? Icons.edit_note_rounded : Icons.reply_rounded,
                      variant: review.hasReply ? AppButtonVariant.outline : AppButtonVariant.primary,
                      onPressed: () => _openReplyDialog(review),
                    ),
                  const SizedBox(width: 6),
                  if (canHide)
                    IconButton(
                      icon: Icon(
                        review.isHidden ? Icons.visibility_off_rounded : Icons.visibility_outlined,
                        size: 17,
                        color: review.isHidden ? AppColors.danger : textSecondary,
                      ),
                      tooltip: review.isHidden ? 'Hiện lại đánh giá' : 'Ẩn đánh giá này',
                      onPressed: () => _toggleHideReview(review, apiService, authProvider.token),
                    ),
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

// ============================================================================
// MODAL DIALOG SOẠN PHẢN HỒI ĐÁNH GIÁ (CHUYÊN DỤNG, RỘNG RÃI & DỄ DÀNG THAO TÁC)
// ============================================================================
class _ReviewReplyDialog extends StatefulWidget {
  final ReviewItem review;
  final DateFormat dateFormat;
  final VoidCallback onReplySubmitted;

  const _ReviewReplyDialog({
    required this.review,
    required this.dateFormat,
    required this.onReplySubmitted,
  });

  @override
  State<_ReviewReplyDialog> createState() => _ReviewReplyDialogState();
}

class _ReviewReplyDialogState extends State<_ReviewReplyDialog> {
  late final TextEditingController _replyCtrl;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  final List<String> _quickReplies = [
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
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi!'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await apiService.replyReview(widget.review.reviewId, text, token: token);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      widget.onReplySubmitted();
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Đã lưu phản hồi thành công!' : 'Thất bại!')),
        backgroundColor: res.success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _deleteReply(ApiService apiService, String? token) async {
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

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final res = await apiService.deleteReply(widget.review.reviewId, token: token);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res.success) {
      widget.onReplySubmitted();
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Đã xóa phản hồi!' : 'Thất bại!')),
        backgroundColor: res.success ? AppColors.success : AppColors.danger,
      ),
    );
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: dialogBg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DIALOG HEADER
            Padding(
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
                          'Phản hồi đánh giá #${review.reviewId}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                        ),
                        Text(
                          'Gửi phản hồi chính thức từ TechStoree đến khách hàng',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. SCROLLABLE BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card tóm tắt Đánh giá của khách hàng
                    Container(
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
                                  child: review.productImageUrl != null && review.productImageUrl!.isNotEmpty
                                      ? Image.network(review.productImageUrl!, fit: BoxFit.cover)
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
                                      maxLines: 1,
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
                                  (review.fullName.isNotEmpty ? review.fullName[0] : review.username[0]).toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.fullName.isNotEmpty ? review.fullName : review.username,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                                    ),
                                    Text(
                                      '${widget.dateFormat.format(review.createdAt)} • @${review.username}',
                                      style: TextStyle(fontSize: 10.5, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),

                              // Rating stars badge
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
                                if (review.imageUrls.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: review.imageUrls.map((url) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(url, width: 48, height: 48, fit: BoxFit.cover),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card soạn thảo phản hồi từ Shop
                    Text(
                      'Nội dung phản hồi từ TechStoree:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
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

                    // Gợi ý phản hồi nhanh (Quick Reply Chips)
                    Text(
                      'Gợi ý câu trả lời nhanh:',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickReplies.map((reply) {
                        return ActionChip(
                          avatar: const Icon(Icons.flash_on_rounded, size: 13, color: AppColors.primary),
                          label: Text(reply, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _replyCtrl.text = reply;
                              _replyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _replyCtrl.text.length));
                            });
                          },
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: cardBorder)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // 3. DIALOG FOOTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  if (review.hasReply)
                    AppButton(
                      label: _isDeleting ? 'Đang xóa...' : 'Xóa phản hồi',
                      variant: AppButtonVariant.danger,
                      icon: Icons.delete_outline_rounded,
                      onPressed: (_isDeleting || _isSubmitting) ? null : () => _deleteReply(apiService, authProvider.token),
                    ),
                  const Spacer(),
                  AppButton(
                    label: 'Đóng',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: _isSubmitting ? 'Đang lưu...' : (review.hasReply ? 'Cập nhật phản hồi' : 'Gửi phản hồi'),
                    icon: Icons.send_rounded,
                    variant: AppButtonVariant.primary,
                    onPressed: (_isSubmitting || _isDeleting) ? null : () => _submitReply(apiService, authProvider.token),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

