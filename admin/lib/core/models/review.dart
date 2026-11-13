import '../utils/json_parse_helper.dart';

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
      reviewId: JsonParseHelper.parseInt(json['reviewId']),
      userId: JsonParseHelper.parseInt(json['userId']),
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      productId: JsonParseHelper.parseInt(json['productId']),
      productName: json['productName']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      orderItemId: JsonParseHelper.parseInt(json['orderItemId']),
      orderId: JsonParseHelper.parseInt(json['orderId']),
      orderCode: json['orderCode']?.toString() ?? '',
      variantId: JsonParseHelper.parseInt(json['variantId']),
      variantName: json['variantName']?.toString() ?? '',
      rating: JsonParseHelper.parseDouble(json['rating'], 5.0),
      comment: json['comment']?.toString(),
      imageUrls: JsonParseHelper.parseStringList(json['imageUrls']),
      replyContent: json['replyContent']?.toString(),
      repliedAt: JsonParseHelper.parseNullableDate(json['repliedAt']),
      isHidden: JsonParseHelper.parseBool(json['isHidden']),
      createdAt: JsonParseHelper.parseDate(json['createdAt']),
      updatedAt: JsonParseHelper.parseNullableDate(json['updatedAt']),
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
    return ReviewStatistics(
      totalReviews: JsonParseHelper.parseInt(json['totalReviews']),
      averageRating: JsonParseHelper.parseDouble(json['averageRating']),
      totalReplied: JsonParseHelper.parseInt(json['totalReplied']),
      totalHidden: JsonParseHelper.parseInt(json['totalHidden']),
      ratingDistribution: JsonParseHelper.parseIntMap(json['ratingDistribution']),
      topRatedProducts: JsonParseHelper.parseJsonList(
        json['topRatedProducts'],
        ProductRatingRanking.fromJson,
      ),
      lowestRatedProducts: JsonParseHelper.parseJsonList(
        json['lowestRatedProducts'],
        ProductRatingRanking.fromJson,
      ),
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
      productId: JsonParseHelper.parseInt(json['productId']),
      productName: json['productName']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      averageRating: JsonParseHelper.parseDouble(json['averageRating']),
      totalReviews: JsonParseHelper.parseInt(json['totalReviews']),
      positiveReviewCount: JsonParseHelper.parseInt(json['positiveReviewCount']),
      negativeReviewCount: JsonParseHelper.parseInt(json['negativeReviewCount']),
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

  int get totalPages =>
      pageSize > 0 ? (totalCount / pageSize).ceil() : (totalCount > 0 ? 1 : 0);
}
