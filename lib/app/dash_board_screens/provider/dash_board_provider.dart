import 'dart:async';
import 'package:jippymart_customer/app/address_screens/screens/address_list_screen.dart';
import 'package:jippymart_customer/app/cart_check_out_page/cart_check_out_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/home_screen_two.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/order_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/utils/color_const.dart';
import '../../profile_screen/profile_screen.dart';

class DashboardTab {
  static const home = 0;
  static const cart = 1;
  static const orders = 2;
  static const profile = 3;
}

class DashBoardProvider extends ChangeNotifier {
  // DashBoardProvider() {}

  // State
  int selectedIndex = DashboardTab.home;
  final List<Widget> pageList = const [
    HomeScreenTwo(),
    CartCheckOutScreen(),
    OrderScreen(),
    ProfileScreen(),
  ];
  DateTime? currentBackPressTime;
  bool canPopNow = false;
  bool _addressCheckCompleted = false;
  bool _cartInitialized = false;
  bool _ordersInitialized = false;

  void changeNavbar(
    int index,
    HomeProvider homeProvider,
    SplashProvider splashProvider,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
  ) {
    if (index < 0 || index >= pageList.length) return;

    if (selectedIndex == index) return;

    selectedIndex = index;
    notifyListeners();

    // Initialize screen-specific data if needed
    switch (index) {
      case DashboardTab.home:
        _initializeHome(homeProvider, splashProvider, context);
        break;

      case DashboardTab.cart:
        _initializeCart(cartControllerProvider, context);
        break;

      case DashboardTab.orders:
        _initializeOrders(orderProvider);
        break;

      case DashboardTab.profile:
        break;
    }
  }

  Future<void> initFunction(BuildContext context) async {
    currentTheme = Constant.theme;

    // Load user data in background
    unawaited(_loadUserDataInBackground(context));
  }

  late String currentTheme;

  void _initializeHome(
    HomeProvider provider,
    SplashProvider splashProvider,
    BuildContext context,
  ) {
    if (provider.bannerModel.isNotEmpty) return;

    splashProvider.refreshFunction(context);
  }

  void _initializeCart(CartControllerProvider provider, BuildContext context) {
    if (_cartInitialized) return;

    _cartInitialized = true;
    provider.initFunction(context);
  }

  void _initializeOrders(OrderProvider provider) {
    if (_ordersInitialized) return;

    _ordersInitialized = true;
    provider.initFunction();
  }

  Future<void> _loadUserDataInBackground(BuildContext context) async {
    try {
      if (Constant.userModel == null) {
        return;
      }

      // Only check address once per session
      if (!_addressCheckCompleted) {
        await _checkUserShippingAddresses();
        _addressCheckCompleted = true;
      }
    } catch (e) {
      debugPrint('[DASHBOARD] Error loading user data: $e');
    }
  }

  static const _addressCheckDelay = Duration(seconds: 5);

  Future<void> _checkUserShippingAddresses() async {
    try {
      // Wait for app to be fully loaded before checking
      await Future.delayed(_addressCheckDelay);

      final addresses = Constant.userModel?.shippingAddress;

      if (addresses?.isEmpty ?? true) {
        _showAddressRequiredAlert();
      }
    } catch (e) {
      debugPrint('[DASHBOARD] Error checking addresses: $e');
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
                    color: ColorConst.kGradEnd,
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
                        backgroundColor: ColorConst.kGradEnd,
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
      debugPrint('[DASHBOARD] Error showing dialog: $e');
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
