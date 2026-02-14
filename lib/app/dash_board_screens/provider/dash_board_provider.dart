import 'dart:async';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/cart_check_out_page/cart_check_out_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/home_screen_two.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/order_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../DealsScreen/DealsScreen.dart';
import '../../profile_screen/profile_screen.dart';

class DashBoardProvider extends ChangeNotifier {
  DashBoardProvider() {
    print('[DASHBOARD_PROVIDER] Initializing...');
    _initializePageList();
  }

  // State
  int selectedIndex = 0;
  List<Widget> pageList = [];
  DateTime? currentBackPressTime;
  bool canPopNow = false;
  bool _addressCheckCompleted = false;

  void changeNavbar(
    int index,
    HomeProvider homeProvider,
    SplashProvider splashProvider,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
    FavouriteProvider favouriteProvider,
  ) {
    if (index < 0 || index >= pageList.length) return;

    selectedIndex = index;
    notifyListeners();

    // Initialize screen-specific data if needed
    switch (index) {
      case 0: // Home
        if (homeProvider.bannerModel.isEmpty) {
          splashProvider.refreshFunction(context);
        }
        break;
      case 2: // Cart
        cartControllerProvider.initFunction(context);
        break;
      case 3: // Orders
        orderProvider.initFunction();
        break;
    }
  }

  Future<void> initFunction(BuildContext context) async {
    currentTheme = Constant.theme;

    // Load user data in background
    unawaited(_loadUserDataInBackground(context));
  }

  String currentTheme = "theme_1";

  void _initializePageList() {
    if (pageList.isNotEmpty) return;

    pageList = [
      const HomeScreenTwo(),
      const CartCheckOutScreen(),
      const DealsScreen(),
      const OrderScreen(),
      const ProfileScreen(),
    ];

    selectedIndex = selectedIndex.clamp(0, pageList.length - 1);
    print('[DASHBOARD_PROVIDER] Initialized with ${pageList.length} pages');
    notifyListeners();
  }

  Future<void> _loadUserDataInBackground(BuildContext context) async {
    try {
      if (Constant.userModel == null) {
        print('[DASHBOARD] User model is null');
        return;
      }

      // Only check address once per session
      if (!_addressCheckCompleted) {
        await _checkUserShippingAddresses();
        _addressCheckCompleted = true;
      }
    } catch (e) {
      print('[DASHBOARD] Error loading user data: $e');
    }
  }

  Future<void> _checkUserShippingAddresses() async {
    try {
      // Wait for app to be fully loaded before checking
      await Future.delayed(const Duration(seconds: 5));

      if (Constant.userModel != null) {
        final hasAddresses =
            Constant.userModel!.shippingAddress != null &&
            Constant.userModel!.shippingAddress!.isNotEmpty;

        if (!hasAddresses) {
          _showAddressRequiredAlert();
        }
      }
    } catch (e) {
      print("[DASHBOARD] Error checking addresses: $e");
    }
  }

  void _showAddressRequiredAlert() {
    if (Get.isDialogOpen == true) return;

    try {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFFF6B35),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Address Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please add a delivery address to place orders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const AddressListScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print('[DASHBOARD] Error showing dialog: $e');
      // Simple fallback
      Get.snackbar(
        'Address Required',
        'Please add a delivery address to continue.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
