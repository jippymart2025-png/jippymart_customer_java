import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/favourite_item_model.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;

class FavouriteProvider extends ChangeNotifier {
  bool favouriteRestaurant = true;
  List<FavouriteModel> favouriteList = <FavouriteModel>[];
  List<VendorModel> favouriteVendorList = <VendorModel>[];
  List<FavouriteItemModel> favouriteItemList = <FavouriteItemModel>[];
  List<ProductModel> favouriteFoodList = <ProductModel>[];

  bool isLoading = true;

  Future<void> initFunction() async {
    isLoading = true;
    getData();
    notifyListeners();
  }

  void changeTabUpdate(bool value) {
    favouriteRestaurant = value;
    notifyListeners();
  }

  // ========== RESTAURANT FAVORITES API METHODS ==========

  // Add restaurant to favorites
  static Future<void> addFavouriteRestaurant(String restaurantId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}favorites/restaurants'),
        headers: await getHeaders(),
        body: json.encode({
          "firebase_id": userId,
          "restaurant_id": restaurantId,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Restaurant added to favorites: $restaurantId');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to add favorite');
        }
      } else {
        throw Exception('Failed to add favorite: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error adding favorite restaurant: $e');
      rethrow;
    }
  }

  // Remove restaurant from favorites
  static Future<void> removeFavouriteRestaurant(String restaurantId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.delete(
        Uri.parse('${AppConst.baseUrl}favorites/restaurants'),
        headers: await getHeaders(),
        body: json.encode({
          "firebase_id": userId,
          "restaurant_id": restaurantId,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Restaurant removed from favorites: $restaurantId');
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to remove favorite',
          );
        }
      } else {
        throw Exception('Failed to remove favorite: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error removing favorite restaurant: $e');
      rethrow;
    }
  }

  // Get user's favorite restaurants
  static Future<List<VendorModel>> getFavouriteRestaurants() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}favorites/restaurants/$userId'),
        headers: await getHeaders(),
      );

      log("📱 getFavouriteRestaurants response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final responseData = decoded;
        if (responseData['success'] == true) {
          final List<dynamic> restaurantsData = responseData['data'] ?? [];
          return restaurantsData
              .whereType<Map<String, dynamic>>()
              .map((item) => VendorModel.fromJson(item))
              .toList();
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch favorites',
          );
        }
      } else {
        throw Exception('Failed to fetch favorites: ${response.statusCode}');
      }
    } catch (e, st) {
      log('❌ Error fetching favorite restaurants: $e\n$st');
      throw Exception('Failed to fetch favorite restaurants: $e');
    }
  }

  // ========== FOOD/ITEM FAVORITES API METHODS ==========

  static Future<void> addFavouriteFood(String productId) async {
    try {
      // Validate product ID before making the API call
      if (productId.isEmpty || productId.length < 3) {
        throw Exception('Invalid product ID: $productId');
      }

      final userId = await SqlStorageConst.getFirebaseId();

      // Additional validation
      if (userId == null) {
        throw Exception('User ID is required');
      }

      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}favorites/items'),
        headers: await getHeaders(),
        body: json.encode({"firebase_id": userId, "product_id": productId}),
      );

      log(
        "📱 addFavouriteFood request: productId: $productId, userId: $userId",
      );
      log("📱 addFavouriteFood response status: ${response.statusCode}");
      log("📱 addFavouriteFood response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Food item added to favorites: $productId');
        } else {
          // Handle API-specific errors
          final errorMessage =
              responseData['message'] ??
              responseData['errors']?.toString() ??
              'Failed to add favorite food';
          throw Exception(errorMessage);
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final errors = errorData['errors'] ?? {};
        throw Exception('Validation error: ${errors.toString()}');
      } else {
        throw Exception('Failed to add favorite food: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error adding favorite food: $e');
      rethrow;
    }
  }

  // Remove food item from favorites
  static Future<void> removeFavouriteFood(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.delete(
        Uri.parse('${AppConst.baseUrl}favorites/items'),
        headers: await getHeaders(),
        body: json.encode({"firebase_id": userId, "product_id": productId}),
      );

      log(
        "📱 removeFavouriteFood request: productId: $productId, userId: $userId",
      );
      log("📱 removeFavouriteFood response status: ${response.statusCode}");
      log("📱 removeFavouriteFood response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Food item removed from favorites: $productId');
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to remove favorite food',
          );
        }
      } else {
        throw Exception(
          'Failed to remove favorite food: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error removing favorite food: $e');
      rethrow;
    }
  }

  // Get user's favorite foods
  static Future<List<ProductModel>> getFavouriteFoods() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}favorites/items/$userId'),
        headers: await getHeaders(),
      );

      log(
        "📱 getFavouriteFoods URL: ${AppConst.baseUrl}favorites/items/$userId",
      );
      log("📱 getFavouriteFoods response status: ${response.statusCode}");
      log("📱 getFavouriteFoods response body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        final responseData = decoded;
        if (responseData['success'] == true) {
          final List<dynamic> foodsData = responseData['data'] ?? [];

          List<ProductModel> favoriteFoods = [];
          for (var foodData in foodsData) {
            try {
              if (foodData is Map<String, dynamic>) {
                // If the API returns product data directly
                favoriteFoods.add(ProductModel.fromJson(foodData));
              }
            } catch (e) {
              log('❌ Error parsing food item: $e');
            }
          }

          log('✅ Loaded ${favoriteFoods.length} favorite foods');
          return favoriteFoods;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch favorite foods',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch favorite foods: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      log('❌ Error fetching favorite foods: $e\n$st');
      throw Exception('Failed to fetch favorite foods: $e');
    }
  }

  // ========== UI HELPER METHODS ==========

  // Remove restaurant from favorites (UI method)
  Future<void> removeFavoriteRestaurantUI(
    String restaurantId,
    int index,
  ) async {
    try {
      // Remove from local lists immediately for fast UI response
      if (index >= 0 && index < favouriteVendorList.length) {
        favouriteVendorList.removeAt(index);
      }
      favouriteList.removeWhere((fav) => fav.restaurantId == restaurantId);
      notifyListeners();

      // Call API in background
      await removeFavouriteRestaurant(restaurantId);

      log('🎯 Restaurant removed successfully from UI: $restaurantId');
    } catch (e) {
      // If API fails, reload data to sync with server
      await getData();
      log('⚠️ Failed to remove restaurant, reloading data: $e');
      rethrow;
    }
  }

  // Remove food item from favorites (UI method)
  Future<void> removeFavoriteFoodUI(String productId, int index) async {
    try {
      // Remove from local lists immediately for fast UI response
      if (index >= 0 && index < favouriteFoodList.length) {
        favouriteFoodList.removeAt(index);
      }
      favouriteItemList.removeWhere((item) => item.productId == productId);
      notifyListeners();

      // Call API in background
      await removeFavouriteFood(productId);

      log('🎯 Food item removed successfully from UI: $productId');
    } catch (e) {
      // If API fails, reload data to sync with server
      await getData();
      log('⚠️ Failed to remove food item, reloading data: $e');
      rethrow;
    }
  }

  // Add food item to favorites (UI method)
  Future<void> addFavoriteFoodUI(String productId, ProductModel product) async {
    try {
      // Add to local lists immediately for fast UI response
      if (!favouriteFoodList.any((item) => item.id == productId)) {
        favouriteFoodList.add(product);
      }
      notifyListeners();
      // Call API in background
      await addFavouriteFood(productId);
      log('🎯 Food item added successfully to UI: $productId');
    } catch (e) {
      // If API fails, reload data to sync with server
      await getData();
      log('⚠️ Failed to add food item, reloading data: $e');
      rethrow;
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

  // Toggle food favorite status
  Future<void> toggleFoodFavorite(ProductModel product) async {
    try {
      if (isFoodFavorite(product.id!)) {
        await removeFavoriteFoodUI(
          product.id!,
          favouriteFoodList.indexWhere((p) => p.id == product.id),
        );
      } else {
        await addFavoriteFoodUI(product.id!, product);
      }
    } catch (e) {
      log('❌ Error toggling food favorite: $e');
      rethrow;
    }
  }

  // ========== DATA LOADING ==========

  getData() async {
    print('[DEBUG] Loading favorite data from API...');
    try {
      if (Constant.userModel != null) {
        // Load favorite restaurants
        final restaurantFavourites = await getFavouriteRestaurants();
        favouriteVendorList = restaurantFavourites;

        // Convert to FavouriteModel list
        favouriteList.clear();
        final userId = await SqlStorageConst.getFirebaseId();
        for (var vendor in restaurantFavourites) {
          favouriteList.add(
            FavouriteModel(restaurantId: vendor.id, userId: userId),
          );
        }

        // Load favorite foods using the new API
        final foodFavourites = await getFavouriteFoods();
        favouriteFoodList = foodFavourites;

        // Convert to FavouriteItemModel list
        favouriteItemList.clear();
        for (var product in foodFavourites) {
          favouriteItemList.add(
            FavouriteItemModel(
              productId: product.id,
              storeId: product.vendorID,
              userId: userId,
            ),
          );
        }

        print(
          '[SUCCESS] Loaded ${favouriteVendorList.length} favorite restaurants and ${favouriteFoodList.length} favorite foods',
        );
      }
    } catch (e) {
      print('[ERROR] Failed to load favorite data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();
    await getData();
  }
}
