import 'package:flutter/foundation.dart';
import '../../features/dashboard/models/dashboard_data.dart';
import 'base_api_service.dart';

mixin ReviewApiService on BaseApiService {
  Future<CustomerReviewOverviewMetric> getReviewStatistics({int? productId, String? token}) async {
    try {
      final queryParams = <String, String>{};
      if (productId != null) {
        queryParams['productId'] = productId.toString();
      }

      final uri = Uri.parse('$baseUrl/Reviews/admin/statistics').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await httpGet(uri, token: token);

      final data = parseApiResponse(response);
      if (data != null && data is Map<String, dynamic>) {
        return CustomerReviewOverviewMetric.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) print('API Error getReviewStatistics: $e');
    }
    return CustomerReviewOverviewMetric.empty();
  }
}
