export 'base_api_service.dart';
export 'product_api_service.dart';
export 'category_api_service.dart';
export 'supplier_api_service.dart';
export 'user_api_service.dart';
export 'order_api_service.dart';
export 'purchase_order_api_service.dart';
export 'promotion_api_service.dart';
export 'voucher_api_service.dart';
export 'survey_api_service.dart';

import 'base_api_service.dart';
import 'product_api_service.dart';
import 'category_api_service.dart';
import 'supplier_api_service.dart';
import 'user_api_service.dart';
import 'order_api_service.dart';
import 'purchase_order_api_service.dart';
import 'promotion_api_service.dart';
import 'voucher_api_service.dart';
import 'survey_api_service.dart';

class ApiService extends BaseApiService
    with
        ProductApiService,
        CategoryApiService,
        SupplierApiService,
        UserApiService,
        OrderApiService,
        PurchaseOrderApiService,
        PromotionApiService,
        VoucherApiService,
        SurveyApiService {}

