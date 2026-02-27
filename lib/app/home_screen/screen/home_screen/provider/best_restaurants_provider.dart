import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/story_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/services/cache_manager.dart';

import '../../../../restaurant_details_screen/provider/restaurant_details_provider.dart';

class BestRestaurantProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 15);
  static const Duration _debounceMs = Duration(milliseconds: 16);
  Timer? _notifyTimer;
  Future<void>? _storiesLoadingTask;
  Future<void>? _relatedDataLoadingTask;
  bool isLoading = true;
  String? currentFilter;
  List<String> availableFilters = [];

  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(_debounceMs, () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  List<VendorModel> allNearestRestaurant = <VendorModel>[];
  List<VendorModel> bestRestaurantList = <VendorModel>[];
  List<VendorModel> popularRestaurantList = <VendorModel>[];
  List<VendorModel> newArrivalRestaurantList = <VendorModel>[];
  List<AdvertisementModel> advertisementList = <AdvertisementModel>[];
  List<CouponModel> couponList = <CouponModel>[];
  List<VendorModel> couponRestaurantList = <VendorModel>[];
  List<StoryModel> storyList = <StoryModel>[];

  Future<void> loadRestaurantsAndRelatedData({String? filter}) async {
    print('[DEBUG] Loading restaurants from API with filter: $filter');
    final String? zoneId = Constant.selectedZone?.id;
    final double latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
    final double longitude =
        Constant.selectedLocation.location?.longitude ?? 0.0;
    if (zoneId == null || zoneId.isEmpty) {
      print('[DEBUG] No zone ID available, skipping restaurant fetch');
      return;
    }
    try {
      final bestRestaurantsKey = 'best_restaurants_$zoneId';
      final nearestKey =
          'nearest_restaurants_${zoneId}_${filter ?? 'all'}_${latitude}_${longitude}';

      // Run both API calls in parallel; cache only, no queue wrapper
      final bestFuture = CacheManager().getOrSetRestaurants<List<VendorModel>>(
        bestRestaurantsKey,
        () => getBestRestaurants(zoneId: zoneId),
      );
      final nearestFuture =
          CacheManager().getOrSetRestaurants<List<VendorModel>>(
        nearestKey,
        () => getNearestRestaurants(
          zoneId: zoneId,
          latitude: latitude,
          longitude: longitude,
          radius: double.parse(Constant.radius),
          filter: filter,
          onFiltersReceived: (availableFilters, currentFilter) {
            this.availableFilters = availableFilters;
            this.currentFilter = currentFilter;
          },
        ),
      );

      final results = await Future.wait([bestFuture, nearestFuture]);
      final bestRestaurants = results[0] as List<VendorModel>;
      final restaurants = results[1] as List<VendorModel>;

      bestRestaurantList.clear();
      bestRestaurantList.addAll(bestRestaurants);
      popularRestaurantList.clear();
      newArrivalRestaurantList.clear();
      allNearestRestaurant.clear();
      advertisementList.clear();
      storyList.clear();
      allNearestRestaurant.addAll(restaurants);
      newArrivalRestaurantList.addAll(restaurants);
      popularRestaurantList.addAll(restaurants);
      Constant.restaurantList = allNearestRestaurant;

      isLoading = false;
      _scheduleNotify();

      // Distance calc in background, then notify
      _processRestaurantData(allNearestRestaurant).then((_) {
        logRestaurantDiagnostics();
        _scheduleNotify();
      }).catchError((e) {
        print('[DEBUG] Error in distance processing: $e');
        _scheduleNotify();
      });

      _storiesLoadingTask = _loadStoriesFromAPI(zoneId).then((_) {
        _scheduleNotify();
      });
      _storiesLoadingTask?.catchError((e) {
        print('[DEBUG] Error in background story load: $e');
      });

      _relatedDataLoadingTask =
          _loadRelatedDataInParallel(allNearestRestaurant).then((_) {
        _scheduleNotify();
      });
      _relatedDataLoadingTask?.catchError((e) {
        print('[DEBUG] Error in background related-data load: $e');
      });
    } catch (e) {
      print('[DEBUG] Error fetching restaurants from API: $e');
      isLoading = false;
      _scheduleNotify();
    }
  }

  // Load stories from API with cache only
  Future<void> _loadStoriesFromAPI(String zoneId) async {
    try {
      print('[DEBUG] Loading stories from API for zone: $zoneId');
      final storiesKey = 'stories_$zoneId';
      final stories = await CacheManager().getOrSet<List<StoryModel>>(
        storiesKey,
        () => getStoriesFromAPI(zoneId: zoneId),
        type: CacheType.general,
      );
      storyList.clear();
      storyList.addAll(stories);
      print('[DEBUG] Stories loaded from API: ${storyList.length}');
      print('[DEBUG] Story enable setting: ${Constant.storyEnable}');
    } catch (e) {
      print('[DEBUG] Error loading stories from API: $e');
    }
  }

  // API method to get stories
  static Future<List<StoryModel>> getStoriesFromAPI({
    required String zoneId,
  }) async {
    try {
      final headers = await getHeaders();

      String url = '${AppConst.baseUrl}stories?zone_id=$zoneId';
      final uri = Uri.parse(url);

      print('[STORY_API] Fetching stories from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('[STORY_API] Response: ${response.body}');

        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          List<StoryModel> stories = data
              .map((item) => StoryModel.fromJson(item))
              .toList();

          print('[STORY_API] Stories fetched successfully: ${stories.length}');
          return stories;
        } else {
          print('[STORY_API] API returned success: false');
          return [];
        }
      } else {
        print('[STORY_API] HTTP error: ${response.statusCode}');
        throw Exception('Failed to load stories: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('[STORY_API] Timeout fetching stories: $e');
      return [];
    } catch (e) {
      print('[STORY_API] Error fetching stories: $e');
      rethrow;
    }
  }

  // Load related data (coupons, ads) in parallel; O(n) matching via Map
  Future<void> _loadRelatedDataInParallel(List<VendorModel> restaurants) async {
    final restaurantById = <String, VendorModel>{};
    for (var r in restaurants) {
      if (r.id != null) restaurantById[r.id!] = r;
    }

    final futures = <Future<void>>[];
    final couponsKey = 'restaurant_coupons_all';
    futures.add(
      CacheManager().getOrSet<List<CouponModel>>(
        couponsKey,
        () => RestaurantApiHelper.getRestaurantCoupons(restaurantId: ''),
        type: CacheType.general,
      ).then((value) {
        couponRestaurantList.clear();
        couponList.clear();
        final now = DateTime.now();
        for (var coupon in value) {
          if (coupon.resturantId == null) continue;
          final restaurant = restaurantById[coupon.resturantId!];
          if (restaurant != null &&
              coupon.expiresAt != null &&
              coupon.expiresAt!.toDate().isAfter(now)) {
            couponList.add(coupon);
            couponRestaurantList.add(restaurant);
          }
        }
        print('[DEBUG] Coupons loaded: ${couponList.length}');
      }),
    );

    if (Constant.isEnableAdsFeature == true) {
      final adsKey = 'advertisements_all';
      futures.add(
        CacheManager().getOrSet<List<AdvertisementModel>>(
          adsKey,
          () => FireStoreUtils.getAllAdvertisement(),
          type: CacheType.banners,
        ).then((value) {
          advertisementList.clear();
          for (var ad in value) {
            if (ad.vendorId == null) continue;
            final restaurant = restaurantById[ad.vendorId!];
            if (restaurant != null) {
              advertisementList.add(ad);
            }
          }
          print('[DEBUG] Advertisements loaded: ${advertisementList.length}');
        }),
      );
    }

    await Future.wait(futures);
    print('[DEBUG] All related data loaded');
  }

  // Get best restaurants from bestrestaurants endpoint
  static Future<List<VendorModel>> getBestRestaurants({
    required String zoneId,
  }) async {
    try {
      final headers = await getHeaders();
      String url =
          '${AppConst.baseUrl}restaurants/bestrestaurants?zone_id=$zoneId';
      final uri = Uri.parse(url);
      print('[BEST_RESTAURANT_API] Fetching best restaurants from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_networkTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('getBestRestaurants ${response.body}');

        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          List<VendorModel> restaurants = data
              .map((item) => VendorModel.fromJson(item))
              .toList();

          print(
            '[BEST_RESTAURANT_API] Best restaurants fetched successfully: ${restaurants.length}',
          );

          return restaurants;
        } else {
          print('[BEST_RESTAURANT_API] API returned success: false');
          return [];
        }
      } else {
        print('[BEST_RESTAURANT_API] HTTP error: ${response.statusCode}');
        throw Exception(
          'Failed to load best restaurants: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print('[BEST_RESTAURANT_API] Timeout fetching best restaurants: $e');
      return [];
    } catch (e) {
      print('[BEST_RESTAURANT_API] Error fetching best restaurants: $e');
      rethrow;
    }
  }

  static Future<List<VendorModel>> getNearestRestaurants({
    required String zoneId,
    required double latitude,
    required double longitude,
    double radius = 20,
    String? filter,
    required Function(List<String> availableFilters, String? currentFilter)
    onFiltersReceived,
  }) async {
    try {
      final headers = await getHeaders();
      // Build URL with optional filter
      String url =
          '${AppConst.baseUrl}restaurants/nearest?'
          'zone_id=$zoneId&'
          'latitude=$latitude&'
          'longitude=$longitude&'
          'radius=$radius';
      if (filter != null && filter.isNotEmpty) {
        url += '&filter=$filter';
      }
      final uri = Uri.parse(url);
      print('[RESTAURANT_API] Fetching restaurants from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_networkTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('getNearestRestaurants ${response.body}');

        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          List<VendorModel> restaurants = data
              .map((item) => VendorModel.fromJson(item))
              .toList();

          // Get available filters from API response
          final availableFilters = List<String>.from(
            jsonResponse['availableFilters'] ?? [],
          );
          final currentFilter = jsonResponse['filter'];

          // Call the callback to update the provider
          onFiltersReceived(availableFilters, currentFilter);

          print(
            '[RESTAURANT_API] Restaurants fetched successfully: ${restaurants.length}',
          );
          print('[RESTAURANT_API] Available filters: $availableFilters');
          print('[RESTAURANT_API] Current filter: $currentFilter');

          return restaurants;
        } else {
          print('[RESTAURANT_API] API returned success: false');
          return [];
        }
      } else {
        print('[RESTAURANT_API] HTTP error: ${response.statusCode}');
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('[RESTAURANT_API] Timeout fetching restaurants: $e');
      return [];
    } catch (e) {
      print('[RESTAURANT_API] Error fetching restaurants: $e');
      rethrow;
    }
  }

  // Process restaurant data (only calculate distances, no sorting since API handles it)
  Future<void> _processRestaurantData(List<VendorModel> restaurants) async {
    print('[DEBUG] Processing restaurant data - calculating distances only');

    // Calculate distances in batches
    await _calculateDistancesInBatches(restaurants);

    print('[DEBUG] Restaurant data processing completed');
  }

  Future<void> _calculateDistancesInBatches(List<VendorModel> vendors) async {
    const int batchSize = 20;
    final lat = Constant.selectedLocation.location?.latitude;
    final lng = Constant.selectedLocation.location?.longitude;
    if (lat == null || lng == null) return;

    for (int i = 0; i < vendors.length; i += batchSize) {
      final end = (i + batchSize < vendors.length)
          ? i + batchSize
          : vendors.length;
      final batch = vendors.sublist(i, end);
      for (var vendor in batch) {
        if (vendor.latitude != null && vendor.longitude != null) {
          vendor.distance =
              Constant.calculateDistance(lat, lng, vendor.latitude!, vendor.longitude!);
        } else {
          vendor.distance = null;
        }
      }
      if (i + batchSize < vendors.length) {
        await Future.delayed(Duration.zero);
      }
    }
  }

  void logRestaurantDiagnostics() {
    print('\n🔍 RESTAURANT VISIBILITY DIAGNOSTICS:');
    print('📋 Zone Available: ${Constant.isZoneAvailable}');
    print(
      '📍 Selected Zone: ${Constant.selectedZone?.name ?? "None"} (ID: ${Constant.selectedZone?.id ?? "None"})',
    );
    print(
      '🌍 User Location: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
    );
    print('📏 Search Radius: ${Constant.radius}km');
    print('🏪 Total Restaurants: ${allNearestRestaurant.length}');
    print('🍽️ Popular Restaurants: ${popularRestaurantList.length}');
    print('🆕 New Arrivals: ${newArrivalRestaurantList.length}');
    print('📖 Stories Available: ${storyList.length}');
    print('💳 Subscription Model: ${Constant.isSubscriptionModelApplied}');
    print('🔍 Available Filters: $availableFilters');
    print('🔍 Current Filter: $currentFilter');
    print('🔍 END RESTAURANT DIAGNOSTICS\n');
  }

  // Method to apply filter and reload data
  Future<void> applyFilter(String? filter) async {
    if (filter == currentFilter) {
      // If same filter is clicked again, remove filter
      currentFilter = null;
    } else {
      currentFilter = filter;
    }

    isLoadingFunction(true);
    await loadRestaurantsAndRelatedData(filter: currentFilter);
    isLoadingFunction(false);
  }

  // Method to clear all filters
  Future<void> clearFilters() async {
    currentFilter = null;
    isLoadingFunction(true);
    await loadRestaurantsAndRelatedData();
    isLoadingFunction(false);
  }

  // Method to refresh stories only
  Future<void> refreshStories() async {
    final String? zoneId = Constant.selectedZone?.id;
    if (zoneId != null && zoneId.isNotEmpty) {
      await _loadStoriesFromAPI(zoneId);
      notifyListeners();
    }
  }
}
