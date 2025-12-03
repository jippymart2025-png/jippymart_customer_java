import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
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
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  Future<void> updateLocationInLocal(UserLocation location) async {
    final box = GetStorage();
    box.write('user_location', {
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
  }

  /// Check if an address with similar coordinates already exists
  /// Returns the existing address if found, null otherwise
  /// Uses a tolerance of 0.001 degrees (approximately 100 meters)
  ShippingAddress? findExistingAddress(
    double latitude,
    double longitude,
    List<ShippingAddress>? existingAddresses,
  ) {
    if (existingAddresses == null || existingAddresses.isEmpty) {
      return null;
    }

    const double tolerance = 0.001; // Approximately 100 meters

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

  /// Calculate distance between two coordinates in kilometers using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
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
                    Consumer<SplashProvider>(
                      builder: (context, splashProvider, _) {
                        return RoundedButtonFill(
                          title: "Use Current Location".tr,
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: () async {
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
                                    splashProvider.refreshFunction(
                                      Get.context ?? context,
                                    );
                                    Get.offAll(const DashBoardScreen());
                                  }
                                } catch (e) {
                                  print('[LOCATION_PERMISSION] Error: $e');
                                  ShowToastDialog.showToast(
                                    "Failed to get location. Please try again."
                                        .tr,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Consumer<SplashProvider>(
                      builder: (context, splashProvider, _) {
                        return RoundedButtonFill(
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
                            Constant.checkPermission(
                              context: context,
                              onTap: () async {
                                try {
                                  final existingAddresses =
                                      Constant.userModel?.shippingAddress;
                                  if (Constant.selectedMapType == 'osm') {
                                    final result = await Get.to(
                                      () => MapPickerPage(),
                                    );
                                    if (result != null) {
                                      final firstPlace = result;
                                      final lat =
                                          firstPlace.coordinates.latitude;
                                      final lng =
                                          firstPlace.coordinates.longitude;
                                      final address = firstPlace.address;
                                      ShippingAddress? existingAddress =
                                          findExistingAddress(
                                            lat,
                                            lng,
                                            existingAddresses,
                                          );
                                      ShippingAddress addressModel;
                                      if (existingAddress != null) {
                                        addressModel = existingAddress;
                                        print(
                                          '[LOCATION_PERMISSION] Using existing address: ${addressModel.id}',
                                        );
                                      } else {
                                        addressModel = ShippingAddress(
                                          id: Constant.getUuid(),
                                          addressAs: "Home",
                                          locality: address.toString(),
                                          location: UserLocation(
                                            latitude: lat,
                                            longitude: lng,
                                          ),
                                          isDefault:
                                              existingAddresses == null ||
                                                  existingAddresses.isEmpty
                                              ? true
                                              : false,
                                        );
                                        if (Constant.userModel != null) {
                                          final updatedAddresses =
                                              List<ShippingAddress>.from(
                                                existingAddresses ?? [],
                                              );
                                          updatedAddresses.add(addressModel);
                                          Constant.userModel!.shippingAddress =
                                              updatedAddresses;
                                          try {
                                            final addressListProvider =
                                                Provider.of<
                                                  AddressListProvider
                                                >(context, listen: false);
                                            final homeProvider =
                                                Provider.of<HomeProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            addressListProvider.userModel =
                                                Constant.userModel!;
                                            addressListProvider
                                                    .shippingAddressList =
                                                updatedAddresses;
                                            // Update user via API and wait for completion
                                            final updateSuccess =
                                                await addressListProvider
                                                    .updateUser(
                                                      Constant.userModel!,
                                                    );
                                            if (updateSuccess) {
                                              final userId =
                                                  await SqlStorageConst.getFirebaseId();
                                              if (userId != null &&
                                                  userId.isNotEmpty) {
                                                final refreshedUserModel =
                                                    await AddressListProvider.getUserProfile(
                                                      userId,
                                                    );
                                                if (refreshedUserModel !=
                                                    null) {
                                                  Constant.userModel =
                                                      refreshedUserModel;
                                                  homeProvider
                                                      .ensureUserModelIsLoaded();
                                                  print(
                                                    '[LOCATION_PERMISSION] User model refreshed from server with new address',
                                                  );
                                                }
                                              }
                                            }
                                            print(
                                              '[LOCATION_PERMISSION] Address added to shipping addresses',
                                            );
                                          } catch (e) {
                                            print(
                                              '[LOCATION_PERMISSION] Error updating user with new address: $e',
                                            );
                                          }
                                        }
                                      }
                                      Constant.selectedLocation = addressModel;
                                      await updateLocationInLocal(
                                        addressModel.location!,
                                      );
                                      splashProvider.refreshFunction(
                                        Get.context ?? context,
                                      );
                                      Get.offAll(const DashBoardScreen());
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlacePicker(
                                          apiKey: Constant.mapAPIKey,
                                          onPlacePicked: (result) async {
                                            final lat =
                                                result.geometry!.location.lat;
                                            final lng =
                                                result.geometry!.location.lng;
                                            final formattedAddress = result
                                                .formattedAddress!
                                                .toString();

                                            // Check if address already exists
                                            ShippingAddress? existingAddress =
                                                findExistingAddress(
                                                  lat,
                                                  lng,
                                                  existingAddresses,
                                                );

                                            ShippingAddress addressModel;
                                            if (existingAddress != null) {
                                              // Use existing address
                                              addressModel = existingAddress;
                                              print(
                                                '[LOCATION_PERMISSION] Using existing address: ${addressModel.id}',
                                              );
                                            } else {
                                              // Create new address and add to list
                                              addressModel = ShippingAddress(
                                                id: Constant.getUuid(),
                                                addressAs: "Home",
                                                locality: formattedAddress,
                                                location: UserLocation(
                                                  latitude: lat,
                                                  longitude: lng,
                                                ),
                                                isDefault:
                                                    existingAddresses == null ||
                                                        existingAddresses
                                                            .isEmpty
                                                    ? true
                                                    : false,
                                              );

                                              // Add to user's shipping addresses
                                              if (Constant.userModel != null) {
                                                final updatedAddresses =
                                                    List<ShippingAddress>.from(
                                                      existingAddresses ?? [],
                                                    );
                                                updatedAddresses.add(
                                                  addressModel,
                                                );
                                                Constant
                                                        .userModel!
                                                        .shippingAddress =
                                                    updatedAddresses;

                                                // Update user profile with new address
                                                try {
                                                  final addressListProvider =
                                                      Provider.of<
                                                        AddressListProvider
                                                      >(context, listen: false);
                                                  final homeProvider =
                                                      Provider.of<HomeProvider>(
                                                        context,
                                                        listen: false,
                                                      );
                                                  addressListProvider
                                                          .userModel =
                                                      Constant.userModel!;
                                                  addressListProvider
                                                          .shippingAddressList =
                                                      updatedAddresses;

                                                  // Update user via API and wait for completion
                                                  final updateSuccess =
                                                      await addressListProvider
                                                          .updateUser(
                                                            Constant.userModel!,
                                                          );

                                                  if (updateSuccess) {
                                                    // Force refresh user model from server to ensure latest data
                                                    final userId =
                                                        await SqlStorageConst.getFirebaseId();
                                                    if (userId != null &&
                                                        userId.isNotEmpty) {
                                                      final refreshedUserModel =
                                                          await AddressListProvider.getUserProfile(
                                                            userId,
                                                          );
                                                      if (refreshedUserModel !=
                                                          null) {
                                                        Constant.userModel =
                                                            refreshedUserModel;
                                                        homeProvider
                                                            .ensureUserModelIsLoaded();
                                                        print(
                                                          '[LOCATION_PERMISSION] User model refreshed from server with new address',
                                                        );
                                                      }
                                                    }
                                                  }
                                                  print(
                                                    '[LOCATION_PERMISSION] Address added to shipping addresses',
                                                  );
                                                } catch (e) {
                                                  print(
                                                    '[LOCATION_PERMISSION] Error updating user with new address: $e',
                                                  );
                                                }
                                              }
                                            }

                                            Constant.selectedLocation =
                                                addressModel;
                                            await updateLocationInLocal(
                                              addressModel.location!,
                                            );
                                            splashProvider.refreshFunction(
                                              Get.context ?? context,
                                            );
                                            Get.offAll(const DashBoardScreen());
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
                                  print(
                                    '[LOCATION_PERMISSION] Error in Add Location: $e',
                                  );
                                  ShowToastDialog.showToast(
                                    "Failed to add location. Please try again."
                                        .tr,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Constant.userModel == null
                        ? const SizedBox()
                        : Consumer2<AddressListProvider, HomeProvider>(
                            builder: (context, addressListProvider, homeProvider, _) {
                              return RoundedButtonFill(
                                title: "Enter Manually location".tr,
                                color: AppThemeData.primary300,
                                textColor: AppThemeData.grey50,
                                isRight: false,
                                onPress: () async {
                                  addressListProvider.initFunction(
                                    context: context,
                                  );
                                  Get.to(const AddressListScreen())?.then((
                                    value,
                                  ) {
                                    if (value != null) {
                                      homeProvider
                                          .changeLocationAddressFunction(
                                            addressModel: value,
                                            context: Get.context ?? context,
                                          );
                                      Get.offAll(const DashBoardScreen());
                                    }
                                  });
                                  // Get.to(const AddressListScreen())!.then((
                                  //   value,
                                  // ) async {
                                  //   if (value != null) {
                                  //     ShippingAddress addressModel = value;
                                  //     Constant.selectedLocation = addressModel;
                                  //     await updateLocationInLocal(
                                  //       addressModel.location!,
                                  //     );
                                  //     Get.offAll(const DashBoardScreen());
                                  //   }
                                  // });
                                },
                              );
                            },
                          ),
                    const SizedBox(height: 10),
                    Consumer<SplashProvider>(
                      builder: (contexts, splashProvider, _) {
                        return RoundedButtonFill(
                          title: "Change Location".tr,
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: () async {
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
                                    splashProvider.refreshFunction(
                                      Get.context ?? context,
                                    );
                                    Get.offAll(const DashBoardScreen());
                                  }
                                } catch (e) {
                                  print(
                                    '[LOCATION_PERMISSION] Error in Change Location: $e',
                                  );
                                  ShowToastDialog.showToast(
                                    "Failed to change location. Please try again."
                                        .tr,
                                  );
                                }
                              },
                            );
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
