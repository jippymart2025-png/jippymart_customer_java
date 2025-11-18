import 'package:jippymart_customer/app/cart_screen/cart_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_product_details_image_widget.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:provider/provider.dart';

class CartCheckOutScreen extends StatefulWidget {
  final bool hideBackButton;
  final String? source;
  final bool isFromMartNavigation;

  const CartCheckOutScreen({
    super.key,
    this.hideBackButton = false,
    this.source,
    this.isFromMartNavigation = false,
  });

  @override
  State<CartCheckOutScreen> createState() => _CartCheckOutScreenState();
}

class _CartCheckOutScreenState extends State<CartCheckOutScreen> {
  late CartControllerProvider controller;
  bool _hasInitialized = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    controller = Provider.of<CartControllerProvider>(context, listen: false);
    // Only initialize once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        _refreshCartData(context);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove duplicate initialization - already handled in initState
  }

  void _refreshCartData(BuildContext context) {
    if (_isRefreshing) {
      return; // Prevent multiple simultaneous refreshes
    }
    
    _isRefreshing = true;
    print('DEBUG: Refreshing cart data...');
    
    // Use a single delayed call instead of multiple
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        controller.forceRefreshCart();
        if (controller.selectedAddress == null) {
          controller.initializeAddress(context);
        }
        // Only call payment method check once, not continuously
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              controller.checkAndUpdatePaymentMethod();
            }
          });
        }
      } finally {
        _isRefreshing = false;
      }
    });
  }

  // Get theme colors based on cart theme
  CartThemeColors _getThemeColors(CartTheme theme) {
    switch (theme) {
      case CartTheme.mart:
        return CartThemeColors(
          primary: MartTheme.jippyMartButton,
          primaryDark: const Color(0xFF005A52),
          accent: const Color(0xFF00A896),
          surface: Colors.white,
          onSurface: Colors.black87,
        );
      case CartTheme.food:
        return CartThemeColors(
          primary: const Color(0xFFFF6B35),
          primaryDark: const Color(0xFFE55A2B),
          accent: const Color(0xFFFF8A65),
          surface: AppThemeData.surface,
          onSurface: Colors.black87,
        );
      case CartTheme.mixed:
        return CartThemeColors(
          primary: const Color(0xFFFF6B35),
          primaryDark: const Color(0xFFE55A2B),
          accent: const Color(0xFFFF8A65),
          surface: AppThemeData.surface,
          onSurface: Colors.black87,
        );
    }
  }

  // Determine cart theme based on source and content
  CartTheme _getCartTheme() {
    // If source is explicitly provided, use it
    if (widget.source != null) {
      if (widget.source == 'mart') {
        return CartTheme.mart;
      } else if (widget.source == 'food') {
        return CartTheme.food;
      }
    }
    // Auto-detect based on cart content
    bool hasMartItems = cartItem.any(
      (item) =>
          item.vendorID?.contains('mart') == true ||
          item.vendorID?.startsWith('demo_') == true ||
          item.vendorID?.contains('vendor') == true,
    );
    bool hasFoodItems = cartItem.any(
      (item) =>
          !(item.vendorID?.contains('mart') == true ||
              item.vendorID?.startsWith('demo_') == true ||
              item.vendorID?.contains('vendor') == true),
    );
    if (hasMartItems && !hasFoodItems) {
      return CartTheme.mart;
    } else if (hasFoodItems && !hasMartItems) {
      return CartTheme.food;
    } else {
      return CartTheme.mixed; // Both food and mart items
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartTheme = _getCartTheme();
    final themeColors = _getThemeColors(cartTheme);
    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        // Remove continuous API calls from build method
        // Payment method check is already handled in _refreshCartData
        return WillPopScope(
          onWillPop: () async {
            if (controller.isGlobalLocked) {
              ShowToastDialog.showToast(
                "Please wait, payment is processing...",
              );
              return false; // prevent back navigation
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: themeColors.surface,
            appBar: AppBar(
              backgroundColor: themeColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: !widget.hideBackButton,
              centerTitle: true,
              title: Text(
                'Cart',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                // Debug buttons removed - methods not available in current version
              ],
            ),
            body: cartItem.isEmpty
                ? Center(
                    child: Text(
                      "No Available Items",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.primary300,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(ImageConst.backgroundImage),
                        fit: BoxFit.cover, // can use contain, fill, repeat
                      ),
                    ),
                    child: Column(
                      children: [cartProductDetailsImageWidget(controller)],
                    ),
                  ),
            bottomNavigationBar: cartItem.isEmpty
                ? null
                : SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: RoundedButtonFill(
                        textColor: AppThemeData.surface,
                        isEnabled: true,
                        title: "Check Out".tr,
                        height: 5,
                        color: AppThemeData.primary300,
                        fontSizes: 16,
                        // onPress: () async {
                        //   await Get.to(() => const CartScreen())?.then((_) {
                        //     _refreshCartData();
                        //   });
                        // }
                        onPress: () async {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CartScreen(),
                            ),
                          );
                          // Get.to(() => const CartScreen());
                        },
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
