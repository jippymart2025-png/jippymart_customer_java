import 'dart:async';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/cart_check_out_page/cart_check_out_screen.dart';
import 'package:jippymart_customer/app/favourite_screens/favourite_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/home_screen_two.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/order_screen.dart';
import 'package:jippymart_customer/app/wallet_screen/wallet_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashBoardProvider extends ChangeNotifier {
  void changeNavbar(int index) {
    if (index >= 0 && index < pageList.length) {
      selectedIndex = index;
      notifyListeners();
    } else {
      print(
        '[DASHBOARD] Invalid index: $index, pageList length: ${pageList.length}',
      );
    }
  }

  bool isCartScreenInitialized = false;
  int selectedIndex = 0;
  List<Widget> pageList = [];
  String currentTheme = "theme_1";
  DateTime? currentBackPressTime;
  bool canPopNow = false;

  Future<void> initFunction(BuildContext context) async {
    loadUserData(context);
    currentTheme = Constant.theme;
    _initializePageList();
  }

  void _initializePageList() {
    pageList = [
      const HomeScreenTwo(),
      const FavouriteScreen(),
      const CartCheckOutScreen(),
      const OrderScreen(),
    ];
    if (selectedIndex >= pageList.length) {
      selectedIndex = 0;
    }
    notifyListeners();
  }

  Future<void> loadUserData(BuildContext context) async {
    try {
      if (Constant.userModel == null) {
        print('[DASHBOARD] User model is null, cannot load additional data');
        return;
      } else {
        print(
          '[DASHBOARD] User model exists: ${Constant.userModel?.firstName}',
        );
      }
      await _checkUserShippingAddresses();
    } catch (e) {
      print('[DASHBOARD] Error loading user data: $e');
    }
  }

  /// Check if user has shipping addresses and show alert if none
  Future<void> _checkUserShippingAddresses() async {
    try {
      print('[DASHBOARD] Waiting for home page to fully load...');
      await Future.delayed(const Duration(milliseconds: 3000));
      if (Constant.userModel != null) {
        final hasAddresses =
            Constant.userModel!.shippingAddress != null &&
            Constant.userModel!.shippingAddress!.isNotEmpty;
        print('[DASHBOARD] Address check - Has addresses: $hasAddresses');
        if (!hasAddresses) {
          print('[DASHBOARD] User has no shipping addresses - showing alert');
          _showAddressRequiredAlert();
        } else {
          print('[DASHBOARD] User has addresses - no alert needed');
        }
      } else {
        print('[DASHBOARD] User model is null - cannot check addresses');
      }
    } catch (e) {
      print('[DASHBOARD] Error checking shipping addresses: $e');
    }
  }

  /// Show address required alert dialog
  void _showAddressRequiredAlert() {
    // Prevent multiple dialogs from showing
    if (Get.isDialogOpen == true) {
      print('[DASHBOARD] Dialog already showing, skipping...');
      return;
    }
    print('[DASHBOARD] Showing address required dialog...');

    try {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8F0), Color(0xFFFFF0E6)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '📍 Address Required',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF6B35).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Color(0xFFFF6B35),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'To place orders and enjoy our services, you need to add a delivery address.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF2D3436),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Action button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_location_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Add Address',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
      // Fallback to simple snackbar
      Get.snackbar(
        'Address Required',
        'Please add a delivery address to continue using the app.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void onClose() {
    // Clean up any resources if needed
    print('[DEBUG] Dashboard provider closed');
  }
}
