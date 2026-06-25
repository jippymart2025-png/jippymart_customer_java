import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/services/cache_manager.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';

class FavouriteProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 15);

  bool favouriteRestaurant = true;
  List<VendorModel> favouriteVendorList = <VendorModel>[];
  List<ProductModel> favouriteFoodList = <ProductModel>[];
  bool isLoading = false;

  // Batch loading control
  bool _isLoadingVendors = false;
  bool _isLoadingFoods = false;

  // Debounce timer
  Timer? _debounceTimer;

  Future<void> initFunction({bool forceRefresh = false}) async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadFavoriteRestaurants(forceRefresh),
        _loadFavoriteFoods(forceRefresh),
      ]);
    } catch (e) {
      log('Error loading favorites: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteRestaurants(bool forceRefresh) async {
    if (_isLoadingVendors) return;

    try {
      _isLoadingVendors = true;

      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null) {
        favouriteVendorList = [];
        return;
      }

      final cacheKey = 'favorite_restaurants_$userId';
      if (forceRefresh) {
        CacheManager().remove(cacheKey);
      }

      final restaurants = await CacheManager()
          .getOrSetUserProfile<List<VendorModel>>(
            cacheKey,
            () => ApiQueueManager().enqueue<List<VendorModel>>(
              priority: RequestPriority.normal,
              key: cacheKey,
              request: () => getFavouriteRestaurants(),
            ),
          );

      favouriteVendorList = restaurants;
    } finally {
      _isLoadingVendors = false;
    }
  }

  Future<void> _loadFavoriteFoods(bool forceRefresh) async {
    if (_isLoadingFoods) return;

    try {
      _isLoadingFoods = true;

      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null) {
        favouriteFoodList = [];
        return;
      }

      final cacheKey = 'favorite_items_$userId';
      if (forceRefresh) {
        CacheManager().remove(cacheKey);
      }

      final foods = await CacheManager()
          .getOrSetUserProfile<List<ProductModel>>(
            cacheKey,
            () => ApiQueueManager().enqueue<List<ProductModel>>(
              priority: RequestPriority.normal,
              key: cacheKey,
              request: () => getFavouriteFoods(),
            ),
          );

      favouriteFoodList = foods;
    } finally {
      _isLoadingFoods = false;
    }
  }

  void changeTabUpdate(bool value) {
    // Debounce tab switching
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      favouriteRestaurant = value;
      notifyListeners();
    });
  }

  // ========== RESTAURANT FAVORITES API METHODS ==========

  static Future<List<VendorModel>> getFavouriteRestaurants() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null) return [];

      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}favorites/restaurants/$userId'),
            headers: await getHeaders(),
          )
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return [];
        }

        final responseData = decoded;
        if (responseData['success'] == true) {
          final List<dynamic> restaurantsData = responseData['data'] ?? [];
          return restaurantsData
              .whereType<Map<String, dynamic>>()
              .map((item) => VendorModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } on TimeoutException {
      log('Timeout fetching favorite restaurants');
      return [];
    } catch (e) {
      log('Error fetching favorite restaurants: $e');
      return [];
    }
  }

  static Future<void> addFavouriteRestaurant(String restaurantId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || restaurantId.isEmpty) return;

      await http
          .post(
            Uri.parse('${AppConst.baseUrl}favorites/restaurants'),
            headers: await getHeaders(),
            body: json.encode({
              "firebase_id": userId,
              "restaurant_id": restaurantId,
            }),
          )
          .timeout(_networkTimeout);

      log('✅ Restaurant added to favorites: $restaurantId');
    } catch (e) {
      log('❌ Error adding favorite restaurant: $e');
    }
  }

  static Future<bool> toggleFavoriteOutlet({
    required int customerId,
    required int outletId,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMzgzNTQ4LCJleHAiOjE3ODI0Njk5NDh9.Pm96Vs395-fbNIPWjYhX5AmqIjq-WHG-h4QU4IbrBdc",
      };

      final response = await http
          .post(
            Uri.parse(
              'http://192.168.0.17:8084/api/fm/customer/favorites/toggleFavoriteOutlet',
            ),
            headers: headers,
            body: json.encode({
              'customerId': customerId,
              'outletId': outletId,
              'createdBy': customerId,
            }),
          )
          .timeout(_networkTimeout);

      log('[Favorites] toggleFavoriteOutlet status: ${response.statusCode}');
      log('[Favorites] toggleFavoriteOutlet body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log('❌ Error toggling favorite outlet: $e');
      return false;
    }
  }

  static Future<void> removeFavouriteRestaurant(String restaurantId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || restaurantId.isEmpty) return;

      await http
          .delete(
            Uri.parse('${AppConst.baseUrl}favorites/restaurants'),
            headers: await getHeaders(),
            body: json.encode({
              "firebase_id": userId,
              "restaurant_id": restaurantId,
            }),
          )
          .timeout(_networkTimeout);

      log('✅ Restaurant removed from favorites: $restaurantId');
    } catch (e) {
      log('❌ Error removing favorite restaurant: $e');
    }
  }

  // ========== FOOD FAVORITES API METHODS ==========

  static Future<List<ProductModel>> getFavouriteFoods() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null) return [];

      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}favorites/items/$userId'),
            headers: await getHeaders(),
          )
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return [];
        }

        final responseData = decoded;
        if (responseData['success'] == true) {
          final List<dynamic> foodsData = responseData['data'] ?? [];
          return foodsData
              .whereType<Map<String, dynamic>>()
              .map((item) => ProductModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } on TimeoutException {
      log('Timeout fetching favorite foods');
      return [];
    } catch (e) {
      log('Error fetching favorite foods: $e');
      return [];
    }
  }

  static Future<void> addFavouriteFood(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || productId.isEmpty || productId.length < 3) {
        return;
      }

      final response = await http
          .post(
            Uri.parse('${AppConst.baseUrl}favorites/items'),
            headers: await getHeaders(),
            body: json.encode({"firebase_id": userId, "product_id": productId}),
          )
          .timeout(_networkTimeout);

      if (response.statusCode != 200) {
        log('Failed to add favorite food: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error adding favorite food: $e');
    }
  }

  static Future<void> removeFavouriteFood(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || productId.isEmpty) return;

      final response = await http
          .delete(
            Uri.parse('${AppConst.baseUrl}favorites/items'),
            headers: await getHeaders(),
            body: json.encode({"firebase_id": userId, "product_id": productId}),
          )
          .timeout(_networkTimeout);

      if (response.statusCode != 200) {
        log('Failed to remove favorite food: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error removing favorite food: $e');
    }
  }

  // ========== UI HELPER METHODS ==========

  Future<void> removeFavoriteRestaurantUI(
    String restaurantId,
    int index,
  ) async {
    try {
      // Remove from local list immediately for fast UI response
      if (index >= 0 && index < favouriteVendorList.length) {
        favouriteVendorList.removeAt(index);
      }
      notifyListeners();

      // Call API in background
      unawaited(removeFavouriteRestaurant(restaurantId));

      // Invalidate cache
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId != null) {
        CacheManager().remove('favorite_restaurants_$userId');
      }

      log('🎯 Restaurant removed from UI: $restaurantId');
    } catch (e) {
      log('⚠️ Error removing restaurant from UI: $e');
    }
  }

  Future<void> removeFavoriteFoodUI(String productId, int index) async {
    try {
      // Remove from local list immediately for fast UI response
      if (index >= 0 && index < favouriteFoodList.length) {
        favouriteFoodList.removeAt(index);
      }
      notifyListeners();

      // Call API in background
      unawaited(removeFavouriteFood(productId));

      // Invalidate cache
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId != null) {
        CacheManager().remove('favorite_items_$userId');
      }

      log('🎯 Food item removed from UI: $productId');
    } catch (e) {
      log('⚠️ Error removing food item from UI: $e');
    }
  }

  Future<void> addFavoriteFoodUI(String productId, ProductModel product) async {
    try {
      // Add to local list immediately for fast UI response
      if (!favouriteFoodList.any((item) => item.id == productId)) {
        favouriteFoodList.add(product);
      }
      notifyListeners();

      // Call API in background
      unawaited(addFavouriteFood(productId));

      // Invalidate cache
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId != null) {
        CacheManager().remove('favorite_items_$userId');
      }

      log('🎯 Food item added to UI: $productId');
    } catch (e) {
      log('⚠️ Error adding food item to UI: $e');
    }
  }

  // Check if restaurant is favorite
  bool isRestaurantFavorite(String restaurantId) {
    return favouriteVendorList.any((vendor) => vendor.id == restaurantId);
  }

  // Check if food item is favorite
  bool isFoodFavorite(String productId) {
    return favouriteFoodList.any((product) => product.id == productId);
  }

  // Refresh data
  Future<void> refreshData() async {
    await initFunction(forceRefresh: true);
  }
}
