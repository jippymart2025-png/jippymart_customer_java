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

import '../../../../../models/outlet.dart';
import '../../../../../utils/restaurant_status_utils.dart';
import '../../../../restaurant_details_screen/provider/restaurant_details_provider.dart';

class BestRestaurantProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 30);
  static const Duration _debounceMs = Duration(milliseconds: 16);
  Timer? _notifyTimer;
  Future<void>? _storiesLoadingTask;
  Future<void>? _relatedDataLoadingTask;
  Future<void>? _restaurantLoadingTask;
  bool isLoading = false;
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
  List<VendorModel> filteredRestaurantList = <VendorModel>[];
  List<VendorModel> displayList = <VendorModel>[];

  void _updateBestRestaurantDerivedLists() {
    final filtered = bestRestaurantList
        .where(
          (restaurant) => RestaurantStatusUtils.canAcceptOrders(restaurant),
        )
        .toList();
    filteredRestaurantList = filtered;
    if (filtered.length <= 12) {
      displayList = filtered;
    } else {
      displayList = filtered.sublist(0, 12);
    }
  }

  Future<void> loadRestaurantsAndRelatedData({String? filter}) async {
    if (_restaurantLoadingTask != null) {
      return _restaurantLoadingTask!;
    }
    _restaurantLoadingTask = _loadRestaurantsAndRelatedDataImpl(filter: filter);
    try {
      await _restaurantLoadingTask;
    } finally {
      _restaurantLoadingTask = null;
    }
  }

  Future<void> _loadRestaurantsAndRelatedDataImpl({String? filter}) async {
    print('[DEBUG] Loading restaurants from API with filter: $filter');
    final String? zoneId = Constant.selectedZone?.id;
    final double latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
    final double longitude =
        Constant.selectedLocation.location?.longitude ?? 0.0;
    final hasLocation = latitude != 0.0 && longitude != 0.0;

    if (!hasLocation && (zoneId == null || zoneId.isEmpty)) {
      print('[DEBUG] No location or zone available, skipping restaurant fetch');
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      List<VendorModel> restaurants = [];

      if (hasLocation) {
        restaurants = await getNearestRestaurants(
          latitude: latitude,
          longitude: longitude,
        );
      }

      applyRestaurants(restaurants, zoneId: zoneId);
    } catch (e) {
      print('[DEBUG] Error fetching restaurants from API: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void applyRestaurants(List<VendorModel> restaurants, {String? zoneId}) {
    bestRestaurantList = List<VendorModel>.from(restaurants);
    popularRestaurantList = List<VendorModel>.from(restaurants);
    newArrivalRestaurantList = List<VendorModel>.from(restaurants);
    allNearestRestaurant = List<VendorModel>.from(restaurants);
    _updateBestRestaurantDerivedLists();
    Constant.restaurantList = allNearestRestaurant;

    isLoading = false;
    notifyListeners();

    if (allNearestRestaurant.isEmpty) return;

    _processRestaurantData(allNearestRestaurant)
        .then((_) {
          logRestaurantDiagnostics();
          _scheduleNotify();
        })
        .catchError((e) {
          print('[DEBUG] Error in distance processing: $e');
          _scheduleNotify();
        });

    final effectiveZoneId = zoneId ?? Constant.selectedZone?.id;
    if (effectiveZoneId != null && effectiveZoneId.isNotEmpty) {
      _storiesLoadingTask = _loadStoriesFromAPI(effectiveZoneId).then((_) {
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
      CacheManager()
          .getOrSet<List<CouponModel>>(
            couponsKey,
            () => RestaurantApiHelper.getRestaurantCoupons(
              restaurantId: '',
              zoneId: Constant.selectedZone!.id.toString(),
            ),
            type: CacheType.general,
          )
          .then((value) {
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
        CacheManager()
            .getOrSet<List<AdvertisementModel>>(
              adsKey,
              () => FireStoreUtils.getAllAdvertisement(),
              type: CacheType.banners,
            )
            .then((value) {
              advertisementList.clear();
              for (var ad in value) {
                if (ad.vendorId == null) continue;
                final restaurant = restaurantById[ad.vendorId!];
                if (restaurant != null) {
                  advertisementList.add(ad);
                }
              }
              print(
                '[DEBUG] Advertisements loaded: ${advertisementList.length}',
              );
            }),
      );
    }

    await Future.wait(futures);
    print('[DEBUG] All related data loaded');
  }

  // Get best restaurants from nearby outlets endpoint
  static Future<List<VendorModel>> getBestRestaurants({
    required String zoneId,
  }) async {
    final latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
    final longitude = Constant.selectedLocation.location?.longitude ?? 0.0;
    if (latitude == 0.0 || longitude == 0.0) return [];
    return getNearestRestaurants(latitude: latitude, longitude: longitude);
  }

  static Future<List<VendorModel>> getNearestRestaurants({
    required double latitude,
    required double longitude,
  }) {
    return RestaurantApiHelper.fetchNearbyOutlets(
      latitude: latitude,
      longitude: longitude,
    );
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
          vendor.distance = Constant.calculateDistance(
            lat,
            lng,
            vendor.latitude!,
            vendor.longitude!,
          );
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
