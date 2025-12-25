import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/cart_screen/coupon_list_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_bill_details_widget.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_navigation_bar_widget.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_product_details_image_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final bool hideBackButton;
  final String? source;
  final bool isFromMartNavigation;

  const CartScreen({
    super.key,
    this.hideBackButton = false,
    this.source,
    this.isFromMartNavigation = false,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartControllerProvider controller;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    controller = Provider.of<CartControllerProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCartData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart data whenever the screen becomes visible
    // This ensures prices are synced every time user opens the cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      if (_lastRefreshTime == null || 
          now.difference(_lastRefreshTime!) > _minRefreshInterval) {
        _refreshCartData();
      }
    });
  }

  Future<void> _refreshCartData() async {
    if (_isRefreshing) {
      return; // Prevent simultaneous calls
    }
    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();
    
    print('[CART_SCREEN] 🔄 Refreshing cart data and syncing prices...');
    
    // Reset delivery tips when cart screen initializes (for new order sessions)
    // This ensures tips don't carry over from previous orders
    controller.deliveryTips = 0.0;
    await controller.forceRefreshCart();
    if (controller.selectedAddress == null ||
        controller.selectedAddress!.location?.latitude == null ||
        controller.selectedAddress!.location?.longitude == null) {
      // 🔑 initializeAddress now handles vendor loading and price calculation
      await controller.initializeAddress(context);
    } else {
      // 🔑 syncAddressWithHomeLocation already handles price calculation
      await controller.syncAddressWithHomeLocation(context);
    }
    controller.checkAndUpdatePaymentMethod();
    
    // 🔑 Background price sync - validates and updates cart prices
    // Runs asynchronously in background without blocking UI
    // Works for both food and mart items
    // This syncs prices from backend database every time cart is opened
    print('[CART_SCREEN] 💰 Starting background price sync for food and mart items...');
    controller.syncCartPricesInBackground().catchError((error) {
      print('[CART_SCREEN] ❌ Error in background price sync: $error');
    });
    
    _isRefreshing = false;
    print('[CART_SCREEN] ✅ Cart refresh complete');
  }

  // Get theme colors based on cart theme
  CartThemeColors _getThemeColors(CartTheme theme) {
    switch (theme) {
      case CartTheme.mart:
        return CartThemeColors(
          primary: MartTheme.jippyMartButton,
          primaryDark: ColorConst.martPrimary,
          accent: ColorConst.martPrimary,
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
          primary: const Color(0xFF607D8B),
          primaryDark: const Color(0xFF455A64),
          accent: const Color(0xFF78909C),
          surface: AppThemeData.surface,
          onSurface: Colors.black87,
        );
    }
  }

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
    bool hasMartItems = HomeProvider.cartItem.any(
      (item) =>
          item.vendorID?.contains('mart') == true ||
          item.vendorID?.startsWith('demo_') == true ||
          item.vendorID?.contains('vendor') == true,
    );

    bool hasFoodItems = HomeProvider.cartItem.any(
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
        // Removed checkAndUpdatePaymentMethod call from build method
        // It's already called in _refreshCartData() to prevent setState during build
        // Use priceSyncVersion to force rebuild when prices update
        final _ = controller.priceSyncVersion;
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
              backgroundColor: ColorConst.martPrimary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: !widget.hideBackButton,
              leading: widget.hideBackButton
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (widget.source == 'mart' &&
                            widget.isFromMartNavigation) {
                          try {
                            final martNavController =
                                Provider.of<MartNavigationProvider>(
                                  context,
                                  listen: false,
                                );
                            martNavController.goToHome();
                          } catch (e) {
                            Get.back();
                          }
                        } else {
                          Get.back();
                        }
                      },
                    ),
              title: Text(
                cartTheme == CartTheme.mart ? 'Mart Cart' : 'Cart',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [],
            ),
            body: HomeProvider.cartItem.isEmpty
                ? Constant.showEmptyView(message: "No Available Items")
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.selectedFoodType == 'TakeAway'
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    controller.changeLocationFunctionInCart(
                                      context: context,
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: ShapeDecoration(
                                          color: AppThemeData.grey50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/ic_send_one.svg",
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                              .selectedAddress
                                                              ?.addressAs
                                                              ?.toString() ??
                                                          "No Address Selected",
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData
                                                            .semiBold,
                                                        color: AppThemeData
                                                            .primary300,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  SvgPicture.asset(
                                                    "assets/icons/ic_down.svg",
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                controller.selectedAddress
                                                        ?.getFullAddress() ??
                                                    "Please select a delivery address",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                  color: AppThemeData.grey500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                        cartProductDetailsImageWidget(controller),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Offers & Benefits".tr,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: AppThemeData.grey900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  ShowToastDialog.showLoader(
                                    "Loading coupons...",
                                  );
                                  await controller.getCartData();
                                  ShowToastDialog.closeLoader();
                                  Get.to(const CouponListScreen());
                                },
                                child: Container(
                                  width: Responsive.width(100, context),
                                  decoration: ShapeDecoration(
                                    color: AppThemeData.grey50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 52,
                                        offset: Offset(0, 0),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Apply Coupons".tr,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              color: AppThemeData.grey900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const Icon(Icons.keyboard_arrow_right),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        //finded
                        billCartWidget(controller, context),
                        controller.selectedFoodType == 'TakeAway' ||
                                (controller.vendorModel.isSelfDelivery ==
                                        true &&
                                    Constant.isSelfDeliveryFeature == true)
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      "Thanks with a tip!".tr,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        color: AppThemeData.grey900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: Responsive.width(100, context),
                                      decoration: ShapeDecoration(
                                        color: AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        shadows: const [
                                          BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 52,
                                            offset: Offset(0, 0),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Around the clock, our delivery partners bring you your favorite meals. Show your appreciation with a tip."
                                                        .tr,
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      color:
                                                          AppThemeData.grey600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                SvgPicture.asset(
                                                  "assets/images/ic_tips.svg",
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips =
                                                          5.0;
                                                      controller
                                                          .calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            width: 1,
                                                            color:
                                                                controller
                                                                        .deliveryTips ==
                                                                    5.0
                                                                ? AppThemeData
                                                                      .primary300
                                                                : AppThemeData
                                                                      .grey100,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(
                                                              amount: "05",
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  AppThemeData
                                                                      .grey900,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips =
                                                          10;
                                                      controller
                                                          .calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            width: 1,
                                                            color:
                                                                controller
                                                                        .deliveryTips ==
                                                                    10
                                                                ? AppThemeData
                                                                      .primary300
                                                                : AppThemeData
                                                                      .grey100,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(
                                                              amount: "10",
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  AppThemeData
                                                                      .grey900,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips =
                                                          15;
                                                      controller
                                                          .calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            width: 1,
                                                            color:
                                                                controller
                                                                        .deliveryTips ==
                                                                    15
                                                                ? AppThemeData
                                                                      .primary300
                                                                : AppThemeData
                                                                      .grey100,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(
                                                              amount: "15",
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  AppThemeData
                                                                      .grey900,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              BuildContext
                                                              context,
                                                            ) {
                                                              return tipsDialog(
                                                                controller,
                                                              );
                                                            },
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            width: 1,
                                                            color: AppThemeData
                                                                .grey100,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        child: Center(
                                                          child: Text(
                                                            'Other'.tr,
                                                            style: TextStyle(
                                                              color:
                                                                  AppThemeData
                                                                      .grey900,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .medium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              TextFieldWidget(
                                title: 'Remarks'.tr,
                                controller: controller.reMarkController,
                                hintText: 'Write remarks for the restaurant'.tr,
                                maxLine: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            //changed here
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomNavigationBar: HomeProvider.cartItem.isEmpty
                ? null
                : cartNavigationBarWidget(context),
          ),
        );
      },
    );
  }

  /// Reusable method to build delivery fee UI for different order types
  ///
  /// Parameters:
  /// - [isFreeDelivery]: Whether delivery is free or not
  /// - [originalFee]: Original delivery fee to show with strikethrough (for free delivery)
  /// - [currentFee]: Current delivery fee to display
  /// - [themeChange]: Theme controller for dark/light mode
  ///
  /// Returns:
  /// - Row widget with appropriate delivery fee display
}
