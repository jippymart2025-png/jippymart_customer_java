import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/AttributesModel.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/email_template_model.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/notification_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/payment_model/cod_setting_model.dart';
import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/review_attribute_model.dart';
import 'package:jippymart_customer/models/tax_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
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
  final String? promoId;

  ProductPriceInfo({
    required this.currentPrice,
    required this.discountPrice,
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
  static Future<void>? _paymentSettingsInFlight;
  static DateTime? _lastPaymentSettingsFetchAt;
  static String? _lastPaymentSettingsZoneId;
  static const Duration _paymentSettingsCacheTtl = Duration(minutes: 2);
  static const Duration _paymentSettingsRequestTimeout = Duration(seconds: 6);

  // static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static final bool _isDatabaseHealthy = true;
  static String?
  backendUserId; // Set this from LoginController after OTP verification
  static bool get isDatabaseHealthy => _isDatabaseHealthy;

  static Map<String, dynamic> _extractZonePaymentSettings(
    dynamic responseData,
  ) {
    if (responseData is! Map) return <String, dynamic>{};
    final root = Map<String, dynamic>.from(responseData as Map);
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
        normalized[key.toString()] = Map<String, dynamic>.from(value as Map);
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

  static Map<String, dynamic> _mergeZonePaymentSettings(
    Map<String, dynamic> base,
    Map<String, dynamic> incoming,
  ) {
    final merged = <String, dynamic>{};

    base.forEach((zoneId, config) {
      if (config is Map) {
        merged[zoneId] = Map<String, dynamic>.from(config);
      }
    });

    incoming.forEach((zoneId, config) {
      if (config is! Map) return;
      final existing = merged[zoneId];
      final mergedConfig = <String, dynamic>{};
      if (existing is Map) {
        mergedConfig.addAll(Map<String, dynamic>.from(existing));
      }
      mergedConfig.addAll(Map<String, dynamic>.from(config));
      merged[zoneId] = mergedConfig;
    });

    return merged;
  }

  static Future<http.Response?> _safeGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    try {
      return await http
          .get(uri, headers: headers)
          .timeout(_paymentSettingsRequestTimeout);
    } catch (e) {
      if (kDebugMode) {
        dev.log('Payment settings request failed for $uri: $e');
      }
      return null;
    }
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

  static Future getPaymentSettingsData() async {
    final selectedZoneId = Constant.selectedZone?.id?.toString().trim();
    final normalizedZoneId = (selectedZoneId == null || selectedZoneId.isEmpty)
        ? null
        : selectedZoneId;
    if (_paymentSettingsInFlight != null) {
      return _paymentSettingsInFlight!;
    }
    final canUseRecentFetch =
        _lastPaymentSettingsFetchAt != null &&
        _lastPaymentSettingsZoneId == normalizedZoneId &&
        DateTime.now().difference(_lastPaymentSettingsFetchAt!) <
            _paymentSettingsCacheTtl;
    if (canUseRecentFetch) return;

    _paymentSettingsInFlight = () async {
      try {
        final headers = await getHeaders();
        final responses = await Future.wait<http.Response?>([
          _safeGet(
            Uri.parse('${AppConst.baseUrl}firestore/settings/razorpay'),
            headers,
          ),
          _safeGet(
            Uri.parse('${AppConst.baseUrl}firestore/settings/cod'),
            headers,
          ),
          if (normalizedZoneId != null)
            _safeGet(
              Uri.parse(
                '${AppConst.baseUrl}zone-payment-settings',
              ).replace(queryParameters: {'zone_id': normalizedZoneId}),
              headers,
            ),
        ]);
        final razorpayResponse = responses[0];
        final codResponse = responses[1];
        var zonePaymentSettings = <String, dynamic>{};
        var hasAnySuccessfulFetch = false;

        if (razorpayResponse?.statusCode == 200) {
          hasAnySuccessfulFetch = true;
          final responseData = jsonDecode(razorpayResponse!.body);
          zonePaymentSettings = _mergeZonePaymentSettings(
            zonePaymentSettings,
            _extractZonePaymentSettings(responseData),
          );
          if (responseData['success'] == true) {
            final razorpayData = responseData['data']['fields'];
            final razorPayModel = RazorPayModel.fromJson(razorpayData);
            await Preferences.setString(
              Preferences.razorpaySettings,
              jsonEncode(razorPayModel.toJson()),
            );
          }
        }

        if (codResponse?.statusCode == 200) {
          hasAnySuccessfulFetch = true;
          final responseData = jsonDecode(codResponse!.body);
          zonePaymentSettings = _mergeZonePaymentSettings(
            zonePaymentSettings,
            _extractZonePaymentSettings(responseData),
          );
          if (responseData['success'] == true) {
            final codData = responseData['data']['fields'];
            final codSettingModel = CodSettingModel.fromJson(codData);
            await Preferences.setString(
              Preferences.codSettings,
              jsonEncode(codSettingModel.toJson()),
            );
          }
        }

        if (normalizedZoneId != null && responses.length > 2) {
          final zonePaymentResponse = responses[2];
          if (zonePaymentResponse?.statusCode == 200) {
            hasAnySuccessfulFetch = true;
            final responseData = jsonDecode(zonePaymentResponse!.body);
            zonePaymentSettings = _mergeZonePaymentSettings(
              zonePaymentSettings,
              _extractZonePaymentSettings(responseData),
            );
          } else {
            if (kDebugMode) {
              dev.log(
                'Zone payment settings fetch failed: ${zonePaymentResponse?.statusCode ?? 'no response'}',
              );
            }
          }
        }

        if (zonePaymentSettings.isNotEmpty) {
          await Preferences.setString(
            Preferences.zonePaymentSettings,
            jsonEncode(zonePaymentSettings),
          );
        }
        if (hasAnySuccessfulFetch) {
          _lastPaymentSettingsFetchAt = DateTime.now();
          _lastPaymentSettingsZoneId = normalizedZoneId;
        }
      } catch (e) {
        print('Error fetching payment settings: $e');
      } finally {
        _paymentSettingsInFlight = null;
      }
    }();

    return _paymentSettingsInFlight!;
  }

  // static Future<VendorModel?> getVendorById(String vendorId) async {
  //   VendorModel? vendorModel;
  //   try {
  //     final response = await http.get(
  //       Uri.parse('${AppConst.baseUrl}restaurants/$vendorId'),
  //       headers: await getHeaders(),
  //     );
  //     dev.log("getVendorById ${response.body}  ");
  //     if (response.statusCode == 200) {
  //       final jsonResponse = json.decode(response.body);
  //       if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
  //         vendorModel = VendorModel.fromJson(jsonResponse['data']);
  //       }
  //     } else {
  //       return null;
  //     }
  //   } catch (e) {
  //     ShowToastDialog.closeLoader();
  //     return null;
  //   }
  //   return vendorModel;
  // }

  // optimized — with in-memory cache (5 min TTL), pending-request deduplication, and ApiQueueManager

  static final Map<String, _CachedVendor> _vendorCache = {};
  static final Map<String, Future<VendorModel?>> _pendingVendorRequests = {};
  static const Duration _vendorCacheDuration = Duration(minutes: 5);

  static bool _isValidVendorId(String vendorId) {
    if (vendorId.isEmpty || vendorId == 'null') return false;
    return vendorId.trim().isNotEmpty;
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

  static Future<VendorModel?> _fetchVendorFromApi(String vendorId) async {
    try {
      final uri = Uri.parse('${AppConst.baseUrl}restaurants/$vendorId');
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Vendor fetch timeout');
            },
          );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          dev.log("⚠️ Vendor fetch failed: ${response.statusCode}");
        }
        return null;
      }
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        if (data != null && data is Map<String, dynamic>) {
          return VendorModel.fromJson(data);
        }
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) dev.log("⏰ Vendor timeout: $e");
      return null;
    } on http.ClientException catch (e) {
      if (kDebugMode) dev.log("🌐 Vendor network error: $e");
      return null;
    } catch (e) {
      if (kDebugMode) dev.log("❌ Error fetching vendor: $e");
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

  Stream<List<VendorModel>> getAllNearestRestaurant({bool? isDining}) async* {
    try {
      getNearestVendorController =
          StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];
      if (Constant.selectedZone == null) {
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
        return;
      }
      // **REPLACED FIREBASE WITH API CALL**
      try {
        final response = await http.get(
          Uri.parse(
            '${AppConst.baseUrl}restaurants/by-zone/${Constant.selectedZone!.id}',
          ),
          headers: await getHeaders(),
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            final List<dynamic> restaurantData = responseData['data'];

            // Filter restaurants based on distance from user location
            for (var restaurant in restaurantData) {
              try {
                VendorModel vendorModel = VendorModel.fromJson(restaurant);

                // Calculate distance between user and restaurant
                double distance = _calculateDistance(
                  Constant.selectedLocation.location!.latitude ?? 0.0,
                  Constant.selectedLocation.location!.longitude ?? 0.0,
                  vendorModel.latitude ?? 0.0,
                  vendorModel.longitude ?? 0.0,
                );

                // Filter by radius
                if (distance <= double.parse(Constant.radius)) {
                  // Apply subscription filtering logic
                  if ((Constant.isSubscriptionModelApplied == true ||
                          Constant.adminCommission?.isEnabled == true) &&
                      vendorModel.subscriptionPlan != null) {
                    if (vendorModel.subscriptionTotalOrders == "-1") {
                      vendorList.add(vendorModel);
                      print(
                        '[DEBUG] Restaurant added (unlimited subscription): ${vendorModel.title}',
                      );
                    } else {
                      if ((vendorModel.subscriptionExpiryDate != null &&
                              vendorModel.subscriptionExpiryDate!
                                      .toDate()
                                      .isBefore(DateTime.now()) ==
                                  false) ||
                          vendorModel.subscriptionPlan?.expiryDay == "-1") {
                        if (vendorModel.subscriptionTotalOrders != '0') {
                          // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                          if (vendorModel.vType == null ||
                              vendorModel.vType!.toLowerCase() != 'mart') {
                            vendorList.add(vendorModel);
                            print(
                              '[DEBUG] Restaurant added (valid subscription): ${vendorModel.title}',
                            );
                          } else {
                            print(
                              '[DEBUG] Mart vendor excluded from FOOD category: ${vendorModel.title}',
                            );
                          }
                        } else {
                          print(
                            '[DEBUG] Restaurant filtered out (subscription orders exhausted): ${vendorModel.title}',
                          );
                        }
                      } else {
                        print(
                          '[DEBUG] Restaurant filtered out (subscription expired): ${vendorModel.title}',
                        );
                      }
                    }
                  } else {
                    // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                    if (vendorModel.vType == null ||
                        vendorModel.vType!.toLowerCase() != 'mart') {
                      vendorList.add(vendorModel);
                      print(
                        '[DEBUG] Restaurant added (no subscription filter): ${vendorModel.title}',
                      );
                    } else {
                      print(
                        '[DEBUG] Mart vendor excluded from FOOD category: ${vendorModel.title}',
                      );
                    }
                  }
                } else {
                  print(
                    '[DEBUG] Restaurant filtered out (distance $distance km > radius ${Constant.radius} km): ${vendorModel.title}',
                  );
                }
              } catch (e) {
                print('[DEBUG] Error parsing restaurant data: $e');
              }
            }

            print(
              '[DEBUG] getAllNearestRestaurant: Final result: ${vendorList.length} restaurants after filtering',
            );
            getNearestVendorController!.sink.add(vendorList);
          } else {
            print('[DEBUG] API returned success: false');
            getNearestVendorController!.sink.add([]);
          }
        } else {
          print('[DEBUG] API call failed with status: ${response.statusCode}');
          getNearestVendorController!.sink.add([]);
        }
      } catch (e) {
        print('[DEBUG] API call error: $e');
        getNearestVendorController!.sink.add([]);
      }

      yield* getNearestVendorController!.stream;
    } catch (e) {
      print('[DEBUG] getAllNearestRestaurant: Error in main try block: $e');

      // **FALLBACK: Try to load restaurants without zone filtering if main query fails**
      try {
        print(
          '[DEBUG] getAllNearestRestaurant: Attempting fallback query without zone filtering',
        );
        List<VendorModel> fallbackVendorList = [];

        // Fallback API call - you might need to adjust this endpoint
        final fallbackResponse = await http.get(
          Uri.parse('${AppConst.baseUrl}restaurants'),
          // Adjust endpoint as needed
          headers: await getHeaders(),
        );

        if (fallbackResponse.statusCode == 200) {
          final Map<String, dynamic> fallbackData = json.decode(
            fallbackResponse.body,
          );

          if (fallbackData['success'] == true) {
            final List<dynamic> fallbackRestaurants = fallbackData['data'];
            print(
              '[DEBUG] getAllNearestRestaurant: Fallback query found ${fallbackRestaurants.length} restaurants',
            );

            for (var restaurant in fallbackRestaurants) {
              try {
                final data = restaurant;
                VendorModel vendorModel = VendorModel.fromJson(data);

                // **FOOD CATEGORY FILTERING: Exclude mart vendors from fallback query too**
                if (vendorModel.vType == null ||
                    vendorModel.vType!.toLowerCase() != 'mart') {
                  fallbackVendorList.add(vendorModel);
                } else {
                  print(
                    '[DEBUG] Mart vendor excluded from fallback FOOD category: ${vendorModel.title}',
                  );
                }
              } catch (e) {
                print('[DEBUG] Error parsing fallback restaurant data: $e');
              }
            }

            print(
              '[DEBUG] getAllNearestRestaurant: Fallback result: ${fallbackVendorList.length} restaurants',
            );
            getNearestVendorController!.sink.add(fallbackVendorList);
            yield* getNearestVendorController!.stream;
          }
        }
      } catch (fallbackError) {
        print(
          '[DEBUG] getAllNearestRestaurant: Fallback query also failed: $fallbackError',
        );
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
      }
    }
  }

  // Helper function to calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius of the earth in km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c; // Distance in km

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

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

  // Added: Validation helper
  static bool _isValidProductId(String productId) {
    if (productId.isEmpty || productId == 'null') return false;
    return productId.trim().isNotEmpty;
  }

  // Main optimized method
  static Future<ProductModel?> getProductById(
    String productId, {
    bool forceRefresh = false,
  }) async {
    // Fast validation with early return
    if (!_isValidProductId(productId)) {
      if (kDebugMode) {
        print('[PRODUCT_API] Invalid product ID: "$productId"');
      }
      return null;
    }

    // Normalize ID once
    final normalizedId = productId.trim();

    // Cache-first approach (unless forced)
    if (!forceRefresh) {
      // Check cache
      final cachedProduct = _getCachedProduct(normalizedId);
      if (cachedProduct != null) {
        return cachedProduct;
      }

      // Check pending requests to prevent duplicate API calls
      final existingRequest = _pendingProductRequests[normalizedId];
      if (existingRequest != null) {
        return existingRequest;
      }
    }

    // Create and track the API request
    final completer = Completer<ProductModel?>();
    _pendingProductRequests[normalizedId] = completer.future;

    // Execute API call
    try {
      final productModel = await _fetchProductFromApi(normalizedId);

      // Cache successful responses
      if (productModel != null) {
        _productCache[normalizedId] = _CachedProduct(
          product: productModel,
          fetchedAt: DateTime.now(),
        );
      }

      completer.complete(productModel);
      return productModel;
    } catch (error, stackTrace) {
      // Enhanced error handling
      if (kDebugMode) {
        print('[PRODUCT_API] Failed to fetch product $normalizedId: $error');
        // Optionally log stack trace in debug mode
      }

      // Complete with null on error (or rethrow if preferred)
      completer.complete(null);
      return null;
    } finally {
      // Always clean up pending requests
      _pendingProductRequests.remove(normalizedId);
    }
  }

  // Optional: Batch fetch for multiple products
  static Future<Map<String, ProductModel?>> getProductsByIds(
    List<String> productIds, {
    bool forceRefresh = false,
  }) async {
    final results = <String, ProductModel?>{};
    final uniqueProductIds = productIds.toSet().toList();

    // Group IDs by status
    final cachedProducts = <String, ProductModel>{};
    final pendingRequests = <String, Future<ProductModel?>>{};
    final idsToFetch = <String>[];

    for (final id in uniqueProductIds) {
      if (!_isValidProductId(id)) continue;

      final normalizedId = id.trim();

      if (!forceRefresh) {
        final cached = _getCachedProduct(normalizedId);
        if (cached != null) {
          cachedProducts[normalizedId] = cached;
          continue;
        }

        final pending = _pendingProductRequests[normalizedId];
        if (pending != null) {
          pendingRequests[normalizedId] = pending;
          continue;
        }
      }

      idsToFetch.add(normalizedId);
    }

    // Add cached results
    results.addAll(cachedProducts);

    // Wait for pending requests
    final pendingResults = await Future.wait(
      pendingRequests.entries.map((e) async {
        return MapEntry(e.key, await e.value);
      }),
    );

    for (final entry in pendingResults) {
      results[entry.key] = entry.value;
    }

    // Fetch new products in parallel (using the existing method)
    final fetchFutures = idsToFetch.map(
      (id) => getProductById(id, forceRefresh: forceRefresh),
    );
    final fetchResults = await Future.wait(fetchFutures);

    for (var i = 0; i < idsToFetch.length; i++) {
      results[idsToFetch[i]] = fetchResults[i];
    }

    return results;
  }

  // Cache management methods
  static void clearProductCache() {
    _productCache.clear();
  }

  static void removeFromCache(String productId) {
    _productCache.remove(productId.trim());
  }

  static void cleanupExpiredCache() {
    final now = DateTime.now();
    _productCache.removeWhere((key, value) {
      return now.difference(value.fetchedAt) > _productCacheDuration;
    });
  }

  // Optional: Add cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _productCache.length,
      'pendingRequests': _pendingProductRequests.length,
      'cacheDuration': _productCacheDuration.toString(),
    };
  }

  // static final Map<String, _CachedProduct> _productCache = {};
  // static final Map<String, Future<ProductModel?>> _pendingProductRequests = {};
  // static const Duration _productCacheDuration = Duration(minutes: 5);
  //
  // static ProductModel? _getCachedProduct(String productId) {
  //   final cachedEntry = _productCache[productId];
  //   if (cachedEntry == null) return null;
  //
  //   final isExpired =
  //       DateTime.now().difference(cachedEntry.fetchedAt) >
  //       _productCacheDuration;
  //   if (isExpired) {
  //     _productCache.remove(productId);
  //     return null;
  //   }
  //   return cachedEntry.product;
  // }
  //
  // static Future<ProductModel?> getProductById(
  //   String productId, {
  //   bool forceRefresh = false,
  // }) async {
  //   if (productId.isEmpty || productId == 'null' || productId.trim().isEmpty) {
  //     print('[PRODUCT_API] Invalid product ID provided: "$productId"');
  //     return null;
  //   }
  //   if (!forceRefresh) {
  //     final cachedProduct = _getCachedProduct(productId);
  //     if (cachedProduct != null) {
  //       return cachedProduct;
  //     }
  //     final pendingRequest = _pendingProductRequests[productId];
  //     if (pendingRequest != null) {
  //       return pendingRequest;
  //     }
  //   }
  //   final request = _fetchProductFromApi(productId);
  //   _pendingProductRequests[productId] = request;
  //   try {
  //     final productModel = await request;
  //     if (productModel != null) {
  //       _productCache[productId] = _CachedProduct(product: productModel);
  //     }
  //     return productModel;
  //   } finally {
  //     _pendingProductRequests.remove(productId);
  //   }
  // }

  static Future<ProductModel?> _fetchProductFromApi(String productId) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    const timeoutDuration = Duration(seconds: 10);
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('${AppConst.baseUrl}products/$productId'),
              headers: await getHeaders(),
            )
            .timeout(timeoutDuration);
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            return ProductModel.fromJson(jsonResponse['data']);
          }
        } else if (response.statusCode == 429) {
          if (attempt < maxRetries) {
            print(
              '[PRODUCT_API] Rate limited (429), retrying in ${retryDelay.inSeconds}s (attempt $attempt/$maxRetries)',
            );
            await Future.delayed(retryDelay * attempt); // Exponential backoff
            continue;
          } else {
            print(
              '[PRODUCT_API] Rate limited (429) after $maxRetries attempts, productId=$productId',
            );
          }
        } else {
          print(
            '[PRODUCT_API] getProductById failed '
            'status=${response.statusCode} productId=$productId',
          );
          // Don't retry for non-429 errors
          return null;
        }
      } on TimeoutException {
        print(
          '[PRODUCT_API] Timeout fetching product $productId (attempt $attempt/$maxRetries)',
        );
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
      } catch (e, s) {
        print('[PRODUCT_API] Error fetching product $productId: $e');
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        print(s);
      }
    }
    return null;
  }

  static Future<List<AttributesModel>> getAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}vendor/attributes'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<AttributesModel> attributeList = [];

          for (var element in responseData['data']) {
            AttributesModel attributeModel = AttributesModel.fromJson(element);
            attributeList.add(attributeModel);
          }
          return attributeList;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load attributes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attributes: $e');
    }
  }

  static Future<DeliveryCharge?> getDeliveryCharge() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/delivery-charge'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return DeliveryCharge.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<TaxModel>?> getTaxList() async {
    print(" getTaxList ");
    List<TaxModel> taxList = [];
    if (Constant.selectedLocation.location?.latitude == null ||
        Constant.selectedLocation.location?.longitude == null) {
      print('[API_UTILS] Location not available for tax calculation');
      return taxList;
    }
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        Constant.selectedLocation.location!.latitude!,
        Constant.selectedLocation.location!.longitude!,
      );
      if (placeMarks.isEmpty) {
        print('[API_UTILS] No placemarks found for coordinates');
        return taxList;
      }
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/tax'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> taxData = responseData['data'];
          // Filter taxes by country and enable status
          for (var element in taxData) {
            TaxModel taxModel = TaxModel.fromJson(element);
            // Apply filters manually (previously done in Firebase query)
            if (taxModel.country == placeMarks.first.country &&
                taxModel.enable == true) {
              taxList.add(taxModel);
            }
          }
        } else {
          print('[API_UTILS] API returned unsuccessful response');
        }
      } else {
        print('[API_UTILS] HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('[API_UTILS] Error getting tax list: $e');
    }
    return taxList;
  }

  static Future<bool> setProduct(ProductModel orderModel) async {
    try {
      final url = "${AppConst.baseUrl}firestore/setProduct?id=${orderModel.id}";
      print("setProduct $url");
      final body = jsonEncode(orderModel.toJson());
      final response = await http.post(
        Uri.parse(url),
        headers: await getHeaders(),
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error: $e");
      return false;
    }
  }

  // static Future<List<OrderModel>> getAllOrder() async {
  //   List<OrderModel> list = [];
  //   // Backend user id only (e.g. "user_26c52283-..."). API does not accept Firebase UID for author_id.
  //   var currentUid = Constant.userModel?.id;
  //   if (currentUid == null || currentUid.isEmpty) {
  //     currentUid = await SqlStorageConst.getUserId();
  //   }
  //   if (currentUid == null || currentUid.isEmpty) {
  //     currentUid = Constant.userModel?.firebaseId;
  //   }
  //   if (currentUid == null || currentUid.isEmpty) {
  //     currentUid = await SqlStorageConst.getFirebaseId();
  //   }
  //   if (kDebugMode) {
  //     print('getAllOrder: userId=$currentUid');
  //   }
  //   if (currentUid == null || currentUid.isEmpty) {
  //     if (kDebugMode) {
  //       print('getAllOrder: No user ID found, returning empty list');
  //     }
  //     return list;
  //   }
  //
  //   try {
  //     // Try mobile/orders first (uses auth header; returns data.orders structure)
  //     list = await _fetchOrdersFromMobile();
  //     if (list.isEmpty &&
  //         currentUid.isNotEmpty &&
  //         currentUid.startsWith('user_')) {
  //       // firestore/orders expects backend user id only, not Firebase UID
  //       list = await _fetchOrdersFromFirestore(currentUid);
  //     }
  //   } catch (e, st) {
  //     if (kDebugMode) {
  //       print('getAllOrder error: $e');
  //       dev.log('getAllOrder stack: $st');
  //     }
  //   }
  //
  //   if (kDebugMode) {
  //     print('getAllOrder: Returning ${list.length} orders');
  //   }
  //   return list;
  // }

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
        final orderModel = OrderModel.fromJson(_normalizeOrderJson(orderData));
        if (orderModel.createdAt != null) list.add(orderModel);
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

  static Future<List<OrderModel>> _fetchOrdersFromMobile() async {
    var list = <OrderModel>[];
    try {
      final uri = Uri.parse('${AppConst.baseUrl}mobile/orders');
      if (kDebugMode) {
        print('getAllOrder: mobile/orders URL: $uri');
      }
      final response = await http.get(uri, headers: await getHeaders());
      if (kDebugMode) {
        print('getAllOrder: mobile/orders status: ${response.statusCode}');
      }
      if (response.statusCode != 200) return list;

      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      if (responseData == null || responseData['success'] != true) return list;

      final data = responseData['data'];
      List<dynamic> ordersData = [];
      if (data is List) {
        ordersData = data;
      } else if (data is Map && data['orders'] != null) {
        final orders = data['orders'];
        ordersData = orders is List ? orders : [];
      }

      if (kDebugMode) {
        print('getAllOrder: mobile/orders raw count: ${ordersData.length}');
      }

      for (var raw in ordersData) {
        try {
          final orderData = raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map);
          final orderModel = OrderModel.fromJson(
            _normalizeOrderJson(orderData),
          );
          list.add(orderModel);
        } catch (e) {
          if (kDebugMode) {
            print('getAllOrder: Skip order parse error: $e');
          }
        }
      }

      list = list.where((o) => o.createdAt != null).toList();
      list.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    } catch (e) {
      if (kDebugMode) {
        print('getAllOrder: mobile/orders error: $e');
      }
    }
    return list;
  }

  static Map<String, dynamic> _normalizeOrderJson(Map<String, dynamic> json) {
    var out = Map<String, dynamic>.from(json);
    // Unwrap if API returns { "order": { ... }, "status": "Order Rejected" }
    if (out['order'] is Map) {
      final inner = Map<String, dynamic>.from(out['order'] as Map);
      for (final key in ['status', 'id', 'createdAt', 'created_at']) {
        if (out[key] != null && inner[key] == null) inner[key] = out[key];
      }
      out = inner;
    }
    if (out['createdAt'] == null && out['created_at'] != null) {
      out['createdAt'] = out['created_at'];
    }
    if (out['vendorID'] == null && out['vendor_id'] != null) {
      out['vendorID'] = out['vendor_id'];
    }
    if (out['id'] == null && out['order_id'] != null) {
      out['id'] = out['order_id'];
    }
    // Ensure status is set from API (some list endpoints use order_status or status_label)
    if (out['status'] == null ||
        (out['status'] is String && (out['status'] as String).trim().isEmpty)) {
      if (out['order_status'] != null) {
        out['status'] = out['order_status'];
      } else if (out['status_label'] != null) {
        out['status'] = out['status_label'];
      }
    }
    return out;
  }

  static String _catalogIdFromCartOrOrderRow(String? productId) {
    if (productId == null || productId.isEmpty) return '';
    final t = productId.trim();
    if (t.toLowerCase() == 'null') return '';
    final tilde = t.indexOf('~');
    if (tilde <= 0) return t;
    return t.substring(0, tilde).trim();
  }

  /// Base product id for API calls when line id is `productId~variantId`.
  static String catalogIdFromOrderLine(String? productId) =>
      _catalogIdFromCartOrOrderRow(productId);

  static bool _idsLooselyEqual(String? a, String? b) {
    if (a == null || b == null) return false;
    final as = a.trim();
    final bs = b.trim();
    if (as.isEmpty || bs.isEmpty) return false;
    if (as == bs) return true;
    final ai = int.tryParse(as);
    final bi = int.tryParse(bs);
    if (ai != null && bi != null && ai == bi) return true;
    return false;
  }

  static ProductOption? _matchProductOptionForReorder(
    ProductModel product,
    VariantInfo? vi,
  ) {
    if (vi == null || product.options == null || product.options!.isEmpty) {
      return null;
    }
    final vid = vi.variantId?.trim();
    if (vid != null && vid.isNotEmpty && vid != '0') {
      for (final o in product.options!) {
        if (_idsLooselyEqual(o.id, vid)) return o;
      }
    }
    final sku = vi.variantSku?.trim();
    if (sku != null && sku.isNotEmpty) {
      for (final o in product.options!) {
        if (o.subtitle == sku || o.title == sku) return o;
      }
    }
    return null;
  }

  static Variants? _matchItemAttributeVariantForReorder(
    ProductModel product,
    VariantInfo? vi,
  ) {
    if (vi == null || product.itemAttribute?.variants == null) return null;
    final vars = product.itemAttribute!.variants!;
    final vid = vi.variantId?.trim();
    if (vid != null && vid.isNotEmpty && vid != '0') {
      for (final v in vars) {
        if (_idsLooselyEqual(v.variantId, vid)) return v;
      }
    }
    final sku = vi.variantSku?.trim();
    if (sku != null && sku.isNotEmpty) {
      for (final v in vars) {
        if (v.variantSku == sku) return v;
      }
    }
    return null;
  }

  static double _commissionUnitPrice(VendorModel v, String? raw) {
    return double.parse(Constant.productCommissionPrice(v, raw ?? '0'));
  }

  static ProductPriceInfo _reorderVariantPriceInfo({
    required double unit,
    String? promoId,
  }) {
    return ProductPriceInfo(
      currentPrice: unit,
      discountPrice: 0.0,
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

      if (product == null) {
        final unit = _fallbackUnitFromOrderSnapshot(
          element.price,
          element.discountPrice,
        );
        final hasVariant = element.variantInfo != null;
        return ProductPriceInfo(
          currentPrice: unit,
          discountPrice: hasVariant ? 0.0 : unit,
          promoId: element.promoId,
        );
      }

      final productVendorId = product.vendorID ?? '';
      if (productVendorId.isNotEmpty &&
          vendorId.isNotEmpty &&
          productVendorId != vendorId) {
        return null;
      }

      final variantInfo = element.variantInfo;
      final promoId = element.promoId;
      if (variantInfo != null) {
        final opt = _matchProductOptionForReorder(product, variantInfo);
        if (opt != null && opt.price != null) {
          return _reorderVariantPriceInfo(
            unit: _commissionUnitPrice(v, opt.price),
            promoId: promoId,
          );
        }

        final varRow = _matchItemAttributeVariantForReorder(
          product,
          variantInfo,
        );
        if (varRow != null && varRow.variantPrice != null) {
          return _reorderVariantPriceInfo(
            unit: _commissionUnitPrice(
              v,
              varRow.variantPrice ?? product.price ?? '0',
            ),
            promoId: promoId,
          );
        }

        final rawVp = variantInfo.variantPrice?.trim();
        final rawParsed = rawVp != null ? double.tryParse(rawVp) : null;
        if (rawParsed != null && rawParsed > 0) {
          return _reorderVariantPriceInfo(
            unit: _commissionUnitPrice(v, rawVp),
            promoId: promoId,
          );
        }

        final fb = _fallbackUnitFromOrderSnapshot(
          element.price,
          element.discountPrice,
        );
        return _reorderVariantPriceInfo(unit: fb, promoId: promoId);
      }

      final reg = double.tryParse(product.price ?? '0') ?? 0.0;
      final dis = double.tryParse(product.disPrice ?? '0') ?? 0.0;
      if (dis > 0 && dis < reg) {
        return ProductPriceInfo(
          currentPrice: _commissionUnitPrice(v, product.price),
          discountPrice: _commissionUnitPrice(v, product.disPrice),
          promoId: promoId,
        );
      }

      final unit = _commissionUnitPrice(v, product.price);
      return ProductPriceInfo(
        currentPrice: unit,
        discountPrice: unit,
        promoId: promoId,
      );
    } catch (e) {
      dev.log('Error building price info for reorder: $e');
      return null;
    }
  }

  /// Fetch current product price from API for reorder / add flows (live, variant-aware).
  static Future<ProductPriceInfo?> getCurrentProductPrice({
    required String productId,
    required String vendorId,
    VariantInfo? variantInfo,
    VendorModel? vendorModel,
    String? fallbackPrice,
    String? fallbackDiscountPrice,
    bool forceRefresh = true,
  }) async {
    try {
      final catalogId = _catalogIdFromCartOrOrderRow(productId);
      if (catalogId.isEmpty) return null;

      final product = await getProductById(
        catalogId,
        forceRefresh: forceRefresh,
      );
      final synthetic = CartProductModel(
        id: productId,
        vendorID: vendorId,
        variantInfo: variantInfo,
        price: fallbackPrice,
        discountPrice: fallbackDiscountPrice,
      );
      return priceInfoForReorderLine(
        product: product,
        element: synthetic,
        vendor: vendorModel,
      );
    } catch (e) {
      dev.log('Error fetching current product price: $e');
      return null;
    }
  }

  /// Fetch single order by ID from API
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/orders/$orderId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final orderData = data is Map<String, dynamic>
              ? data
              : data['order'] ?? data;
          if (orderData != null && orderData is Map<String, dynamic>) {
            return OrderModel.fromJson(orderData);
          }
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching order by ID: $e');
      return null;
    }
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/email-templates/$type'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return EmailTemplateModel.fromJson(responseData['data']);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception(
          'Failed to load email template: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching email template: $e');
      return null;
    }
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/notifications/$type'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return NotificationModel.fromJson(jsonResponse['data']);
        } else {
          return NotificationModel(
            id: "",
            message: "Notification setup is pending",
            subject: "setup notification",
            type: "",
          );
        }
      } else {
        // Handle HTTP error
        return NotificationModel(
          id: "",
          message: "Failed to fetch notification: ${response.statusCode}",
          subject: "Error",
          type: "",
        );
      }
    } catch (e) {
      // Handle network/parsing errors
      return NotificationModel(
        id: "",
        message: "Network error: $e",
        subject: "Error",
        type: "",
      );
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
      print("getVendorReviews ${AppConst.baseUrl}vendor/$vendorId/reviews)}");
      print("getVendorReviews " + response.body);
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
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error fetching reviews: $error');
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
        print(
          'getReviewEligibility API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching review eligibility: $e');
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

      print(
        'submitOrderReview API Error: ${response.statusCode} - ${response.body}',
      );
      return false;
    } catch (e) {
      print('Error submitting order review: $e');
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
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching review attribute: $e');
      return null;
    }
  }

  static Future<bool?> setRatingModel(RatingModel ratingModel) async {
    bool isAdded = false;
    try {
      print("setRatingModel ${ratingModel.toJson()} ");
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}firestore/ratings'),
        headers: await getHeaders(),
        body: jsonEncode(ratingModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isAdded = true;
      } else {
        isAdded = false;
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      isAdded = false;
      print('Exception: $error');
    }

    return isAdded;
  }

  // static Future<VendorModel?> updateVendor(VendorModel vendor) async {
  //   return await fireStore
  //       .collection(CollectionName.vendors)
  //       .doc(vendor.id)
  //       .set(vendor.toJson())
  //       .then((document) {
  //         return vendor;
  //       });
  // }

  static Future<List<AdvertisementModel>> getAllAdvertisement() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/advertisements/active'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> advertisementsData =
              responseData['data']['advertisements'];

          List<AdvertisementModel> advertisementList = [];

          for (var element in advertisementsData) {
            try {
              AdvertisementModel advertisementModel =
                  AdvertisementModel.fromJson(element);

              // Apply the same filtering logic
              if (advertisementModel.isPaused == null ||
                  advertisementModel.isPaused == false) {
                advertisementList.add(advertisementModel);
              }
            } catch (e) {
              // Handle individual advertisement parsing errors
              print('Error parsing advertisement: $e');
            }
          }

          return advertisementList;
        } else {
          throw Exception(
            'API returned unsuccessful response: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      print('Error fetching advertisements: $error');
      return []; // Return empty list on error, similar to your catchError
    }
  }

  /// **FETCH ALL ACTIVE PROMOTIONS**
  static Future<List<Map<String, dynamic>>> getAllActivePromotions({
    required String zoneId,
  }) async {
    try {
      final uri = Uri.parse('${AppConst.baseUrl}firestore/promotions/active')
          .replace(
            queryParameters: {
              'zoneId': zoneId, // ✅ SEND ZONE ID
            },
          );

      final response = await http.get(uri, headers: await getHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> promotionsData =
              responseData['data']['promotions'] ?? [];

          final now = DateTime.now();
          List<Map<String, dynamic>> promotionsList = [];

          for (final promo in promotionsData) {
            try {
              final isAvailable =
                  promo['isAvailable'] == 1 || promo['isAvailable'] == true;

              // ⏱ Time validation
              final startTime = DateTime.parse(promo['start_time']);
              final endTime = DateTime.parse(promo['end_time']);

              // 🗺 Zone validation (extra safety)
              final promoZoneId = promo['zoneId']?.toString();

              if (!isAvailable ||
                  promoZoneId != zoneId ||
                  now.isBefore(startTime) ||
                  now.isAfter(endTime)) {
                continue;
              }

              promotionsList.add({
                'id': promo['id'],
                'payment_mode': promo['payment_mode'],
                'product_title': promo['product_title'],
                'extra_km_charge': promo['extra_km_charge'],
                'product_id': promo['product_id'],
                'end_time': promo['end_time'],
                'restaurant_id': promo['restaurant_id'],
                'start_time': promo['start_time'],
                'item_limit': promo['item_limit'],
                'restaurant_title': promo['restaurant_title'],
                'vType': promo['vType'],
                'zoneId': promoZoneId,
                'free_delivery_km': promo['free_delivery_km'],
                'special_price': promo['special_price'],
                'isAvailable': true,
              });
            } catch (e) {
              print('Error parsing promotion: $e');
            }
          }

          return promotionsList;
        } else {
          throw Exception(responseData['message'] ?? 'API failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching promotions: $e');
      return [];
    }
  }

  /// **ULTRA-FAST PROMOTIONAL DATA FETCHING WITH API**
  static Future<List<Map<String, dynamic>>> fetchActivePromotions({
    required String restaurantId,
    required String productId,
  }) async {
    try {
      // Only make API call if both IDs are provided and not empty
      if (productId.isEmpty || restaurantId.isEmpty) {
        print('[DEBUG] Skipping API call - productId or restaurantId is empty');
        return [];
      }

      final String apiUrl =
          '${AppConst.baseUrl}firestore/promotions/by-product?'
          'product_id=$productId&'
          'restaurant_id=$restaurantId';
      print('fetchActivePromotions: $apiUrl');
      // Make API call
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await getHeaders(),
      );

      print('[DEBUG] API Response Status: ${response.statusCode}');
      print('[DEBUG] API Response Body: ${response.body}');

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

            print(
              '[DEBUG] Promotion for product ${promo['product_id']}: active=$isActive, available=${processedPromotion['isAvailable']}',
            );

            if (isActive) {
              activePromotions.add(processedPromotion);
            }
          }

          print('[DEBUG] Found ${activePromotions.length} active promotions');
          print('[DEBUG] ===== ULTRA-FAST API FETCH COMPLETE =====');

          return activePromotions;
        } else {
          print(
            '[DEBUG] API returned unsuccessful response: ${responseData['message'] ?? 'Unknown error'}',
          );
          return [];
        }
      } else if (response.statusCode == 404) {
        print('[DEBUG] No promotion found (404) for product $productId');
        return [];
      } else {
        print('[DEBUG] API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('[DEBUG] ERROR in ultra-fast API fetch: $e');
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
        print('[DEBUG] Error parsing timestamp: $e');
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

  static Future<List<ProductModel>> getAllProductsInZone({int? limit}) async {
    try {
      print(
        "🔍 Fetching products from API for zone: ${Constant.selectedZone?.name}",
      );

      // Prepare API parameters
      final Map<String, String> queryParams = {};

      // Add zone_id if selected
      if (Constant.selectedZone != null) {
        queryParams['zone_id'] = Constant.selectedZone!.id.toString();
      }
      // Add limit if provided
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      // Make API call
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}firestore/search/products',
        ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsData = responseData['data']['products'];
          final List<ProductModel> productList = [];

          for (var productData in productsData) {
            try {
              // Use the API JSON factory constructor
              ProductModel product = ProductModel.fromApiJson(productData);
              productList.add(product);
            } catch (e) {
              print('❌ Error parsing product ${productData['id']}: $e');
            }
          }

          print('✅ Loaded ${productList.length} products from API');
          return productList;
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('❌ HTTP error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading products from API: $e');
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
        );
      }
      return [];
    }
  }

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
  //       print(
  //         '🔍 Loading vendors from zone: ${Constant.selectedZone!.name} (${Constant.selectedZone!.id})',
  //       );
  //     } else {
  //       query = FirebaseFirestore.instance
  //           .collection(CollectionName.vendors)
  //           .limit(safeLimit);
  //       print('🔍 No zone selected, loading all vendors');
  //     }
  //     QuerySnapshot querySnapshot = await query.get();
  //     print(
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
  //           print('🔍 Mart vendor excluded from search: ${vendorModel.title}');
  //         }
  //       } catch (e) {
  //         print('❌ Error parsing vendor ${document.id}: $e');
  //       }
  //     }
  //     print('✅ Loaded ${vendorList.length} vendors for search');
  //     return vendorList;
  //   } catch (e) {
  //     print('❌ Error loading all vendors: $e');
  //     if (e.toString().contains('OutOfMemoryError')) {
  //       print(
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
      print('🌐 Fetching products from API: $uri');
      // Make API request
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsJson = responseData['data'];
          final Map<String, dynamic> meta = responseData['meta'];

          print(
            '📊 API Response: Loaded ${productsJson.length} products (Page $page of ${meta['last_page']}, Total: ${meta['total']})',
          );

          // Parse products
          for (var productJson in productsJson) {
            try {
              ProductModel productModel = ProductModel.fromJson(productJson);
              productList.add(productModel);
            } catch (e) {
              print('❌ Error parsing product ${productJson['id']}: $e');
            }
          }

          print(
            '✅ Successfully loaded ${productList.length} products from API',
          );
          return productList;
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print(
          '❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return [];
      }
    } catch (e) {
      print('❌ Error loading products from API: $e');

      if (e is http.ClientException) {
        print('🌐 Network error: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ Request timeout');
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
      print('❌ Error loading trending searches: $e');
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
