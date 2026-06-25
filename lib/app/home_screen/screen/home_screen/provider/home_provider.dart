import 'dart:async';
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
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
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
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/gps_location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jippymart_customer/services/cache_manager.dart';
import 'package:jippymart_customer/utils/location_zone_navigation.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/app/location_permission_screen/provider/location_permission_provider.dart';

class HomeProvider extends ChangeNotifier {
  // Constants and static properties
  static List<CartProductModel> cartItem = <CartProductModel>[];
  static const Duration _networkTimeout = Duration(seconds: 10);

  // Cache system
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Instance properties
  final CartProvider cartProvider = CartProvider();
  bool _cartListenerAttached = false;
  StreamSubscription<List<CartProductModel>>? _cartSubscription;
  bool _orderProviderInitialized = false;
  bool _martInitialized = false;
  bool _favouriteProviderInitialized = false;

  // Optimized loading control
  final Set<String> _loadingTasks = {};
  Completer<void>? _initialLoadCompleter;
  bool _isInitialLoadComplete = false;

  // State properties
  bool isLoading = false;
  bool zoneCheckCompleted = true;
  bool hasActuallyCheckedZone = false;
  bool isNavBarVisible = true;
  bool isPopular = true;
  String selectedOrderTypeValue = "Delivery";

  // Banner properties
  PageController pageController = PageController(viewportFraction: 1.0);
  PageController pageBottomController = PageController(viewportFraction: 1.0);
  int currentPage = 0;
  int currentBottomPage = 0;
  Timer? _bannerTimer;
  Timer? _bottomBannerTimer;
  var selectedIndex = 0;

  // Data lists
  List<BannerModel> bannerModel = <BannerModel>[];
  List<BannerModel> bannerBottomModel = <BannerModel>[];
  List<VendorModel> favouriteList = <VendorModel>[];

  // Provider references
  late CategoryViewProvider categoryViewProvider;
  late BestRestaurantProvider bestRestaurantProvider;
  late DashBoardProvider dashBoardProvider;
  late AddressListProvider addressListProvider;
  late FavouriteProvider favouriteProvider;
  late OrderProvider orderProvider;
  late MartProvider martProvider;
  late SplashProvider splashProvider;
  late TabController tabController;

  // Cache helper methods
  static void _addToCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static dynamic _getFromCache(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  static void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void _clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Optimized initialization
  Future<void> initFunction({required BuildContext context}) async {
    if (_isInitialLoadComplete && _initialLoadCompleter != null) {
      return _initialLoadCompleter!.future;
    }

    _initialLoadCompleter = Completer<void>();

    // Initialize provider references
    _initializeProviderReferences(context);

    // Load zone ID from storage
    await _loadZoneIdFromStorage();

    // Set initial states
    zoneCheckCompleted = true;
    notifyListeners();

    // Start banner timer
    startBannerTimer();

    // Load data in parallel without blocking UI
    _performOptimizedInitialLoad(context)
        .then((_) {
          _isInitialLoadComplete = true;
          _initialLoadCompleter?.complete();
          notifyListeners();
        })
        .catchError((error) {
          _initialLoadCompleter?.completeError(error);
          print('[HOME_PROVIDER] Initial load error: $error');
        });

    return _initialLoadCompleter!.future;
  }

  void _initializeProviderReferences(BuildContext context) {
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
  }

  // Optimized data loading
  Future<void> _performOptimizedInitialLoad(BuildContext context) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Start cart listener
      getCartData();

      // Load user model in background if needed
      if (Constant.userModel == null) {
        unawaited(ensureUserModelIsLoaded());
      }

      // Load location and zone in parallel with other data
      final locationFuture = _ensureUserLocationIsSet().then((_) => getZone());
      final bannersFuture = _loadBanners();
      final categoryFuture = categoryViewProvider.loadVendorCategories();

      await Future.wait([
        locationFuture.timeout(const Duration(seconds: 8)),
        bannersFuture.timeout(const Duration(seconds: 15)),
        categoryFuture.timeout(const Duration(seconds: 15)),
      ], eagerError: true).catchError((_) {
        // Continue even if some requests fail
      });

      // Outlets load inside getZone() when service is available.

      // Initialize other providers in background
      _initializeBackgroundProviders();

      print(
        '[HOME_PROVIDER] Initial load completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e, stack) {
      print('[HOME_PROVIDER] Error in initial load: $e\n$stack');
      ShowToastDialog.showToast(
        "Some data failed to load. Pull to refresh.".tr,
      );
    } finally {
      stopwatch.stop();
    }
  }

