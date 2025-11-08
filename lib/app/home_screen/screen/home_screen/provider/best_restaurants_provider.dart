import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/story_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:http/http.dart' as http;

class BestRestaurantProvider extends ChangeNotifier {
  bool isLoading = true;
  String? currentFilter;
  List<String> availableFilters = [];

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  List<VendorModel> allNearestRestaurant = <VendorModel>[];
  List<VendorModel> popularRestaurantList = <VendorModel>[];
  List<VendorModel> newArrivalRestaurantList = <VendorModel>[];
  List<AdvertisementModel> advertisementList = <AdvertisementModel>[];
  List<CouponModel> couponList = <CouponModel>[];
  List<VendorModel> couponRestaurantList = <VendorModel>[];
  List<StoryModel> storyList = <StoryModel>[];

  Future<void> loadRestaurantsAndRelatedData({String? filter}) async {
    print('[DEBUG] Loading restaurants from API with filter: $filter');
    await Future.delayed(Duration(milliseconds: 100));

    final String? zoneId = Constant.selectedZone?.id;
    final double latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
    final double longitude =
        Constant.selectedLocation.location?.longitude ?? 0.0;

    if (zoneId == null || zoneId.isEmpty) {
      print('[DEBUG] No zone ID available, skipping restaurant fetch');
      return;
    }

    try {
      // Fetch restaurants from API with optional filter
      final restaurants = await getNearestRestaurants(
        zoneId: zoneId,
        latitude: latitude,
        longitude: longitude,
        radius: double.parse(Constant.radius),
        filter: filter,
        onFiltersReceived: (availableFilters, currentFilter) {
          // Update the provider state with filters from API
          this.availableFilters = availableFilters;
          this.currentFilter = currentFilter;
          notifyListeners(); // Notify listeners to update UI
        },
      );

      // Clear lists efficiently
      popularRestaurantList.clear();
      newArrivalRestaurantList.clear();
      allNearestRestaurant.clear();
      advertisementList.clear();
      storyList.clear(); // Clear stories list
      // Add all restaurants at once
      allNearestRestaurant.addAll(restaurants);
      newArrivalRestaurantList.addAll(restaurants);
      popularRestaurantList.addAll(restaurants);
      Constant.restaurantList = allNearestRestaurant;
      // Load stories from API
      await _loadStoriesFromAPI(zoneId);
      // Load other related data in parallel (excluding stories)
      await _loadRelatedDataInParallel(allNearestRestaurant);
      // Calculate distances and sort
      await _processRestaurantData(allNearestRestaurant);
      // **DEBUG: Log restaurant diagnostics**
      logRestaurantDiagnostics();
    } catch (e) {
      print('[DEBUG] Error fetching restaurants from API: $e');
    }
    notifyListeners();
  }

  // Load stories from API instead of Firebase
  Future<void> _loadStoriesFromAPI(String zoneId) async {
    try {
      print('[DEBUG] Loading stories from API for zone: $zoneId');

      final stories = await getStoriesFromAPI(zoneId: zoneId);
      storyList.clear();
      storyList.addAll(stories);
      print('[DEBUG] Stories loaded from API: ${storyList.length}');
      print('[DEBUG] Story enable setting: ${Constant.storyEnable}');
    } catch (e) {
      print('[DEBUG] Error loading stories from API: $e');
      // Fallback: try Firebase if API fails (optional)
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

      final response = await http.get(uri, headers: headers);

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
    } catch (e) {
      print('[STORY_API] Error fetching stories: $e');
      rethrow;
    }
  }

  // Load related data (coupons, ads) in parallel (stories are now loaded separately)
  Future<void> _loadRelatedDataInParallel(List<VendorModel> restaurants) async {
    print('[DEBUG] Loading related data in parallel');
    final futures = <Future<void>>[];

    // Load coupons
    futures.add(
      FireStoreUtils.getHomeCoupon().then((value) {
        couponRestaurantList.clear();
        couponList.clear();
        for (var element1 in value) {
          for (var element in restaurants) {
            if (element1.resturantId == element.id &&
                element1.expiresAt!.toDate().isAfter(DateTime.now())) {
              couponList.add(element1);
              couponRestaurantList.add(element);
            }
          }
        }
        print('[DEBUG] Coupons loaded: ${couponList.length}');
      }),
    );

    // Load advertisements (if enabled)
    if (Constant.isEnableAdsFeature == true) {
      futures.add(
        FireStoreUtils.getAllAdvertisement().then((value) {
          advertisementList.clear();
          for (var element1 in value) {
            for (var element in restaurants) {
              if (element1.vendorId == element.id) {
                advertisementList.add(element1);
              }
            }
          }
          print('[DEBUG] Advertisements loaded: ${advertisementList.length}');
        }),
      );
    }

    // Wait for all related data to load
    await Future.wait(futures);
    print('[DEBUG] All related data loaded');
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

      final response = await http.get(uri, headers: headers);

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

  DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        String cleanTimestamp = timestamp.replaceAll('"', '');
        return DateTime.parse(cleanTimestamp);
      } catch (e) {
        print('Error parsing DateTime from string: $timestamp, error: $e');
        return DateTime.now();
      }
    }

    if (timestamp is Map<String, dynamic>) {
      try {
        final seconds = timestamp['_seconds'] ?? 0;
        final nanoseconds = timestamp['_nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds / 1000000).round(),
        );
      } catch (e) {
        print('Error parsing DateTime from map: $e');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Future<void> _calculateDistancesInBatches(List<VendorModel> vendors) async {
    const int batchSize = 10;
    for (int i = 0; i < vendors.length; i += batchSize) {
      final end = (i + batchSize < vendors.length)
          ? i + batchSize
          : vendors.length;
      final batch = vendors.sublist(i, end);

      for (var vendor in batch) {
        if (vendor.latitude != null && vendor.longitude != null) {
          vendor.distance = Constant.calculateDistance(
            Constant.selectedLocation.location!.latitude!,
            Constant.selectedLocation.location!.longitude!,
            vendor.latitude!,
            vendor.longitude!,
          );
        } else {
          vendor.distance = null;
        }
      }

      if (i + batchSize < vendors.length) {
        await Future.delayed(Duration(milliseconds: 10));
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
