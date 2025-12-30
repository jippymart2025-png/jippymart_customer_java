import 'dart:async';

import 'package:jippymart_customer/utils/fire_store_utils.dart';

  /// **OPTIMIZED PROMOTIONAL CACHE SERVICE (Android & iOS)**
class PromotionalCacheService {
  static final PromotionalCacheService _instance =
      PromotionalCacheService._internal();

  factory PromotionalCacheService() => _instance;

  PromotionalCacheService._internal();

  // **PROMOTIONAL CACHE STORAGE**
  static final Map<String, Map<String, dynamic>> _promotionalCache = {};
  static final Map<String, int> _promotionalLimits = {};
  static final Map<String, bool> _promotionalAvailability = {};
  static final Map<String, bool> _restaurantCacheLoaded = {};
  static final Map<String, Set<String>> _restaurantPromotionalProducts = {};
  static final Map<String, List<Map<String, dynamic>>>
  _restaurantPromotionsMap = {};

  // iOS-specific: Track ongoing requests to prevent duplicate calls
  static final Map<String, Completer<void>> _ongoingRequests = {};

  /// **IOS-OPTIMIZED: LAZY LOADING PROMOTIONAL CACHE**
  static Future<void> loadRestaurantPromotions({
    required String restaurantId,
    required String productId,
  }) async {
    final cacheKey = '$productId-$restaurantId';

    // Check if already cached
    if (_promotionalCache.containsKey(cacheKey)) {
      return;
    }

    // Check if already being loaded
    final requestKey = 'single-$cacheKey';
    if (_ongoingRequests.containsKey(requestKey)) {
      return await _ongoingRequests[requestKey]!.future;
    }

    final completer = Completer<void>();
    _ongoingRequests[requestKey] = completer;

    try {
      print('📱 Loading promotion for product: $productId');

      final promotions = await FireStoreUtils.fetchActivePromotions(
        restaurantId: restaurantId,
        productId: productId,
      );

      if (promotions.isNotEmpty) {
        _cachePromotions(promotions, restaurantId);

        // Track this product as having promotions
        if (!_restaurantPromotionalProducts.containsKey(restaurantId)) {
          _restaurantPromotionalProducts[restaurantId] = Set<String>();
        }
        _restaurantPromotionalProducts[restaurantId]!.add(productId);

        print('✅ Found promotion for product: $productId');
      }
    } catch (e) {
      print('❌ Error loading promotion for $productId: $e');
    } finally {
      completer.complete();
      _ongoingRequests.remove(requestKey);
    }
  }

