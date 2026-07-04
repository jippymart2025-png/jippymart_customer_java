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

import '../../../models/FavouriteRestaurantResponse.dart';

class FavouriteProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 15);

  bool favouriteRestaurant = true;
  List<VendorModel> favouriteVendorList = <VendorModel>[];
  List<VendorModel> frequentVendorList = <VendorModel>[];
  VendorModel? recentVendor;
  List<ProductModel> favouriteFoodList = <ProductModel>[];
  bool isLoading = false;

  bool _isLoadingVendors = false;
  bool _isLoadingFoods = false;

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

  Future<void> _loadFavoriteRestaurants(bool forceRefresh) async {
    if (_isLoadingVendors) return;

    try {
      _isLoadingVendors = true;

      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null) {
        favouriteVendorList = [];
        frequentVendorList = [];
        recentVendor = null;
        return;
      }

      final cacheKey = 'favorite_restaurants_$userId';

      if (forceRefresh) {
        CacheManager().remove(cacheKey);
      }

      final response = await CacheManager()
          .getOrSetUserProfile<FavouriteRestaurantResponse>(
            cacheKey,
            () => ApiQueueManager().enqueue<FavouriteRestaurantResponse>(
              priority: RequestPriority.normal,
              key: cacheKey,
              request: () => getFavouriteRestaurants(),
            ),
          );

      favouriteVendorList = response.favorites;
      frequentVendorList = response.frequentOutlets;
      recentVendor = response.recentOutlet;
    } finally {
      _isLoadingVendors = false;
    }
  }

  void changeTabUpdate(bool value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      favouriteRestaurant = value;
      notifyListeners();
    });
  }

  static String _firstNonEmptyId(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final str = value.toString().trim();
      if (str.isNotEmpty && str != '0' && str.toLowerCase() != 'null') {
        return str;
      }
    }
    return '';
  }

  static String _outletIdFromFavoriteJson(Map<String, dynamic> json) {
    final direct = _firstNonEmptyId(json, [
      'outletId',
      'favoriteOutletId',
      'vendorId',
      'vendor_id',
      'vendorID',
      'storeId',
      'store_id',
    ]);
    if (direct.isNotEmpty) return direct;

    final outlet = json['outlet'];
    if (outlet is Map) {
      return _firstNonEmptyId(Map<String, dynamic>.from(outlet), [
        'outletId',
        'favoriteOutletId',
        'id',
      ]);
    }
    return '';
  }

  static VendorModel _parseFavoriteOutlet(Map<String, dynamic> json) {
    final review = (json['review'] as num?)?.toDouble() ?? 0;
    return VendorModel(
      id: _firstNonEmptyId(json, ['favoriteOutletId', 'outletId', 'id']),
      title: json['outletName']?.toString() ?? 'Restaurant',
      photo: json['outletPicUrl']?.toString() ?? '',
      reviewsSum: review,
      reviewsCount: review > 0 ? 1 : 0,
      latitude: 0,
      longitude: 0,
      location: '',
      isOpen: true,
      isActive: true,
      zoneId: Constant.selectedZone?.id,
      vType: 'restaurant',
    );
  }

  static List<VendorModel> _parseOutletList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => _parseFavoriteOutlet(Map<String, dynamic>.from(e)))
        .where((vendor) => vendor.id != null && vendor.id!.isNotEmpty)
        .toList();
  }

  // ========== RESTAURANT FAVORITES API METHODS ==========
  static Future<FavouriteRestaurantResponse> getFavouriteRestaurants() async {
    try {
      final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');

      if (customerId == null) {
        return FavouriteRestaurantResponse(
          favorites: [],
          frequentOutlets: [],
          recentOutlet: null,
        );
      }

      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}fm/customer/favorites/getFavoriteRecentFrequentOutlets',
      ).replace(queryParameters: {'customerId': customerId.toString()});

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(_networkTimeout);

      log('[Favorites] GET $uri status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return FavouriteRestaurantResponse(
          favorites: [],
          frequentOutlets: [],
          recentOutlet: null,
        );
      }

      final jsonBody = jsonDecode(response.body);
      if (jsonBody is! Map<String, dynamic>) {
        return FavouriteRestaurantResponse(
          favorites: [],
          frequentOutlets: [],
          recentOutlet: null,
        );
      }

      final favorites = _parseOutletList(jsonBody['favorites']);
      final frequentOutlets = _parseOutletList(jsonBody['frequentOutlets']);

      VendorModel? recentOutlet;
      final recentRaw = jsonBody['recentOutlet'];
      if (recentRaw is Map<String, dynamic>) {
        recentOutlet = _parseFavoriteOutlet(recentRaw);
      } else if (recentRaw is Map) {
        recentOutlet = _parseFavoriteOutlet(
          Map<String, dynamic>.from(recentRaw),
        );
      }

      return FavouriteRestaurantResponse(
        favorites: favorites,
        frequentOutlets: frequentOutlets,
        recentOutlet: recentOutlet,
      );
    } catch (e) {
      log('Error fetching favorite restaurants: $e');
      return FavouriteRestaurantResponse(
        favorites: [],
        frequentOutlets: [],
        recentOutlet: null,
      );
    }
  }

  static Future<void> addFavouriteRestaurant(String restaurantId) async {
    try {
      final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
      final outletId = int.tryParse(restaurantId);

      if (customerId == null || outletId == null) return;

      await toggleFavoriteOutlet(customerId: customerId, outletId: outletId);
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
      final response = await http
          .post(
            Uri.parse(
              '${AppConst.outletBaseUrl}fm/customer/favorites/toggleFavouriteOutletOrProduct',
            ),
            headers: await getHeaders(),
            body: json.encode({
              'customerId': customerId,
              'favoriteId': outletId,
              'favouriteType': "OUTLET",
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
      final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
      final outletId = int.tryParse(restaurantId);

      if (customerId == null || outletId == null) return;

      await toggleFavoriteOutlet(customerId: customerId, outletId: outletId);
      log('✅ Restaurant removed from favorites: $restaurantId');
    } catch (e) {
      log('❌ Error removing favorite restaurant: $e');
    }
  }

  // ========== FOOD FAVORITES API METHODS ==========

  static Future<List<ProductModel>> getFavouriteFoods() async {
    try {
      final userId = await SqlStorageConst.getUserId();

      if (userId == null) return [];

      final response = await http
          .get(
            Uri.parse(
              '${AppConst.outletBaseUrl}fm/customer/favorites/getFavoriteProducts?customerId=$userId',
            ),
            headers: await getHeaders(),
          )
          .timeout(_networkTimeout);

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return [];
      }

      final List<dynamic> foodsData = decoded['favoriteProducts'] ?? [];

      return foodsData
          .whereType<Map<String, dynamic>>()
          .map((item) => _parseFavoriteProduct(item))
          .toList();
    } on TimeoutException {
      log('Timeout fetching favorite foods');
      return [];
    } catch (e) {
      log('Error fetching favorite foods: $e');
      return [];
    }
  }

  static ProductModel _parseFavoriteProduct(Map<String, dynamic> json) {
    return ProductModel(
      id: _firstNonEmptyId(json, ['productId', 'favoriteId', 'id']),
      name: json['productName'] ?? json['name'] ?? '',
      photo: json['imageUrl'] ?? json['photo'] ?? '',
      price: ((json['onlinePrice'] as num?) ?? json['price'] as num? ?? 0)
          .toString(),
      disPrice:
          (json['discountPrice'] ?? json['disPrice'] ?? json['onlinePrice'])
              ?.toString() ??
          '0',
      reviewsSum: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: ((json['rating'] as num?) ?? 0) > 0 ? 1 : 0,
      veg: json['isVeg'] == true || json['veg'] == true,
      nonveg: json['isVeg'] == false || json['nonVeg'] == true,
      vendorID: _outletIdFromFavoriteJson(json),
    );
  }

  VendorModel? findFavoriteVendorByOutletId(String outletId) {
    if (outletId.isEmpty) return null;

    final vendors = <VendorModel>[
      if (recentVendor != null) recentVendor!,
      ...frequentVendorList,
      ...favouriteVendorList,
    ];

    for (final vendor in vendors) {
      if (vendor.id == outletId) return vendor;
    }
    return null;
  }

  static Future<void> addFavouriteFood(String productId) async {
    try {
      print("===== addFavouriteFood called =====");

      final userId = await SqlStorageConst.getFirebaseId();
      print("userId: $userId");
      print("productId: $productId");

      if (userId == null) {
        print("userId is null");
        return;
      }

      if (productId.isEmpty) {
        print("productId is empty");
        return;
      }

      final url =
          '${AppConst.outletBaseUrl}fm/customer/favorites/toggleFavouriteOutletOrProduct';

      print("URL: $url");

      final body = {
        "customerId": userId,
        "favoriteId": productId,
        "favouriteType": "PRODUCT",
      };

      print("BODY: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(url),
        headers: await getHeaders(),
        body: jsonEncode(body),
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
    } catch (e, s) {
      print("ERROR: $e");
      print(s);
    }
  }

  static Future<void> removeFavouriteFood(String productId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || productId.isEmpty) return;

      final response = await http
          .delete(
            Uri.parse('${AppConst.baseUrl}favorites/items/$userId/$productId'),
            headers: await getHeaders(),
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

  bool get hasRestaurantFavorites =>
      favouriteVendorList.isNotEmpty ||
      frequentVendorList.isNotEmpty ||
      recentVendor != null;

  Future<void> removeFavoriteRestaurantUI(
    String restaurantId,
    int index,
  ) async {
    try {
      if (index >= 0 && index < favouriteVendorList.length) {
        favouriteVendorList.removeAt(index);
      }
      notifyListeners();

      unawaited(removeFavouriteRestaurant(restaurantId));

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
    print("1. removeFavoriteFoodUI called");
    print("2. productId = $productId");
    print("3. index = $index");

    try {
      print("4. Before API");

      await addFavouriteFood(productId);

      print("5. After API");

      if (index >= 0 && index < favouriteFoodList.length) {
        favouriteFoodList.removeAt(index);
      }

      notifyListeners();

      print("6. UI updated");
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  Future<void> addFavoriteFoodUI(String productId, ProductModel product) async {
    log("UI method called");

    try {
      if (!favouriteFoodList.any((item) => item.id == productId)) {
        favouriteFoodList.add(product);
      }
      notifyListeners();

      log("Calling API...");
      await addFavouriteFood(productId);

      log("API completed");
    } catch (e) {
      log("Error: $e");
    }
  }

  bool isRestaurantFavorite(String restaurantId) {
    return favouriteVendorList.any((vendor) => vendor.id == restaurantId);
  }

  bool isFoodFavorite(String productId) {
    return favouriteFoodList.any((product) => product.id == productId);
  }

  Future<void> refreshData() async {
    await initFunction(forceRefresh: true);
  }
}
