import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/review_attribute_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/outlet_details.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/data/repositories/chat_repository.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';

/// Current product price info from Firestore (for reorder with live prices)
class ProductPriceInfo {
  final double currentPrice;
  final double discountPrice;
  final String? merchantPrice;
  final String? promoId;

  ProductPriceInfo({
    required this.currentPrice,
    required this.discountPrice,
    this.merchantPrice,
    this.promoId,
  });
}

/// Pagination meta from firestore/orders API (aligns with backend buildPagination).
class OrdersPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const OrdersPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory OrdersPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const OrdersPagination(
        total: 0,
        perPage: 10,
        currentPage: 1,
        totalPages: 1,
        hasNext: false,
        hasPrev: false,
      );
    }
    final total = (json['total'] is int)
        ? json['total'] as int
        : int.tryParse(json['total']?.toString() ?? '0') ?? 0;
    final perPage = (json['per_page'] is int)
        ? json['per_page'] as int
        : int.tryParse(json['per_page']?.toString() ?? '10') ?? 10;
    final currentPage = (json['current_page'] is int)
        ? json['current_page'] as int
        : int.tryParse(json['current_page']?.toString() ?? '1') ?? 1;
    final totalPages = (json['total_pages'] is int)
        ? json['total_pages'] as int
        : int.tryParse(json['total_pages']?.toString() ?? '1') ?? 1;
    return OrdersPagination(
      total: total,
      perPage: perPage,
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: json['has_next'] == true,
      hasPrev: json['has_prev'] == true,
    );
  }
}

/// Result of a single paginated orders request.
class OrdersPageResult {
  final List<OrderModel> orders;
  final OrdersPagination pagination;

  const OrdersPageResult({required this.orders, required this.pagination});
}

class FireStoreUtils {

  // static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static final bool _isDatabaseHealthy = true;
  static String?
  backendUserId; // Set this from LoginController after OTP verification
  static bool get isDatabaseHealthy => _isDatabaseHealthy;

  static Map<String, dynamic> _extractZonePaymentSettings(
    dynamic responseData,
  ) {
    if (responseData is! Map) return <String, dynamic>{};
    final root = Map<String, dynamic>.from(responseData);
    final data = root['data'];
    final fields = data is Map ? data['fields'] : null;

    dynamic zoneSettings;
    if (fields is Map && fields['ZonePaymentSettings'] is Map) {
      zoneSettings = fields['ZonePaymentSettings'];
    } else if (data is Map && data['ZonePaymentSettings'] is Map) {
      zoneSettings = data['ZonePaymentSettings'];
    } else if (root['ZonePaymentSettings'] is Map) {
      zoneSettings = root['ZonePaymentSettings'];
    }

    final normalized = <String, dynamic>{};
    if (zoneSettings is Map) {
      zoneSettings.forEach((key, value) {
        if (key == null || value is! Map) return;
        normalized[key.toString()] = Map<String, dynamic>.from(value);
      });
    }

    // Also support flat API shape:
    // { success: true, data: { zone_id, cod, razorpay, maxAmount } }
    if (data is Map && data['zone_id'] != null) {
      final zoneId = data['zone_id'].toString().trim();
      if (zoneId.isNotEmpty) {
        final zoneConfig = <String, dynamic>{};
        if (data.containsKey('cod')) {
          zoneConfig['cod'] = data['cod'];
        }
        if (data.containsKey('razorpay')) {
          zoneConfig['razorpay'] = data['razorpay'];
        }
        if (data.containsKey('maxAmount')) {
          zoneConfig['maxAmount'] = data['maxAmount'];
        }
        if (zoneConfig.isNotEmpty) {
          normalized[zoneId] = zoneConfig;
        }
      }
    }
    return normalized;
  }

  static Future<Map<String, dynamic>> getChatMessages({
    required String orderId,
    required String chatType,
    required int page,
  }) {
    return const ChatRepository().getChatMessages(
      orderId: orderId,
      chatType: chatType,
      page: page,
    );
  }

  static final Map<String, _CachedVendor> _vendorCache = {};
  static final Map<String, Future<VendorModel?>> _pendingVendorRequests = {};
  static const Duration _vendorCacheDuration = Duration(minutes: 5);

  static bool _isValidVendorId(String vendorId) {
    final id = vendorId.trim();
    if (id.isEmpty || id == 'null' || id == '0') return false;
    return true;
  }

  static bool _isVendorCacheValid(_CachedVendor entry) {
    return DateTime.now().difference(entry.fetchedAt) <= _vendorCacheDuration;
  }

  static VendorModel? _getCachedVendor(String vendorId) {
    final entry = _vendorCache[vendorId];
    if (entry != null && _isVendorCacheValid(entry)) {
      return entry.vendor;
    }
    if (entry != null) {
      _vendorCache.remove(vendorId);
    }
    return null;
  }

