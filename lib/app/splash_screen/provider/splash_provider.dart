import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/app_update_service.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'package:provider/provider.dart';

class SplashProvider extends ChangeNotifier {
  late HomeProvider homeProvider;
  late AddressListProvider addressListProvider;
  bool _hasNavigated = false; // Flag to prevent multiple navigations

  void initFunction(BuildContext context) async {
    _initializeLogo(context);
  }

  _initializeLogo(BuildContext context) async {
    try {
      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 1));

      // Check if context is still mounted before navigating
      if (context.mounted) {
        _navigateToMainApp(context);
      }
    } catch (e) {
      // Try to navigate anyway if context is mounted
      if (context.mounted) {
        _navigateToMainApp(context);
      }
    }
  }

  void refreshFunction(BuildContext context) async {
    try {
      await _loadUserDataFromStorage();

      // Initialize home provider in background (non-blocking)
      homeProvider
          .initFunction(context: context)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print(
                '[SPLASH] refreshFunction: homeProvider.initFunction timed out',
              );
            },
          )
          .catchError((e) {
            print(
              '[SPLASH] refreshFunction: Error in homeProvider.initFunction: ${e.toString()}',
            );
          });
    } catch (e) {
      print(
        '[SPLASH] refreshFunction: Error loading user data: ${e.toString()}',
      );
    }
  }

  void _navigateToMainApp(BuildContext context) async {
    // Prevent multiple navigations
    if (_hasNavigated) {
      return;
    }

    try {
      // FIRST: Check if user is logged in (for first install, skip location check)
      String? apiToken;
      String? userId;
      try {
        apiToken = await SqlStorageConst.getAuthToken().timeout(
          const Duration(seconds: 5),
        );
        userId = await SqlStorageConst.getFirebaseId().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        print('[SPLASH] Error getting auth token/user ID: $e');
      }

      // Get providers
      if (!context.mounted) {
        return;
      }

      homeProvider = Provider.of<HomeProvider>(context, listen: false);
      addressListProvider = Provider.of<AddressListProvider>(
        context,
        listen: false,
      );

      // If user is not logged in, show login page first (skip location check for first install)
      if (apiToken == null ||
          apiToken.isEmpty ||
          userId == null ||
          userId.isEmpty) {
        if (context.mounted && !_hasNavigated) {
          _hasNavigated = true;
          Get.offAll(
            () => const PhoneNumberScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 800),
          );
          _checkUpdatesInBackground();
        }
        return;
      }

      // User is logged in, NOW check location permission
      LocationPermission locationPermission;
      try {
        locationPermission = await Geolocator.checkPermission().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        print('[SPLASH] Error checking location permission: $e');
        locationPermission = LocationPermission.denied;
      }

      // If location permission is denied, request it
      if (locationPermission == LocationPermission.denied) {
        try {
          locationPermission = await Geolocator.requestPermission().timeout(
            const Duration(seconds: 5),
          );
        } catch (e) {
          print('[SPLASH] Error requesting location permission: $e');
        }
      }

      // If permission is not granted (denied or deniedForever), show location permission screen
      if (locationPermission != LocationPermission.whileInUse &&
          locationPermission != LocationPermission.always) {
        if (context.mounted && !_hasNavigated) {
          _hasNavigated = true;
          Get.offAll(
            () => const LocationPermissionScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 800),
          );
          _checkUpdatesInBackground();
        }
        return;
      }

      // User is logged in, proceed to dashboard
      try {
        await _loadUserDataFromStorage().timeout(const Duration(seconds: 5));
      } catch (e) {
        // Continue anyway
      }

      if (!context.mounted) {
        return;
      }

      // IMPORTANT: Initialize home provider first
      await homeProvider.initFunction(context: context);

      // CRITICAL: Wait for location and zone check before navigating
      try {
        await homeProvider.ensureLocationAndZoneChecked().timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            homeProvider.zoneCheckCompleted = true;
            homeProvider.hasActuallyCheckedZone = true;
            homeProvider.isLoadingFunction(false);
            homeProvider.notifyListeners();
          },
        );
      } catch (e) {
        print('[SPLASH] ❌ Error during location/zone check: $e');
        homeProvider.zoneCheckCompleted = true;
        homeProvider.hasActuallyCheckedZone = true;
        homeProvider.isLoadingFunction(false);
        homeProvider.notifyListeners();
      }

      if (!context.mounted || _hasNavigated) {
        return;
      }

      // Check if location and zone are cached/valid before deciding to show location screen
      final box = GetStorage();
      final cachedLocation = box.read('user_location');
      final cachedZoneData = box.read('zone_data');

      final hasCachedLocation =
          cachedLocation != null &&
          cachedLocation['latitude'] != null &&
          cachedLocation['longitude'] != null &&
          cachedLocation['latitude'] != 0.0 &&
          cachedLocation['longitude'] != 0.0;

      final hasCachedZone =
          cachedZoneData != null &&
          cachedZoneData['zoneId'] != null &&
          cachedZoneData['zoneId'].toString().isNotEmpty;

      final hasLocationInConstant =
          Constant.selectedLocation.location?.latitude != null &&
          Constant.selectedLocation.location!.latitude != 0.0 &&
          Constant.selectedLocation.location!.longitude != null &&
          Constant.selectedLocation.location!.longitude != 0.0;

      // Check zone ID from Preferences as well
      final zoneIdFromPrefs = Preferences.getString(Preferences.selectedZoneId);
      final hasZoneIdFromPrefs = zoneIdFromPrefs.isNotEmpty;

      final bool hasAnyLocation = hasCachedLocation || hasLocationInConstant;
      final bool hasAnyZone =
          hasCachedZone ||
          hasZoneIdFromPrefs ||
          (Constant.selectedZone?.id != null) ||
          (Constant.selectedLocation.zoneId != null &&
              Constant.selectedLocation.zoneId!.isNotEmpty);

      if (!hasAnyLocation && !hasAnyZone) {
        _hasNavigated = true;
        Get.offAll(
          () => const LocationPermissionScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
        _checkUpdatesInBackground();
        return;
      }

      // Navigate to dashboard — home screen loads outlets and shows no-service if needed.
      _hasNavigated = true;
      try {
        Get.offAll(
          () => const DashBoardScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );

        // Load address list in background after navigation (with timeout)
        Future.microtask(() async {
          try {
            await addressListProvider
                .initFunction(context: context)
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            print(
              '[SPLASH] Error in addressListProvider.initFunction: ${e.toString()}',
            );
          }
        });

        // Process deep links in background
        Future.microtask(() {
          try {
            final deepLinkService = FinalDeepLinkService();
            deepLinkService.processPendingDeepLinkAfterLogin(context);
          } catch (e) {
            print('[SPLASH] Error in deepLinkService: ${e.toString()}');
          }
        });

        _checkUpdatesInBackground();
      } catch (e) {
        print('[SPLASH] Error with Get.offAll, trying Navigator: $e');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashBoardScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      print('[SPLASH] Error in _navigateToMainApp: ${e.toString()}');
      print('[SPLASH] Stack trace: $stackTrace');

      // Fallback navigation to login screen
      if (context.mounted && !_hasNavigated) {
        _hasNavigated = true;
        try {
          Get.offAll(
            () => const PhoneNumberScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 800),
          );
        } catch (e2) {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const PhoneNumberScreen(),
              ),
              (Route<dynamic> route) => false,
            );
          }
        }
      }
    }
  }

  Future<void> _loadUserDataFromStorage() async {
    try {
      final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
      final userId = await secureStorage.read(key: 'user_id');
      final firebaseId = await secureStorage.read(key: 'firebase_id');
      final firstName = await secureStorage.read(key: 'user_firstName') ?? '';
      final lastName = await secureStorage.read(key: 'user_lastName') ?? '';
      final email = await secureStorage.read(key: 'user_email') ?? '';
      final phone = await secureStorage.read(key: 'user_phone') ?? '';
      final countryCode =
          await secureStorage.read(key: 'user_countryCode') ?? '+91';
      if (firebaseId != null) {
        UserModel userModel = UserModel(
          id: userId,
          firstName: firstName,
          firebaseId: firebaseId,
          lastName: lastName,
          email: email,
          phoneNumber: phone,
          countryCode: countryCode,
          role: Constant.userRoleCustomer,
          active: true,
        );
        Constant.userModel = userModel;
        print(" _loadAllDataInParallel  1 ${Constant.userModel?.firebaseId} ");
        notifyListeners();
      } else {}
    } catch (e) {
      print(" _loadAllDataInParallel  2 ${e.toString()} ");
    }
  }

  void _checkUpdatesInBackground() {
    Future.microtask(() async {
      try {
        bool updateRequired = await AppUpdateService.checkForUpdate().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return false;
          },
        );
        if (updateRequired) {
        } else {}
      } catch (e) {}
    });
  }
}
