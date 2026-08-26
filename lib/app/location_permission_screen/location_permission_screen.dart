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
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:jippymart_customer/widget/osm_map/place_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';
import '../address_screens/screens/address_list_screen.dart';

// ─── Design tokens (match home screen) ───────────────────────────────────────

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  // ── All original static/instance methods preserved exactly ────────────────

  /// Runs zones/current for the selected location. Returns true only when in zone.
  static Future<bool> finalizeLocationWithZoneCheck(
    BuildContext context,
  ) async {
    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final locProvider = Provider.of<LocationPermissionProvider>(
        context,
        listen: false,
      );
      await homeProvider.getZone();
      await LocationPermissionProvider.cacheZoneData();
      final inZone =
          Constant.isZoneAvailable == true &&
          Constant.selectedZone?.id != null &&
          Constant.selectedZone!.id!.isNotEmpty;
      locProvider.setOutOfService(!inZone);
      if (inZone) {
        await homeProvider.reloadBanners();
      }
      return inZone;
    } catch (e) {
      print('[LOCATION_PERMISSION] Zone check failed: $e');
      Provider.of<LocationPermissionProvider>(
        context,
        listen: false,
      ).setOutOfService(true);
      return false;
    }
  }

  static Future<void> navigateAfterLocationSet(
    BuildContext context,
    SplashProvider? splashProvider,
  ) async {
    if (Constant.isZoneAvailable != true ||
        Constant.selectedZone?.id == null ||
        Constant.selectedZone!.id!.isEmpty) {
      print(
        '[LOCATION_PERMISSION] Navigation blocked — location is out of service area',
      );
      Provider.of<LocationPermissionProvider>(
        context,
        listen: false,
      ).setOutOfService(true);
      ShowToastDialog.showToast(
        "Service is not available at this location. Please choose a different address."
            .tr,
      );
      return;
    }

    try {
      final box = GetStorage();
      final cachedAuth = box.read('cached_auth_check');

      if (cachedAuth != null) {
        final cachedTime = DateTime.parse(cachedAuth['timestamp']);
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

      final apiToken = await SqlStorageConst.getAuthToken();
      final userId = await SqlStorageConst.getFirebaseId();

      if (apiToken != null &&
          apiToken.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        box.write('cached_auth_check', {
          'hasAuth': true,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (splashProvider != null) {
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

  Future<void> updateLocationInLocal(UserLocation location) async {
    final box = GetStorage();
    box.write('user_location', {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await Preferences.setString(
      Preferences.selectedLocationLat,
      location.latitude.toString(),
    );
    await Preferences.setString(
      Preferences.selectedLocationLng,
      location.longitude.toString(),
    );
  }

  ShippingAddress? findExistingAddress(
    double latitude,
    double longitude,
    List<ShippingAddress>? existingAddresses,
  ) {
    if (existingAddresses == null || existingAddresses.isEmpty) return null;
    const double tolerance = 0.001;
    for (var address in existingAddresses) {
      final addressLat = address.location?.latitude ?? address.latitude;
      final addressLng = address.location?.longitude ?? address.longitude;
      if (addressLat != null && addressLng != null) {
        if ((addressLat - latitude).abs() <= tolerance &&
            (addressLng - longitude).abs() <= tolerance) {
          return address;
        }
      }
    }
    return null;
  }

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

  Future<void> _handleMapSelection(
    BuildContext context,
    dynamic result,
    List<ShippingAddress>? existingAddresses,
    SplashProvider splashProvider,
  ) async {
    if (result == null) {
      print('[MAP_SELECTION] User cancelled map selection');
      return;
    }
    try {
      double? lat;
      double? lng;
      String? address;
      try {
        if (result is PlaceModel) {
          lat = result.coordinates.latitude;
          lng = result.coordinates.longitude;
          address = result.address;
        } else {
          try {
            final d = result as dynamic;
            if (d.coordinates != null) {
              lat = d.coordinates.latitude?.toDouble();
              lng = d.coordinates.longitude?.toDouble();
              address = d.address?.toString();
            }
          } catch (_) {
            try {
              final d = result as dynamic;
              if (d.geometry?.location != null) {
                lat = d.geometry.location.lat?.toDouble();
                lng = d.geometry.location.lng?.toDouble();
                address = d.formattedAddress?.toString();
              }
            } catch (e2) {
              print('[MAP_SELECTION] Error accessing both formats: $e2');
            }
          }
        }
      } catch (e) {
        print('[MAP_SELECTION] Error parsing result: $e');
        ShowToastDialog.showToast("Invalid location data received".tr);
        return;
      }
      if (lat == null || lng == null) {
        ShowToastDialog.showToast("Invalid location selected".tr);
        return;
      }
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
        if (Constant.userModel != null) {
          final updatedAddresses = List<ShippingAddress>.from(
            existingAddresses ?? [],
          );
          updatedAddresses.add(addressModel);
          Constant.userModel!.shippingAddress = updatedAddresses;
          try {
            final addressListProvider = Provider.of<AddressListProvider>(
              context,
              listen: false,
            );
            addressListProvider.userModel = Constant.userModel!;
            addressListProvider.shippingAddressList = updatedAddresses;
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
      try {
        final currentContext = Get.context ?? context;
        final inZone =
            await LocationPermissionScreen.finalizeLocationWithZoneCheck(
              currentContext,
            );
        if (inZone) {
          await LocationPermissionScreen.navigateAfterLocationSet(
            currentContext,
            splashProvider,
          );
        } else {
          ShowToastDialog.showToast(
            "Service is not available at this location. Please choose a different address."
                .tr,
          );
        }
      } catch (zoneError) {
        print('[MAP_SELECTION] Error checking zone: $zoneError');
        try {
          final currentContext = Get.context ?? context;
          Provider.of<LocationPermissionProvider>(
            currentContext,
            listen: false,
          ).setOutOfService(true);
        } catch (navError) {
          print('[MAP_SELECTION] Error navigating: $navError');
          ShowToastDialog.showToast(
            "Location set but navigation failed. Please restart the app.".tr,
          );
        }
      }
    } catch (e, stackTrace) {
      print('[MAP_SELECTION] Error: $e\n$stackTrace');
      ShowToastDialog.showToast(
        "Failed to process location. Please try again.".tr,
      );
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // White icons on the gradient-like dark top
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Consumer<LocationPermissionProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          body: _LocationBody(controller: controller, screen: this),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocationBody  — extracted for cleanliness
// ─────────────────────────────────────────────────────────────────────────────

class _LocationBody extends StatefulWidget {
  final LocationPermissionProvider controller;
  final LocationPermissionScreen screen;

  const _LocationBody({required this.controller, required this.screen});

  @override
  State<_LocationBody> createState() => _LocationBodyState();
}

class _LocationBodyState extends State<_LocationBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.syncOutOfServiceFromConstant();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.refreshZoneStatus(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Full-bleed background image (top 60% of screen) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.62,
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/location_bg.png",
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient fade from image into bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom sheet panel ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomPanel(
            controller: widget.controller,
            screen: widget.screen,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomPanel  — white card with title, subtitle, and action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final LocationPermissionProvider controller;
  final LocationPermissionScreen screen;

  const _BottomPanel({required this.controller, required this.screen});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row — permission prompt vs out-of-service zone
          Consumer<LocationPermissionProvider>(
            builder: (context, locProvider, _) {
              final isOutOfZone = locProvider.isOutOfServiceArea;
              final isChecking = locProvider.isCheckingZone;

              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          (isOutOfZone
                                  ? const Color(0xFFFFE8E8)
                                  : AppThemeData.kBrand)
                              .withOpacity(isOutOfZone ? 1.0 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppThemeData.kBrand,
                              ),
                            )
                          : Icon(
                              isOutOfZone
                                  ? Icons.location_off_rounded
                                  : Icons.location_on,
                              color: isOutOfZone
                                  ? AppThemeData.kBrandDeep
                                  : AppThemeData.kBrand,
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOutOfZone
                              ? "Service Not Available in Your Area".tr
                              : "Enable Location Services".tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOutOfZone
                              ? "We don't currently deliver to your location. Please try a different address within our service area."
                                    .tr
                              : "Allow JippyMart to find restaurants near you"
                                    .tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Primary button: Use Current Location ──
          _PrimaryLocationButton(
            label: "Use Current Location".tr,
            icon: Icons.my_location_rounded,
            onTap: () async {
              if (!LocationPermissionScreen._shouldProcessTap()) return;
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
                      final ctx = Get.context ?? context;
                      final inZone =
                          await LocationPermissionScreen.finalizeLocationWithZoneCheck(
                            ctx,
                          );
                      if (inZone) {
                        final splashProvider = Provider.of<SplashProvider>(
                          ctx,
                          listen: false,
                        );
                        await LocationPermissionScreen.navigateAfterLocationSet(
                          ctx,
                          splashProvider,
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "Service is not available at this location. Please choose a different address."
                              .tr,
                        );
                      }
                    }
                  } catch (e) {
                    print('[CURRENT_LOCATION] Error: $e');
                    ShowToastDialog.showToast(
                      "Failed to get location. Please try again.".tr,
                    );
                  }
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // ── Secondary buttons row ──
          Row(
            children: [
              Expanded(
                child: _SecondaryLocationButton(
                  label: "Set From Map".tr,
                  icon: Icons.map_outlined,
                  onTap: () async {
                    if (!LocationPermissionScreen._shouldProcessTap()) return;
                    Constant.checkPermission(
                      context: context,
                      onTap: () async {
                        try {
                          final existingAddresses =
                              Constant.userModel?.shippingAddress;
                          final splashProvider = Provider.of<SplashProvider>(
                            Get.context ?? context,
                            listen: false,
                          );

                          if (Constant.selectedMapType == 'osm') {
                            final result = await Get.to(() => MapPickerPage());
                            if (result != null) {
                              await screen._handleMapSelection(
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
                                    if (result != null) {
                                      await screen._handleMapSelection(
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
                            "Failed to add location. Please try again.".tr,
                          );
                        }
                      },
                    );
                  },
                ),
              ),

              // Show "Enter Manually" only when userModel is available
              if (Constant.userModel != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer2<AddressListProvider, HomeProvider>(
                    builder: (context, addressListProvider, homeProvider, _) {
                      return _SecondaryLocationButton(
                        label: "Enter Manually".tr,
                        icon: Icons.edit_location_alt_outlined,
                        onTap: () async {
                          if (!LocationPermissionScreen._shouldProcessTap())
                            return;
                          addressListProvider.initFunction(context: context);
                          final result = await Get.to(
                            const AddressListScreen(),
                          );
                          if (result != null && result is ShippingAddress) {
                            final ctx = Get.context ?? context;
                            final inZone = await homeProvider
                                .changeLocationAddressFunction(
                                  context: ctx,
                                  addressModel: result,
                                );
                            if (inZone) {
                              final splashProvider =
                                  Provider.of<SplashProvider>(
                                    ctx,
                                    listen: false,
                                  );
                              await LocationPermissionScreen.navigateAfterLocationSet(
                                ctx,
                                splashProvider,
                              );
                            } else {
                              ShowToastDialog.showToast(
                                "Service is not available at this location. Please choose a different address."
                                    .tr,
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── Change Location (outlined/ghost button) ──
          _GhostLocationButton(
            label: "Change Location".tr,
            onTap: () async {
              if (!LocationPermissionScreen._shouldProcessTap()) return;
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
                      final ctx = Get.context ?? context;
                      final inZone =
                          await LocationPermissionScreen.finalizeLocationWithZoneCheck(
                            ctx,
                          );
                      if (inZone) {
                        final splashProvider = Provider.of<SplashProvider>(
                          ctx,
                          listen: false,
                        );
                        await LocationPermissionScreen.navigateAfterLocationSet(
                          ctx,
                          splashProvider,
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "Service is not available at this location. Please choose a different address."
                              .tr,
                        );
                      }
                    }
                  } catch (e) {
                    print('[CHANGE_LOCATION] Error: $e');
                    ShowToastDialog.showToast(
                      "Failed to change location. Please try again.".tr,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrimaryLocationButton  — full-width, brand-red, with left icon
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryLocationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryLocationButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppThemeData.kBrand, AppThemeData.kBrandLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeData.kBrand.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SecondaryLocationButton  — half-width, white card with border
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryLocationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryLocationButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppThemeData.kBrand.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppThemeData.kBrand),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GhostLocationButton  — full-width, outlined, subtle
// ─────────────────────────────────────────────────────────────────────────────

class _GhostLocationButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostLocationButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