  static Map<String, dynamic>? _parseOutletDetailsApiData(
    dynamic jsonResponse,
  ) {
    if (jsonResponse is! Map<String, dynamic>) return null;

    if (jsonResponse['success'] == true &&
        jsonResponse['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(jsonResponse['data'] as Map);
    }

    if (jsonResponse.containsKey('outletId') ||
        jsonResponse.containsKey('categories')) {
      return jsonResponse;
    }

    return null;
  }

  static Future<VendorModel?> _fetchVendorFromApi(String vendorId) async {
    final userId = await SqlStorageConst.getFirebaseId();

    try {
      final uri =
          Uri.parse(
            '${AppConst.defaultBaseUrl}fm/outlets/getOutletDetails',
          ).replace(
            queryParameters: {
              'outletId': vendorId,
              'userType': 'CUSTOMER',
              if (userId != null) 'customerId': userId,
            },
          );

      if (kDebugMode) {
        debugPrint("Vendor API : $uri");
      }

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint("Status Code : ${response.statusCode}");
        debugPrint("Response : ${response.body}");
      }

      if (response.statusCode != 200) {
        return null;
      }

      final jsonResponse = jsonDecode(response.body);
      final data = _parseOutletDetailsApiData(jsonResponse);

      if (data == null) {
        if (kDebugMode) debugPrint("Invalid outlet details response");
        return null;
      }

      final vendor = OutletDetails.fromJson(data).toVendorModel();

      if (kDebugMode) {
        debugPrint("Vendor Parsed");
        debugPrint("OutletId : ${vendor.id}");
        // debugPrint("ZoneId : ${vendor.zoneId}");
      }

      return vendor;
    } catch (e, s) {
      debugPrint("Vendor Parse Error");
      debugPrint(e.toString());
      debugPrint(s.toString());
      return null;
    }
  }

  static Future<VendorModel?> getVendorById(
    String vendorId, {
    bool forceRefresh = false,
  }) async {
    if (!_isValidVendorId(vendorId)) {
      if (kDebugMode) {
        dev.log("getVendorById invalid id: $vendorId");
      }
      return null;
    }

    final normalizedId = vendorId.trim();

    if (!forceRefresh) {
      final cached = _getCachedVendor(normalizedId);
      if (cached != null) return Future.value(cached);

      final pending = _pendingVendorRequests[normalizedId];
      if (pending != null) return pending;
    }

    final completer = Completer<VendorModel?>();
    _pendingVendorRequests[normalizedId] = completer.future;

    try {
      final vendorModel = await ApiQueueManager().enqueue<VendorModel?>(
        priority: RequestPriority.normal,
        key: 'vendor_$normalizedId',
        request: () => _fetchVendorFromApi(normalizedId),
      );

      if (vendorModel != null) {
        _vendorCache[normalizedId] = _CachedVendor(
          vendor: vendorModel,
          fetchedAt: DateTime.now(),
        );
      }

      completer.complete(vendorModel);
      return vendorModel;
    } catch (e) {
      if (kDebugMode) dev.log("❌ getVendorById error: $e");
      completer.complete(null);
      return null;
    } finally {
      _pendingVendorRequests.remove(normalizedId);
    }
  }

  /// Clear vendor cache (e.g. on logout).
  static void clearVendorCache() {
    _vendorCache.clear();
  }

  /// Remove a single vendor from cache.
  static void removeVendorFromCache(String vendorId) {
    _vendorCache.remove(vendorId.trim());
  }

  /// Remove expired vendor cache entries (call periodically if desired).
  static void cleanupExpiredVendorCache() {
    final now = DateTime.now();
    _vendorCache.removeWhere((key, value) {
      return now.difference(value.fetchedAt) > _vendorCacheDuration;
    });
  }

  StreamController<List<VendorModel>>? getNearestVendorController;

  /// Stream method to get mart bottom banners (position: "bottom") - Lazy loading
  // Stream method to get mart bottom banners (position: "bottom") - Lazy loading

  static final Map<String, _CachedProduct> _productCache = {};
  static final Map<String, Future<ProductModel?>> _pendingProductRequests = {};
  static const Duration _productCacheDuration = Duration(minutes: 5);

  // TTL check helper
  static bool _isCacheValid(_CachedProduct cachedEntry) {
    return DateTime.now().difference(cachedEntry.fetchedAt) <=
        _productCacheDuration;
  }

