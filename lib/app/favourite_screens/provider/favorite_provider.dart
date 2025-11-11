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

  void initFunction() {
    isLoading = true;
    getData();
    notifyListeners();
  }

  void changeTabUpdate(bool value) {
    favouriteRestaurant = value;
    notifyListeners();
  }

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

  // ========== ITEM FAVORITES API METHODS ==========

  // Add item to favorites
  Future<void> addFavouriteItem(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}favorites/items'),
        headers: await getHeaders(),
        body: json.encode({"firebase_id": userId, "product_id": productId}),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Item added to favorites: $productId');
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to add favorite item',
          );
        }
      } else {
        throw Exception('Failed to add favorite item: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error adding favorite item: $e');
      rethrow;
    }
  }

  // Remove item from favorites
  Future<void> removeFavouriteItem(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.delete(
        Uri.parse('${AppConst.baseUrl}favorites/items'),
        headers: await getHeaders(),
        body: json.encode({"firebase_id": userId, "product_id": productId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          log('✅ Item removed from favorites: $productId');
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to remove favorite item',
          );
        }
      } else {
        throw Exception(
          'Failed to remove favorite item: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error removing favorite item: $e');
      rethrow;
    }
  }

  // Get user's favorite items
  Future<List<ProductModel>> getFavouriteItems() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}favorites/items/$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> itemsData = responseData['data'] ?? [];
          return itemsData.map((item) => ProductModel.fromJson(item)).toList();
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch favorite items',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch favorite items: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error fetching favorite items: $e');
      throw Exception('Failed to fetch favorite items: $e');
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

  // Remove item from favorites (UI method)
  Future<void> removeFavoriteItemUI(String productId, int index) async {
    try {
      // Remove from local lists immediately for fast UI response
      if (index >= 0 && index < favouriteFoodList.length) {
        favouriteFoodList.removeAt(index);
      }
      favouriteItemList.removeWhere((item) => item.productId == productId);
      notifyListeners();

      // Call API in background
      await removeFavouriteItem(productId);

      log('🎯 Item removed successfully from UI: $productId');
    } catch (e) {
      // If API fails, reload data to sync with server
      await getData();
      log('⚠️ Failed to remove item, reloading data: $e');
      rethrow;
    }
  }

  // Check if restaurant is favorite
  bool isRestaurantFavorite(String restaurantId) {
    return favouriteVendorList.any((vendor) => vendor.id == restaurantId);
  }

  // Check if item is favorite
  bool isItemFavorite(String productId) {
    return favouriteFoodList.any((product) => product.id == productId);
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

        // Load favorite items
        final itemFavourites = await getFavouriteItems();
        favouriteFoodList = itemFavourites;

        // Convert to FavouriteItemModel list
        favouriteItemList.clear();
        for (var product in itemFavourites) {
          favouriteItemList.add(
            FavouriteItemModel(
              productId: product.id,
              storeId: product.vendorID,
              userId: userId,
            ),
          );
        }

        print(
          '[SUCCESS] Loaded ${favouriteVendorList.length} favorite restaurants and ${favouriteFoodList.length} favorite items',
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
