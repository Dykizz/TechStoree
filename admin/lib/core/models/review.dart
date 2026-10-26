class ReviewItem {
  final int reviewId;
  final int userId;
  final String username;
  final String fullName;
  final String email;
  final String? phone;

  final int productId;
  final String productName;
  final String? productImageUrl;

  final int orderItemId;
  final int orderId;
  final String orderCode;

  final int variantId;
  final String variantName;

  final double rating;
  final String? comment;
  final List<String> imageUrls;

  final String? replyContent;
  final DateTime? repliedAt;

  final bool isHidden;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get hasReply => replyContent != null && replyContent!.trim().isNotEmpty;
  bool get isPositive => rating >= 4.0;
  bool get isNegative => rating <= 2.0;

  ReviewItem({
    required this.reviewId,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.orderItemId,
    required this.orderId,
    required this.orderCode,
    required this.variantId,
    required this.variantName,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.replyContent,
    this.repliedAt,
    this.isHidden = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      reviewId: json['reviewId'] is int ? json['reviewId'] : int.tryParse(json['reviewId']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      productId: json['productId'] is int ? json['productId'] : int.tryParse(json['productId']?.toString() ?? '0') ?? 0,
      productName: json['productName']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      orderItemId: json['orderItemId'] is int ? json['orderItemId'] : int.tryParse(json['orderItemId']?.toString() ?? '0') ?? 0,
      orderId: json['orderId'] is int ? json['orderId'] : int.tryParse(json['orderId']?.toString() ?? '0') ?? 0,
      orderCode: json['orderCode']?.toString() ?? '',
      variantId: json['variantId'] is int ? json['variantId'] : int.tryParse(json['variantId']?.toString() ?? '0') ?? 0,
      variantName: json['variantName']?.toString() ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      comment: json['comment']?.toString(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      replyContent: json['replyContent']?.toString(),
      repliedAt: json['repliedAt'] != null ? DateTime.tryParse(json['repliedAt'].toString()) : null,
      isHidden: json['isHidden'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}

class ReviewStatistics {
  final int totalReviews;
  final double averageRating;
  final int totalReplied;
  final int totalHidden;
  final Map<String, int> ratingDistribution;
  final List<ProductRatingRanking> topRatedProducts;
  final List<ProductRatingRanking> lowestRatedProducts;

  ReviewStatistics({
    required this.totalReviews,
    required this.averageRating,
    required this.totalReplied,
    required this.totalHidden,
    this.ratingDistribution = const {},
    this.topRatedProducts = const [],
    this.lowestRatedProducts = const [],
  });

  factory ReviewStatistics.fromJson(Map<String, dynamic> json) {
    final distRaw = json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    final dist = distRaw.map((key, value) => MapEntry(key, value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0));

    final topList = (json['topRatedProducts'] as List<dynamic>?)
            ?.map((e) => ProductRatingRanking.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final lowestList = (json['lowestRatedProducts'] as List<dynamic>?)
            ?.map((e) => ProductRatingRanking.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ReviewStatistics(
      totalReviews: json['totalReviews'] is int ? json['totalReviews'] : int.tryParse(json['totalReviews']?.toString() ?? '0') ?? 0,
      averageRating: json['averageRating'] is num ? (json['averageRating'] as num).toDouble() : double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      totalReplied: json['totalReplied'] is int ? json['totalReplied'] : int.tryParse(json['totalReplied']?.toString() ?? '0') ?? 0,
      totalHidden: json['totalHidden'] is int ? json['totalHidden'] : int.tryParse(json['totalHidden']?.toString() ?? '0') ?? 0,
      ratingDistribution: dist,
      topRatedProducts: topList,
      lowestRatedProducts: lowestList,
    );
  }
}

class ProductRatingRanking {
  final int productId;
  final String productName;
  final String? productImageUrl;
  final double averageRating;
  final int totalReviews;
  final int positiveReviewCount;
  final int negativeReviewCount;

  ProductRatingRanking({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.averageRating,
    required this.totalReviews,
    required this.positiveReviewCount,
    required this.negativeReviewCount,
  });

  factory ProductRatingRanking.fromJson(Map<String, dynamic> json) {
    return ProductRatingRanking(
      productId: json['productId'] is int ? json['productId'] : int.tryParse(json['productId']?.toString() ?? '0') ?? 0,
      productName: json['productName']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      averageRating: json['averageRating'] is num ? (json['averageRating'] as num).toDouble() : double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      totalReviews: json['totalReviews'] is int ? json['totalReviews'] : int.tryParse(json['totalReviews']?.toString() ?? '0') ?? 0,
      positiveReviewCount: json['positiveReviewCount'] is int ? json['positiveReviewCount'] : int.tryParse(json['positiveReviewCount']?.toString() ?? '0') ?? 0,
      negativeReviewCount: json['negativeReviewCount'] is int ? json['negativeReviewCount'] : int.tryParse(json['negativeReviewCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class ReviewPagedResult {
  final List<ReviewItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  ReviewPagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil();
}
