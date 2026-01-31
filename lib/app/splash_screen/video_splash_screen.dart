import 'dart:async';
import 'package:jippymart_customer/app/home_screen/provider/global_settings_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late SplashProvider splashProvider;
  late GlobalSettingsProvider globalSettingsProvider;
  Timer? _timeoutTimer;
  bool _hasNavigated = false; // Flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    splashProvider = Provider.of<SplashProvider>(context, listen: false);
    globalSettingsProvider = Provider.of<GlobalSettingsProvider>(
      context,
      listen: false,
    );
    
    // Start initialization
    splashProvider.initFunction(context);
    globalSettingsProvider.initFunction(context);
    
    // Add safety timeout - if navigation doesn't happen within 15 seconds, force it
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_hasNavigated) {
        print('[SPLASH_SCREEN] Timeout reached, forcing navigation...');
        _forceNavigation();
      } else if (_hasNavigated) {
        print('[SPLASH_SCREEN] Navigation already completed, skipping timeout');
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _forceNavigation() async {
    if (!mounted || _hasNavigated) {
      if (_hasNavigated) {
        print('[SPLASH_SCREEN] Already navigated, skipping force navigation');
      }
      return;
    }
    
    try {
      print('[SPLASH_SCREEN] Force navigation: Checking auth status first...');
      
      // FIRST: Check auth status (for first install, skip location check)
      String? apiToken;
      String? userId;
      try {
        apiToken = await SqlStorageConst.getAuthToken()
            .timeout(const Duration(seconds: 3));
        userId = await SqlStorageConst.getFirebaseId()
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        print('[SPLASH_SCREEN] Error getting auth token/user ID: $e');
      }
      
      if (!mounted || _hasNavigated) return;
      
      // If user is not logged in, go directly to login (first install)
      if (apiToken == null || apiToken.isEmpty || userId == null || userId.isEmpty) {
        print('[SPLASH_SCREEN] User not logged in (first install), going to PhoneNumberScreen');
        _hasNavigated = true;
        Get.offAll(
          () => const PhoneNumberScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
        return;
      }
      
      // User is logged in, NOW check location permission
      print('[SPLASH_SCREEN] User is logged in, checking location permission...');
      bool hasLocationPermission = false;
      try {
        final permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 3));
        hasLocationPermission = permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      } catch (e) {
        print('[SPLASH_SCREEN] Error checking location permission: $e');
      }
      
      if (!mounted || _hasNavigated) return;
      
      // Navigate based on location permission and auth status
      // When force timeout fires, always go to LocationPermissionScreen for logged-in users
      // with permission - this ensures zone is checked before home (main flow may have timed out)
      _hasNavigated = true;
      if (!hasLocationPermission) {
        print('[SPLASH_SCREEN] No location permission, going to LocationPermissionScreen');
        Get.offAll(
          () => const LocationPermissionScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      } else {
        // Has permission - go to LocationPermissionScreen to verify zone before home
        print('[SPLASH_SCREEN] Force nav: checking zone via LocationPermissionScreen');
        Get.offAll(
          () => const LocationPermissionScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      }
    } catch (e) {
      print('[SPLASH_SCREEN] Error in _forceNavigation: $e');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        // Fallback to login screen (safest option for first install)
        Get.offAll(
          () => const PhoneNumberScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/ic_logo.png",
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
