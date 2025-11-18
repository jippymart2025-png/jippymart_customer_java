import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart'
    show AddressListProvider;
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/model/zone_model.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/category_view_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/common.dart';
import 'dart:async';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/gps_location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 15);

  void changeLocationAddressFunction({
    required BuildContext context,
    required ShippingAddress addressModel,
  }) async {
    // Ensure address and locality are properly set
    // Use getFullAddress() to get a proper address string if address/locality are empty
    String? finalAddress = addressModel.address;
    String? finalLocality = addressModel.locality;
    
    // If address is empty or null, use locality
    if (finalAddress == null || finalAddress.isEmpty || finalAddress == 'Current Location') {
      finalAddress = finalLocality;
    }
    
    // If locality is empty or null, use address
    if (finalLocality == null || finalLocality.isEmpty || finalLocality == 'Current Location') {
      finalLocality = finalAddress;
    }
    
    // If both are still empty, we should not save this as a valid address
    // But for now, let's ensure we have something meaningful
    if ((finalAddress == null || finalAddress.isEmpty) && 
        (finalLocality == null || finalLocality.isEmpty)) {
      log('[HOME_PROVIDER] Warning: Address model has no address or locality set');
      // Don't proceed if there's no valid address information
      return;
    }
    
    // Create a new ShippingAddress with properly set address and locality
    final updatedAddressModel = ShippingAddress(
      id: addressModel.id,
      addressAs: addressModel.addressAs ?? 'Home',
      address: finalAddress,
      locality: finalLocality,
      landmark: addressModel.landmark,
      location: addressModel.location,
      isDefault: addressModel.isDefault,
      zoneId: addressModel.zoneId,
    );
    
    Constant.selectedLocation = updatedAddressModel;
    notifyListeners();
    log("changeLocationAddressFunction ${updatedAddressModel.toJson().toString()}");
    
    if (updatedAddressModel.location != null) {
      try {
        final box = GetStorage();
        await box.write('user_location', {
          'latitude': updatedAddressModel.location!.latitude,
          'longitude': updatedAddressModel.location!.longitude,
          'address': finalAddress ?? '',
          'locality': finalLocality ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print(
          "changeLocationAddressFunction saved: latitude=${updatedAddressModel.location?.latitude}, longitude=${updatedAddressModel.location?.longitude}, address=$finalAddress, locality=$finalLocality",
        );
        // Detect and set zone for the new location
        if (updatedAddressModel.location?.latitude != null &&
            updatedAddressModel.location?.longitude != null) {
          await getZone();
        }
      } catch (e) {
        print('[HOME_PROVIDER] Error saving location: $e');
      }
    }
    
    // Refresh data but skip location setup since we just set it
    await _loadAllDataInParallel(
      context,
      waitForSupplemental: true,
      forceRefresh: true,
      skipLocationSetup: true, // Skip _ensureUserLocationIsSet since we just set the location
    );
    notifyListeners();
  }

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
      final response = await http
          .get(
            Uri.parse(
              '${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
            ),
            headers: headers,
          )
          .timeout(_networkTimeout);
      print(
        ' getCurrentZone  ${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
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
    } on TimeoutException catch (e) {
      print('[ZONE_API] Timeout getting current zone: $e');
      return null;
    } catch (e) {
      print('[ZONE_API] Error getting current zone: $e');
      return null;
    }
  }

  /// Detect zone ID only
  static Future<String?> detectZoneId(double latitude, double longitude) async {
    try {
      print('[ZONE_API] Detecting zone ID for: $latitude, $longitude');
      final response = await http
          .get(
            Uri.parse(
              '${AppConst.baseUrl}zones/detect-id?latitude=$latitude&longitude=$longitude',
            ),
            headers: headers,
          )
          .timeout(_networkTimeout);
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
    } on TimeoutException catch (e) {
      print('[ZONE_API] Timeout detecting zone ID: $e');
      return null;
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
      final response = await http
          .get(
            Uri.parse(
              '${AppConst.baseUrl}zones/check-service-area?latitude=$latitude&longitude=$longitude',
            ),
            headers: headers,
          )
          .timeout(_networkTimeout);
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
    final zoneModel = await getCurrentZone(latitude, longitude);
    notifyListeners();
    if (zoneModel != null && zoneModel.success == true) {
      if (zoneModel.zone != null) {
        final detectedZone = convertToOldZoneModel(zoneModel);
        if (detectedZone != null) {
          Constant.selectedZone = detectedZone;
          Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
          // Also update Constant.selectedLocation.zoneId for consistency
          if (detectedZone.id != null && detectedZone.id!.isNotEmpty) {
            Constant.selectedLocation.zoneId = detectedZone.id;
            print('[DEBUG] ✅ Set Constant.selectedLocation.zoneId: ${detectedZone.id}');
          }
          print(
            '[DEBUG] User location:  ${Constant.isZoneAvailable} $latitude, $longitude',
          );
          print(
            '[DEBUG] Zone detected: ${detectedZone.name} (${detectedZone.id})',
          );
          print('[DEBUG] Is zone available: ${Constant.isZoneAvailable}');
          notifyListeners();
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
      final allZonesResponse = await http
          .get(Uri.parse('${AppConst.baseUrl}zones/all'), headers: headers)
          .timeout(_networkTimeout);

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
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
      print('[DEBUG] No fallback zone available!');
      notifyListeners();
    } on TimeoutException catch (e) {
      print('[DEBUG] Timeout while setting fallback zone: $e');
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
      notifyListeners();
    } catch (e) {
      print('[DEBUG] Error setting fallback zone: $e');
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
      notifyListeners();
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
  bool _cartListenerAttached = false;
  StreamSubscription<List<CartProductModel>>? _cartSubscription;
  bool _orderProviderInitialized = false;
  bool _martInitialized = false;
  bool _favouriteProviderInitialized = false;
  Future<void>? _ongoingLoad;
  final ScrollController scrollController = ScrollController();
  bool _isScrollListenerAttached = false;
  bool isNavBarVisible = true;

  void getCartData() {
    if (_cartListenerAttached) return;
    _cartListenerAttached = true;
    _cartSubscription = cartProvider.cartStream.listen((event) {
      cartItem
        ..clear()
        ..addAll(event);
      notifyListeners();
    });
  }

  bool isLoading = true;

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

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
  late MartProvider martProvider;
  late SplashProvider splashProvider;

  Future<void> initFunction({required BuildContext context}) async {
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
    martProvider = Provider.of<MartProvider>(context, listen: false);
    splashProvider = Provider.of<SplashProvider>(context, listen: false);
    if (!_isScrollListenerAttached) {
      scrollController.addListener(() {
        if (scrollController.position.userScrollDirection.toString() ==
            'ScrollDirection.reverse') {
          if (isNavBarVisible) isNavBarVisible = false;
        } else if (scrollController.position.userScrollDirection.toString() ==
            'ScrollDirection.forward') {
          if (!isNavBarVisible) isNavBarVisible = true;
        }
      });
      _isScrollListenerAttached = true;
    }
    notifyListeners();
    startBannerTimer();
    await _loadAllDataInParallel(context, waitForSupplemental: false);
  }

  void onClose() {
    _bannerTimer?.cancel();
    _cartSubscription?.cancel();

    if (pageController.hasClients) {
      pageController.dispose();
    }
    if (pageBottomController.hasClients) {
      pageBottomController.dispose();
    }
    notifyListeners();
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
    notifyListeners();
  }

  void stopBannerTimer() {
    _bannerTimer?.cancel();
  }

  late TabController tabController;

  List<BannerModel> bannerModel = <BannerModel>[];
  List<BannerModel> bannerBottomModel = <BannerModel>[];
  List<VendorModel> favouriteList = <VendorModel>[];

  // Optimized parallel data loading
  Future<void> _loadAllDataInParallel(
    BuildContext context, {
    bool waitForSupplemental = true,
    bool forceRefresh = false,
    bool skipLocationSetup = false,
  }) async {
    if (_ongoingLoad != null && !forceRefresh) {
      return _ongoingLoad!;
    }
    final loadFuture = _performInitialLoad(
      context,
      waitForSupplemental: waitForSupplemental,
      skipLocationSetup: skipLocationSetup,
    );
    _ongoingLoad = loadFuture;
    try {
      await loadFuture;
    } finally {
      if (_ongoingLoad == loadFuture) {
        _ongoingLoad = null;
      }
    }
  }

  Future<void> _performInitialLoad(
    BuildContext context, {
    required bool waitForSupplemental,
    bool skipLocationSetup = false,
  }) async {
    isLoadingFunction(true);
    getCartData();
    try {
      if (Constant.userModel == null) {
        await ensureUserModelIsLoaded();
      } else if (Constant.userModel!.shippingAddress != null &&
          Constant.userModel!.shippingAddress!.isNotEmpty &&
          addressListProvider.shippingAddressList.isEmpty) {
        addressListProvider.shippingAddressList =
            Constant.userModel!.shippingAddress!;
        notifyListeners();
      }
      // Skip location setup if location was just manually changed
      if (!skipLocationSetup) {
        await _ensureUserLocationIsSet();
        await getZone();
      } else {
        log('[HOME_PROVIDER] Skipping _ensureUserLocationIsSet() - location was just manually set');
        // Zone is already set in changeLocationAddressFunction, so no need to call again
        // Only call getZone if it wasn't called in changeLocationAddressFunction
        // (This shouldn't happen, but adding as safety check)
      }
      final categoryFuture = categoryViewProvider.loadVendorCategories();
      final bannerFuture = _loadBanners();
      final restaurantFuture = bestRestaurantProvider
          .loadRestaurantsAndRelatedData();
      if (waitForSupplemental) {
        await Future.wait([
          categoryFuture,
          bannerFuture,
          restaurantFuture,
        ], eagerError: true);
        isLoadingFunction(false);
      } else {
        await restaurantFuture;
        isLoadingFunction(false);
        unawaited(
          categoryFuture.catchError((error, stack) {
            log('[HOME_PROVIDER] Category load failed: $error\n$stack');
          }),
        );
        unawaited(
          bannerFuture.catchError((error, stack) {
            log('[HOME_PROVIDER] Banner load failed: $error\n$stack');
          }),
        );
      }
      if (!_favouriteProviderInitialized) {
        _favouriteProviderInitialized = true;
        unawaited(favouriteProvider.initFunction());
      }
      if (!_orderProviderInitialized) {
        _orderProviderInitialized = true;
        unawaited(orderProvider.initFunction());
      }
      if (!_martInitialized) {
        _martInitialized = true;
        Future.microtask(() => martProvider.initFunction());
      }
    } catch (e, stack) {
      log('[HOME_PROVIDER] Error loading home data: $e\n$stack');
      ShowToastDialog.showToast(
        "Unable to load Home data right now. Pull to refresh to try again.".tr,
      );
      isLoadingFunction(false);
    } finally {
      isLoadingFunction(false);
    }
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
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_networkTimeout);
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
    } on TimeoutException catch (e) {
      log('[BANNER_API] Timeout fetching top banners: $e');
      rethrow;
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
        notifyListeners();
        print('[DEBUG] Favorites loaded: ${value.length}');
      });
    }
  }

  // Future<void> ensureUserModelIsLoaded() async {
  //   print(" ensureUserModelIsLoaded 1");
  //   try {
  //     if (Constant.userModel != null) {
  //       if (Constant.userModel!.shippingAddress != null &&
  //           addressListProvider.shippingAddressList.isEmpty) {
  //         print(
  //           " ensureUserModelIsLoaded - Loading shipping addresses from existing model",
  //         );
  //         addressListProvider.shippingAddressList =
  //             Constant.userModel!.shippingAddress!;
  //         notifyListeners();
  //       }
  //       return;
  //     }
  //
  //     final userId = await SqlStorageConst.getFirebaseId();
  //     if (userId == null) {
  //       print('[DEBUG] No user ID available');
  //       return;
  //     }
  //     final userModel = await AddressListProvider.getUserProfile(
  //       userId.toString(),
  //     );
  //     print(" ensureUserModelIsLoaded 2");
  //     if (userModel != null) {
  //       Constant.userModel = userModel;
  //       if (userModel.shippingAddress != null) {
  //         print(" ensureUserModelIsLoaded 3");
  //         addressListProvider.shippingAddressList = userModel.shippingAddress!;
  //         notifyListeners();
  //       }
  //       return;
  //     }
  //     notifyListeners();
  //   } catch (e) {
  //     print('[DEBUG] Error loading user model fresh: $e');
  //   }
  //   print('[DEBUG] User model not available, proceeding anyway');
  // }

  /// **ENSURE USER MODEL IS LOADED BEFORE LOCATION DETECTION**
  Future<void> ensureUserModelIsLoaded() async {
    try {
      if (Constant.userModel != null) {
        if (Constant.userModel!.shippingAddress != null &&
            Constant.userModel!.shippingAddress!.isNotEmpty &&
            addressListProvider.shippingAddressList.isEmpty) {
          addressListProvider.shippingAddressList =
              Constant.userModel!.shippingAddress!;
          notifyListeners();
        }
        return;
      }

      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null || userId.isEmpty) {
        print('[DEBUG] No stored user ID while ensuring user model');
        return;
      }

      final userModel = await AddressListProvider.getUserProfile(userId);
      print(" ensureUserModelIsLoaded 2");
      if (userModel != null) {
        Constant.userModel = userModel;
        if (userModel.shippingAddress != null &&
            userModel.shippingAddress!.isNotEmpty) {
          print(" ensureUserModelIsLoaded 3");
          addressListProvider.shippingAddressList = userModel.shippingAddress!;
          notifyListeners();
        }
        return;
      }
      notifyListeners();
    } catch (e) {
      print('[DEBUG] Error loading user model fresh: $e');
    }
    print('[DEBUG] User model not available, proceeding anyway');
  }

  Future<void> _ensureUserLocationIsSet() async {
    // Check if location is already set with valid coordinates
    if (Constant.selectedLocation.location?.latitude != null &&
        Constant.selectedLocation.location?.longitude != null) {
      // Also check if address/locality are already set and valid (not empty or "Current Location")
      final currentAddress = Constant.selectedLocation.address ?? '';
      final currentLocality = Constant.selectedLocation.locality ?? '';
      final hasValidAddress = currentAddress.isNotEmpty && 
                              currentAddress != 'Current Location' &&
                              !currentAddress.contains('Current Location');
      final hasValidLocality = currentLocality.isNotEmpty && 
                               currentLocality != 'Current Location' &&
                               !currentLocality.contains('Current Location');
      
      // If we have valid address information, don't override it
      if (hasValidAddress || hasValidLocality) {
        return;
      }
    }
    for (int attempt = 1; attempt <= 3; attempt++) {
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
          notifyListeners();
          return;
        }
      }
      try {
        final box = GetStorage();
        final savedLocation = box.read('user_location');
        if (savedLocation != null &&
            savedLocation['latitude'] != null &&
            savedLocation['longitude'] != null) {
          String savedAddress = savedLocation['address'] ?? '';
          String savedLocality = savedLocation['locality'] ?? '';
          
          // Only try to fill empty address/locality if they're truly empty (not "Current Location")
          final isAddressInvalid = savedAddress.isEmpty || 
                                   savedAddress == 'Current Location' ||
                                   savedAddress.contains('Current Location');
          final isLocalityInvalid = savedLocality.isEmpty || 
                                    savedLocality == 'Current Location' ||
                                    savedLocality.contains('Current Location');
          
          if (isAddressInvalid || isLocalityInvalid) {
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
                if (fullAddress.isNotEmpty) {
                  savedAddress = fullAddress;
                  savedLocality = fullAddress;
                  print('[DEBUG] Got address from coordinates');
                } else {
                  // If we still can't get address, don't set "Current Location" 
                  // Just use what we have (might be empty, but better than "Current Location")
                  print('[DEBUG] Could not retrieve address from coordinates');
                  // Only set "Current Location" as last resort if both are truly empty
                  if (savedAddress.isEmpty && savedLocality.isEmpty) {
                    savedAddress = 'Current Location';
                    savedLocality = 'Current Location';
                  }
                }
              }
              await box.write('user_location', {
                'latitude': savedLocation['latitude'],
                'longitude': savedLocation['longitude'],
                'address': savedAddress,
                'locality': savedLocality,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              notifyListeners();
            } catch (e) {
              print('[DEBUG] Error getting address info: $e');
              // Only set "Current Location" if both are truly empty
              if (savedAddress.isEmpty && savedLocality.isEmpty) {
                savedAddress = 'Current Location';
                savedLocality = 'Current Location';
              }
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
          notifyListeners();
          return;
        }
      } catch (e) {
        print("_ensureUserLocationIsSet $e}");
      }
      try {
        final gpsLocation =
            await GpsLocationService.getLocationForZoneDetection();
        if (gpsLocation != null &&
            gpsLocation['latitude'] != null &&
            gpsLocation['longitude'] != null) {
          final fullAddress =
              await GpsLocationService.getAddressFromCoordinates(
                gpsLocation['latitude']!,
                gpsLocation['longitude']!,
              );
          String? detectedZoneId = await _detectZoneIdForCoordinates(
            gpsLocation['latitude']!,
            gpsLocation['longitude']!,
          );
          Constant.selectedLocation = ShippingAddress(
            id: 'gps_location_${DateTime.now().millisecondsSinceEpoch}',
            addressAs: 'Current Location',
            address: fullAddress,
            location: UserLocation(
              latitude: gpsLocation['latitude']!,
              longitude: gpsLocation['longitude']!,
            ),
            locality: fullAddress,
            zoneId: detectedZoneId, // 🔑 Add detected zone ID
          );
          return;
        }
      } catch (e) {
        print("_ensureUserLocationIsSet $e}");
      }

      if (Constant.userModel == null) {
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 300));
      }
    }
    notifyListeners();
  }

  Future<String?> _detectZoneIdForCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final zoneModel = await getCurrentZone(latitude, longitude);
      if (zoneModel == null || zoneModel.zone == null) {
        return null;
      }
      final zone = zoneModel.zone!;
      if (zone.area != null && zone.area!.isNotEmpty) {
        if (Constant.isPointInPolygon(
          LatLng(latitude, longitude),
          zone.area!.cast<GeoPoint>(),
        )) {
          return zone.id;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  getData(BuildContext context) async {
    await _loadAllDataInParallel(
      context,
      waitForSupplemental: true,
      forceRefresh: true,
    );
  }

  Future<void> getRefresh(BuildContext context) async {
    await _loadAllDataInParallel(
      context,
      waitForSupplemental: true,
      forceRefresh: true,
    );
  }

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FavouriteProvider.getFavouriteRestaurants().then((value) {
        favouriteList = value;
        notifyListeners();
      });
    }
  }

  void bannerOnTapFunction(
    BannerModel bannerModel,
    RestaurantDetailsProvider restaurantDetailsProvider,
  ) async {
    stopBannerTimer();
    if (bannerModel.redirectType == "store") {
      ShowToastDialog.showLoader("Please wait");
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        bannerModel.redirectId.toString(),
      );
      if (vendorModel!.zoneId == Constant.selectedZone!.id) {
        ShowToastDialog.closeLoader();
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
        Get.to(const RestaurantDetailsScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Sorry, The Zone is not available in your area. change the other location first.",
        );
      }
    } else if (bannerModel.redirectType == "product") {
      ShowToastDialog.showLoader("Please wait");
      ProductModel? productModel = await FireStoreUtils.getProductById(
        bannerModel.redirectId.toString(),
      );
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        productModel!.vendorID.toString(),
      );
      if (vendorModel!.zoneId == Constant.selectedZone!.id) {
        ShowToastDialog.closeLoader();
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
        Get.to(const RestaurantDetailsScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Sorry, The Zone is not available in your area. change the other location first."
              .tr,
        );
      }
    } else if (bannerModel.redirectType == "external_link") {
      final uri = Uri.parse(bannerModel.redirectId.toString());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ShowToastDialog.showToast("Could not launch".tr);
      }
    }
    notifyListeners();
  }
}