  /// **OPTIMIZED: BULK LOADING FOR MULTIPLE PRODUCTS (ANDROID & iOS)**
  /// Uses parallel batch processing for better performance
  static Future<void> loadAllRestaurantPromotions({
    required String restaurantId,
    required List<String> productIds,
  }) async {
    // Check if already loaded
    if (_restaurantCacheLoaded[restaurantId] == true) {
      print('📱 Promotions already loaded for restaurant: $restaurantId');
      return;
    }

    // Check if already being loaded
    final requestKey = 'bulk-$restaurantId';
    if (_ongoingRequests.containsKey(requestKey)) {
      return await _ongoingRequests[requestKey]!.future;
    }

    final completer = Completer<void>();
    _ongoingRequests[requestKey] = completer;

    if (productIds.isEmpty) {
      print('📱 No product IDs provided');
      _restaurantCacheLoaded[restaurantId] = true;
      completer.complete();
      _ongoingRequests.remove(requestKey);
      return;
    }

    try {
      print('📱 Starting bulk loading for restaurant: $restaurantId');
      print('📱 Checking ${productIds.length} products');

      // Initialize tracking
      if (!_restaurantPromotionalProducts.containsKey(restaurantId)) {
        _restaurantPromotionalProducts[restaurantId] = Set<String>();
      }

      // Filter out already checked/cached products
      final productsToCheck = <String>[];
      for (final productId in productIds) {
        // Skip if already checked
        if (_restaurantPromotionalProducts[restaurantId]!.contains(productId)) {
          continue;
        }

        final cacheKey = '$productId-$restaurantId';
        if (_promotionalCache.containsKey(cacheKey)) {
          _restaurantPromotionalProducts[restaurantId]!.add(productId);
          continue;
        }

        productsToCheck.add(productId);
      }

      if (productsToCheck.isEmpty) {
        print('📱 All products already cached');
        _restaurantCacheLoaded[restaurantId] = true;
        completer.complete();
        _ongoingRequests.remove(requestKey);
        return;
      }

      print('📱 Loading promotions for ${productsToCheck.length} products in parallel batches');

      // OPTIMIZED: Process in parallel batches for better performance
      // Use smaller batches (10 products at a time) to avoid overwhelming the network
      const batchSize = 10;
      int processedCount = 0;

      for (int i = 0; i < productsToCheck.length; i += batchSize) {
        final end = (i + batchSize < productsToCheck.length)
            ? i + batchSize
            : productsToCheck.length;
        final batch = productsToCheck.sublist(i, end);

        // Process batch in parallel
        final batchFutures = batch.map((productId) async {
          try {
            final promotions = await FireStoreUtils.fetchActivePromotions(
              restaurantId: restaurantId,
              productId: productId,
            );

            if (promotions.isNotEmpty) {
              _cachePromotions(promotions, restaurantId);
              _restaurantPromotionalProducts[restaurantId]!.add(productId);
              print('✅ Found promotion for: $productId');
              return true;
            }
            return false;
          } catch (e) {
            print('⚠️ Error checking $productId: $e');
            return false;
          }
        }).toList();

        // Wait for batch to complete
        await Future.wait(batchFutures, eagerError: false);
        processedCount += batch.length;

        // Small delay between batches to prevent network overload
        if (i + batchSize < productsToCheck.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      _restaurantCacheLoaded[restaurantId] = true;

      final promoCount = _restaurantPromotionalProducts[restaurantId]!.length;
      print('📱 Bulk loading complete');
      print('📱 Processed $processedCount products, found $promoCount promotional products');
    } catch (e) {
      print('❌ Error in bulk loading: $e');
      // Still mark as loaded to prevent repeated attempts
      _restaurantCacheLoaded[restaurantId] = true;
    } finally {
      completer.complete();
      _ongoingRequests.remove(requestKey);
    }
  }

  /// **Helper: Cache promotions**
  static void _cachePromotions(
    List<Map<String, dynamic>> promotions,
    String restaurantId,
  ) {
    for (final promo in promotions) {
      final promoProductId = promo['product_id'] as String?;
      final promoRestaurantId =
          promo['restaurant_id'] as String? ?? restaurantId;

      if (promoProductId != null) {
        final promoCacheKey = '$promoProductId-$promoRestaurantId';

        // **INSTANT CACHE STORAGE**
        _promotionalCache[promoCacheKey] = promo;

        // **PRE-CALCULATE FOR INSTANT ACCESS**
        final itemLimitData = promo['item_limit'];
        int? itemLimit;
        if (itemLimitData != null) {
          if (itemLimitData is int) {
            itemLimit = itemLimitData;
          } else if (itemLimitData is double) {
            itemLimit = itemLimitData.toInt();
          } else if (itemLimitData is String) {
            itemLimit = int.tryParse(itemLimitData);
          } else if (itemLimitData is num) {
            itemLimit = itemLimitData.toInt();
          }
        }
        _promotionalLimits[promoCacheKey] = itemLimit ?? 0;
        _promotionalAvailability[promoCacheKey] =
            itemLimit != null && itemLimit > 0;
      }
    }
  }

  /// **Get ALL promotional products for restaurant**
  static Set<String> getPromotionalProductsForRestaurant(String restaurantId) {
    return _restaurantPromotionalProducts[restaurantId] ?? Set<String>();
  }

  /// **Check if restaurant promotions are loaded**
  static bool isRestaurantPromotionsLoaded(String restaurantId) {
    return _restaurantCacheLoaded[restaurantId] == true;
  }

  /// **Get all promotions for restaurant**
  static List<Map<String, dynamic>> getAllPromotionsForRestaurant(
    String restaurantId,
  ) {
    return _restaurantPromotionsMap[restaurantId] ?? [];
  }

  /// **GET CACHED PROMOTIONAL DATA (INSTANT - ZERO ASYNC)**
  static Map<String, dynamic>? getCachedPromotionalData(
    String productId,
    String restaurantId,
  ) {
    final cacheKey = '$productId-$restaurantId';
    return _promotionalCache[cacheKey];
  }

  /// **CHECK PROMOTIONAL AVAILABILITY (INSTANT - ZERO ASYNC)**
  static bool isPromotionalAvailable(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _promotionalAvailability[cacheKey] ?? false;
  }

  /// **GET PROMOTIONAL LIMIT (INSTANT - ZERO ASYNC)**
  static int getPromotionalLimit(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _promotionalLimits[cacheKey] ?? 0;
  }

  /// **GET PROMOTIONAL ITEM LIMIT (INSTANT - ZERO ASYNC)**
  static int? getPromotionalItemLimit(String productId, String restaurantId) {
    if (!isPromotionalAvailable(productId, restaurantId)) {
      return null;
    }
    final limit = getPromotionalLimit(productId, restaurantId);
    return limit > 0 ? limit : null;
  }

  /// **CHECK IF PROMOTIONAL ITEM QUANTITY IS ALLOWED (INSTANT - ZERO ASYNC)**
  static bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) {
      return true; // Allow decrement
    }

    if (!isPromotionalAvailable(productId, restaurantId)) {
      return false;
    }

    final limit = getPromotionalLimit(productId, restaurantId);
    return currentQuantity <= limit;
  }

  /// **CLEAR CACHE FOR RESTAURANT**
  static void clearRestaurantCache(String restaurantId) {
    _restaurantCacheLoaded[restaurantId] = false;
    _restaurantPromotionalProducts.remove(restaurantId);
    _restaurantPromotionsMap.remove(restaurantId);

    // Remove all cached items for this restaurant
    final keysToRemove = <String>[];
    for (final key in _promotionalCache.keys) {
      if (key.endsWith('-$restaurantId')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _promotionalCache.remove(key);
      _promotionalLimits.remove(key);
      _promotionalAvailability.remove(key);
    }

    print('📱 Cleared promotional cache for restaurant: $restaurantId');
  }

  /// **CLEAR ALL CACHE**
  static void clearAllCache() {
    _promotionalCache.clear();
    _promotionalLimits.clear();
    _promotionalAvailability.clear();
    _restaurantCacheLoaded.clear();
    _restaurantPromotionalProducts.clear();
    _restaurantPromotionsMap.clear();
    _ongoingRequests.clear();
    print('📱 Cleared all promotional cache');
  }

  /// **GET CACHE STATS**
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _promotionalCache.length,
      'loadedRestaurants': _restaurantCacheLoaded.keys.toList(),
      'restaurantsWithPromotions': _restaurantPromotionalProducts.keys.length,
      'ongoingRequests': _ongoingRequests.keys.length,
    };
  }
}
