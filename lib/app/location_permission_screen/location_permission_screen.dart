// import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/location_permission_screen/provider/location_permission_provider.dart';
// import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/services/location_service.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:provider/provider.dart';
// import 'dart:math' as math;
//
// class LocationPermissionScreen extends StatelessWidget {
//   const LocationPermissionScreen({super.key});
//
//   /// Helper function to navigate to appropriate screen based on login status
//   static Future<void> navigateAfterLocationSet(
//     BuildContext context,
//     SplashProvider? splashProvider,
//   ) async {
//     try {
//       // Check if user is logged in
//       final apiToken = await SqlStorageConst.getAuthToken();
//       final userId = await SqlStorageConst.getFirebaseId();
//
//       if (apiToken != null &&
//           apiToken.isNotEmpty &&
//           userId != null &&
//           userId.isNotEmpty) {
//         // User is logged in, go to dashboard
//         if (splashProvider != null) {
//           splashProvider.refreshFunction(Get.context ?? context);
//         }
//         Get.offAll(const DashBoardScreen());
//       } else {
//         // User not logged in, go to login screen
//         Get.offAll(const PhoneNumberScreen());
//       }
//     } catch (e) {
//       print('[LOCATION_PERMISSION] Error in navigateAfterLocationSet: $e');
//       // Fallback to login screen
//       Get.offAll(const PhoneNumberScreen());
//     }
//   }
//
//   Future<void> updateLocationInLocal(UserLocation location) async {
//     final box = GetStorage();
//     box.write('user_location', {
//       'latitude': location.latitude,
//       'longitude': location.longitude,
//     });
//   }
//
//   /// Check if an address with similar coordinates already exists
//   /// Returns the existing address if found, null otherwise
//   /// Uses a tolerance of 0.001 degrees (approximately 100 meters)
//   ShippingAddress? findExistingAddress(
//     double latitude,
//     double longitude,
//     List<ShippingAddress>? existingAddresses,
//   ) {
//     if (existingAddresses == null || existingAddresses.isEmpty) {
//       return null;
//     }
//
//     const double tolerance = 0.001; // Approximately 100 meters
//
//     for (var address in existingAddresses) {
//       final addressLat = address.location?.latitude ?? address.latitude;
//       final addressLng = address.location?.longitude ?? address.longitude;
//
//       if (addressLat != null && addressLng != null) {
//         final latDiff = (addressLat - latitude).abs();
//         final lngDiff = (addressLng - longitude).abs();
//
//         if (latDiff <= tolerance && lngDiff <= tolerance) {
//           return address;
//         }
//       }
//     }
//
//     return null;
//   }
//
//   /// Calculate distance between two coordinates in kilometers using Haversine formula
//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double earthRadius = 6371; // Earth's radius in kilometers
//
//     final double dLat = _toRadians(lat2 - lat1);
//     final double dLon = _toRadians(lon2 - lon1);
//
//     final double a =
//         math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_toRadians(lat1)) *
//             math.cos(_toRadians(lat2)) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//
//     final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     final double distance = earthRadius * c;
//
//     return distance;
//   }
//
//   double _toRadians(double degrees) {
//     return degrees * (math.pi / 180);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Consumer<LocationPermissionProvider>(
//         builder: (context, controller, _) {
//           return Scaffold(
//             body: Container(
//               height: Responsive.height(100, context),
//               width: Responsive.width(100, context),
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage("assets/images/location_bg.png"),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 35,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text(
//                       "Enable Location Services 📍".tr,
//                       style: TextStyle(
//                         color: AppThemeData.grey900,
//                         fontSize: 22,
//                         fontFamily: AppThemeData.semiBold,
//                       ),
//                     ),
//                     Text(
//                       "To provide the best shopping experience, allow JippyMart to access your location."
//                           .tr,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: AppThemeData.grey900,
//                         fontSize: 16,
//                         fontFamily: AppThemeData.regular,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     Consumer<SplashProvider>(
//                       builder: (context, splashProvider, _) {
//                         return RoundedButtonFill(
//                           title: "Use Current Location".tr,
//                           color: AppThemeData.primary300,
//                           textColor: AppThemeData.grey50,
//                           onPress: () async {
//                             Constant.checkPermission(
//                               context: context,
//                               onTap: () async {
//                                 try {
//                                   bool success =
//                                       await LocationService.updateLocationAndNavigate(
//                                         showLoader: true,
//                                         showError: true,
//                                       );
//                                   if (success) {
//                                     // Check if user is logged in before navigating
//                                     final apiToken =
//                                         await SqlStorageConst.getAuthToken();
//                                     final userId =
//                                         await SqlStorageConst.getFirebaseId();
//
//                                     if (apiToken != null &&
//                                         apiToken.isNotEmpty &&
//                                         userId != null &&
//                                         userId.isNotEmpty) {
//                                       // User is logged in, go to dashboard
//                                       splashProvider.refreshFunction(
//                                         Get.context ?? context,
//                                       );
//                                       Get.offAll(const DashBoardScreen());
//                                     } else {
//                                       // User not logged in, go to login screen
//                                       Get.offAll(const PhoneNumberScreen());
//                                     }
//                                   }
//                                 } catch (e) {
//                                   print('[LOCATION_PERMISSION] Error: $e');
//                                   ShowToastDialog.showToast(
//                                     "Failed to get location. Please try again."
//                                         .tr,
//                                   );
//                                 }
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 10),
//                     Consumer<SplashProvider>(
//                       builder: (context, splashProvider, _) {
//                         return RoundedButtonFill(
//                           title: "Set From Map".tr,
//                           color: AppThemeData.primary300,
//                           textColor: AppThemeData.grey50,
//                           icon: Padding(
//                             padding: const EdgeInsets.only(right: 10),
//                             child: SvgPicture.asset(
//                               "assets/icons/ic_location_pin.svg",
//                               colorFilter: const ColorFilter.mode(
//                                 AppThemeData.grey50,
//                                 BlendMode.srcIn,
//                               ),
//                             ),
//                           ),
//                           isRight: false,
//                           onPress: () async {
//                             Constant.checkPermission(
//                               context: context,
//                               onTap: () async {
//                                 try {
//                                   final existingAddresses =
//                                       Constant.userModel?.shippingAddress;
//                                   if (Constant.selectedMapType == 'osm') {
//                                     final result = await Get.to(
//                                       () => MapPickerPage(),
//                                     );
//                                     if (result != null) {
//                                       final firstPlace = result;
//                                       final lat =
//                                           firstPlace.coordinates.latitude;
//                                       final lng =
//                                           firstPlace.coordinates.longitude;
//                                       final address = firstPlace.address;
//                                       ShippingAddress? existingAddress =
//                                           findExistingAddress(
//                                             lat,
//                                             lng,
//                                             existingAddresses,
//                                           );
//                                       ShippingAddress addressModel;
//                                       if (existingAddress != null) {
//                                         addressModel = existingAddress;
//                                         print(
//                                           '[LOCATION_PERMISSION] Using existing address: ${addressModel.id}',
//                                         );
//                                       } else {
//                                         addressModel = ShippingAddress(
//                                           id: Constant.getUuid(),
//                                           addressAs: "Home",
//                                           locality: address.toString(),
//                                           location: UserLocation(
//                                             latitude: lat,
//                                             longitude: lng,
//                                           ),
//                                           isDefault:
//                                               existingAddresses == null ||
//                                                   existingAddresses.isEmpty
//                                               ? true
//                                               : false,
//                                         );
//                                         if (Constant.userModel != null) {
//                                           final updatedAddresses =
//                                               List<ShippingAddress>.from(
//                                                 existingAddresses ?? [],
//                                               );
//                                           updatedAddresses.add(addressModel);
//                                           Constant.userModel!.shippingAddress =
//                                               updatedAddresses;
//                                           try {
//                                             final addressListProvider =
//                                                 Provider.of<
//                                                   AddressListProvider
//                                                 >(context, listen: false);
//                                             final homeProvider =
//                                                 Provider.of<HomeProvider>(
//                                                   context,
//                                                   listen: false,
//                                                 );
//                                             addressListProvider.userModel =
//                                                 Constant.userModel!;
//                                             addressListProvider
//                                                     .shippingAddressList =
//                                                 updatedAddresses;
//                                             // Update user via API and wait for completion
//                                             final updateSuccess =
//                                                 await addressListProvider
//                                                     .updateUser(
//                                                       Constant.userModel!,
//                                                     );
//                                             if (updateSuccess) {
//                                               final userId =
//                                                   await SqlStorageConst.getFirebaseId();
//                                               if (userId != null &&
//                                                   userId.isNotEmpty) {
//                                                 final refreshedUserModel =
//                                                     await AddressListProvider.getUserProfile(
//                                                       userId,
//                                                     );
//                                                 if (refreshedUserModel !=
//                                                     null) {
//                                                   Constant.userModel =
//                                                       refreshedUserModel;
//                                                   homeProvider
//                                                       .ensureUserModelIsLoaded();
//                                                   print(
//                                                     '[LOCATION_PERMISSION] User model refreshed from server with new address',
//                                                   );
//                                                 }
//                                               }
//                                             }
//                                             print(
//                                               '[LOCATION_PERMISSION] Address added to shipping addresses',
//                                             );
//                                           } catch (e) {
//                                             print(
//                                               '[LOCATION_PERMISSION] Error updating user with new address: $e',
//                                             );
//                                           }
//                                         }
//                                       }
//                                       Constant.selectedLocation = addressModel;
//                                       await updateLocationInLocal(
//                                         addressModel.location!,
//                                       );
//                                       // Navigate based on login status
//                                       await LocationPermissionScreen.navigateAfterLocationSet(
//                                         context,
//                                         splashProvider,
//                                       );
//                                     }
//                                   } else {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => PlacePicker(
//                                           apiKey: Constant.mapAPIKey,
//                                           onPlacePicked: (result) async {
//                                             final lat =
//                                                 result.geometry!.location.lat;
//                                             final lng =
//                                                 result.geometry!.location.lng;
//                                             final formattedAddress = result
//                                                 .formattedAddress!
//                                                 .toString();
//
//                                             // Check if address already exists
//                                             ShippingAddress? existingAddress =
//                                                 findExistingAddress(
//                                                   lat,
//                                                   lng,
//                                                   existingAddresses,
//                                                 );
//
//                                             ShippingAddress addressModel;
//                                             if (existingAddress != null) {
//                                               // Use existing address
//                                               addressModel = existingAddress;
//                                               print(
//                                                 '[LOCATION_PERMISSION] Using existing address: ${addressModel.id}',
//                                               );
//                                             } else {
//                                               // Create new address and add to list
//                                               addressModel = ShippingAddress(
//                                                 id: Constant.getUuid(),
//                                                 addressAs: "Home",
//                                                 locality: formattedAddress,
//                                                 location: UserLocation(
//                                                   latitude: lat,
//                                                   longitude: lng,
//                                                 ),
//                                                 isDefault:
//                                                     existingAddresses == null ||
//                                                         existingAddresses
//                                                             .isEmpty
//                                                     ? true
//                                                     : false,
//                                               );
//
//                                               // Add to user's shipping addresses
//                                               if (Constant.userModel != null) {
//                                                 final updatedAddresses =
//                                                     List<ShippingAddress>.from(
//                                                       existingAddresses ?? [],
//                                                     );
//                                                 updatedAddresses.add(
//                                                   addressModel,
//                                                 );
//                                                 Constant
//                                                         .userModel!
//                                                         .shippingAddress =
//                                                     updatedAddresses;
//
//                                                 // Update user profile with new address
//                                                 try {
//                                                   final addressListProvider =
//                                                       Provider.of<
//                                                         AddressListProvider
//                                                       >(context, listen: false);
//                                                   final homeProvider =
//                                                       Provider.of<HomeProvider>(
//                                                         context,
//                                                         listen: false,
//                                                       );
//                                                   addressListProvider
//                                                           .userModel =
//                                                       Constant.userModel!;
//                                                   addressListProvider
//                                                           .shippingAddressList =
//                                                       updatedAddresses;
//
//                                                   // Update user via API and wait for completion
//                                                   final updateSuccess =
//                                                       await addressListProvider
//                                                           .updateUser(
//                                                             Constant.userModel!,
//                                                           );
//
//                                                   if (updateSuccess) {
//                                                     // Force refresh user model from server to ensure latest data
//                                                     final userId =
//                                                         await SqlStorageConst.getFirebaseId();
//                                                     if (userId != null &&
//                                                         userId.isNotEmpty) {
//                                                       final refreshedUserModel =
//                                                           await AddressListProvider.getUserProfile(
//                                                             userId,
//                                                           );
//                                                       if (refreshedUserModel !=
//                                                           null) {
//                                                         Constant.userModel =
//                                                             refreshedUserModel;
//                                                         homeProvider
//                                                             .ensureUserModelIsLoaded();
//                                                         print(
//                                                           '[LOCATION_PERMISSION] User model refreshed from server with new address',
//                                                         );
//                                                       }
//                                                     }
//                                                   }
//                                                   print(
//                                                     '[LOCATION_PERMISSION] Address added to shipping addresses',
//                                                   );
//                                                 } catch (e) {
//                                                   print(
//                                                     '[LOCATION_PERMISSION] Error updating user with new address: $e',
//                                                   );
//                                                 }
//                                               }
//                                             }
//
//                                             Constant.selectedLocation =
//                                                 addressModel;
//                                             await updateLocationInLocal(
//                                               addressModel.location!,
//                                             );
//                                             // Navigate based on login status
//                                             await LocationPermissionScreen.navigateAfterLocationSet(
//                                               context,
//                                               splashProvider,
//                                             );
//                                           },
//                                           initialPosition: const LatLng(
//                                             -33.8567844,
//                                             151.213108,
//                                           ),
//                                           useCurrentLocation: true,
//                                           selectInitialPosition: true,
//                                           usePinPointingSearch: true,
//                                           usePlaceDetailSearch: true,
//                                           zoomGesturesEnabled: true,
//                                           zoomControlsEnabled: true,
//                                           resizeToAvoidBottomInset: false,
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 } catch (e) {
//                                   print(
//                                     '[LOCATION_PERMISSION] Error in Add Location: $e',
//                                   );
//                                   ShowToastDialog.showToast(
//                                     "Failed to add location. Please try again."
//                                         .tr,
//                                   );
//                                 }
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 10),
//                     Constant.userModel == null
//                         ? const SizedBox()
//                         : Consumer2<AddressListProvider, HomeProvider>(
//                             builder: (context, addressListProvider, homeProvider, _) {
//                               return RoundedButtonFill(
//                                 title: "Enter Manually location".tr,
//                                 color: AppThemeData.primary300,
//                                 textColor: AppThemeData.grey50,
//                                 isRight: false,
//                                 onPress: () async {
//                                   addressListProvider.initFunction(
//                                     context: context,
//                                   );
//                                   Get.to(const AddressListScreen())?.then((
//                                     value,
//                                   ) async {
//                                     if (value != null) {
//                                       homeProvider
//                                           .changeLocationAddressFunction(
//                                             addressModel: value,
//                                             context: Get.context ?? context,
//                                           );
//                                       // Navigate based on login status
//                                       final splashProvider =
//                                           Provider.of<SplashProvider>(
//                                             Get.context ?? context,
//                                             listen: false,
//                                           );
//                                       await LocationPermissionScreen.navigateAfterLocationSet(
//                                         Get.context ?? context,
//                                         splashProvider,
//                                       );
//                                     }
//                                   });
//                                   // Get.to(const AddressListScreen())!.then((
//                                   //   value,
//                                   // ) async {
//                                   //   if (value != null) {
//                                   //     ShippingAddress addressModel = value;
//                                   //     Constant.selectedLocation = addressModel;
//                                   //     await updateLocationInLocal(
//                                   //       addressModel.location!,
//                                   //     );
//                                   //     Get.offAll(const DashBoardScreen());
//                                   //   }
//                                   // });
//                                 },
//                               );
//                             },
//                           ),
//                     const SizedBox(height: 10),
//                     Consumer<SplashProvider>(
//                       builder: (contexts, splashProvider, _) {
//                         return RoundedButtonFill(
//                           title: "Change Location".tr,
//                           color: AppThemeData.primary300,
//                           textColor: AppThemeData.grey50,
//                           onPress: () async {
//                             Constant.checkPermission(
//                               context: context,
//                               onTap: () async {
//                                 try {
//                                   bool success =
//                                       await LocationService.updateLocationAndNavigate(
//                                         showLoader: true,
//                                         showError: true,
//                                       );
//
//                                   if (success) {
//                                     // Navigate based on login status
//                                     await LocationPermissionScreen.navigateAfterLocationSet(
//                                       context,
//                                       splashProvider,
//                                     );
//                                   }
//                                 } catch (e) {
//                                   print(
//                                     '[LOCATION_PERMISSION] Error in Change Location: $e',
//                                   );
//                                   ShowToastDialog.showToast(
//                                     "Failed to change location. Please try again."
//                                         .tr,
//                                   );
//                                 }
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/location_permission_screen/provider/location_permission_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/location_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:jippymart_customer/widget/osm_map/place_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  /// Simplified optimized navigation
  static Future<void> navigateAfterLocationSet(
    BuildContext context,
    SplashProvider? splashProvider,
  ) async {
    try {
      // Quick cache check first (fastest path)
      final box = GetStorage();
      final cachedAuth = box.read('cached_auth_check');

      if (cachedAuth != null) {
        final cachedTime = DateTime.parse(cachedAuth['timestamp']);
        // Cache valid for 1 minute
        if (DateTime.now().difference(cachedTime) <
            const Duration(minutes: 1)) {
          if (cachedAuth['hasAuth'] == true) {
            Get.offAll(const DashBoardScreen());
            return;
          } else {
            Get.offAll(const PhoneNumberScreen());
            return;
          }
        }
      }

      // Original logic
      final apiToken = await SqlStorageConst.getAuthToken();
      final userId = await SqlStorageConst.getFirebaseId();

      if (apiToken != null &&
          apiToken.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        // Cache the result for next time
        box.write('cached_auth_check', {
          'hasAuth': true,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (splashProvider != null) {
          // Start refresh in background, don't wait for it
          Future.microtask(() {
            try {
              splashProvider.refreshFunction(context);
            } catch (e) {
              print('[BACKGROUND_REFRESH] Error: $e');
            }
          });
        }
        Get.offAll(const DashBoardScreen());
      } else {
        // Cache negative result
        box.write('cached_auth_check', {
          'hasAuth': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
        Get.offAll(const PhoneNumberScreen());
      }
    } catch (e) {
      print('[LOCATION_PERMISSION] Error: $e');
      Get.offAll(const PhoneNumberScreen());
    }
  }

  /// Optimized location update with simple cache
  Future<void> updateLocationInLocal(UserLocation location) async {
    final box = GetStorage();
    box.write('user_location', {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Also save to Preferences for consistency
    await Preferences.setString(
      Preferences.selectedLocationLat,
      location.latitude.toString(),
    );
    await Preferences.setString(
      Preferences.selectedLocationLng,
      location.longitude.toString(),
    );
  }
  
  /// Cache zone data after zone is set
  static Future<void> cacheZoneData() async {
    try {
      final box = GetStorage();
      
      // Cache zone availability status
      box.write('zone_data', {
        'isZoneAvailable': Constant.isZoneAvailable,
        'zoneId': Constant.selectedZone?.id ?? Constant.selectedLocation.zoneId ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Also ensure zone ID is stored in Preferences
      final zoneId = Constant.selectedZone?.id ?? Constant.selectedLocation.zoneId;
      if (zoneId != null && zoneId.isNotEmpty) {
        await Preferences.setString(Preferences.selectedZoneId, zoneId);
        print('[LOCATION_PERMISSION] ✅ Cached zone ID: $zoneId');
      }
      
      // Cache location with zone info
      if (Constant.selectedLocation.location != null) {
        final location = Constant.selectedLocation.location!;
        box.write('user_location', {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'zoneId': zoneId ?? '',
          'isZoneAvailable': Constant.isZoneAvailable,
          'address': Constant.selectedLocation.address ?? Constant.selectedLocation.locality ?? '',
          'locality': Constant.selectedLocation.locality ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('[LOCATION_PERMISSION] ✅ Cached location with zone data');
      }
    } catch (e) {
      print('[LOCATION_PERMISSION] Error caching zone data: $e');
    }
  }

  /// Fast address finder with tolerance
  ShippingAddress? findExistingAddress(
    double latitude,
    double longitude,
    List<ShippingAddress>? existingAddresses,
  ) {
    if (existingAddresses == null || existingAddresses.isEmpty) {
      return null;
    }

    const double tolerance = 0.001; // ~100 meters

    for (var address in existingAddresses) {
      final addressLat = address.location?.latitude ?? address.latitude;
      final addressLng = address.location?.longitude ?? address.longitude;

      if (addressLat != null && addressLng != null) {
        final latDiff = (addressLat - latitude).abs();
        final lngDiff = (addressLng - longitude).abs();

        if (latDiff <= tolerance && lngDiff <= tolerance) {
          return address;
        }
      }
    }

    return null;
  }

  /// Simple debounce tracker
  static DateTime? _lastTapTime;

  static bool _shouldProcessTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      return false;
    }
    _lastTapTime = now;
    return true;
  }

  /// Optimized map selection handler
  Future<void> _handleMapSelection(
    BuildContext context,
    dynamic result,
    List<ShippingAddress>? existingAddresses,
    SplashProvider splashProvider,
  ) async {
    // Check if result is null (user cancelled)
    if (result == null) {
      print('[MAP_SELECTION] User cancelled map selection');
      return;
    }

    try {
      double? lat;
      double? lng;
      String? address;

      // Handle different result types - OSM MapPickerPage returns PlaceModel
      // Google Maps PlacePicker returns PickResult
      try {
        // Try OSM PlaceModel format first
        if (result is PlaceModel) {
          lat = result.coordinates.latitude;
          lng = result.coordinates.longitude;
          address = result.address;
        } 
        // Try accessing as dynamic for OSM format (in case type checking fails)
        else {
          try {
            final dynamicResult = result as dynamic;
            if (dynamicResult.coordinates != null) {
              final coords = dynamicResult.coordinates;
              lat = coords.latitude?.toDouble() ?? 
                    (coords.latitude is double ? coords.latitude : null);
              lng = coords.longitude?.toDouble() ?? 
                    (coords.longitude is double ? coords.longitude : null);
              address = dynamicResult.address?.toString() ?? dynamicResult.address;
            }
          } catch (e) {
            // Try Google Maps PickResult format
            try {
              final dynamicResult = result as dynamic;
              if (dynamicResult.geometry != null && 
                  dynamicResult.geometry.location != null) {
                final loc = dynamicResult.geometry.location;
                lat = loc.lat?.toDouble() ?? 
                      (loc.lat is double ? loc.lat : null);
                lng = loc.lng?.toDouble() ?? 
                      (loc.lng is double ? loc.lng : null);
                address = dynamicResult.formattedAddress?.toString();
              }
            } catch (e2) {
              print('[MAP_SELECTION] Error accessing both formats: $e2');
            }
          }
        }
      } catch (e) {
        print('[MAP_SELECTION] Error parsing result: $e');
        print('[MAP_SELECTION] Result type: ${result.runtimeType}');
        print('[MAP_SELECTION] Result: $result');
        ShowToastDialog.showToast("Invalid location data received".tr);
        return;
      }

      if (lat == null || lng == null) {
        print('[MAP_SELECTION] Missing coordinates: lat=$lat, lng=$lng');
        print('[MAP_SELECTION] Result type: ${result.runtimeType}');
        print('[MAP_SELECTION] Result: $result');
        ShowToastDialog.showToast("Invalid location selected".tr);
        return;
      }

      // Check for existing address
      final existingAddress = findExistingAddress(lat, lng, existingAddresses);

      ShippingAddress addressModel;
      if (existingAddress != null) {
        addressModel = existingAddress;
      } else {
        addressModel = ShippingAddress(
          id: Constant.getUuid(),
          addressAs: "Home",
          locality: address ?? "Unknown location",
          location: UserLocation(latitude: lat, longitude: lng),
          isDefault: existingAddresses == null || existingAddresses.isEmpty,
        );

        // Update user model locally if it exists
        if (Constant.userModel != null) {
          final updatedAddresses = List<ShippingAddress>.from(
            existingAddresses ?? [],
          );
          updatedAddresses.add(addressModel);
          Constant.userModel!.shippingAddress = updatedAddresses;

          // Update server in background if possible
          try {
            final addressListProvider = Provider.of<AddressListProvider>(
              context,
              listen: false,
            );

            // Update local provider state
            addressListProvider.userModel = Constant.userModel!;
            addressListProvider.shippingAddressList = updatedAddresses;

            // Try to update server in background (non-blocking)
            Future.microtask(() async {
              try {
                await addressListProvider.updateUser(Constant.userModel!);
              } catch (e) {
                print('[BACKGROUND_UPDATE] Error: $e');
              }
            });
          } catch (e) {
            print('[LOCAL_UPDATE] Error: $e');
          }
        }
      }

      Constant.selectedLocation = addressModel;
      await updateLocationInLocal(addressModel.location!);

      // Check zone after setting location
      try {
        final currentContext = Get.context ?? context;
        
        final homeProvider = Provider.of<HomeProvider>(
          currentContext,
          listen: false,
        );
        await homeProvider.getZone();
        
        // Cache zone data after zone is set
        await LocationPermissionScreen.cacheZoneData();
        
        // Reload banners after zone is set
        await homeProvider.reloadBanners();

        // Navigate immediately
        await LocationPermissionScreen.navigateAfterLocationSet(
          currentContext,
          splashProvider,
        );
      } catch (zoneError) {
        print('[MAP_SELECTION] Error checking zone: $zoneError');
        // Even if zone check fails, try to navigate
        try {
          final currentContext = Get.context ?? context;
          await LocationPermissionScreen.navigateAfterLocationSet(
            currentContext,
            splashProvider,
          );
        } catch (navError) {
          print('[MAP_SELECTION] Error navigating: $navError');
          // If navigation fails, show error to user
          ShowToastDialog.showToast("Location set but navigation failed. Please restart the app.".tr);
        }
      }
    } catch (e, stackTrace) {
      print('[MAP_SELECTION] Error: $e');
      print('[MAP_SELECTION] Stack trace: $stackTrace');
      ShowToastDialog.showToast("Failed to process location. Please try again.".tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<LocationPermissionProvider>(
        builder: (context, controller, _) {
          return Scaffold(
            body: Container(
              height: Responsive.height(100, context),
              width: Responsive.width(100, context),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/location_bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 35,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Enable Location Services 📍".tr,
                      style: TextStyle(
                        color: AppThemeData.grey900,
                        fontSize: 22,
                        fontFamily: AppThemeData.semiBold,
                      ),
                    ),
                    Text(
                      "To provide the best shopping experience, allow JippyMart to access your location."
                          .tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemeData.grey900,
                        fontSize: 16,
                        fontFamily: AppThemeData.regular,
                      ),
                    ),
                    const SizedBox(height: 32),
                    RoundedButtonFill(
                      title: "Use Current Location".tr,
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (!_shouldProcessTap()) return;

                        Constant.checkPermission(
                          context: context,
                          onTap: () async {
                            try {
                              bool success =
                                  await LocationService.updateLocationAndNavigate(
                                    showLoader: true,
                                    showError: true,
                                  );
                              if (success) {
                                // Check zone after setting location
                                final homeProvider =
                                    Provider.of<HomeProvider>(
                                  Get.context ?? context,
                                  listen: false,
                                );
                                await homeProvider.getZone();
                                
                                // Cache zone data after zone is set
                                await LocationPermissionScreen.cacheZoneData();
                                
                                // Reload banners after zone is set
                                await homeProvider.reloadBanners();
                                
                                final splashProvider =
                                    Provider.of<SplashProvider>(
                                  Get.context ?? context,
                                  listen: false,
                                );
                                await LocationPermissionScreen.navigateAfterLocationSet(
                                  Get.context ?? context,
                                  splashProvider,
                                );
                              }
                            } catch (e) {
                              print('[CURRENT_LOCATION] Error: $e');
                              ShowToastDialog.showToast(
                                "Failed to get location. Please try again."
                                    .tr,
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    RoundedButtonFill(
                      title: "Set From Map".tr,
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SvgPicture.asset(
                          "assets/icons/ic_location_pin.svg",
                          colorFilter: const ColorFilter.mode(
                            AppThemeData.grey50,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      isRight: false,
                      onPress: () async {
                        if (!_shouldProcessTap()) return;

                        Constant.checkPermission(
                          context: context,
                          onTap: () async {
                            try {
                              final existingAddresses =
                                  Constant.userModel?.shippingAddress;

                              final splashProvider =
                                  Provider.of<SplashProvider>(
                                Get.context ?? context,
                                listen: false,
                              );

                              if (Constant.selectedMapType == 'osm') {
                                final result = await Get.to(
                                  () => MapPickerPage(),
                                );
                                // Only process if result is not null (user selected a location)
                                if (result != null) {
                                  await _handleMapSelection(
                                    Get.context ?? context,
                                    result,
                                    existingAddresses,
                                    splashProvider,
                                  );
                                }
                              } else {
                                Navigator.push(
                                  Get.context ?? context,
                                  MaterialPageRoute(
                                    builder: (context) => PlacePicker(
                                      apiKey: Constant.mapAPIKey,
                                      onPlacePicked: (result) async {
                                        // Only process if result is not null
                                        if (result != null) {
                                          await _handleMapSelection(
                                            Get.context ?? context,
                                            result,
                                            existingAddresses,
                                            splashProvider,
                                          );
                                        }
                                      },
                                      initialPosition: const LatLng(
                                        -33.8567844,
                                        151.213108,
                                      ),
                                      useCurrentLocation: true,
                                      selectInitialPosition: true,
                                      usePinPointingSearch: true,
                                      usePlaceDetailSearch: true,
                                      zoomGesturesEnabled: true,
                                      zoomControlsEnabled: true,
                                      resizeToAvoidBottomInset: false,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('[SET_FROM_MAP] Error: $e');
                              ShowToastDialog.showToast(
                                "Failed to add location. Please try again."
                                    .tr,
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Constant.userModel == null
                        ? const SizedBox()
                        : Consumer2<AddressListProvider, HomeProvider>(
                            builder:
                                (
                                  context,
                                  addressListProvider,
                                  homeProvider,
                                  _,
                                ) {
                                  return RoundedButtonFill(
                                    title: "Enter Manually location".tr,
                                    color: AppThemeData.primary300,
                                    textColor: AppThemeData.grey50,
                                    isRight: false,
                                    onPress: () async {
                                      if (!_shouldProcessTap()) return;

                                      addressListProvider.initFunction(
                                        context: context,
                                      );

                                      final result = await Get.to(
                                        const AddressListScreen(),
                                      );
                                      if (result != null &&
                                          result is ShippingAddress) {
                                        homeProvider
                                            .changeLocationAddressFunction(
                                              addressModel: result,
                                              context: Get.context ?? context,
                                            );

                                        final splashProvider =
                                            Provider.of<SplashProvider>(
                                              Get.context ?? context,
                                              listen: false,
                                            );
                                        await LocationPermissionScreen.navigateAfterLocationSet(
                                          Get.context ?? context,
                                          splashProvider,
                                        );
                                      }
                                    },
                                  );
                                },
                          ),
                    const SizedBox(height: 10),
                    RoundedButtonFill(
                      title: "Change Location".tr,
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (!_shouldProcessTap()) return;

                        Constant.checkPermission(
                          context: context,
                          onTap: () async {
                            try {
                              bool success =
                                  await LocationService.updateLocationAndNavigate(
                                    showLoader: true,
                                    showError: true,
                                  );

                              if (success) {
                                // Check zone after setting location
                                final homeProvider =
                                    Provider.of<HomeProvider>(
                                  Get.context ?? context,
                                  listen: false,
                                );
                                await homeProvider.getZone();
                                
                                // Cache zone data after zone is set
                                await LocationPermissionScreen.cacheZoneData();
                                
                                // Reload banners after zone is set
                                await homeProvider.reloadBanners();
                                
                                final splashProvider =
                                    Provider.of<SplashProvider>(
                                  Get.context ?? context,
                                  listen: false,
                                );
                                await LocationPermissionScreen.navigateAfterLocationSet(
                                  Get.context ?? context,
                                  splashProvider,
                                );
                              }
                            } catch (e) {
                              print('[CHANGE_LOCATION] Error: $e');
                              ShowToastDialog.showToast(
                                "Failed to change location. Please try again."
                                    .tr,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