  // Optimized cache getter with single null check
  static ProductModel? _getCachedProduct(String productId) {
    final cachedEntry = _productCache[productId];
    if (cachedEntry != null && _isCacheValid(cachedEntry)) {
      return cachedEntry.product;
    }

    // Auto-clean expired entry
    if (cachedEntry != null) {
      _productCache.remove(productId);
    }
    return null;
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _productCache.length,
      'pendingRequests': _pendingProductRequests.length,
      'cacheDuration': _productCacheDuration.toString(),
    };
  }

  /// Resolves author_id for firestore/orders: backend user id preferred, then Firebase UID.
  static Future<String> _resolveOrdersAuthorId() async {
    var id = Constant.userModel?.id;
    if (id == null || id.isEmpty) id = await SqlStorageConst.getUserId();
    if (id == null || id.isEmpty) id = Constant.userModel?.firebaseId;
    if (id == null || id.isEmpty) id = await SqlStorageConst.getFirebaseId();
    return id ?? '';
  }

  /// Fetches one page of orders from firestore/orders API (paginated, scalable).
  /// Uses page/limit query params; returns orders and pagination meta.
  static Future<OrdersPageResult> fetchOrdersFromFirestorePage({
    int page = 1,
    int limit = 10,
    bool isRefresh = false, // ✅ ADD THIS
  }) async {
    const defaultLimit = 20;
    const maxLimit = 200;
    final effectiveLimit = limit.clamp(1, maxLimit);
    final effectivePage = page < 1 ? 1 : page;

    final authorId = await _resolveOrdersAuthorId();
    if (authorId.isEmpty) {
      if (kDebugMode) dev.log('fetchOrdersFromFirestorePage: no author_id');
      return OrdersPageResult(
        orders: [],
        pagination: const OrdersPagination(
          total: 0,
          perPage: defaultLimit,
          currentPage: 1,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        ),
      );
    }

    final uri = Uri.parse('${AppConst.baseUrl}firestore/orders').replace(
      queryParameters: {
        'author_id': await SqlStorageConst.getFirebaseId(),
        'page': effectivePage.toString(),
        'limit': effectiveLimit.toString(),
        if (isRefresh) 'refresh': 'true',
      },
    );
    if (kDebugMode) {
      dev.log('fetchOrdersFromFirestorePage: $uri');
    }

    final response = await http.get(uri, headers: await getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode)
        dev.log('fetchOrdersFromFirestorePage: status ${response.statusCode}');
      return OrdersPageResult(
        orders: [],
        pagination: OrdersPagination(
          total: 0,
          perPage: effectiveLimit,
          currentPage: effectivePage,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        ),
      );
    }

    final responseData = json.decode(response.body) as Map<String, dynamic>?;
    if (responseData == null || responseData['success'] != true) {
      return OrdersPageResult(
        orders: [],
        pagination: OrdersPagination(
          total: 0,
          perPage: effectiveLimit,
          currentPage: effectivePage,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        ),
      );
    }

    final data = responseData['data'];
    List<dynamic> ordersData = [];
    Map<String, dynamic>? paginationJson;
    if (data is Map) {
      final d = data as Map<String, dynamic>;
      final orders = d['orders'];
      ordersData = orders is List ? orders : [];
      paginationJson = d['pagination'] is Map
          ? Map<String, dynamic>.from(d['pagination'] as Map)
          : null;
    } else if (data is List) {
      ordersData = data;
    }

    final list = <OrderModel>[];
    for (var raw in ordersData) {
      try {
        final orderData = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        // final orderModel = OrderModel.fromJson(_normalizeOrderJson(orderData));
        // if (orderModel.createdAt != null) list.add(orderModel);
      } catch (e) {
        if (kDebugMode) dev.log('fetchOrdersFromFirestorePage: skip order $e');
      }
    }
    list.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    OrdersPagination pagination = OrdersPagination.fromJson(paginationJson);
    if (paginationJson == null && list.isNotEmpty) {
      // Backend may not return pagination; infer from page size
      final inferredHasNext = list.length >= effectiveLimit;
      pagination = OrdersPagination(
        total: list.length,
        perPage: effectiveLimit,
        currentPage: effectivePage,
        totalPages: inferredHasNext ? effectivePage + 1 : effectivePage,
        hasNext: inferredHasNext,
        hasPrev: effectivePage > 1,
      );
    }
    return OrdersPageResult(orders: list, pagination: pagination);
  }

  /// Fetches first page of orders (backward compatible). Prefer fetchOrdersFromFirestorePage for pagination.
  static Future<List<OrderModel>> fetchOrdersFromFirestore() async {
    final result = await fetchOrdersFromFirestorePage(page: 1, limit: 20);
    return result.orders;
  }

  static String _catalogIdFromCartOrOrderRow(String? productId) {
    if (productId == null || productId.isEmpty) return '';
    final t = productId.trim();
    if (t.toLowerCase() == 'null') return '';
    final tilde = t.indexOf('~');
    if (tilde <= 0) return t;
    return t.substring(0, tilde).trim();
  }

  static ProductVariant? _matchProductVariantForReorder(
    ProductModel product,
    VariantInfo? vi,
  ) {
    if (vi == null || product.variants == null || product.variants!.isEmpty) {
      return null;
    }

    final variants = product.variants!;

    // 1. Match by variant ID
    final variantId = vi.variantId?.trim();

    if (variantId != null && variantId.isNotEmpty && variantId != '0') {
      for (final variant in variants) {
        if (variant.variantId?.toString() == variantId) {
          return variant;
        }
      }
    }

    // 2. Match by SKU/name
    final sku = vi.variantSku?.trim();

    if (sku != null && sku.isNotEmpty) {
      for (final variant in variants) {
        if (variant.variantName?.trim() == sku) {
          return variant;
        }
      }
    }

    return null;
  }

  static double _commissionUnitPrice(VendorModel v, String? raw) {
    return double.parse(Constant.productCommissionPrice(v, raw ?? '0'));
  }

  static ProductPriceInfo _reorderVariantPriceInfo({
    required double unit,
    String? merchantPrice,
    String? promoId,
  }) {
    return ProductPriceInfo(
      currentPrice: unit,
      discountPrice: 0.0,
      merchantPrice: merchantPrice,
      promoId: promoId,
    );
  }

  static double _fallbackUnitFromOrderSnapshot(
    String? price,
    String? discountPrice,
  ) {
    final d = double.tryParse(discountPrice ?? '0') ?? 0.0;
    final p = double.tryParse(price ?? '0') ?? 0.0;
    if (d > 0 && d < p) return d;
    return p;
  }

  /// Resolves per-unit display prices for a food line (variants/options + discounts), aligned with cart pricing.
  static ProductPriceInfo? priceInfoForReorderLine({
    required ProductModel? product,
    required CartProductModel element,
    VendorModel? vendor,
  }) {
    try {
      final vendorId = element.vendorID ?? '';
      final v = vendor ?? VendorModel(id: vendorId);

      // ============================================================
      // 1. PRODUCT NOT FOUND
      // ============================================================
      if (product == null) {
        final unit = _fallbackUnitFromOrderSnapshot(
          element.price,
          element.discountPrice,
        );

        final hasVariant = element.variantInfo != null;

        return ProductPriceInfo(
          currentPrice: unit,
          discountPrice: hasVariant ? 0.0 : unit,
          merchantPrice: element.merchantPrice ?? element.price,
          promoId: element.promoId,
        );
      }

      // ============================================================
      // 2. VENDOR VALIDATION
      // ============================================================
      final productVendorId = product.vendorID ?? '';

      if (productVendorId.isNotEmpty &&
          vendorId.isNotEmpty &&
          productVendorId != vendorId) {
        return null;
      }

      // ============================================================
      // 3. PRODUCT AVAILABILITY
      // ============================================================
      if (product.isAvailable == false) {
        return null;
      }

      final variantInfo = element.variantInfo;
      final promoId = element.promoId;

      // ============================================================
      // 4. VARIANT PRODUCT
      // ============================================================
      if (variantInfo != null) {
        final variant = _matchProductVariantForReorder(product, variantInfo);

        // ----------------------------------------------------------
        // Variant found in current API
        // ----------------------------------------------------------
        if (variant != null) {
          // Variant is explicitly unavailable
          if (variant.isAvailable == false) {
            return null;
          }

          final double? variantPrice =
              double.tryParse(variant.price?.toString() ?? '') ??
              double.tryParse(product.price?.toString() ?? '');

          final String? variantMerchantPrice =
              variant.merchantPrice?.toString() ??
              variant.price?.toString() ??
              product.merchantPrice?.toString() ??
              product.price?.toString();

          if (variantPrice != null && variantPrice > 0) {
            return _reorderVariantPriceInfo(
              unit: _commissionUnitPrice(v, variantPrice.toString()),
              merchantPrice: variantMerchantPrice,
              promoId: promoId,
            );
          }
        }

        // ----------------------------------------------------------
        // Variant not found in current product.
        // Use the price stored in the old order.
        // ----------------------------------------------------------
        final rawVariantPrice = variantInfo.variantPrice?.trim();

        final parsedVariantPrice = rawVariantPrice != null
            ? double.tryParse(rawVariantPrice)
            : null;

        if (parsedVariantPrice != null && parsedVariantPrice > 0) {
          return _reorderVariantPriceInfo(
            unit: _commissionUnitPrice(v, parsedVariantPrice.toString()),
            merchantPrice: parsedVariantPrice.toString(),
            promoId: promoId,
          );
        }

        // ----------------------------------------------------------
        // Final fallback for variant
        // ----------------------------------------------------------
        final fallbackUnit = _fallbackUnitFromOrderSnapshot(
          element.price,
          element.discountPrice,
        );

        return _reorderVariantPriceInfo(
          unit: fallbackUnit,
          merchantPrice: element.merchantPrice ?? element.price,
          promoId: promoId,
        );
      }

      // ============================================================
      // 5. NORMAL PRODUCT
      // ============================================================
      final double regularPrice =
          double.tryParse(product.price?.toString() ?? '0') ?? 0;

      final String merchantPrice =
          product.merchantPrice?.toString() ?? regularPrice.toString();

      if (regularPrice <= 0) {
        // Product has no valid current price.
        // Try the old order snapshot.
        final fallbackUnit = _fallbackUnitFromOrderSnapshot(
          element.price,
          element.discountPrice,
        );

        return ProductPriceInfo(
          currentPrice: fallbackUnit,
          discountPrice: fallbackUnit,
          merchantPrice: element.merchantPrice ?? element.price,
          promoId: promoId,
        );
      }

      // ============================================================
      // 6. CURRENT PRODUCT PRICE
      // ============================================================
      final unit = _commissionUnitPrice(v, product.price?.toString());

      return ProductPriceInfo(
        currentPrice: unit,
        discountPrice: unit,
        merchantPrice: merchantPrice,
        promoId: promoId,
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error building price info for reorder: $e',
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  static Future<InboxModel> addDriverInbox(InboxModel inboxModel) async {
    try {
      // Your API base URL
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "order_id": inboxModel.orderId,
        "restaurant_id": inboxModel.restaurantId,
        "restaurant_name": inboxModel.restaurantName,
        "restaurant_profile_image": inboxModel.restaurantProfileImage,
        "customer_id": inboxModel.customerId,
        "customer_name": inboxModel.customerName,
        "customer_profile_image": inboxModel.customerProfileImage,
        "last_sender_id": inboxModel.lastSenderId,
        "last_message": inboxModel.lastMessage,
        "chat_type": inboxModel.chatType,
        "created_at": inboxModel.createdAt?.toString(),
      };
      // Remove null values from the request body
      requestBody.removeWhere((key, value) => value == null);
      // Make the POST request
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/driver/inbox'),
        headers: await getHeaders(),
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return inboxModel;
      } else {
        throw Exception(
          'Failed to add driver inbox: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Failed to add driver inbox: $e');
    }
  }

  static Future<ConversationModel> addDriverChat(
    ConversationModel conversationModel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/driver/messages'),
        headers: await getHeaders(),
        body: jsonEncode({
          "chat_id": conversationModel.id,
          "order_id": conversationModel.orderId,
          "sender_id": conversationModel.senderId,
          "receiver_id": conversationModel.receiverId,
          "message_type": conversationModel.messageType,
          "message": conversationModel.message,
          "created_at": conversationModel.createdAt?.toString(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addDriverChat SUCCESS: orderId=${conversationModel.orderId}, messageId=${conversationModel.id}',
        );
        return conversationModel;
      } else {
        debugPrint(
          '[API] addDriverChat ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to send driver message: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API] addDriverChat ERROR: $e');
      rethrow;
    }
  }

  static Future<void> addRestaurantInbox(InboxModel inboxModel) async {
    try {
      // Your API base URL

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "order_id": inboxModel.orderId,
        "restaurant_id": inboxModel.restaurantId,
        "restaurant_name": inboxModel.restaurantName,
        "restaurant_profile_image": inboxModel.restaurantProfileImage,
        "customer_id": inboxModel.customerId,
        "customer_name": inboxModel.customerName,
        "customer_profile_image": inboxModel.customerProfileImage,
        "last_sender_id": inboxModel.lastSenderId,
        "last_message": inboxModel.lastMessage,
        "chat_type": "restaurant", // Default to "restaurant" as per API spec
        "created_at": inboxModel.createdAt.toString(),
      };

      // Remove null values from the request body
      requestBody.removeWhere((key, value) => value == null);

      // Make the POST request
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/restaurant/inbox'),
        headers: await getHeaders(),
        body: json.encode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addRestaurantInbox SUCCESS: orderId=${inboxModel.orderId}',
        );
      } else {
        // Handle error response
        debugPrint(
          '[API] addRestaurantInbox ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to add restaurant inbox: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API] addRestaurantInbox ERROR: $e');
      // Re-throw the exception to maintain the same error behavior
      throw e;
    }
  }

  static Future<void> addRestaurantChat(
    ConversationModel conversationModel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/restaurant/messages'),
        headers: await getHeaders(),
        body: jsonEncode({
          "chat_id": conversationModel.id,
          "order_id": conversationModel.orderId,
          "sender_id": conversationModel.senderId,
          "receiver_id": conversationModel.receiverId,
          "message_type": conversationModel.messageType,
          "message": conversationModel.message,
          "url": conversationModel.url,
          "video_thumbnail": conversationModel.videoThumbnail,
          "created_at": conversationModel.createdAt?.toString(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addRestaurantChat SUCCESS: orderId=${conversationModel.orderId}, messageId=${conversationModel.id}',
        );
      } else {
        debugPrint(
          '[API] addRestaurantChat ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API] addRestaurantChat ERROR: $e');
      rethrow; // Re-throw to handle the error in the calling function
    }
  }

  static Future<Url> uploadChatImageToFireStorage(
    File image,
    BuildContext context,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child(
      'images/$uniqueID.png',
    );
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
      mime: metaData.contentType ?? 'image',
      url: downloadUrl.toString(),
    );
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(
    BuildContext context,
    File video,
  ) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef = FirebaseStorage.instance.ref(
        'videos/$uniqueID.mp4',
      );
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      File thumbnail = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 75, // 0 - 100
        position: -1, // Get the first frame
      );

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef = FirebaseStorage.instance.ref(
        'thumbnails/$thumbnailID.jpg',
      );
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnail.readAsBytesSync(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();
      return ChatVideoContainer(
        videoUrl: Url(
          url: videoUrl.toString(),
          mime: metaData.contentType ?? 'video',
          videoThumbnail: thumbnailUrl,
        ),
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<List<RatingModel>> getVendorReviews(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}vendor/$vendorId/reviews'),
        headers: await getHeaders(),
      );
      debugPrint(
        "getVendorReviews ${AppConst.baseUrl}vendor/$vendorId/reviews)}",
      );
      debugPrint("getVendorReviews " + response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          List<RatingModel> ratingList = [];
          for (var element in data) {
            RatingModel ratingModel = RatingModel.fromJson(element);
            ratingList.add(ratingModel);
          }

          return ratingList;
        } else {
          throw Exception('Failed to load reviews: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load reviews. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  static Future<RatingModel?> getOrderReviewsByID(
    String orderId,
    String productID,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}reviews/order?orderid=$orderId&productId=$productID',
        ),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return RatingModel.fromJson(responseData['data']);
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching reviews: $error');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getReviewEligibility() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}reviews/eligibility?customerId=${await SqlStorageConst.getFirebaseId()}',
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] is Map) {
          return Map<String, dynamic>.from(responseData['data'] as Map);
        }
      } else {
        debugPrint(
          'getReviewEligibility API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching review eligibility: $e');
    }
    return null;
  }

  static Future<bool> submitOrderReview({
    required String orderId,
    required String vendorId,
    String? driverId,
    required String action,
    int? rating,
    String? comment,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'customerId': await SqlStorageConst.getFirebaseId(),
        'uname': await SqlStorageConst.getUserName(),
        'orderId': orderId,
        'vendorId': vendorId,
        'driverId': driverId,
        'action': action,
      };

      if (rating != null) payload['rating'] = rating;
      if (comment != null && comment.trim().isNotEmpty) {
        payload['comment'] = comment.trim();
      }

      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}reviews/submit'),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData['success'] == true;
      }

      // Treat already handled as successful from UX perspective.
      if (responseData['code'] == 'ALREADY_DONE') {
        return true;
      }

      debugPrint(
        'submitOrderReview API Error: ${response.statusCode} - ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Error submitting order review: $e');
      return false;
    }
  }

  static Future<VendorCategoryModel?> getVendorCategoryByCategoryId(
    String categoryId,
  ) async {
    VendorCategoryModel? vendorCategoryModel;
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/vendor-categories/$categoryId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          vendorCategoryModel = VendorCategoryModel.fromJson(
            jsonResponse['data'],
          );
        }
      }
    } catch (e) {
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<ReviewAttributeModel?> getVendorReviewAttribute(
    String attributeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}review-attributes/$attributeId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ReviewAttributeModel.fromJson(jsonResponse['data']);
        } else {
          return null;
        }
      } else {
        // Handle different status codes
        debugPrint('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching review attribute: $e');
      return null;
    }
  }

  static Future<bool?> setRatingModel(RatingModel ratingModel) async {
    bool isAdded = false;
    try {
      debugPrint("setRatingModel ${ratingModel.toJson()} ");
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}firestore/ratings'),
        headers: await getHeaders(),
        body: jsonEncode(ratingModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isAdded = true;
      } else {
        isAdded = false;
        debugPrint('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      isAdded = false;
      debugPrint('Exception: $error');
    }

    return isAdded;
  }

  /// **ULTRA-FAST PROMOTIONAL DATA FETCHING WITH API**
  static Future<List<Map<String, dynamic>>> fetchActivePromotions({
    required String restaurantId,
    required String productId,
  }) async {
    try {
      // Only make API call if both IDs are provided and not empty
      if (productId.isEmpty || restaurantId.isEmpty) {
        debugPrint(
          '[DEBUG] Skipping API call - productId or restaurantId is empty',
        );
        return [];
      }

      final String apiUrl =
          '${AppConst.baseUrl}firestore/promotions/by-product?'
          'product_id=$productId&'
          'restaurant_id=$restaurantId';
      debugPrint('fetchActivePromotions: $apiUrl');
      // Make API call
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await getHeaders(),
      );

      debugPrint('[DEBUG] API Response Status: ${response.statusCode}');
      debugPrint('[DEBUG] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final promotionData = responseData['data'];

          // Handle both Map and List responses
          List<Map<String, dynamic>> promotions = [];

          if (promotionData is Map<String, dynamic>) {
            // Single promotion object
            promotions.add(promotionData);
          } else if (promotionData is List) {
            // List of promotions
            promotions = promotionData.cast<Map<String, dynamic>>();
          }

          // Process each promotion
          final List<Map<String, dynamic>> activePromotions = [];

          for (final promo in promotions) {
            // Convert API response to match your existing data structure
            final Map<String, dynamic> processedPromotion = {
              ...promo,
              'isAvailable':
                  promo['isAvailable'] == 1 || promo['isAvailable'] == true,
              'start_time': _parseTimestamp(promo['start_time']),
              'end_time': _parseTimestamp(promo['end_time']),
            };

            // Check if promotion is currently active based on time
            final startTime = processedPromotion['start_time'] as Timestamp?;
            final endTime = processedPromotion['end_time'] as Timestamp?;

            bool isActive = processedPromotion['isAvailable'] == true;

            if (startTime != null && endTime != null) {
              isActive =
                  isActive &&
                  startTime.compareTo(Timestamp.now()) <= 0 &&
                  endTime.compareTo(Timestamp.now()) >= 0;
            }

            debugPrint(
              '[DEBUG] Promotion for product ${promo['product_id']}: active=$isActive, available=${processedPromotion['isAvailable']}',
            );

            if (isActive) {
              activePromotions.add(processedPromotion);
            }
          }

          debugPrint(
            '[DEBUG] Found ${activePromotions.length} active promotions',
          );
          debugPrint('[DEBUG] ===== ULTRA-FAST API FETCH COMPLETE =====');

          return activePromotions;
        } else {
          debugPrint(
            '[DEBUG] API returned unsuccessful response: ${responseData['message'] ?? 'Unknown error'}',
          );
          return [];
        }
      } else if (response.statusCode == 404) {
        debugPrint('[DEBUG] No promotion found (404) for product $productId');
        return [];
      } else {
        debugPrint(
          '[DEBUG] API Error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('[DEBUG] ERROR in ultra-fast API fetch: $e');
      return [];
    }
  }

  /// Helper method to parse timestamp strings to Firestore Timestamp
  static Timestamp? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        debugPrint('[DEBUG] Error parsing timestamp: $e');
        return null;
      }
    }

    return null;
  }

  /// Checks if a product is currently a promo item (OPTIMIZED)
  static Future<Map<String, dynamic>?> getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) async {
    final promos = await fetchActivePromotions(
      restaurantId: restaurantId,
      productId: productId,
    );
    final promo = promos.firstWhere(
      (p) =>
          p['product_id'] == productId &&
          p['restaurant_id'] == restaurantId &&
          p['isAvailable'] == true,
      orElse: () => <String, dynamic>{},
    );
    return promo.isNotEmpty ? promo : null;
  }

  // static Future<List<ProductModel>> getAllProductsInZone({int? limit}) async {
  //   try {
  //     debugPrint(
  //       "🔍 Fetching products from API for zone: ${Constant.selectedZone?.name}",
  //     );
  //
  //     // Prepare API parameters
  //     final Map<String, String> queryParams = {};
  //
  //     // Add zone_id if selected
  //     if (Constant.selectedZone != null) {
  //       queryParams['zone_id'] = Constant.selectedZone!.id.toString();
  //     }
  //     // Add limit if provided
  //     if (limit != null) {
  //       queryParams['limit'] = limit.toString();
  //     }
  //
  //     // Make API call
  //     final response = await http.get(
  //       Uri.parse(
  //         '${AppConst.baseUrl}firestore/search/products',
  //       ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null),
  //       headers: await getHeaders(),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(response.body);
  //
  //       if (responseData['success'] == true) {
  //         final List<dynamic> productsData = responseData['data']['products'];
  //         final List<ProductModel> productList = [];
  //
  //         for (var productData in productsData) {
  //           try {
  //             // Use the API JSON factory constructor
  //             ProductModel product = ProductModel.fromApiJson(productData);
  //             productList.add(product);
  //           } catch (e) {
  //             debugPrint('❌ Error parsing product ${productData['id']}: $e');
  //           }
  //         }
  //
  //         debugPrint('✅ Loaded ${productList.length} products from API');
  //         return productList;
  //       } else {
  //         debugPrint('❌ API returned error: ${responseData['message']}');
  //         return [];
  //       }
  //     } else {
  //       debugPrint('❌ HTTP error ${response.statusCode}: ${response.body}');
  //       return [];
  //     }
  //   } catch (e) {
  //     debugPrint('❌ Error loading products from API: $e');
  //     if (e.toString().contains('OutOfMemoryError')) {
  //       debugPrint(
  //         '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
  //       );
  //     }
  //     return [];
  //   }
  // }

  /// Get all vendors for search indexing - MEMORY OPTIMIZED
  // static Future<List<VendorModel>> getAllVendors({int? limit}) async {
  //   try {
  //     List<VendorModel> vendorList = [];
  //     int safeLimit =
  //         limit ?? 500; // Increased to 500 to match admin panel results
  //     Query query;
  //     if (Constant.selectedZone != null) {
  //       query = FirebaseFirestore.instance
  //           .collection(CollectionName.vendors)
  //           .where('zoneId', isEqualTo: Constant.selectedZone!.id.toString())
  //           .limit(safeLimit);
  //       debugPrint(
  //         '🔍 Loading vendors from zone: ${Constant.selectedZone!.name} (${Constant.selectedZone!.id})',
  //       );
  //     } else {
  //       query = FirebaseFirestore.instance
  //           .collection(CollectionName.vendors)
  //           .limit(safeLimit);
  //       debugPrint('🔍 No zone selected, loading all vendors');
  //     }
  //     QuerySnapshot querySnapshot = await query.get();
  //     debugPrint(
  //       '🔍 Found ${querySnapshot.docs.length} vendors in Firestore (limited to $safeLimit for memory safety)',
  //     );
  //     for (var document in querySnapshot.docs) {
  //       try {
  //         final data = document.data() as Map<String, dynamic>;
  //         VendorModel vendorModel = VendorModel.fromJson(data);
  //         // **FOOD CATEGORY FILTERING: Exclude mart vendors from search**
  //         if (vendorModel.vType == null ||
  //             vendorModel.vType!.toLowerCase() != 'mart') {
  //           vendorList.add(vendorModel);
  //         } else {
  //           debugPrint('🔍 Mart vendor excluded from search: ${vendorModel.title}');
  //         }
  //       } catch (e) {
  //         debugPrint('❌ Error parsing vendor ${document.id}: $e');
  //       }
  //     }
  //     debugPrint('✅ Loaded ${vendorList.length} vendors for search');
  //     return vendorList;
  //   } catch (e) {
  //     debugPrint('❌ Error loading all vendors: $e');
  //     if (e.toString().contains('OutOfMemoryError')) {
  //       debugPrint(
  //         '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
  //       );
  //     }
  //     return [];
  //   }
  // }

  /// Get all products for search indexing - MEMORY OPTIMIZED

  static Future<List<ProductModel>> getAllProducts({
    int? limit,
    int page = 1,
  }) async {
    try {
      List<ProductModel> productList = [];

      final String baseUrl =
          '${AppConst.baseUrl}products'; // Replace with your actual base URL
      final Map<String, String> queryParams = {'page': page.toString()};
      if (limit != null && limit > 0) {
        queryParams['limit'] = limit.toString();
      }
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('🌐 Fetching products from API: $uri');
      // Make API request
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsJson = responseData['data'];
          final Map<String, dynamic> meta = responseData['meta'];

          debugPrint(
            '📊 API Response: Loaded ${productsJson.length} products (Page $page of ${meta['last_page']}, Total: ${meta['total']})',
          );

          // Parse products
          for (var productJson in productsJson) {
            try {
              ProductModel productModel = ProductModel.fromJson(productJson);
              productList.add(productModel);
            } catch (e) {
              debugPrint('❌ Error parsing product ${productJson['id']}: $e');
            }
          }

          debugPrint(
            '✅ Successfully loaded ${productList.length} products from API',
          );
          return productList;
        } else {
          debugPrint('❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        debugPrint(
          '❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error loading products from API: $e');

      if (e is http.ClientException) {
        debugPrint('🌐 Network error: ${e.message}');
      } else if (e is TimeoutException) {
        debugPrint('⏰ Request timeout');
      }

      return [];
    }
  }

  /// Get trending searches (can be customized based on your backend)
  static Future<List<String>> getTrendingSearches() async {
    try {
      return [
        "Pizza",
        "Biryani",
        "Burgers",
        "Coffee",
        "Ice Cream",
        "Chinese",
        "Italian",
        "South Indian",
        "Fast Food",
        "Desserts",
        "Chicken",
        "Vegetarian",
        "Spicy",
        "Sweet",
        "Healthy",
      ];
    } catch (e) {
      debugPrint('❌ Error loading trending searches: $e');
      return [];
    }
  }
}

class _CachedProduct {
  _CachedProduct({required this.product, required DateTime fetchedAt})
    : fetchedAt = DateTime.now();

  final ProductModel product;
  final DateTime fetchedAt;
}

class _CachedVendor {
  _CachedVendor({required this.vendor, required DateTime fetchedAt})
    : fetchedAt = DateTime.now();

  final VendorModel vendor;
  final DateTime fetchedAt;
}
