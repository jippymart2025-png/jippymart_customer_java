// import 'dart:convert';
// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart'
//     show AddressListProvider;
// import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
// import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
// import 'package:jippymart_customer/app/home_screen/model/zone_model.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/category_view_provider.dart';
// import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
// import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/product_model.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:jippymart_customer/utils/utils/app_constant.dart';
// import 'package:http/http.dart' as http;
// import 'package:jippymart_customer/utils/utils/common.dart';
// import 'dart:async';
// import 'package:jippymart_customer/models/BannerModel.dart';
// import 'package:jippymart_customer/services/cart_provider.dart';
// import 'package:jippymart_customer/services/gps_location_service.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/utils/preferences.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class HomeProvider extends ChangeNotifier {
//   static List<CartProductModel> cartItem = <CartProductModel>[];
//   static const Duration _networkTimeout = Duration(seconds: 15);
//
//   void changeLocationAddressFunction({
//     required BuildContext context,
//     required ShippingAddress addressModel,
//   }) async {
//     String? finalAddress = addressModel.address;
//     String? finalLocality = addressModel.locality;
//     notifyListeners();
//     if (finalAddress == null ||
//         finalAddress.isEmpty ||
//         finalAddress == 'Current Location') {
//       finalAddress = finalLocality;
//     }
//     // If locality is empty or null, use address
//     if (finalLocality == null ||
//         finalLocality.isEmpty ||
//         finalLocality == 'Current Location') {
//       finalLocality = finalAddress;
//     }
//     if ((finalAddress == null || finalAddress.isEmpty) &&
//         (finalLocality == null || finalLocality.isEmpty)) {
//       log(
//         '[HOME_PROVIDER] Warning: Address model has no address or locality set',
//       );
//       return;
//     }
//     final updatedAddressModel = ShippingAddress(
//       id: addressModel.id,
//       addressAs: addressModel.addressAs ?? 'Home',
//       address: finalAddress,
//       locality: finalLocality,
//       landmark: addressModel.landmark,
//       location: addressModel.location,
//       isDefault: addressModel.isDefault,
//       zoneId: addressModel.zoneId,
//       latitude: addressModel.latitude,
//       longitude: addressModel.longitude,
//     );
//     Constant.selectedLocation = updatedAddressModel;
//     notifyListeners();
//     log(
//       "changeLocationAddressFunction ${updatedAddressModel.toJson().toString()}",
//     );
//     if (updatedAddressModel.location != null) {
//       try {
//         final box = GetStorage();
//         await box.write('user_location', {
//           'latitude': updatedAddressModel.location!.latitude,
//           'longitude': updatedAddressModel.location!.longitude,
//           'address': finalAddress ?? '',
//           'locality': finalLocality ?? '',
//           'timestamp': DateTime.now().millisecondsSinceEpoch,
//         });
//         print(
//           "changeLocationAddressFunction saved: latitude=${updatedAddressModel.location?.latitude}, longitude=${updatedAddressModel.location?.longitude}, address=$finalAddress, locality=$finalLocality",
//         );
//         // Detect and set zone for the new location
//         if (updatedAddressModel.location?.latitude != null &&
//             updatedAddressModel.location?.longitude != null) {
//           await getZone();
//         }
//       } catch (e) {
//         print('[HOME_PROVIDER] Error saving location: $e');
//       }
//     }
//     await _loadAllDataInParallel(
//       context,
//       waitForSupplemental: true,
//       forceRefresh: true,
//       skipLocationSetup:
//           true, // Skip _ensureUserLocationIsSet since we just set the location
//     );
//     notifyListeners();
//   }
//
//   void changeBannerPage(int value) {
//     currentPage = value;
//     // Restart timer after manual page change
//     if (bannerModel.isNotEmpty) {
//       startBannerTimer();
//     }
//     notifyListeners();
//   }
//
//   static Future<ZoneModel?> getCurrentZone(
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       final headers = await getHeaders();
//       print('[ZONE_API] Getting current zone for: $latitude, $longitude');
//       final response = await http
//           .get(
//             Uri.parse(
//               '${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
//             ),
//             headers: headers,
//           )
//           .timeout(_networkTimeout);
//       print(
//         ' getCurrentZone  ${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
//       );
//       print('[ZONE_API] Response status: ${response.statusCode}');
//       print('[ZONE_API] Response body: ${response.body}');
//       if (response.statusCode == 200) {
//         final zoneModel = zoneModelFromJson(response.body);
//         if (zoneModel.success == true) {
//           return zoneModel;
//         } else {
//           print(
//             '[ZONE_API] API returned success: false - ${zoneModel.message}',
//           );
//           return null;
//         }
//       } else {
//         print('[ZONE_API] HTTP error: ${response.statusCode}');
//         return null;
//       }
//     } on TimeoutException catch (e) {
//       print('[ZONE_API] Timeout getting current zone: $e');
//       return null;
//     } catch (e) {
//       print('[ZONE_API] Error getting current zone: $e');
//       return null;
//     }
//   }
//
//   /// Detect zone ID only
//   static Future<String?> detectZoneId(double latitude, double longitude) async {
//     try {
//       print('[ZONE_API] Detecting zone ID for: $latitude, $longitude');
//       final response = await http
//           .get(
//             Uri.parse(
//               '${AppConst.baseUrl}zones/detect-id?latitude=$latitude&longitude=$longitude',
//             ),
//             headers: headers,
//           )
//           .timeout(_networkTimeout);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['success'] == true && data['is_zone_available'] == true) {
//           print('[ZONE_API] Zone ID detected: ${data['zone_id']}');
//           return data['zone_id'];
//         } else {
//           print('[ZONE_API] No zone detected: ${data['message']}');
//           return null;
//         }
//       } else {
//         print('[ZONE_API] HTTP error: ${response.statusCode}');
//         return null;
//       }
//     } on TimeoutException catch (e) {
//       print('[ZONE_API] Timeout detecting zone ID: $e');
//       return null;
//     } catch (e) {
//       print('[ZONE_API] Error detecting zone ID: $e');
//       return null;
//     }
//   }
//
//   /// Check if location is in service area
//   static Future<bool> checkServiceArea(
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse(
//               '${AppConst.baseUrl}zones/check-service-area?latitude=$latitude&longitude=$longitude',
//             ),
//             headers: headers,
//           )
//           .timeout(_networkTimeout);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['success'] == true) {
//           final isInServiceArea = data['is_in_service_area'] == true;
//           return isInServiceArea;
//         }
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Convert Laravel Zone to your Zone format
//   static Zone? convertToOldZoneModel(ZoneModel apiZoneModel) {
//     try {
//       if (apiZoneModel.zone == null) return null;
//       final zone = apiZoneModel.zone!;
//       List<Area> areaList = [];
//       if (zone.area != null && zone.area!.isNotEmpty) {
//         for (var areaPoint in zone.area!) {
//           areaList.add(
//             Area(
//               latitude: areaPoint.latitude ?? 0.0,
//               longitude: areaPoint.longitude ?? 0.0,
//             ),
//           );
//         }
//       }
//       return Zone(
//         area: areaList.isNotEmpty ? areaList : null,
//         publish: zone.publish ?? false,
//         latitude: zone.latitude != null
//             ? double.tryParse(zone.latitude ?? '0').toString()
//             : null,
//         name: zone.name,
//         id: zone.id,
//         longitude: zone.longitude != null
//             ? double.tryParse(zone.longitude ?? "0").toString()
//             : null,
//       );
//     } catch (e) {
//       print('[ZONE_CONVERSION] Error converting to old ZoneModel: $e');
//       return null;
//     }
//   }
//
//   /// Main getZone method
//   Future<void> getZone() async {
//     print(
//       '[DEBUG] getZone() called - User location: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
//     );
//     final double latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
//     final double longitude =
//         Constant.selectedLocation.location?.longitude ?? 0.0;
//     final zoneModel = await getCurrentZone(latitude, longitude);
//     notifyListeners();
//     if (zoneModel != null && zoneModel.success == true) {
//       if (zoneModel.zone != null) {
//         final detectedZone = convertToOldZoneModel(zoneModel);
//         if (detectedZone != null) {
//           Constant.selectedZone = detectedZone;
//           Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
//           // Also update Constant.selectedLocation.zoneId for consistency
//           if (detectedZone.id != null && detectedZone.id!.isNotEmpty) {
//             Constant.selectedLocation.zoneId = detectedZone.id;
//             print(
//               '[DEBUG] ✅ Set Constant.selectedLocation.zoneId: ${detectedZone.id}',
//             );
//
//             // PRODUCTION: Store zone ID in persistent storage
//             try {
//               await Preferences.setString(Preferences.selectedZoneId, detectedZone.id!);
//               print('[HOME_PROVIDER] ✅ Zone ID stored in preferences: ${detectedZone.id}');
//             } catch (e) {
//               print('[HOME_PROVIDER] ⚠️ Error storing zone ID: $e');
//             }
//           }
//           print(
//             '[DEBUG] User location:  ${Constant.isZoneAvailable} $latitude, $longitude',
//           );
//           print(
//             '[DEBUG] Zone detected: ${detectedZone.name} (${detectedZone.id})',
//           );
//           print('[DEBUG] Is zone available: ${Constant.isZoneAvailable}');
//           // Load restaurants after zone is detected
//           _loadRestaurantsAfterZoneSet();
//           // PRODUCTION: Reload banners with zone ID after zone detection
//           unawaited(_loadBanners());
//           zoneCheckCompleted = true;
//           hasActuallyCheckedZone = true; // Mark that we've actually checked
//           notifyListeners();
//         } else {
//           await _setFallbackZone();
//         }
//       } else {
//         // No zone found, use fallback
//         await _setFallbackZone();
//       }
//     } else {
//       await _setFallbackZone();
//     }
//     zoneCheckCompleted = true;
//     hasActuallyCheckedZone = true; // Mark that we've actually checked
//     notifyListeners();
//   }
//
//   /// Load restaurants after zone is set (called from getZone)
//   void _loadRestaurantsAfterZoneSet() {
//     if (Constant.selectedZone?.id != null && Constant.selectedZone!.id!.isNotEmpty) {
//       // Check if restaurants are already loaded or loading
//       if (bestRestaurantProvider.allNearestRestaurant.isEmpty) {
//         print('[HOME_PROVIDER] Loading restaurants after zone detection...');
//         unawaited(
//           bestRestaurantProvider.loadRestaurantsAndRelatedData().catchError((e) {
//             print('[HOME_PROVIDER] Error loading restaurants after zone set: $e');
//           }),
//         );
//       }
//     }
//   }
//
//   /// Zone detection for coordinates
//   Future<String?> detectZoneIdForCoordinates(
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       final zoneId = await detectZoneId(latitude, longitude);
//       if (zoneId != null) {
//         return zoneId;
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Service area check
//   Future<bool> isLocationInServiceArea(
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       final isInServiceArea = await checkServiceArea(latitude, longitude);
//       if (isInServiceArea) {
//         final zoneModel = await getCurrentZone(latitude, longitude);
//         if (zoneModel != null && zoneModel.zone != null) {
//           final zone = convertToOldZoneModel(zoneModel);
//           if (zone != null) {
//             Constant.selectedZone = zone;
//             Constant.isZoneAvailable = true;
//           }
//         }
//       }
//       return isInServiceArea;
//     } catch (e) {
//       log('[LOCATION_SERVICE] Error checking service area: $e');
//       return false;
//     }
//   }
//
//   /// Fallback zone method
//   Future<void> _setFallbackZone() async {
//     try {
//       print('[DEBUG] Setting fallback zone...');
//       // Try to get any published zone as fallback from API
//       final allZonesResponse = await http
//           .get(Uri.parse('${AppConst.baseUrl}zones/all'), headers: headers)
//           .timeout(_networkTimeout);
//
//       if (allZonesResponse.statusCode == 200) {
//         final data = json.decode(allZonesResponse.body);
//         if (data['success'] == true &&
//             data['zones'] != null &&
//             data['zones'].isNotEmpty) {
//           // Use the first available zone as fallback
//           final firstZone = data['zones'][0];
//
//           // Create a Zone from the raw data
//           final fallbackZoneModel = Zone(
//             id: firstZone['id']?.toString(),
//             name: firstZone['name']?.toString(),
//             latitude: firstZone['latitude'] == null
//                 ? null
//                 : double.tryParse(firstZone['latitude'].toString()).toString(),
//             longitude: firstZone['longitude'] != null
//                 ? double.tryParse(firstZone['longitude'].toString()).toString()
//                 : null,
//             publish: firstZone['publish'] == true || firstZone['publish'] == 1,
//             area: _convertToAreaList(firstZone['area']),
//           );
//
//           if (fallbackZoneModel.id != null) {
//             Constant.selectedZone = fallbackZoneModel;
//             Constant.isZoneAvailable = false; // User is outside service area
//             print(
//               '[DEBUG] Using fallback zone: ${fallbackZoneModel.name} (${fallbackZoneModel.id})',
//             );
//
//             // PRODUCTION: Store fallback zone ID in persistent storage
//             try {
//               await Preferences.setString(Preferences.selectedZoneId, fallbackZoneModel.id!);
//               print('[HOME_PROVIDER] ✅ Fallback zone ID stored in preferences: ${fallbackZoneModel.id}');
//             } catch (e) {
//               print('[HOME_PROVIDER] ⚠️ Error storing fallback zone ID: $e');
//             }
//             if (Constant.selectedLocation.location?.latitude == null ||
//                 Constant.selectedLocation.location?.longitude == null) {
//               Constant.selectedLocation = ShippingAddress(
//                 addressAs: '${fallbackZoneModel.name} Center',
//                 location: UserLocation(
//                   latitude: double.parse(
//                     fallbackZoneModel.latitude ?? '15.41813013195468',
//                   ),
//                   longitude: double.parse(
//                     fallbackZoneModel.longitude ?? '80.05922178576178',
//                   ),
//                 ),
//                 locality: '${fallbackZoneModel.name}, Andhra Pradesh, India',
//               );
//             }
//             // Load restaurants even with fallback zone
//             _loadRestaurantsAfterZoneSet();
//             // PRODUCTION: Reload banners with zone ID after fallback zone is set
//             unawaited(_loadBanners());
//             zoneCheckCompleted = true;
//             hasActuallyCheckedZone = true; // Mark that we've actually checked
//             return;
//           }
//         }
//       }
//       Constant.selectedZone = null;
//       Constant.isZoneAvailable = false;
//       print('[DEBUG] No fallback zone available!');
//
//       // PRODUCTION: Clear zone ID from storage when zone is null
//       try {
//         await Preferences.setString(Preferences.selectedZoneId, '');
//         print('[HOME_PROVIDER] ✅ Cleared zone ID from storage');
//       } catch (e) {
//         print('[HOME_PROVIDER] ⚠️ Error clearing zone ID: $e');
//       }
//
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true; // Mark that we've actually checked
//       notifyListeners();
//     } on TimeoutException catch (e) {
//       print('[DEBUG] Timeout while setting fallback zone: $e');
//       Constant.selectedZone = null;
//       Constant.isZoneAvailable = false;
//
//       // PRODUCTION: Clear zone ID from storage on timeout
//       try {
//         await Preferences.setString(Preferences.selectedZoneId, '');
//       } catch (storageError) {
//         print('[HOME_PROVIDER] ⚠️ Error clearing zone ID on timeout: $storageError');
//       }
//
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true; // Mark that we've actually checked
//       notifyListeners();
//     } catch (e) {
//       print('[DEBUG] Error setting fallback zone: $e');
//       Constant.selectedZone = null;
//       Constant.isZoneAvailable = false;
//
//       // PRODUCTION: Clear zone ID from storage on error
//       try {
//         await Preferences.setString(Preferences.selectedZoneId, '');
//       } catch (storageError) {
//         print('[HOME_PROVIDER] ⚠️ Error clearing zone ID on error: $storageError');
//       }
//
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true; // Mark that we've actually checked
//       notifyListeners();
//     }
//
//     zoneCheckCompleted = true;
//     hasActuallyCheckedZone = true; // Mark that we've actually checked
//     notifyListeners();
//   }
//
//   /// Helper method to convert area data to List<Area>
//   List<Area> _convertToAreaList(dynamic areaData) {
//     List<Area> areaList = [];
//
//     if (areaData != null && areaData is List) {
//       for (var point in areaData) {
//         if (point is Map &&
//             point['latitude'] != null &&
//             point['longitude'] != null) {
//           areaList.add(
//             Area(
//               latitude: point['latitude'] is double
//                   ? point['latitude']
//                   : double.parse(point['latitude'].toString()),
//               longitude: point['longitude'] is double
//                   ? point['longitude']
//                   : double.parse(point['longitude'].toString()),
//             ),
//           );
//         }
//       }
//     }
//     return areaList;
//   }
//
//   final CartProvider cartProvider = CartProvider();
//   bool _cartListenerAttached = false;
//   StreamSubscription<List<CartProductModel>>? _cartSubscription;
//   bool _orderProviderInitialized = false;
//   bool _martInitialized = false;
//   bool _favouriteProviderInitialized = false;
//   Future<void>? _ongoingLoad;
//   bool isNavBarVisible = true;
//
//   void getCartData() {
//     if (_cartListenerAttached) return;
//     _cartListenerAttached = true;
//     _cartSubscription = cartProvider.cartStream.listen((event) {
//       cartItem
//         ..clear()
//         ..addAll(event);
//       notifyListeners();
//     });
//   }
//
//   bool isLoading = false;
//
//   /// Tracks whether we've finished at least one zone check
//   /// (either a real zone or a fallback zone).
//   /// Default to true so UI shows content immediately on first install
//   /// Will be updated as zone detection completes in background
//   bool zoneCheckCompleted = true;
//
//   /// Tracks whether we've actually performed a zone check (not just defaulted)
//   /// This prevents showing "Service Not Available" before checking location
//   bool hasActuallyCheckedZone = false;
//
//   void isLoadingFunction(bool value) {
//     isLoading = value;
//     notifyListeners();
//   }
//
//   bool isPopular = true;
//   String selectedOrderTypeValue = "Delivery";
//   PageController pageController = PageController(viewportFraction: 1.0);
//   PageController pageBottomController = PageController(viewportFraction: 1.0);
//   int currentPage = 0;
//   int currentBottomPage = 0;
//   Timer? _bannerTimer;
//   Timer? _bottomBannerTimer;
//   var selectedIndex = 0;
//   late CategoryViewProvider categoryViewProvider;
//   late BestRestaurantProvider bestRestaurantProvider;
//   late DashBoardProvider dashBoardProvider;
//   late AddressListProvider addressListProvider;
//   late FavouriteProvider favouriteProvider;
//   late OrderProvider orderProvider;
//   late MartProvider martProvider;
//   late SplashProvider splashProvider;
//
//   Future<void> initFunction({required BuildContext context}) async {
//     categoryViewProvider = Provider.of<CategoryViewProvider>(
//       context,
//       listen: false,
//     );
//     bestRestaurantProvider = Provider.of<BestRestaurantProvider>(
//       context,
//       listen: false,
//     );
//     dashBoardProvider = Provider.of<DashBoardProvider>(context, listen: false);
//     addressListProvider = Provider.of<AddressListProvider>(
//       context,
//       listen: false,
//     );
//     favouriteProvider = Provider.of<FavouriteProvider>(context, listen: false);
//     orderProvider = Provider.of<OrderProvider>(context, listen: false);
//     martProvider = Provider.of<MartProvider>(context, listen: false);
//     splashProvider = Provider.of<SplashProvider>(context, listen: false);
//
//     // PRODUCTION: Load zone ID from storage if available
//     await _loadZoneIdFromStorage();
//
//     // For non-blocking mode (first install), set zoneCheckCompleted immediately
//     // This ensures UI shows content right away instead of waiting
//     if (Constant.selectedZone == null) {
//       print('[HOME_PROVIDER] First install detected, setting zoneCheckCompleted = true immediately');
//       zoneCheckCompleted = true;
//     } else {
//       print('[HOME_PROVIDER] Zone exists, setting zoneCheckCompleted = true immediately');
//       zoneCheckCompleted = true;
//     }
//
//     notifyListeners();
//     startBannerTimer();
//
//     // Load data in background (non-blocking) - don't await
//     _loadAllDataInParallel(context, waitForSupplemental: false)
//         .catchError((e) {
//       print('[HOME_PROVIDER] Error in initFunction: $e');
//     });
//   }
//
//   /// PRODUCTION: Load zone ID from persistent storage
//   /// This ensures zone ID is available immediately on app start
//   Future<void> _loadZoneIdFromStorage() async {
//     try {
//       final savedZoneId = Preferences.getString(Preferences.selectedZoneId);
//       if (savedZoneId.isNotEmpty && Constant.selectedZone?.id != savedZoneId) {
//         print('[HOME_PROVIDER] ✅ Loaded zone ID from storage: $savedZoneId');
//         // If we have a saved zone ID but no zone object, we'll fetch it during location check
//         // For now, just log it - the zone will be set during ensureLocationAndZoneChecked
//         if (Constant.selectedLocation.zoneId == null || Constant.selectedLocation.zoneId!.isEmpty) {
//           Constant.selectedLocation.zoneId = savedZoneId;
//           print('[HOME_PROVIDER] ✅ Set zoneId in selectedLocation from storage');
//         }
//       } else if (savedZoneId.isEmpty) {
//         print('[HOME_PROVIDER] No zone ID found in storage (first install or cleared)');
//       }
//     } catch (e) {
//       print('[HOME_PROVIDER] ⚠️ Error loading zone ID from storage: $e');
//     }
//   }
//
//   void startBannerTimer() {
//     _bannerTimer?.cancel();
//     if (bannerModel.isEmpty) return;
//     if (!pageController.hasClients) return;
//
//     _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
//       if (!pageController.hasClients) {
//         timer.cancel();
//         return;
//       }
//       if (bannerModel.isEmpty) {
//         timer.cancel();
//         return;
//       }
//
//       int nextPage = currentPage + 1;
//       if (nextPage >= bannerModel.length) {
//         nextPage = 0;
//       }
//
//       currentPage = nextPage;
//       try {
//         await pageController.animateToPage(
//           currentPage,
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.easeInOut,
//         );
//       } catch (e) {
//         timer.cancel();
//       }
//     });
//     notifyListeners();
//   }
//
//   void stopBannerTimer() {
//     _bannerTimer?.cancel();
//   }
//
//   void startBottomBannerTimer() {
//     _bottomBannerTimer?.cancel();
//     if (bannerBottomModel.isEmpty) return;
//     if (!pageBottomController.hasClients) return;
//
//     _bottomBannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
//       if (!pageBottomController.hasClients) {
//         timer.cancel();
//         return;
//       }
//       if (bannerBottomModel.isEmpty) {
//         timer.cancel();
//         return;
//       }
//
//       int nextPage = currentBottomPage + 1;
//       if (nextPage >= bannerBottomModel.length) {
//         nextPage = 0;
//       }
//
//       currentBottomPage = nextPage;
//       try {
//         await pageBottomController.animateToPage(
//           currentBottomPage,
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.easeInOut,
//         );
//       } catch (e) {
//         timer.cancel();
//       }
//     });
//     notifyListeners();
//   }
//
//   void stopBottomBannerTimer() {
//     _bottomBannerTimer?.cancel();
//   }
//
//   void changeBottomBannerPage(int value) {
//     currentBottomPage = value;
//     // Restart timer after manual page change
//     if (bannerBottomModel.isNotEmpty) {
//       startBottomBannerTimer();
//     }
//     notifyListeners();
//   }
//
//   late TabController tabController;
//   List<BannerModel> bannerModel = <BannerModel>[];
//   List<BannerModel> bannerBottomModel = <BannerModel>[];
//   List<VendorModel> favouriteList = <VendorModel>[];
//
//   // Optimized parallel data loading
//   Future<void> _loadAllDataInParallel(
//     BuildContext context, {
//     bool waitForSupplemental = true,
//     bool forceRefresh = false,
//     bool skipLocationSetup = false,
//   }) async {
//     // if (_ongoingLoad != null && !forceRefresh) {
//     //   return _ongoingLoad!;
//     // }
//     // final loadFuture =
//     _performInitialLoad(
//       context,
//       waitForSupplemental: waitForSupplemental,
//       skipLocationSetup: skipLocationSetup,
//     );
//     // _ongoingLoad = loadFuture;
//     // try {
//     //   await loadFuture;
//     // } finally {
//     //   if (_ongoingLoad == loadFuture) {
//     //     _ongoingLoad = null;
//     //   }
//     // }
//   }
//
//   Future<void> _performInitialLoad(
//     BuildContext context, {
//     required bool waitForSupplemental,
//     bool skipLocationSetup = false,
//   }) async {
//     print('[HOME_PROVIDER] _performInitialLoad started');
//     getCartData();
//
//     // Check if we already have zone data - if yes, mark as completed immediately
//     if (!waitForSupplemental && Constant.selectedZone != null) {
//       print('[HOME_PROVIDER] Zone already exists, marking as completed immediately');
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true; // We have a zone, so we've checked
//       notifyListeners();
//     }
//
//     // Safety timeout: For first install, show content after max 3 seconds
//     // This ensures UI never hangs on first install
//     if (!waitForSupplemental) {
//       // Short timeout for first install - show content quickly
//       Future.delayed(const Duration(seconds: 3), () {
//         if (!zoneCheckCompleted) {
//           print('[HOME_PROVIDER] First install timeout (3s): forcing zoneCheckCompleted = true to show content');
//           zoneCheckCompleted = true;
//           notifyListeners();
//         }
//       });
//     }
//
//     // For non-blocking mode, don't set isLoading to true at all
//     // This prevents the loading screen from showing
//     // zoneCheckCompleted is already true by default, so content shows immediately
//     if (!waitForSupplemental) {
//       print('[HOME_PROVIDER] Non-blocking mode: skipping isLoading=true, zoneCheckCompleted=true (default), loading in background');
//     } else {
//       print('[HOME_PROVIDER] Blocking mode: setting isLoading to true, zoneCheckCompleted to false');
//       isLoadingFunction(true);
//       zoneCheckCompleted = false; // In blocking mode, wait for zone check
//       notifyListeners();
//     }
//
//     try {
//       // Load user model in background if needed (non-blocking)
//       if (Constant.userModel == null) {
//         unawaited(
//           ensureUserModelIsLoaded().catchError((e) {
//             print('[HOME_PROVIDER] Error loading user model: $e');
//           }),
//         );
//       } else if (Constant.userModel!.shippingAddress != null &&
//           Constant.userModel!.shippingAddress!.isNotEmpty &&
//           addressListProvider.shippingAddressList.isEmpty) {
//         addressListProvider.shippingAddressList =
//             Constant.userModel!.shippingAddress!;
//         print("_performInitialLoad ");
//         notifyListeners();
//       }
//
//       // Load location and zone
//       if (!skipLocationSetup) {
//         if (waitForSupplemental) {
//           await _ensureUserLocationIsSet();
//           await getZone();
//         } else {
//           // In non-blocking mode, check if we have saved location first
//           // If yes, use it immediately and show content, then update in background
//           bool hasSavedLocation = Constant.selectedLocation.location?.latitude != null &&
//               Constant.selectedLocation.location?.longitude != null &&
//               (Constant.selectedLocation.location!.latitude != 0.0 ||
//                Constant.selectedLocation.location!.longitude != 0.0);
//
//           if (hasSavedLocation && Constant.selectedZone != null) {
//             // We have location and zone, mark as completed immediately
//             print('[HOME_PROVIDER] Using saved location/zone, showing content immediately');
//             zoneCheckCompleted = true;
//             hasActuallyCheckedZone = true; // We have a zone, so we've checked
//             notifyListeners();
//
//             // Still update in background to get latest zone status
//             unawaited(() async {
//               try {
//                 await _ensureUserLocationIsSet().timeout(
//                   const Duration(seconds: 5),
//                   onTimeout: () {
//                     print('[HOME_PROVIDER] _ensureUserLocationIsSet timed out');
//                   },
//                 );
//                 await getZone().timeout(
//                   const Duration(seconds: 5),
//                   onTimeout: () {
//                     print('[HOME_PROVIDER] getZone timed out');
//                   },
//                 );
//               } catch (e) {
//                 print('[HOME_PROVIDER] Error updating location/zone: $e');
//               }
//             }());
//           } else {
//             // No saved location (first install) - show content immediately, then load in background
//             print(
//               '[HOME_PROVIDER] No saved location (first install), showing content immediately, loading location/zone in background...',
//             );
//
//             // For first install, mark as completed immediately so UI shows content
//             // Location/zone will load in background and update when ready
//             zoneCheckCompleted = true;
//             notifyListeners();
//
//             // Load location and zone in background without blocking UI
//             unawaited(() async {
//               try {
//                 // Try to get location with timeout
//                 await _ensureUserLocationIsSet().timeout(
//                   const Duration(seconds: 8),
//                   onTimeout: () {
//                     print('[HOME_PROVIDER] _ensureUserLocationIsSet timed out, using fallback');
//                     // If location times out, try to set fallback zone
//                     if (Constant.selectedLocation.location?.latitude == null ||
//                         Constant.selectedLocation.location?.latitude == 0.0) {
//                       unawaited(_setFallbackZone());
//                     }
//                   },
//                 );
//
//                 // Only call getZone if we have valid location
//                 if (Constant.selectedLocation.location?.latitude != null &&
//                     Constant.selectedLocation.location!.latitude != 0.0) {
//                   await getZone().timeout(
//                     const Duration(seconds: 8),
//                     onTimeout: () {
//                       print('[HOME_PROVIDER] getZone timed out');
//                       // Try fallback
//                       unawaited(_setFallbackZone());
//                     },
//                   );
//                 } else {
//                   // No valid location, use fallback
//                   unawaited(_setFallbackZone());
//                 }
//
//                 print(
//                   '[HOME_PROVIDER] Zone detection completed in background, zoneId: ${Constant.selectedZone?.id}',
//                 );
//                 notifyListeners();
//               } catch (e) {
//                 print('[HOME_PROVIDER] Error loading location/zone: $e');
//                 // Try fallback zone
//                 unawaited(_setFallbackZone());
//               }
//             }());
//           }
//         }
//       } else {
//         log(
//           '[HOME_PROVIDER] Skipping _ensureUserLocationIsSet() - location was just manually set',
//         );
//         // Still need to get zone if location was manually set
//         if (waitForSupplemental) {
//           await getZone();
//         } else {
//           // Location was just set, so we can mark as completed immediately
//           // and update zone in background
//           zoneCheckCompleted = true;
//           notifyListeners();
//
//           unawaited(
//             getZone().timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print('[HOME_PROVIDER] getZone timed out');
//               },
//             ).catchError((e) {
//               print('[HOME_PROVIDER] Error getting zone: $e');
//             }),
//           );
//         }
//       }
//
//       final categoryFuture = categoryViewProvider.loadVendorCategories();
//       final bannerFuture = _loadBanners();
//       // Only load restaurants if zone is available or fallback zone is set
//       final restaurantFuture = (Constant.selectedZone?.id != null && Constant.selectedZone!.id!.isNotEmpty)
//           ? bestRestaurantProvider.loadRestaurantsAndRelatedData()
//           : Future.value().then((_) {
//               print('[HOME_PROVIDER] Skipping restaurant load - no zone available yet');
//             });
//       if (waitForSupplemental) {
//         await Future.wait([
//           categoryFuture,
//           bannerFuture,
//           restaurantFuture,
//         ], eagerError: true);
//         print('[HOME_PROVIDER] All data loaded (waitForSupplemental=true), setting isLoading to false');
//         isLoadingFunction(false);
//       } else {
//         // For non-blocking mode, set loading to false immediately
//         // and let data load in background
//         print('[HOME_PROVIDER] Non-blocking mode: setting isLoading to false immediately');
//         isLoadingFunction(false);
//
//         // Load data in background without blocking
//         unawaited(
//           restaurantFuture.catchError((error, stack) {
//             log('[HOME_PROVIDER] Restaurant load failed: $error\n$stack');
//           }),
//         );
//         unawaited(
//           categoryFuture.catchError((error, stack) {
//             log('[HOME_PROVIDER] Category load failed: $error\n$stack');
//           }),
//         );
//         unawaited(
//           bannerFuture.catchError((error, stack) {
//             log('[HOME_PROVIDER] Banner load failed: $error\n$stack');
//           }),
//         );
//       }
//       if (!_favouriteProviderInitialized) {
//         _favouriteProviderInitialized = true;
//         unawaited(favouriteProvider.initFunction());
//       }
//       if (!_orderProviderInitialized) {
//         _orderProviderInitialized = true;
//         unawaited(orderProvider.initFunction());
//       }
//       if (!_martInitialized) {
//         _martInitialized = true;
//         Future.microtask(() => martProvider.initFunction());
//       }
//     } catch (e, stack) {
//       log('[HOME_PROVIDER] Error loading home data: $e\n$stack');
//       print('[HOME_PROVIDER] ERROR: $e');
//       print('[HOME_PROVIDER] Setting isLoading to false after error');
//       isLoadingFunction(false);
//       ShowToastDialog.showToast(
//         "Unable to load Home data right now. Pull to refresh to try again.".tr,
//       );
//     } finally {
//       print('[HOME_PROVIDER] Finally block: ensuring isLoading is false');
//       isLoadingFunction(false);
//     }
//   }
//
//   // Load vendor categories in parallel
//   // http://192.168.0.105:8000/api/menu-items/banners/top?zone_id=PsKHGNMgkuQaMDONJVOC
//   // Get top banners - PRODUCTION: Always fetch based on zone ID
//   static Future<List<BannerModel>> getHomeTopBanner(String type) async {
//     try {
//       // PRODUCTION: Get zone ID from multiple sources with priority
//       String? customerZoneId;
//
//       // Priority 1: Use zone ID from Constant.selectedZone
//       if (Constant.selectedZone?.id != null && Constant.selectedZone!.id!.isNotEmpty) {
//         customerZoneId = Constant.selectedZone!.id;
//         log('[BANNER_API] Using zone ID from Constant.selectedZone: $customerZoneId');
//       }
//       // Priority 2: Use zone ID from Constant.selectedLocation
//       else if (Constant.selectedLocation.zoneId != null && Constant.selectedLocation.zoneId!.isNotEmpty) {
//         customerZoneId = Constant.selectedLocation.zoneId;
//         log('[BANNER_API] Using zone ID from Constant.selectedLocation: $customerZoneId');
//       }
//       // Priority 3: Try to load from storage
//       else {
//         try {
//           customerZoneId = Preferences.getString(Preferences.selectedZoneId);
//           if (customerZoneId.isNotEmpty) {
//             log('[BANNER_API] Using zone ID from storage: $customerZoneId');
//             // Update selectedLocation with zone ID from storage
//             Constant.selectedLocation.zoneId = customerZoneId;
//           }
//         } catch (e) {
//           log('[BANNER_API] Error loading zone ID from storage: $e');
//         }
//       }
//
//       // Build URL with zone_id parameter - PRODUCTION: Always include zone_id if available
//       String url = '${AppConst.baseUrl}menu-items/banners/$type';
//       if (customerZoneId != null && customerZoneId.isNotEmpty) {
//         url += '?zone_id=$customerZoneId';
//         log('[BANNER_API] Fetching $type banners for zone: $customerZoneId');
//       } else {
//         log('[BANNER_API] ⚠️ No zone ID available, fetching banners without zone filter');
//       }
//
//       final headers = await getHeaders();
//       log('[BANNER_API] Request URL: $url');
//       final response = await http
//           .get(Uri.parse(url), headers: headers)
//           .timeout(_networkTimeout);
//
//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         if (jsonResponse['success'] == true) {
//           List<dynamic> data = jsonResponse['data'];
//           List<BannerModel> banners = data
//               .map((item) => BannerModel.fromJson(item))
//               .toList();
//           log(
//             '[BANNER_API] ✅ $type banners fetched successfully: ${banners.length} banners for zone: $customerZoneId',
//           );
//           return banners;
//         } else {
//           log('[BANNER_API] ⚠️ API returned success: false - ${jsonResponse['message'] ?? 'Unknown error'}');
//           return [];
//         }
//       } else {
//         log('[BANNER_API] ❌ HTTP error: ${response.statusCode}');
//         throw Exception('Failed to load $type banners: ${response.statusCode}');
//       }
//     } on TimeoutException catch (e) {
//       log('[BANNER_API] ❌ Timeout fetching $type banners: $e');
//       return []; // Return empty list instead of rethrowing for better UX
//     } catch (e) {
//       log('[BANNER_API] ❌ Error fetching $type banners: $e');
//       return []; // Return empty list instead of rethrowing for better UX
//     }
//   }
//
//   /// PRODUCTION: Load banners based on current zone ID
//   /// This method ensures banners are always fetched for the correct zone
//   Future<void> _loadBanners() async {
//     log('[BANNER_LOADING] Starting banner load process...');
//
//     // Log current zone information from all sources
//     String? zoneIdFromConstant = Constant.selectedZone?.id;
//     String? zoneIdFromLocation = Constant.selectedLocation.zoneId;
//     String? zoneIdFromStorage = Preferences.getString(Preferences.selectedZoneId);
//     String? currentZoneTitle = Constant.selectedZone?.name;
//
//     log(
//       '[BANNER_LOADING] Zone sources - Constant.selectedZone: $zoneIdFromConstant, '
//       'selectedLocation.zoneId: $zoneIdFromLocation, Storage: $zoneIdFromStorage, Title: $currentZoneTitle',
//     );
//
//     // PRODUCTION: Ensure we have zone ID before loading banners
//     String? effectiveZoneId = zoneIdFromConstant ?? zoneIdFromLocation ?? (zoneIdFromStorage.isNotEmpty ? zoneIdFromStorage : null);
//
//     if (effectiveZoneId == null || effectiveZoneId.isEmpty) {
//       log('[BANNER_LOADING] ⚠️ No zone ID available, banners will be loaded without zone filter');
//     } else {
//       log('[BANNER_LOADING] ✅ Using zone ID for banner fetch: $effectiveZoneId');
//     }
//
//     try {
//       await Future.wait([
//         getHomeTopBanner("top").then((value) {
//           bannerModel = value;
//           log('[BANNER_LOADING] ✅ Top banners loaded: ${value.length}');
//           if (value.isNotEmpty) {
//             log(
//               '[BANNER_LOADING] Top banner details: ${value.map((b) => '${b.title} (Zone: ${b.zoneId})').join(', ')}',
//             );
//           }
//         }).catchError((e) {
//           log('[BANNER_LOADING] ❌ Error loading top banners: $e');
//           bannerModel = []; // Set empty list on error
//         }),
//         getHomeTopBanner("middle").then((value) {
//           bannerBottomModel = value;
//           log('[BANNER_LOADING] ✅ Middle banners loaded: ${value.length}');
//           if (value.isNotEmpty) {
//             log(
//               '[BANNER_LOADING] Middle banner details: ${value.map((b) => '${b.title} (Zone: ${b.zoneId})').join(', ')}',
//             );
//           }
//         }).catchError((e) {
//           log('[BANNER_LOADING] ❌ Error loading middle banners: $e');
//           bannerBottomModel = []; // Set empty list on error
//         }),
//       ]);
//
//       // Start timers only if banners are loaded
//       if (bannerModel.isNotEmpty) {
//         startBannerTimer();
//       }
//       if (bannerBottomModel.isNotEmpty) {
//         startBottomBannerTimer();
//       }
//
//       log(
//         '[BANNER_LOADING] ✅ Banner load completed - Top: ${bannerModel.length}, Middle: ${bannerBottomModel.length}',
//       );
//
//       notifyListeners();
//     } catch (e) {
//       log('[BANNER_LOADING] ❌ Critical error loading banners: $e');
//       // Set empty lists to prevent UI errors
//       bannerModel = [];
//       bannerBottomModel = [];
//       notifyListeners();
//     }
//   }
//
//   // Load favorites in parallel
//   Future<void> _loadFavorites() async {
//     print('[DEBUG] Loading favorites');
//     if (Constant.userModel != null) {
//       await FavouriteProvider.getFavouriteRestaurants().then((value) {
//         favouriteList = value;
//         notifyListeners();
//         print('[DEBUG] Favorites loaded: ${value.length}');
//       });
//     }
//   }
//
//   // Future<void> ensureUserModelIsLoaded() async {
//   //   print(" ensureUserModelIsLoaded 1");
//   //   try {
//   //     if (Constant.userModel != null) {
//   //       if (Constant.userModel!.shippingAddress != null &&
//   //           addressListProvider.shippingAddressList.isEmpty) {
//   //         print(
//   //           " ensureUserModelIsLoaded - Loading shipping addresses from existing model",
//   //         );
//   //         addressListProvider.shippingAddressList =
//   //             Constant.userModel!.shippingAddress!;
//   //         notifyListeners();
//   //       }
//   //       return;
//   //     }
//   //
//   //     final userId = await SqlStorageConst.getFirebaseId();
//   //     if (userId == null) {
//   //       print('[DEBUG] No user ID available');
//   //       return;
//   //     }
//   //     final userModel = await AddressListProvider.getUserProfile(
//   //       userId.toString(),
//   //     );
//   //     print(" ensureUserModelIsLoaded 2");
//   //     if (userModel != null) {
//   //       Constant.userModel = userModel;
//   //       if (userModel.shippingAddress != null) {
//   //         print(" ensureUserModelIsLoaded 3");
//   //         addressListProvider.shippingAddressList = userModel.shippingAddress!;
//   //         notifyListeners();
//   //       }
//   //       return;
//   //     }
//   //     notifyListeners();
//   //   } catch (e) {
//   //     print('[DEBUG] Error loading user model fresh: $e');
//   //   }
//   //   print('[DEBUG] User model not available, proceeding anyway');
//   // }
//
//   /// **ENSURE USER MODEL IS LOADED BEFORE LOCATION DETECTION**
//   Future<void> ensureUserModelIsLoaded() async {
//     try {
//       if (Constant.userModel != null) {
//         if (Constant.userModel!.shippingAddress != null &&
//             Constant.userModel!.shippingAddress!.isNotEmpty &&
//             addressListProvider.shippingAddressList.isEmpty) {
//           addressListProvider.shippingAddressList =
//               Constant.userModel!.shippingAddress!;
//           notifyListeners();
//         }
//         return;
//       }
//       final userId = await SqlStorageConst.getFirebaseId();
//       if (userId == null || userId.isEmpty) {
//         print('[DEBUG] No stored user ID while ensuring user model');
//         return;
//       }
//       final userModel = await AddressListProvider.getUserProfile(userId);
//       print(" ensureUserModelIsLoaded 2");
//       if (userModel != null) {
//         Constant.userModel = userModel;
//         if (userModel.shippingAddress != null &&
//             userModel.shippingAddress!.isNotEmpty) {
//           print(" ensureUserModelIsLoaded 3");
//           addressListProvider.shippingAddressList = userModel.shippingAddress!;
//           notifyListeners();
//         }
//         return;
//       }
//       notifyListeners();
//     } catch (e) {
//       print('[DEBUG] Error loading user model fresh: $e');
//     }
//     print('[DEBUG] User model not available, proceeding anyway');
//   }
//
//   /// Public method to ensure location and zone are checked synchronously
//   /// Used by splash screen to wait for location/zone before navigation
//   /// This method properly awaits all async operations
//   Future<void> ensureLocationAndZoneChecked() async {
//     print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Starting location and zone check...');
//
//     // Set loading state
//     isLoadingFunction(true);
//     zoneCheckCompleted = false;
//     hasActuallyCheckedZone = false;
//     notifyListeners();
//
//     try {
//       // Step 1: Ensure user model is loaded (needed for default addresses)
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Step 1 - Loading user model...');
//       await ensureUserModelIsLoaded().timeout(
//         const Duration(seconds: 5),
//         onTimeout: () {
//           print('[HOME_PROVIDER] ensureLocationAndZoneChecked: User model load timed out');
//         },
//       );
//
//       // Step 2: Ensure location is set
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Step 2 - Setting location...');
//       await _ensureUserLocationIsSet().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Location check timed out');
//         },
//       );
//
//       // Step 3: Get zone for the location
//       if (Constant.selectedLocation.location?.latitude != null &&
//           Constant.selectedLocation.location!.latitude != 0.0) {
//         print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Step 3 - Getting zone...');
//         try {
//           await getZone().timeout(
//             const Duration(seconds: 10),
//             onTimeout: () {
//               print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Zone check timed out, using fallback');
//             },
//           );
//         } catch (e) {
//           print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Error getting zone: $e, using fallback');
//           await _setFallbackZone();
//         }
//       } else {
//         print('[HOME_PROVIDER] ensureLocationAndZoneChecked: No valid location, setting fallback zone');
//         await _setFallbackZone();
//       }
//
//       // If zone is still null after getZone, use fallback
//       if (Constant.selectedZone == null) {
//         print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Zone is null after getZone, setting fallback');
//         await _setFallbackZone();
//       }
//
//       // Mark as completed
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true;
//       isLoadingFunction(false);
//       notifyListeners();
//
//       // PRODUCTION: Reload banners with zone ID after zone check completes
//       // This ensures banners are fetched with the correct zone ID after login
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Reloading banners with zone ID...');
//       unawaited(_loadBanners());
//
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: ✅ Completed. Zone: ${Constant.selectedZone?.id}, Available: ${Constant.isZoneAvailable}');
//     } catch (e) {
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: ❌ Error - $e');
//       // Try fallback zone
//       await _setFallbackZone();
//       zoneCheckCompleted = true;
//       hasActuallyCheckedZone = true;
//       isLoadingFunction(false);
//       notifyListeners();
//
//       // PRODUCTION: Reload banners with zone ID even if fallback zone is used
//       print('[HOME_PROVIDER] ensureLocationAndZoneChecked: Reloading banners with fallback zone ID...');
//       unawaited(_loadBanners());
//     }
//   }
//
//   Future<void> _ensureUserLocationIsSet() async {
//     if (Constant.selectedLocation.location?.latitude != null &&
//         Constant.selectedLocation.location?.longitude != null) {
//       final currentAddress = Constant.selectedLocation.address ?? '';
//       final currentLocality = Constant.selectedLocation.locality ?? '';
//       final hasValidAddress =
//           currentAddress.isNotEmpty &&
//           currentAddress != 'Current Location' &&
//           !currentAddress.contains('Current Location');
//       final hasValidLocality =
//           currentLocality.isNotEmpty &&
//           currentLocality != 'Current Location' &&
//           !currentLocality.contains('Current Location');
//       if (hasValidAddress || hasValidLocality) {
//         return;
//       }
//     }
//     for (int attempt = 1; attempt <= 3; attempt++) {
//       if (Constant.userModel != null &&
//           Constant.userModel!.shippingAddress != null &&
//           Constant.userModel!.shippingAddress!.isNotEmpty) {
//         final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
//           (a) => a.isDefault == true,
//           orElse: () => Constant.userModel!.shippingAddress!.first,
//         );
//         if (defaultAddress.location?.latitude != null &&
//             defaultAddress.location?.longitude != null) {
//           Constant.selectedLocation = defaultAddress;
//           notifyListeners();
//           return;
//         }
//       }
//       try {
//         final box = GetStorage();
//         final savedLocation = box.read('user_location');
//         if (savedLocation != null &&
//             savedLocation['latitude'] != null &&
//             savedLocation['longitude'] != null) {
//           String savedAddress = savedLocation['address'] ?? '';
//           String savedLocality = savedLocation['locality'] ?? '';
//           final isAddressInvalid =
//               savedAddress.isEmpty ||
//               savedAddress == 'Current Location' ||
//               savedAddress.contains('Current Location');
//           final isLocalityInvalid =
//               savedLocality.isEmpty ||
//               savedLocality == 'Current Location' ||
//               savedLocality.contains('Current Location');
//           if (isAddressInvalid || isLocalityInvalid) {
//             try {
//               final gpsCacheInfo =
//                   await GpsLocationService.getCachedAddressInfo();
//               if (gpsCacheInfo != null &&
//                   gpsCacheInfo['address']?.isNotEmpty == true &&
//                   gpsCacheInfo['locality']?.isNotEmpty == true) {
//                 savedAddress = gpsCacheInfo['address']!;
//                 savedLocality = gpsCacheInfo['locality']!;
//                 print('[DEBUG] Using GPS cached address info');
//               } else {
//                 // If GPS cache doesn't have address, try to get it from coordinates
//                 final fullAddress =
//                     await GpsLocationService.getAddressFromCoordinates(
//                       savedLocation['latitude'],
//                       savedLocation['longitude'],
//                     );
//                 if (fullAddress.isNotEmpty) {
//                   savedAddress = fullAddress;
//                   savedLocality = fullAddress;
//                   print('[DEBUG] Got address from coordinates');
//                 } else {
//                   print('[DEBUG] Could not retrieve address from coordinates');
//                   if (savedAddress.isEmpty && savedLocality.isEmpty) {
//                     savedAddress = 'Current Location';
//                     savedLocality = 'Current Location';
//                   }
//                 }
//               }
//               await box.write('user_location', {
//                 'latitude': savedLocation['latitude'],
//                 'longitude': savedLocation['longitude'],
//                 'address': savedAddress,
//                 'locality': savedLocality,
//                 'timestamp': DateTime.now().millisecondsSinceEpoch,
//               });
//               notifyListeners();
//             } catch (e) {
//               print('[DEBUG] Error getting address info: $e');
//               // Only set "Current Location" if both are truly empty
//               if (savedAddress.isEmpty && savedLocality.isEmpty) {
//                 savedAddress = 'Current Location';
//                 savedLocality = 'Current Location';
//               }
//             }
//           }
//           Constant.selectedLocation = ShippingAddress(
//             addressAs: 'Home',
//             address: savedAddress,
//             location: UserLocation(
//               latitude: savedLocation['latitude'],
//               longitude: savedLocation['longitude'],
//             ),
//             locality: savedLocality,
//           );
//           notifyListeners();
//           return;
//         }
//       } catch (e) {
//         print("_ensureUserLocationIsSet $e}");
//       }
//       try {
//         final gpsLocation =
//             await GpsLocationService.getLocationForZoneDetection();
//         if (gpsLocation != null &&
//             gpsLocation['latitude'] != null &&
//             gpsLocation['longitude'] != null) {
//           final fullAddress =
//               await GpsLocationService.getAddressFromCoordinates(
//                 gpsLocation['latitude']!,
//                 gpsLocation['longitude']!,
//               );
//           String? detectedZoneId = await _detectZoneIdForCoordinates(
//             gpsLocation['latitude']!,
//             gpsLocation['longitude']!,
//           );
//           Constant.selectedLocation = ShippingAddress(
//             id: 'gps_location_${DateTime.now().millisecondsSinceEpoch}',
//             addressAs: 'Current Location',
//             address: fullAddress,
//             location: UserLocation(
//               latitude: gpsLocation['latitude']!,
//               longitude: gpsLocation['longitude']!,
//             ),
//             locality: fullAddress,
//             zoneId: detectedZoneId, // 🔑 Add detected zone ID
//           );
//           return;
//         }
//       } catch (e) {
//         print("_ensureUserLocationIsSet $e}");
//       }
//
//       if (Constant.userModel == null) {
//         await Future.delayed(Duration(milliseconds: 500));
//         continue;
//       }
//       if (attempt < 3) {
//         await Future.delayed(Duration(milliseconds: 300));
//       }
//     }
//     notifyListeners();
//   }
//
//   Future<String?> _detectZoneIdForCoordinates(
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       final zoneModel = await getCurrentZone(latitude, longitude);
//       if (zoneModel == null || zoneModel.zone == null) {
//         return null;
//       }
//       final zone = zoneModel.zone!;
//       if (zone.area != null && zone.area!.isNotEmpty) {
//         if (Constant.isPointInPolygon(
//           LatLng(latitude, longitude),
//           zone.area!.cast<GeoPoint>(),
//         )) {
//           return zone.id;
//         }
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   getData(BuildContext context) async {
//     await _loadAllDataInParallel(
//       context,
//       waitForSupplemental: true,
//       forceRefresh: true,
//     );
//   }
//
//   Future<void> getRefresh(BuildContext context) async {
//     await _loadAllDataInParallel(
//       context,
//       waitForSupplemental: true,
//       forceRefresh: true,
//       skipLocationSetup: true,
//     );
//   }
//
//   getFavouriteRestaurant() async {
//     if (Constant.userModel != null) {
//       await FavouriteProvider.getFavouriteRestaurants().then((value) {
//         favouriteList = value;
//         notifyListeners();
//       });
//     }
//   }
//
//   void bannerOnTapFunction(
//     BannerModel bannerModel,
//     RestaurantDetailsProvider restaurantDetailsProvider,
//   ) async {
//     stopBannerTimer();
//     if (bannerModel.redirectType == "store") {
//       ShowToastDialog.showLoader("Please wait");
//       VendorModel? vendorModel = await FireStoreUtils.getVendorById(
//         bannerModel.redirectId.toString(),
//       );
//       if (vendorModel?.zoneId == Constant.selectedZone?.id) {
//         ShowToastDialog.closeLoader();
//         restaurantDetailsProvider.initFunction(
//           vendorModels: vendorModel ?? VendorModel(),
//         );
//         Get.to(const RestaurantDetailsScreen());
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Sorry, The Zone is not available in your area. change the other location first.",
//         );
//       }
//     } else if (bannerModel.redirectType == "product") {
//       ShowToastDialog.showLoader("Please wait");
//       ProductModel? productModel = await FireStoreUtils.getProductById(
//         bannerModel.redirectId.toString(),
//       );
//       VendorModel? vendorModel = await FireStoreUtils.getVendorById(
//         productModel!.vendorID.toString(),
//       );
//       if (vendorModel!.zoneId == Constant.selectedZone!.id) {
//         ShowToastDialog.closeLoader();
//         restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
//         Get.to(const RestaurantDetailsScreen());
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Sorry, The Zone is not available in your area. change the other location first."
//               .tr,
//         );
//       }
//     } else if (bannerModel.redirectType == "external_link") {
//       final uri = Uri.parse(bannerModel.redirectId.toString());
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         ShowToastDialog.showToast("Could not launch".tr);
//       }
//     }
//     notifyListeners();
//   }
// }

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
        bannersFuture.timeout(const Duration(seconds: 5)),
        categoryFuture.timeout(const Duration(seconds: 5)),
      ], eagerError: true).catchError((_) {
        // Continue even if some requests fail
      });

      // Load restaurants if zone is available
      if (Constant.selectedZone?.id != null &&
          Constant.selectedZone!.id!.isNotEmpty) {
        unawaited(
          bestRestaurantProvider
              .loadRestaurantsAndRelatedData()
              .timeout(const Duration(seconds: 8))
              .catchError((e) {
                print('[HOME_PROVIDER] Restaurant load error: $e');
              }),
        );
      }

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
      notifyListeners();
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
    try {
      final savedZoneId = Preferences.getString(Preferences.selectedZoneId);
      if (savedZoneId.isNotEmpty) {
        Constant.selectedLocation.zoneId = savedZoneId;
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error loading zone ID from storage: $e');
    }
  }

  Future<void> changeLocationAddressFunction({
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

      // Reload data with new location
      await _reloadDataAfterLocationChange(context);

      print(
        '[HOME_PROVIDER] Location change completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      print('[HOME_PROVIDER] Error changing location: $e');
      ShowToastDialog.showToast("Failed to update location".tr);
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _reloadDataAfterLocationChange(BuildContext context) async {
    isLoadingFunction(true);

    try {
      // Get zone for new location
      await getZone();

      // Reload banners with new zone
      await _loadBanners();

      // Reload restaurants
      if (Constant.selectedZone?.id != null &&
          Constant.selectedZone!.id!.isNotEmpty) {
        await bestRestaurantProvider.loadRestaurantsAndRelatedData();
      }

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
        await _setFallbackZone();
        return;
      }

      final cacheKey = 'zone_${latitude}_${longitude}';
      final cachedZone = _getFromCache(cacheKey) as ZoneModel?;

      if (cachedZone != null && cachedZone.success == true) {
        _processZoneModel(cachedZone);
        return;
      }

      final zoneModel = await getCurrentZone(latitude, longitude);

      if (zoneModel != null && zoneModel.success == true) {
        _addToCache(cacheKey, zoneModel);
        _processZoneModel(zoneModel);
      } else {
        await _setFallbackZone();
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error getting zone: $e');
      await _setFallbackZone();
    } finally {
      _removeLoadingTask('getZone');
      zoneCheckCompleted = true;
      hasActuallyCheckedZone = true;
      notifyListeners();
    }
  }

  void _processZoneModel(ZoneModel zoneModel) {
    if (zoneModel.zone != null) {
      final detectedZone = convertToOldZoneModel(zoneModel);
      if (detectedZone != null) {
        Constant.selectedZone = detectedZone;
        Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;

        if (detectedZone.id != null && detectedZone.id!.isNotEmpty) {
          Constant.selectedLocation.zoneId = detectedZone.id;
          Preferences.setString(Preferences.selectedZoneId, detectedZone.id!);
        }

        // Load restaurants in background
        if (bestRestaurantProvider.allNearestRestaurant.isEmpty) {
          unawaited(bestRestaurantProvider.loadRestaurantsAndRelatedData());
        }
      }
    }
  }

  Future<void> _setFallbackZone() async {
    try {
      final cacheKey = 'fallback_zone';
      final cachedZone = _getFromCache(cacheKey) as Zone?;

      if (cachedZone != null) {
        Constant.selectedZone = cachedZone;
        Constant.isZoneAvailable = false;
        return;
      }

      final response = await http
          .get(Uri.parse('${AppConst.baseUrl}zones/all'), headers: headers)
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['zones'] != null &&
            data['zones'].isNotEmpty) {
          final firstZone = data['zones'][0];
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
            Constant.isZoneAvailable = false;
            Preferences.setString(
              Preferences.selectedZoneId,
              fallbackZoneModel.id!,
            );
            _addToCache(cacheKey, fallbackZoneModel);
          }
        }
      }
    } catch (e) {
      print('[HOME_PROVIDER] Error setting fallback zone: $e');
      Constant.selectedZone = null;
      Constant.isZoneAvailable = false;
      Preferences.setString(Preferences.selectedZoneId, '');
    }
  }

  List<Area> _convertToAreaList(dynamic areaData) {
    final List<Area> areaList = [];

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
      // Check if we have valid location already
      if (_hasValidLocation()) return;

      // Try to load from storage first (fastest)
      final storageLocation = await _loadLocationFromStorage();
      if (storageLocation != null) {
        Constant.selectedLocation = storageLocation;
        return;
      }

      // Try to get from user model
      if (Constant.userModel != null) {
        final userLocation = _getDefaultAddressFromUser();
        if (userLocation != null) {
          Constant.selectedLocation = userLocation;
          return;
        }
      }

      // Finally, try GPS
      await _getLocationFromGPS();
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

    // Clear cache for fresh data
    _clearCache();

    try {
      await Future.wait([
        _ensureUserLocationIsSet(),
        getZone(),
        _loadBanners(),
        categoryViewProvider.loadVendorCategories(),
        if (Constant.selectedZone?.id != null &&
            Constant.selectedZone!.id!.isNotEmpty)
          bestRestaurantProvider.loadRestaurantsAndRelatedData(),
      ], eagerError: true);
    } catch (e) {
      print('[HOME_PROVIDER] Refresh error: $e');
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
              print('[HOME_PROVIDER] Zone check timed out, using fallback');
              unawaited(_setFallbackZone());
            },
          );
        } catch (e) {
          print('[HOME_PROVIDER] Error getting zone: $e, using fallback');
          await _setFallbackZone();
        }
      } else {
        print('[HOME_PROVIDER] No valid location, setting fallback zone');
        await _setFallbackZone();
      }

      // If zone is still null after getZone, use fallback
      if (Constant.selectedZone == null) {
        print('[HOME_PROVIDER] Zone is null after getZone, setting fallback');
        await _setFallbackZone();
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
      // Try fallback zone
      try {
        await _setFallbackZone();
      } catch (fallbackError) {
        print('[HOME_PROVIDER] Fallback zone also failed: $fallbackError');
      }

      zoneCheckCompleted = true;
      hasActuallyCheckedZone = true;
      isLoadingFunction(false);
      notifyListeners();

      // Try to reload banners even if fallback failed
      unawaited(_loadBanners());
    } finally {
      stopwatch.stop();
    }
  }

  // Static helper methods (from original code - kept for compatibility)
  static Future<ZoneModel?> getCurrentZone(
    double latitude,
    double longitude,
  ) async {
    try {
      final headers = await getHeaders();
      final response = await http
          .get(
            Uri.parse(
              '${AppConst.baseUrl}zones/current?latitude=$latitude&longitude=$longitude',
            ),
            headers: headers,
          )
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        return zoneModelFromJson(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
