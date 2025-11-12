import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart'
    show AddressListProvider;
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/model/zone_model.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/category_view_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/common.dart';
import 'dart:async';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/gps_location_service.dart';
import 'package:jippymart_customer/utils/performance_optimizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

class HomeProvider extends ChangeNotifier {
  void changeBannerPage(int value) {
    currentPage = value;
    notifyListeners();
  }

  static Future<ZoneModel?> getCurrentZone(
    double latitude,
    double longitude,
  ) async {
    try {
      final headers = await getHeaders();
      print('[ZONE_API] Getting current zone for: $latitude, $longitude');
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
        ),
        headers: headers,
      );
      print('[ZONE_API] Response status: ${response.statusCode}');
      print('[ZONE_API] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final zoneModel = zoneModelFromJson(response.body);
        if (zoneModel.success == true) {
          return zoneModel;
        } else {
          print(
            '[ZONE_API] API returned success: false - ${zoneModel.message}',
          );
          return null;
        }
      } else {
        print('[ZONE_API] HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ZONE_API] Error getting current zone: $e');
      return null;
    }
  }

  /// Detect zone ID only
  static Future<String?> detectZoneId(double latitude, double longitude) async {
    try {
      print('[ZONE_API] Detecting zone ID for: $latitude, $longitude');
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}zones/detect-id?latitude=$latitude&longitude=$longitude',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['is_zone_available'] == true) {
          print('[ZONE_API] Zone ID detected: ${data['zone_id']}');
          return data['zone_id'];
        } else {
          print('[ZONE_API] No zone detected: ${data['message']}');
          return null;
        }
      } else {
        print('[ZONE_API] HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ZONE_API] Error detecting zone ID: $e');
      return null;
    }
  }

  /// Check if location is in service area
  static Future<bool> checkServiceArea(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}zones/check-service-area?latitude=$latitude&longitude=$longitude',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final isInServiceArea = data['is_in_service_area'] == true;
          return isInServiceArea;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Convert Laravel Zone to your Zone format
  static Zone? convertToOldZoneModel(ZoneModel apiZoneModel) {
    try {
      if (apiZoneModel.zone == null) return null;
      final zone = apiZoneModel.zone!;
      List<Area> areaList = [];
      if (zone.area != null && zone.area!.isNotEmpty) {
        for (var areaPoint in zone.area!) {
          areaList.add(
            Area(
              latitude: areaPoint.latitude ?? 0.0,
              longitude: areaPoint.longitude ?? 0.0,
            ),
          );
        }
      }
      return Zone(
        area: areaList.isNotEmpty ? areaList : null,
        publish: zone.publish ?? false,
        latitude: zone.latitude != null
            ? double.tryParse(zone.latitude ?? '0').toString()
            : null,
        name: zone.name,
        id: zone.id,
        longitude: zone.longitude != null
            ? double.tryParse(zone.longitude ?? "0").toString()
            : null,
      );
    } catch (e) {
      print('[ZONE_CONVERSION] Error converting to old ZoneModel: $e');
      return null;
    }
  }

  /// Main getZone method
  Future<void> getZone() async {
    print(
      '[DEBUG] getZone() called - User location: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
    );
    final double latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
    final double longitude =
        Constant.selectedLocation.location?.longitude ?? 0.0;
    // Get current zone from Laravel API
    final zoneModel = await getCurrentZone(latitude, longitude);
    notifyListeners();
    if (zoneModel != null && zoneModel.success == true) {
      if (zoneModel.zone != null) {
        final detectedZone = convertToOldZoneModel(zoneModel);
        if (detectedZone != null) {
          Constant.selectedZone = detectedZone;
          Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
          print(
            '[DEBUG] User location:  ${Constant.isZoneAvailable} $latitude, $longitude',
          );
          print(
            '[DEBUG] Zone detected: ${detectedZone.name} (${detectedZone.id})',
          );
          print('[DEBUG] Is zone available: ${Constant.isZoneAvailable}');
        } else {
          await _setFallbackZone();
        }
      } else {
        // No zone found, use fallback
        await _setFallbackZone();
      }
    } else {
      await _setFallbackZone();
    }
    notifyListeners();
  }

  /// Zone detection for coordinates
  Future<String?> detectZoneIdForCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final zoneId = await detectZoneId(latitude, longitude);
      if (zoneId != null) {
        return zoneId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Service area check
  Future<bool> isLocationInServiceArea(
    double latitude,
    double longitude,
  ) async {
    try {
      final isInServiceArea = await checkServiceArea(latitude, longitude);
      if (isInServiceArea) {
        final zoneModel = await getCurrentZone(latitude, longitude);
        if (zoneModel != null && zoneModel.zone != null) {
          final zone = convertToOldZoneModel(zoneModel);
          if (zone != null) {
            Constant.selectedZone = zone;
            Constant.isZoneAvailable = true;
          }
        }
      }
      return isInServiceArea;
    } catch (e) {
      log('[LOCATION_SERVICE] Error checking service area: $e');
      return false;
    }
  }

  /// Fallback zone method
  Future<void> _setFallbackZone() async {
    try {
      print('[DEBUG] Setting fallback zone...');
      // Try to get any published zone as fallback from API
      final allZonesResponse = await http.get(
        Uri.parse('${AppConst.baseUrl}zones/all'),
        headers: headers,
      );

      if (allZonesResponse.statusCode == 200) {
        final data = json.decode(allZonesResponse.body);
        if (data['success'] == true &&
            data['zones'] != null &&
            data['zones'].isNotEmpty) {
          // Use the first available zone as fallback
          final firstZone = data['zones'][0];

          // Create a Zone from the raw data
          final fallbackZoneModel = Zone(
            id: firstZone['id']?.toString(),
            name: firstZone['name']?.toString(),
            latitude: firstZone['latitude'] == null
                ? null
                : double.tryParse(firstZone['latitude'].toString()).toString(),
            longitude: firstZone['longitude'] != null
                ? double.tryParse(firstZone['longitude'].toString()).toString()
                : null,
            publish: firstZone['publish'] == true || firstZone['publish'] == 1,
            area: _convertToAreaList(firstZone['area']),
          );

          if (fallbackZoneModel.id != null) {
            Constant.selectedZone = fallbackZoneModel;
            Constant.isZoneAvailable = false; // User is outside service area
            print(
              '[DEBUG] Using fallback zone: ${fallbackZoneModel.name} (${fallbackZoneModel.id})',
            );
            if (Constant.selectedLocation.location?.latitude == null ||
                Constant.selectedLocation.location?.longitude == null) {
              Constant.selectedLocation = ShippingAddress(
                addressAs: '${fallbackZoneModel.name} Center',
                location: UserLocation(
                  latitude: double.parse(
                    fallbackZoneModel.latitude ?? '15.41813013195468',
                  ),
                  longitude: double.parse(
                    fallbackZoneModel.longitude ?? '80.05922178576178',
                  ),
                ),
                locality: '${fallbackZoneModel.name}, Andhra Pradesh, India',
              );
            }
            return;
          }
        }
      }

      // If API fails, set default values
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
      print('[DEBUG] No fallback zone available!');
    } catch (e) {
      print('[DEBUG] Error setting fallback zone: $e');
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
    }

    notifyListeners();
  }

  /// Helper method to convert area data to List<Area>
  List<Area> _convertToAreaList(dynamic areaData) {
    List<Area> areaList = [];

    if (areaData != null && areaData is List) {
      for (var point in areaData) {
        if (point is Map &&
            point['latitude'] != null &&
            point['longitude'] != null) {
          areaList.add(
            Area(
              latitude: point['latitude'] is double
                  ? point['latitude']
                  : double.parse(point['latitude'].toString()),
              longitude: point['longitude'] is double
                  ? point['longitude']
                  : double.parse(point['longitude'].toString()),
            ),
          );
        }
      }
    }
    return areaList;
  }

  final CartProvider cartProvider = CartProvider();
  final ScrollController scrollController = ScrollController();
  bool isNavBarVisible = true;

  getCartData() async {
    cartProvider.cartStream.listen((event) async {
      cartItem.clear();
      cartItem.addAll(event);
    });
  }

  bool isLoading = true;

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  bool isListView = true;
  bool isPopular = true;
  String selectedOrderTypeValue = "Delivery";
  PageController pageController = PageController(viewportFraction: 1.0);
  PageController pageBottomController = PageController(viewportFraction: 1.0);
  int currentPage = 0;
  int currentBottomPage = 0;

  Timer? _bannerTimer;

  var selectedIndex = 0;
  late CategoryViewProvider categoryViewProvider;
  late BestRestaurantProvider bestRestaurantProvider;
  late DashBoardProvider dashBoardProvider;
  late AddressListProvider addressListProvider;
  late FavouriteProvider favouriteProvider;
  late OrderProvider orderProvider;

  void initFunction({required BuildContext context}) {
    categoryViewProvider = Provider.of<CategoryViewProvider>(
      context,
      listen: false,
    );
    bestRestaurantProvider = Provider.of<BestRestaurantProvider>(
      context,
      listen: false,
    );
    dashBoardProvider = Provider.of<DashBoardProvider>(context, listen: false);
    addressListProvider = Provider.of<AddressListProvider>(
      context,
      listen: false,
    );
    favouriteProvider = Provider.of<FavouriteProvider>(context, listen: false);
    orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _loadAllDataInParallel(context);
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection.toString() ==
          'ScrollDirection.reverse') {
        if (isNavBarVisible) isNavBarVisible = false;
      } else if (scrollController.position.userScrollDirection.toString() ==
          'ScrollDirection.forward') {
        if (!isNavBarVisible) isNavBarVisible = true;
      }
    });
    notifyListeners();
    startBannerTimer();
  }

  void onClose() {
    _bannerTimer?.cancel();
    try {
      if (pageController.hasClients) {
        pageController.dispose();
      }
      if (pageBottomController.hasClients) {
        pageBottomController.dispose();
      }
    } catch (e) {}
  }

  void startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (pageController.hasClients) {
        timer.cancel();
        return;
      }

      if (bannerModel.isEmpty) return;

      int nextPage = currentPage + 1;

      if (nextPage >= bannerModel.length) {
        // Instead of animating back to 0, jump instantly without animation
        pageController.jumpToPage(0);
        currentPage = 0;
      } else {
        currentPage = nextPage;
        try {
          await pageController.animateToPage(
            currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          timer.cancel();
        }
      }
    });
  }

  void stopBannerTimer() {
    _bannerTimer?.cancel();
  }

  late TabController tabController;

  List<BannerModel> bannerModel = <BannerModel>[];
  List<BannerModel> bannerBottomModel = <BannerModel>[];
  List<VendorModel> favouriteList = <VendorModel>[];

  // Optimized parallel data loading
  Future<void> _loadAllDataInParallel(BuildContext context) async {
    log(" _loadAllDataInParallel  second ");
    return PerformanceOptimizer.measureAsync('parallel_data_fetch', () async {
      isLoadingFunction(true);
      getCartData();
      await _ensureUserModelIsLoaded();
      await _ensureUserLocationIsSet();
      await getZone();
      await Future.wait([
        categoryViewProvider.loadVendorCategories(),
        _loadBanners(),
        _loadFavorites(),
        bestRestaurantProvider.loadRestaurantsAndRelatedData(),
      ]);
      dashBoardProvider.initFunction(context);
      favouriteProvider.initFunction();
      orderProvider.initFunction();
      notifyListeners();
      setLoading();
    });
  }

  setLoading() async {
    await Future.delayed(Duration(seconds: 1), () async {
      if (bestRestaurantProvider.allNearestRestaurant.isEmpty) {
        await Future.delayed(Duration(seconds: 2), () {
          isLoadingFunction(false);
        });
      } else {
        isLoadingFunction(false);
      }
      notifyListeners();
    });
  }

  // Load vendor categories in parallel

  // Get top banners
  static Future<List<BannerModel>> getHomeTopBanner(String type) async {
    try {
      String? customerZoneId = Constant.selectedZone?.id;
      // Build URL with zone_id parameter
      String url = '${AppConst.baseUrl}menu-items/banners/$type';
      if (customerZoneId != null && customerZoneId.isNotEmpty) {
        url += '?zone_id=$customerZoneId';
      }
      final headers = await getHeaders();
      log('[BANNER_API] Fetching top banners from: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        log(' getHomeTopBanner  ${response.body}');
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          List<BannerModel> banners = data
              .map((item) => BannerModel.fromJson(item))
              .toList();
          log(
            '[BANNER_API] Top banners fetched successfully: ${banners.length}',
          );
          return banners;
        } else {
          log('[BANNER_API] API returned success: false');
          return [];
        }
      } else {
        log('[BANNER_API] HTTP error: ${response.statusCode}');
        throw Exception('Failed to load top banners: ${response.statusCode}');
      }
    } catch (e) {
      log('[BANNER_API] Error fetching top banners: $e');
      rethrow;
    }
  }

  Future<void> _loadBanners() async {
    print('[DEBUG] Loading banners from API');
    // Log current zone information
    String? currentZoneId = Constant.selectedZone?.id;
    String? currentZoneTitle = Constant.selectedZone?.name;
    print(
      '[BANNER_LOADING] Current customer zone - ID: $currentZoneId, Title: $currentZoneTitle',
    );

    try {
      await Future.wait([
        getHomeTopBanner("top").then((value) {
          bannerModel = value;
          print('[BANNER_LOADING] Top banners loaded: ${value.length}');
          print(
            '[BANNER_LOADING] Top banner details: ${value.map((b) => '${b.title} (Zone: ${b.zoneId})').join(', ')}',
          );
        }),
        getHomeTopBanner("middle").then((value) {
          bannerBottomModel = value;
          print('[BANNER_LOADING] Bottom banners loaded: ${value.length}');
          print(
            '[BANNER_LOADING] Bottom banner details: ${value.map((b) => '${b.title} (Zone: ${b.zoneId})').join(', ')}',
          );
        }),
      ]);
      if (bannerModel.isNotEmpty) {
        startBannerTimer();
      }
      print(
        '[BANNER_LOADING] Total banners loaded - Top: ${bannerModel.length}, Bottom: ${bannerBottomModel.length}',
      );
    } catch (e) {
      print('[BANNER_LOADING] Error loading banners: $e');
      // Handle error appropriately (show error message, etc.)
    }
  }

  // Load favorites in parallel
  Future<void> _loadFavorites() async {
    print('[DEBUG] Loading favorites');
    if (Constant.userModel != null) {
      await FavouriteProvider.getFavouriteRestaurants().then((value) {
        favouriteList = value;
        print('[DEBUG] Favorites loaded: ${value.length}');
      });
    }
  }

  /// **ENSURE USER MODEL IS LOADED BEFORE LOCATION DETECTION**
  Future<void> _ensureUserModelIsLoaded() async {
    print('[DEBUG] _ensureUserModelIsLoaded: Checking user model...');
    // If user model is already loaded, return
    if (Constant.userModel != null) {
      print('[DEBUG] User model already loaded: ${Constant.userModel!.id}');
      return;
    }
    // for (int attempt = 1; attempt <= 5; attempt++) {
    //   print('[DEBUG] User model loading attempt $attempt/5');
    //   if (Constant.userModel != null) {
    //     print(
    //       '[DEBUG] User model loaded successfully: ${Constant.userModel!.id}',
    //     );
    //     return;
    //   }
    //   if (attempt < 5) {
    //     print(
    //       '[DEBUG] User model not loaded yet, waiting 200ms before retry...',
    //     );
    //     await Future.delayed(Duration(milliseconds: 200));
    //   }
    // }
    print(
      '[DEBUG] User model not loaded after 5 attempts, trying to load fresh...',
    );
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      print(
        '[DEBUG] Attempting to load user model fresh from Firestore... $userId',
      );
      final userModel = await AddressListProvider.getUserProfile(
        userId.toString(),
      );
      if (userModel != null) {
        Constant.userModel = userModel;
        print(
          '[DEBUG] User model loaded fresh from Firestore: ${userModel.id}',
        );
        return;
      }
    } catch (e) {
      print('[DEBUG] Error loading user model fresh: $e');
    }
    print('[DEBUG] User model not available, proceeding anyway');
  }

  /// **ENSURE USER LOCATION IS SET BEFORE ZONE DETECTION WITH RETRY MECHANISM**
  Future<void> _ensureUserLocationIsSet() async {
    print('[DEBUG] _ensureUserLocationIsSet: Checking current location...');
    print(
      '[DEBUG] Current location: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
    );
    // If location is already set, return
    if (Constant.selectedLocation.location?.latitude != null &&
        Constant.selectedLocation.location?.longitude != null) {
      print('[DEBUG] Location already set, proceeding with zone detection');
      return;
    }
    // **RETRY MECHANISM: Try multiple times with delays**
    for (int attempt = 1; attempt <= 3; attempt++) {
      print('[DEBUG] Location detection attempt $attempt/3');
      // Try to get location from user model
      if (Constant.userModel != null &&
          Constant.userModel!.shippingAddress != null &&
          Constant.userModel!.shippingAddress!.isNotEmpty) {
        final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => Constant.userModel!.shippingAddress!.first,
        );
        if (defaultAddress.location?.latitude != null &&
            defaultAddress.location?.longitude != null) {
          Constant.selectedLocation = defaultAddress;
          print(
            '[DEBUG] Location set from user model (attempt $attempt): ${defaultAddress.location?.latitude}, ${defaultAddress.location?.longitude}',
          );
          return;
        }
      }
      // Try to get location from local storage
      try {
        final box = GetStorage();
        final savedLocation = box.read('user_location');
        if (savedLocation != null &&
            savedLocation['latitude'] != null &&
            savedLocation['longitude'] != null) {
          String savedAddress = savedLocation['address'] ?? '';
          String savedLocality = savedLocation['locality'] ?? '';
          if (savedAddress.isEmpty || savedLocality.isEmpty) {
            try {
              final gpsCacheInfo =
                  await GpsLocationService.getCachedAddressInfo();
              if (gpsCacheInfo != null &&
                  gpsCacheInfo['address']?.isNotEmpty == true &&
                  gpsCacheInfo['locality']?.isNotEmpty == true) {
                savedAddress = gpsCacheInfo['address']!;
                savedLocality = gpsCacheInfo['locality']!;
                print('[DEBUG] Using GPS cached address info');
              } else {
                // If GPS cache doesn't have address, try to get it from coordinates
                final fullAddress =
                    await GpsLocationService.getAddressFromCoordinates(
                      savedLocation['latitude'],
                      savedLocation['longitude'],
                    );
                savedAddress = fullAddress;
                savedLocality = fullAddress;
                print('[DEBUG] Got address from coordinates');
              }

              // Save the updated address info to local storage
              await box.write('user_location', {
                'latitude': savedLocation['latitude'],
                'longitude': savedLocation['longitude'],
                'address': savedAddress,
                'locality': savedLocality,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              print('[DEBUG] Updated local storage with address info');
            } catch (e) {
              print('[DEBUG] Error getting address for saved location: $e');
              // Use fallback address
              savedAddress = 'Current Location';
              savedLocality = 'Current Location';
            }
          }

          Constant.selectedLocation = ShippingAddress(
            addressAs: 'Home',
            address: savedAddress,
            location: UserLocation(
              latitude: savedLocation['latitude'],
              longitude: savedLocation['longitude'],
            ),
            locality: savedLocality,
          );
          print(
            '[DEBUG] Location set from local storage (attempt $attempt): ${savedLocation['latitude']}, ${savedLocation['longitude']} - $savedAddress',
          );
          return;
        }
      } catch (e) {
        print(
          '[DEBUG] Error reading location from local storage (attempt $attempt): $e',
        );
      }

      // **NEW: Try to get location from GPS as fallback**
      try {
        print(
          '[DEBUG] Attempting GPS location detection (attempt $attempt)...',
        );
        final gpsLocation =
            await GpsLocationService.getLocationForZoneDetection();
        if (gpsLocation != null &&
            gpsLocation['latitude'] != null &&
            gpsLocation['longitude'] != null) {
          // Get full address from GPS coordinates
          final fullAddress =
              await GpsLocationService.getAddressFromCoordinates(
                gpsLocation['latitude']!,
                gpsLocation['longitude']!,
              );
          // 🔑 CRITICAL: Detect zone ID for GPS location
          String? detectedZoneId = await _detectZoneIdForCoordinates(
            gpsLocation['latitude']!,
            gpsLocation['longitude']!,
          );
          Constant.selectedLocation = ShippingAddress(
            id: 'gps_location_${DateTime.now().millisecondsSinceEpoch}',
            // 🔑 Add unique ID
            addressAs: 'Current Location',
            address: fullAddress,
            location: UserLocation(
              latitude: gpsLocation['latitude']!,
              longitude: gpsLocation['longitude']!,
            ),
            locality: fullAddress,
            zoneId: detectedZoneId, // 🔑 Add detected zone ID
          );
          print(
            '[DEBUG] Location set from GPS (attempt $attempt): ${gpsLocation['latitude']}, ${gpsLocation['longitude']} - $fullAddress',
          );
          return;
        }
      } catch (e) {
        print('[DEBUG] Error getting GPS location (attempt $attempt): $e');
      }

      // If user model is not loaded yet, wait and retry
      if (Constant.userModel == null) {
        print(
          '[DEBUG] User model not loaded yet, waiting 500ms before retry...',
        );
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }

      // If we reach here, location is not available, wait before retry
      if (attempt < 3) {
        print('[DEBUG] Location not found, waiting 300ms before retry...');
        await Future.delayed(Duration(milliseconds: 300));
      }
    }

    print(
      '[DEBUG] No valid location found after 3 attempts, will use fallback zone',
    );

    // **FINAL DEBUG: Log all available location sources**
    await _debugLocationSources();
  }

  /// 🔑 DETECT ZONE ID FOR COORDINATES
  ///
  /// This method detects the zone ID for given coordinates by checking
  /// if the coordinates fall within any zone polygon
  Future<String?> _detectZoneIdForCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      print(
        '[DEBUG] Starting zone detection for coordinates: $latitude, $longitude',
      );

      // If you need to get all zones from Firestore/API, you'd need a separate method
      // For example: final List<Zone> zones = await getAllZones();

      // For now, using your existing getCurrentZone method
      final zoneModel = await getCurrentZone(latitude, longitude);

      if (zoneModel == null || zoneModel.zone == null) {
        print('[DEBUG] No zone available');
        return null;
      }

      final zone = zoneModel.zone!;
      print('[DEBUG] Checking zone: ${zone.name} (${zone.id})');

      // Check if coordinates fall within the zone polygon
      if (zone.area != null && zone.area!.isNotEmpty) {
        if (Constant.isPointInPolygon(
          LatLng(latitude, longitude),
          zone.area!.cast<GeoPoint>(),
        )) {
          print('[DEBUG] Zone detected: ${zone.name} (${zone.id})');
          return zone.id;
        }
      }
      print('[DEBUG] Coordinates not within the service zone');
      return null;
    } catch (e) {
      print('[DEBUG] Error detecting zone: $e');
      return null;
    }
  }

  /// **GET LOCATION NAME FROM GPS COORDINATES**

  /// **DEBUG ALL LOCATION SOURCES**
  Future<void> _debugLocationSources() async {
    print('\n🔍 LOCATION SOURCES DEBUG:');
    print(
      '📍 Constant.selectedLocation: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
    );
    print('👤 Constant.userModel: ${Constant.userModel?.id ?? "NULL"}');

    if (Constant.userModel?.shippingAddress != null) {
      print(
        '🏠 User shipping addresses: ${Constant.userModel!.shippingAddress!.length}',
      );
      for (int i = 0; i < Constant.userModel!.shippingAddress!.length; i++) {
        final addr = Constant.userModel!.shippingAddress![i];
        print(
          '   Address $i: ${addr.addressAs} - ${addr.location?.latitude}, ${addr.location?.longitude} (default: ${addr.isDefault})',
        );
      }
    } else {
      print('🏠 User shipping addresses: NULL');
    }

    try {
      final box = GetStorage();
      final savedLocation = box.read('user_location');
      print(
        '💾 Local storage location: ${savedLocation?['latitude']}, ${savedLocation?['longitude']}',
      );
    } catch (e) {
      print('💾 Local storage error: $e');
    }

    // **NEW: Check GPS location availability**
    try {
      final isGpsAvailable = await GpsLocationService.isLocationAvailable();
      print('📡 GPS location available: $isGpsAvailable');
      if (isGpsAvailable) {
        final gpsLocation =
            await GpsLocationService.getLocationForZoneDetection();
        print(
          '📡 GPS location: ${gpsLocation?['latitude']}, ${gpsLocation?['longitude']}',
        );
      }
    } catch (e) {
      print('📡 GPS location error: $e');
    }

    print('🔍 END LOCATION SOURCES DEBUG\n');
  }

  /// **RESTAURANT VISIBILITY DIAGNOSTICS**

  getData(BuildContext context) async {
    await _loadAllDataInParallel(context);
  }

  Future<void> getRefresh(BuildContext context) async {
    await _loadAllDataInParallel(context);
  }

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FavouriteProvider.getFavouriteRestaurants().then((value) {
        favouriteList = value;
      });
    }
  }

  // Optimized distance calculation in batches
}
