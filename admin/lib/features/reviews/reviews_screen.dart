import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/review.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/page_header.dart';
import 'dialog/review_reply_dialog.dart';
import 'widgets/review_data_table.dart';
import 'widgets/review_filter_bar.dart';
import 'widgets/review_rankings_cards.dart';
import 'widgets/review_status_tab_bar.dart';

/// Màn hình chính quản lý đánh giá sản phẩm: điều phối bộ lọc, thống kê xếp hạng và bảng đánh giá.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Filter States
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _selectedStatusTab = 'all'; // 'all', 'pending', 'replied', 'negative', 'hidden'
  double? _selectedRating; // null = all, 5.0, 4.0, 3.0, 2.0, 1.0
  int? _filteredProductId;
  String? _filteredProductName;
  bool _onlyWithImages = false;
  bool _showRankings = false; // Mặc định ẩn để bảng dữ liệu thoáng đãng
  bool _isActionBusy = false;

  // Data Futures & Error State (giữ error state khi reload thất bại với CachedFutureBuilder)
  late Future<ReviewPagedResult> _reviewsFuture;
  late Future<ReviewStatistics?> _statsFuture;
  Object? _reviewsError;
  int _reviewsRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadData(reloadStats: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData({bool reloadStats = false}) {
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

    final reqId = ++_reviewsRequestId;
    _reviewsError = null;
    _reviewsFuture = _fetchReviews(
      reqId,
      apiService.getAdminReviews(
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
        throwOnError: true,
      ),
    )..ignore();

    if (reloadStats) {
      _statsFuture = apiService.getDetailedReviewStatistics(
        token: token,
        throwOnError: true,
      )..ignore();
    }
  }

  Future<ReviewPagedResult> _fetchReviews(int reqId, Future<ReviewPagedResult> request) async {
    try {
      final result = await request;
      if (mounted && _reviewsRequestId == reqId && _reviewsError != null) {
        setState(() => _reviewsError = null);
      }
      return result;
    } catch (e) {
      if (mounted && _reviewsRequestId == reqId) {
        setState(() => _reviewsError = e);
      }
      rethrow;
    }
  }

  String _extractFriendlyError(Object? error) {
    if (error == null) return 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
    var msg = error.toString().trim();
    const prefix = 'Exception:';
    if (msg.startsWith(prefix)) {
      msg = msg.substring(prefix.length).trim();
    }
    return msg.isNotEmpty ? msg : 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
  }

  void _refreshList({bool resetPage = false, bool reloadStats = true}) {
    setState(() {
      if (resetPage) _currentPage = 1;
      _loadData(reloadStats: reloadStats);
    });
  }

  void _filterByProduct(int productId, String productName) {
    setState(() {
      _filteredProductId = productId;
      _filteredProductName = productName;
      _currentPage = 1;
      _loadData(reloadStats: false);
    });
  }

  void _clearProductFilter() {
    setState(() {
      _filteredProductId = null;
      _filteredProductName = null;
      _currentPage = 1;
      _loadData(reloadStats: false);
    });
  }

  void _openReplyDialog(ReviewItem review, {required bool canReply}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReviewReplyDialog(
        review: review,
        canReply: canReply,
        onReplySubmitted: () => _refreshList(reloadStats: true),
      ),
    );
  }

  Future<void> _toggleHideReview(ReviewItem review) async {
    if (_isActionBusy) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final willHide = !review.isHidden;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          willHide ? 'Xác nhận ẩn đánh giá' : 'Xác nhận hiển thị lại đánh giá',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        content: Text(
          willHide
              ? 'Bạn có chắc muốn ẩn đánh giá này khỏi website công khai? Đánh giá này sẽ không còn hiển thị với khách hàng.'
              : 'Bạn có muốn khôi phục hiển thị đánh giá này lên website công khai không?',
          style: const TextStyle(fontSize: 13),
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

    if (confirm != true || !mounted) return;

    setState(() => _isActionBusy = true);
    try {
      final res = await apiService.toggleHideReview(review.reviewId, willHide, token: token);
      if (!mounted) return;

      if (res.success) {
        _refreshList(reloadStats: true);
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Thao tác thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Thao tác thất bại!');
      }
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIÊU ĐỀ TRANG & NÚT TOGGLE TOP XẾP HẠNG
          PageHeader(
            title: 'Quản lý đánh giá sản phẩm',
            subtitle: 'Theo dõi phản hồi khách hàng, kiểm soát chất lượng sản phẩm và chăm sóc khách hàng',
            action: AppButton(
              label: _showRankings ? 'Ẩn Top xếp hạng' : 'Xem Top xếp hạng',
              icon: _showRankings ? Icons.expand_less_rounded : Icons.leaderboard_rounded,
              variant: _showRankings ? AppButtonVariant.primary : AppButtonVariant.secondary,
              onPressed: () => setState(() => _showRankings = !_showRankings),
            ),
          ),

          // 2 & 3. TOP 5 XẾP HẠNG + THANH TAB TRẠNG THÁI
          FutureBuilder<ReviewStatistics?>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (snapshot.hasError)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.space12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _extractFriendlyError(snapshot.error),
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _refreshList(reloadStats: true),
                            child: const Text('Tải lại', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  if (_showRankings) ...[
                    ReviewRankingsCards(
                      stats: stats,
                      onSelectProduct: _filterByProduct,
                    ),
                    const SizedBox(height: AppTokens.space16),
                  ],
                  ReviewStatusTabBar(
                    stats: stats,
                    selectedStatusTab: _selectedStatusTab,
                    onTabSelected: (key) {
                      setState(() {
                        _selectedStatusTab = key;
                        _currentPage = 1;
                        _loadData(reloadStats: false);
                      });
                    },
                  ),
                ],
              );
            },
          ),

          // 4. THANH TÌM KIẾM & BỘ LỌC
          ReviewFilterBar(
            searchController: _searchCtrl,
            selectedRating: _selectedRating,
            onlyWithImages: _onlyWithImages,
            filteredProductId: _filteredProductId,
            filteredProductName: _filteredProductName,
            onSearchChanged: () => setState(() {}),
            onClearSearch: () {
              _searchCtrl.clear();
              _refreshList(resetPage: true, reloadStats: false);
            },
            onSearchSubmitted: () => _refreshList(resetPage: true, reloadStats: false),
            onRatingChanged: (val) {
              setState(() {
                _selectedRating = val;
                _currentPage = 1;
                _loadData(reloadStats: false);
              });
            },
            onOnlyWithImagesChanged: (val) {
              setState(() {
                _onlyWithImages = val;
                _currentPage = 1;
                _loadData(reloadStats: false);
              });
            },
            onClearProductFilter: _clearProductFilter,
          ),

          // 5. BẢNG DANH SÁCH ĐÁNH GIÁ & PHÂN TRANG
          ReviewDataTable(
            reviewsFuture: _reviewsFuture,
            reviewsError: _reviewsError,
            isActionBusy: _isActionBusy,
            currentPage: _currentPage,
            itemsPerPage: _itemsPerPage,
            formatError: _extractFriendlyError,
            onRetry: () => _refreshList(reloadStats: true),
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _loadData(reloadStats: false);
              });
            },
            onItemsPerPageChanged: (size) {
              setState(() {
                _itemsPerPage = size;
                _currentPage = 1;
                _loadData(reloadStats: false);
              });
            },
            onOpenReplyDialog: _openReplyDialog,
            onToggleHideReview: _toggleHideReview,
          ),
        ],
      ),
    );
  }
}