  void _initializeBackgroundProviders() {
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
  }

  // Cart management
  void getCartData() {
    if (_cartListenerAttached) return;
    _cartListenerAttached = true;

    _cartSubscription = cartProvider.cartStream.listen((event) {
      cartItem
        ..clear()
        ..addAll(event);
      // Defer notify to next frame to avoid "dependent is not a descendant"
      // when tree is updating (e.g. route transition or list rebuild).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_cartSubscription != null) notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _bannerTimer?.cancel();
    _bottomBannerTimer?.cancel();
    super.dispose();
  }

  // Banner timer management
  void startBannerTimer() {
    _bannerTimer?.cancel();
    if (bannerModel.isEmpty || !pageController.hasClients) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!pageController.hasClients) {
        timer.cancel();
        return;
      }
      if (bannerModel.isEmpty) {
        timer.cancel();
        return;
      }

      int nextPage = currentPage + 1;
      if (nextPage >= bannerModel.length) {
        nextPage = 0;
      }

      currentPage = nextPage;
      try {
        pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void stopBannerTimer() {
    _bannerTimer?.cancel();
  }

  void changeBannerPage(int value) {
    currentPage = value;
    if (bannerModel.isNotEmpty) {
      startBannerTimer();
    }
    notifyListeners();
  }

  void startBottomBannerTimer() {
    _bottomBannerTimer?.cancel();
    if (bannerBottomModel.isEmpty || !pageBottomController.hasClients) return;

    _bottomBannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!pageBottomController.hasClients) {
        timer.cancel();
        return;
      }
      if (bannerBottomModel.isEmpty) {
        timer.cancel();
        return;
      }

      int nextPage = currentBottomPage + 1;
      if (nextPage >= bannerBottomModel.length) {
        nextPage = 0;
      }

      currentBottomPage = nextPage;
      try {
        pageBottomController.animateToPage(
          currentBottomPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void stopBottomBannerTimer() {
    _bottomBannerTimer?.cancel();
  }

  void changeBottomBannerPage(int value) {
    currentBottomPage = value;
    if (bannerBottomModel.isNotEmpty) {
      startBottomBannerTimer();
    }
    notifyListeners();
  }

  // Location and zone management
  Future<void> _loadZoneIdFromStorage() async {
    // Zone ID is set only after a successful in-zone check in getZone().
    // Do not restore a saved zone ID here — it may be stale or from fallback.
  }

  /// Updates global location and reloads home data.
  /// Returns `false` when coordinates are out of zone (navigates to location screen).
  Future<bool> changeLocationAddressFunction({
    required BuildContext context,
    required ShippingAddress addressModel,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      String? finalAddress = addressModel.address;
      String? finalLocality = addressModel.locality;

      // Validate and clean address data
      if (finalAddress == null ||
          finalAddress.isEmpty ||
          finalAddress == 'Current Location') {
        finalAddress = finalLocality;
      }
      if (finalLocality == null ||
          finalLocality.isEmpty ||
          finalLocality == 'Current Location') {
        finalLocality = finalAddress;
      }

      final updatedAddressModel = ShippingAddress(
        id: addressModel.id,
        addressAs: addressModel.addressAs ?? 'Home',
        address: finalAddress,
        locality: finalLocality,
        landmark: addressModel.landmark,
        location: addressModel.location,
        isDefault: addressModel.isDefault,
        zoneId: addressModel.zoneId,
        latitude: addressModel.latitude,
        longitude: addressModel.longitude,
      );

      Constant.selectedLocation = updatedAddressModel;

      // Save to storage
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
        } catch (e) {
          print('[HOME_PROVIDER] Error saving location: $e');
        }
      }

      // Clear cache as location changed
      _clearCache();
      RestaurantApiHelper.clearNearbyOutletsCache();

      // Reload data with new location
      await _reloadDataAfterLocationChange(context);

      print(
        '[HOME_PROVIDER] Location change completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (!LocationZoneNavigation.isInServiceArea()) {
        await LocationPermissionProvider.cacheZoneData();
        if (context.mounted) {
          await LocationZoneNavigation.openOutOfServiceScreen(
            context: context,
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      print('[HOME_PROVIDER] Error changing location: $e');
      ShowToastDialog.showToast("Failed to update location".tr);
      return false;
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _reloadDataAfterLocationChange(BuildContext context) async {
    isLoadingFunction(true);

    try {
      // Get service availability and load outlets for new location
      await getZone();

      // Reload banners with new zone
      await _loadBanners();

      // Reload categories
      await categoryViewProvider.loadVendorCategories();
    } catch (e) {
      print('[HOME_PROVIDER] Error reloading data: $e');
    } finally {
      isLoadingFunction(false);
    }
  }

  Future<void> getZone() async {
    if (_isTaskRunning('getZone')) return;
    _addLoadingTask('getZone');

    try {
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;

      if (latitude == 0.0 || longitude == 0.0) {
        await _clearZoneState();
        return;
      }

      final cacheKey = 'service_${latitude}_$longitude';
      final cachedAvailable = _getFromCache(cacheKey) as bool?;

      if (cachedAvailable == true) {
        _markServiceAvailable();
        if (bestRestaurantProvider.allNearestRestaurant.isEmpty) {
          await _loadOutletsIfCoordinatesAvailable();
        }
        return;
      }

      if (cachedAvailable == false) {
        await _clearZoneState();
        return;
      }

      final restaurants = await RestaurantApiHelper.fetchNearbyOutlets(
        latitude: latitude,
        longitude: longitude,
      );

      final isServiceAvailable = restaurants.isNotEmpty;
      _addToCache(cacheKey, isServiceAvailable);

      if (isServiceAvailable) {
        _markServiceAvailable();
        bestRestaurantProvider.applyRestaurants(
          restaurants,
          zoneId: Constant.selectedZone?.id,
        );
      } else {
        await _clearZoneState();
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error checking outlet service: $e');
      await _clearZoneState();
    } finally {
      _removeLoadingTask('getZone');
      zoneCheckCompleted = true;
      hasActuallyCheckedZone = true;
      notifyListeners();
    }
  }

  void _markServiceAvailable() {
    Constant.isZoneAvailable = true;
    Constant.selectedZone ??= Zone(
      id: 'service-area',
      name: 'Service Area',
      publish: true,
    );
    if (Constant.selectedZone!.id == null ||
        Constant.selectedZone!.id!.isEmpty) {
      Constant.selectedZone!.id = 'service-area';
    }
    Constant.selectedLocation.zoneId = Constant.selectedZone!.id;
    Preferences.setString(
      Preferences.selectedZoneId,
      Constant.selectedZone!.id!,
    );
  }

  void _processZoneModel(ZoneModel zoneModel) {
    if (zoneModel.isZoneAvailable != true ||
        zoneModel.zone == null ||
        zoneModel.zone!.publish != true) {
      unawaited(_clearZoneState());
      return;
    }

    final detectedZone = convertToOldZoneModel(zoneModel);
    if (detectedZone == null ||
        detectedZone.id == null ||
        detectedZone.id!.isEmpty) {
      unawaited(_clearZoneState());
      return;
    }

    // Clear mart vendor cache when zone changes to ensure fresh data
    final previousZoneId = Constant.selectedZone?.id;
    Constant.selectedZone = detectedZone;
    Constant.isZoneAvailable = true;
    Constant.selectedLocation.zoneId = detectedZone.id;
    Preferences.setString(Preferences.selectedZoneId, detectedZone.id!);

    // Clear mart vendor cache if zone changed
    if (previousZoneId != null && previousZoneId != detectedZone.id) {
      MartZoneUtils.clearMartVendorCache();
    }

    _loadOutletsIfCoordinatesAvailable();
  }

  bool _hasCoordinates() {
    final lat = Constant.selectedLocation.location?.latitude ?? 0.0;
    final lng = Constant.selectedLocation.location?.longitude ?? 0.0;
    return lat != 0.0 && lng != 0.0;
  }

  Future<void> _loadOutletsIfCoordinatesAvailable() async {
    if (!_hasCoordinates() || Constant.isZoneAvailable != true) {
      print('[HOME_PROVIDER] Service unavailable or no coordinates, skipping outlet load');
      bestRestaurantProvider.isLoading = false;
      bestRestaurantProvider.notifyListeners();
      return;
    }
    try {
      await bestRestaurantProvider.loadRestaurantsAndRelatedData();
    } catch (e) {
      print('[HOME_PROVIDER] Restaurant load error: $e');
    }
  }

  /// Clears zone state when location is out of zone or zone cannot be resolved.
  /// Does not assign a fallback zone or persist a zone ID.
  Future<void> _clearZoneState() async {
    RestaurantApiHelper.clearNearbyOutletsCache();
    Constant.selectedZone = null;
    Constant.isZoneAvailable = false;
    Constant.selectedLocation.zoneId = null;
    Preferences.setString(Preferences.selectedZoneId, '');
    _cache.remove('fallback_zone');
    _cacheTimestamps.remove('fallback_zone');

    try {
      final box = GetStorage();
      box.write('zone_data', {
        'isZoneAvailable': false,
        'zoneId': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final savedLocation = box.read('user_location');
      if (savedLocation is Map) {
        box.write('user_location', {
          ...Map<String, dynamic>.from(savedLocation),
          'zoneId': '',
          'isZoneAvailable': false,
        });
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error clearing zone cache: $e');
    }
  }

  /// Public method to reload banners (useful after zone changes)
  Future<void> reloadBanners() async {
    await _loadBanners();
  }

  // Banner loading with cache
  Future<void> _loadBanners() async {
    if (_isTaskRunning('loadBanners')) return;
    _addLoadingTask('loadBanners');

    try {
      final zoneId =
          Constant.selectedZone?.id ??
          Constant.selectedLocation.zoneId ??
          Preferences.getString(Preferences.selectedZoneId);

      final cacheKeyTop = 'banners_top_$zoneId';
      final cacheKeyMiddle = 'banners_middle_$zoneId';

      final cachedTop = _getFromCache(cacheKeyTop) as List<BannerModel>?;
      final cachedMiddle = _getFromCache(cacheKeyMiddle) as List<BannerModel>?;

      if (cachedTop != null && cachedMiddle != null) {
        bannerModel = cachedTop;
        bannerBottomModel = cachedMiddle;
        notifyListeners();
        return;
      }

      await Future.wait([
        getHomeTopBanner("top").then((value) {
          bannerModel = value;
          _addToCache(cacheKeyTop, value);
        }),
        getHomeTopBanner("middle").then((value) {
          bannerBottomModel = value;
          _addToCache(cacheKeyMiddle, value);
        }),
      ], eagerError: true).catchError((e) {
        print('[HOME_PROVIDER] Error loading banners: $e');
      });

      // Start timers if banners are loaded
      if (bannerModel.isNotEmpty) startBannerTimer();
      if (bannerBottomModel.isNotEmpty) startBottomBannerTimer();

      notifyListeners();
    } finally {
      _removeLoadingTask('loadBanners');
    }
  }

  static Future<List<BannerModel>> getHomeTopBanner(String type) async {
    try {
      String? zoneId =
          Constant.selectedZone?.id ??
          Constant.selectedLocation.zoneId ??
          Preferences.getString(Preferences.selectedZoneId);

      String url = '${AppConst.baseUrl}menu-items/banners/$type';
      if (zoneId != null && zoneId.isNotEmpty) {
        url += '?zone_id=$zoneId';
      }

      final headers = await getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => BannerModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('[HOME_PROVIDER] Error fetching banners: $e');
      return [];
    }
  }

  // Location management
  Future<void> _ensureUserLocationIsSet() async {
    if (_isTaskRunning('ensureLocation')) return;
    _addLoadingTask('ensureLocation');

    try {
      // Prefer fresh GPS location on startup so the app does not continue using
      // a stale saved location from previous launches.
      await _getLocationFromGPS();
      if (_hasValidLocation()) return;

      // Fallback to previously saved location if GPS is unavailable.
      final storageLocation = await _loadLocationFromStorage();
      if (storageLocation != null) {
        Constant.selectedLocation = storageLocation;
        if (_hasValidLocation()) return;
      }

      // Try to get from user model if no saved location is available.
      if (Constant.userModel != null) {
        final userLocation = _getDefaultAddressFromUser();
        if (userLocation != null) {
          Constant.selectedLocation = userLocation;
          return;
        }
      }
      if (_hasCoordinates()) {
        unawaited(_loadOutletsIfCoordinatesAvailable());
      }
    } finally {
      _removeLoadingTask('ensureLocation');
    }
  }

  bool _hasValidLocation() {
    return Constant.selectedLocation.location?.latitude != null &&
        Constant.selectedLocation.location?.longitude != null &&
        Constant.selectedLocation.location!.latitude != 0.0 &&
        Constant.selectedLocation.location!.longitude != 0.0 &&
        Constant.selectedLocation.address != null &&
        Constant.selectedLocation.address!.isNotEmpty &&
        Constant.selectedLocation.address != 'Current Location';
  }

  Future<ShippingAddress?> _loadLocationFromStorage() async {
    try {
      final box = GetStorage();
      final savedLocation = box.read('user_location');

      if (savedLocation != null &&
          savedLocation['latitude'] != null &&
          savedLocation['longitude'] != null) {
        String address = savedLocation['address'] ?? '';
        String locality = savedLocation['locality'] ?? '';

        // Validate address
        if (address.isEmpty || address == 'Current Location') {
          final gpsCache = await GpsLocationService.getCachedAddressInfo();
          if (gpsCache != null) {
            address = gpsCache['address'] ?? address;
            locality = gpsCache['locality'] ?? locality;
          }
        }

        return ShippingAddress(
          addressAs: 'Home',
          address: address,
          location: UserLocation(
            latitude: savedLocation['latitude'],
            longitude: savedLocation['longitude'],
          ),
          locality: locality,
        );
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error loading location from storage: $e');
    }
    return null;
  }

  ShippingAddress? _getDefaultAddressFromUser() {
    if (Constant.userModel?.shippingAddress == null ||
        Constant.userModel!.shippingAddress!.isEmpty) {
      return null;
    }

    final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
      (a) => a.isDefault == true,
      orElse: () => Constant.userModel!.shippingAddress!.first,
    );

    if (defaultAddress.location?.latitude != null &&
        defaultAddress.location?.longitude != null) {
      return defaultAddress;
    }

    return null;
  }

  Future<void> _getLocationFromGPS() async {
    try {
      final gpsLocation =
          await GpsLocationService.getLocationForZoneDetection();
      if (gpsLocation != null &&
          gpsLocation['latitude'] != null &&
          gpsLocation['longitude'] != null) {
        final fullAddress = await GpsLocationService.getAddressFromCoordinates(
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
        );
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error getting GPS location: $e');
    }
  }

  // User model loading
  Future<void> ensureUserModelIsLoaded() async {
    if (Constant.userModel != null) return;

    try {
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null || userId.isEmpty) return;

      final userModel = await AddressListProvider.getUserProfile(userId);
      if (userModel != null) {
        Constant.userModel = userModel;
        if (userModel.shippingAddress != null &&
            userModel.shippingAddress!.isNotEmpty &&
            addressListProvider.shippingAddressList.isEmpty) {
          addressListProvider.shippingAddressList = userModel.shippingAddress!;
          notifyListeners();
        }
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error loading user model: $e');
    }
  }

  // Task management
  bool _isTaskRunning(String taskId) {
    return _loadingTasks.contains(taskId);
  }

  void _addLoadingTask(String taskId) {
    _loadingTasks.add(taskId);
  }

  void _removeLoadingTask(String taskId) {
    _loadingTasks.remove(taskId);
  }

  // Public methods
  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> getRefresh(BuildContext context) async {
    isLoadingFunction(true);

    print('[HOME_PROVIDER] 🔄 Starting refresh - clearing all caches...');

    // Clear provider's internal cache
    _clearCache();

    // Clear global CacheManager caches for home screen data
    // This ensures fresh data is fetched on refresh
    final zoneId = Constant.selectedZone?.id;

    // Clear restaurant caches
    if (zoneId != null && zoneId.isNotEmpty) {
      CacheManager().remove('best_restaurants_$zoneId');
      CacheManager().clearByPattern('nearest_restaurants_$zoneId');
      CacheManager().remove('stories_$zoneId');
    }
    CacheManager().clearByPattern('nearest_outlets_v2_');

    // Clear category cache
    CacheManager().remove('categories_home');

    // Clear banner caches
    CacheManager().clearByPattern('banners_');
    CacheManager().clearByPattern('mart_banners_');

    // Clear coupon and advertisement caches
    CacheManager().remove('restaurant_coupons_all');
    CacheManager().remove('advertisements_all');

    // Clear deals screen caches if zone exists
    if (zoneId != null && zoneId.isNotEmpty) {
      CacheManager().remove('deals_banners_$zoneId');
      CacheManager().remove('promotions_$zoneId');
    }

    print('[HOME_PROVIDER] ✅ Caches cleared, reloading data...');

    try {
      await Future.wait([
        _ensureUserLocationIsSet(),
        getZone(),
        _loadBanners(),
        categoryViewProvider.loadVendorCategories(),
        _loadOutletsIfCoordinatesAvailable(),
      ], eagerError: true);

      print('[HOME_PROVIDER] ✅ Refresh completed successfully');
    } catch (e) {
      print('[HOME_PROVIDER] ❌ Refresh error: $e');
      ShowToastDialog.showToast("Refresh failed. Please try again.".tr);
    } finally {
      isLoadingFunction(false);
    }
  }

  Future<void> getData(BuildContext context) async {
    await getRefresh(context);
  }

  Future<void> getFavouriteRestaurant() async {
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

    try {
      if (bannerModel.redirectType == "store") {
        ShowToastDialog.showLoader("Please wait");
        VendorModel? vendorModel = await FireStoreUtils.getVendorById(
          bannerModel.redirectId.toString(),
        );

        ShowToastDialog.closeLoader();
        if (vendorModel?.zoneId == Constant.selectedZone?.id) {
          restaurantDetailsProvider.initFunction(
            vendorModels: vendorModel ?? VendorModel(),
          );
          Get.to(() => const RestaurantDetailsScreen());
        } else {
          ShowToastDialog.showToast(
            "Sorry, The Zone is not available in your area. change the other location first.",
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
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to process banner".tr);
    }
  }

  // Public method to ensure location and zone are checked synchronously
  Future<void> ensureLocationAndZoneChecked() async {
    print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Starting...');

    // Set loading state
    isLoadingFunction(true);
    zoneCheckCompleted = false;
    hasActuallyCheckedZone = false;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Ensure user model is loaded
      print('[HOME_PROVIDER] Step 1 - Loading user model...');
      await ensureUserModelIsLoaded().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[HOME_PROVIDER] User model load timed out');
        },
      );

      // Step 2: Ensure location is set
      print('[HOME_PROVIDER] Step 2 - Setting location...');
      await _ensureUserLocationIsSet().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[HOME_PROVIDER] Location check timed out');
        },
      );

      // Step 3: Get zone for the location
      if (Constant.selectedLocation.location?.latitude != null &&
          Constant.selectedLocation.location!.latitude != 0.0) {
        print('[HOME_PROVIDER] Step 3 - Getting zone...');
        try {
          await getZone().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[HOME_PROVIDER] Zone check timed out, clearing zone state');
              unawaited(_clearZoneState());
            },
          );
        } catch (e) {
          print('[HOME_PROVIDER] Error getting zone: $e, clearing zone state');
          await _clearZoneState();
        }
      } else {
        print('[HOME_PROVIDER] No valid location, clearing zone state');
        await _clearZoneState();
      }

      // Mark as completed
      zoneCheckCompleted = true;
      hasActuallyCheckedZone = true;
      isLoadingFunction(false);
      notifyListeners();

      // Reload banners with zone ID after zone check completes
      print('[HOME_PROVIDER] Reloading banners with zone ID...');
      unawaited(_loadBanners());

      print(
        '[HOME_PROVIDER] ensureLocationAndZoneChecked: ✅ Completed in ${stopwatch.elapsedMilliseconds}ms. '
        'Zone: ${Constant.selectedZone?.id}, Available: ${Constant.isZoneAvailable}',
      );
    } catch (e) {
      print('[HOME_PROVIDER] ensureLocationAndZoneChecked: ❌ Error - $e');
      await _clearZoneState();

      zoneCheckCompleted = true;
      hasActuallyCheckedZone = true;
      isLoadingFunction(false);
      notifyListeners();

      unawaited(_loadBanners());
    } finally {
      stopwatch.stop();
    }
  }

  // Static helper — outlet API replaces legacy zones/current.
  static Future<ZoneModel?> getCurrentZone(
    double latitude,
    double longitude,
  ) async {
    try {
      final restaurants = await RestaurantApiHelper.fetchNearbyOutlets(
        latitude: latitude,
        longitude: longitude,
      );

      if (restaurants.isEmpty) {
        return ZoneModel(
          success: true,
          isZoneAvailable: false,
          message: 'Service not available in this area',
        );
      }

      return ZoneModel(
        success: true,
        isZoneAvailable: true,
        zone: Zone(
          id: 'service-area',
          name: 'Service Area',
          publish: true,
          latitude: latitude.toString(),
          longitude: longitude.toString(),
        ),
      );
    } catch (e) {
      print('[HOME_PROVIDER] Outlet service check failed: $e');
      return null;
    }
  }

  static Future<String?> detectZoneId(double latitude, double longitude) async {
    try {
      print('[ZONE_API] Detecting service for: $latitude, $longitude');
      final zoneModel = await getCurrentZone(latitude, longitude);
      if (zoneModel?.isZoneAvailable == true && zoneModel?.zone?.id != null) {
        print('[ZONE_API] Service area id: ${zoneModel!.zone!.id}');
        return zoneModel.zone!.id;
      }
      print('[ZONE_API] No service for coordinates');
      return null;
    } on TimeoutException catch (e) {
      print('[ZONE_API] Timeout detecting service area: $e');
      return null;
    } catch (e) {
      print('[ZONE_API] Error detecting service area: $e');
      return null;
    }
  }

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
      return null;
    }
  }
}
