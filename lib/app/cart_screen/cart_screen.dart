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
import 'dart:async';

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
  Timer? _refreshDebounceTimer;
  Timer? _performanceTimer;
  Stopwatch _performanceStopwatch = Stopwatch();
  static const Duration _minRefreshInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _performanceStopwatch.start();
    controller = Provider.of<CartControllerProvider>(context, listen: false);

    // 🔑 OPTIMIZED: Use microtask for immediate initialization
    Future.microtask(() {
      _refreshCartData();
      _performanceStopwatch.stop();
      print(
        '[CART_SCREEN] 🚀 Initialized in ${_performanceStopwatch.elapsedMilliseconds}ms',
      );
    });

    // Start performance monitoring
    _performanceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      controller.logPerformance();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Debounced refresh to prevent excessive calls
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!) > _minRefreshInterval) {
        _refreshCartData();
      }
    });
  }

  // In CartScreen class, update the refresh method
  Future<void> _refreshCartData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    print('[CART_SCREEN] 🔄 Starting comprehensive cart refresh...');

    try {
      // Run operations in sequence to avoid conflicts
      await controller.forceRefreshCart();

      if (controller.selectedAddress == null ||
          controller.selectedAddress!.location?.latitude == null ||
          controller.selectedAddress!.location?.longitude == null) {
        await controller.initializeAddress(context);
      } else {
        await controller.syncAddressWithHomeLocation(context);
      }

      controller.checkAndUpdatePaymentMethod();

      // 🔑 CRITICAL: Force immediate price sync (not in background)
      print('[CART_SCREEN] 🔄 Starting immediate price sync...');
      await controller.syncCartPricesInBackground();

      print('[CART_SCREEN] ✅ Cart refresh complete with price sync');
    } catch (e) {
      print('[CART_SCREEN] ❌ Error refreshing cart: $e');

      // Fallback: Try basic refresh
      try {
        await controller.getCartData();
        await controller.calculatePrice();
      } catch (fallbackError) {
        print('[CART_SCREEN] ❌ Fallback also failed: $fallbackError');
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // In your CartScreen's build method, update the button logic:

  Future<void> _handlePlaceOrder(CartControllerProvider controller) async {
    try {
      await controller.processPayment(controller, context);
    } catch (e) {
      print('❌ [CART_SCREEN] Error placing order: $e');
      // The controller should handle its own state cleanup
    }
  }

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
    if (widget.source != null) {
      if (widget.source == 'mart') return CartTheme.mart;
      if (widget.source == 'food') return CartTheme.food;
    }

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

    if (hasMartItems && !hasFoodItems) return CartTheme.mart;
    if (hasFoodItems && !hasMartItems) return CartTheme.food;
    return CartTheme.mixed;
  }

  @override
  void dispose() {
    _refreshDebounceTimer?.cancel();
    _performanceTimer?.cancel();
    _performanceStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartTheme = _getCartTheme();
    final themeColors = _getThemeColors(cartTheme);

    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        // 🔑 OPTIMIZATION: Use selective listening
        final _ = controller.priceSyncVersion;

        return WillPopScope(
          onWillPop: () async {
            if (controller.isGlobalLocked) {
              ShowToastDialog.showToast(
                "Please wait, payment is processing...",
              );
              return false;
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
            ),
            body: _buildBody(controller, themeColors, cartTheme),
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

  Widget _buildBody(
    CartControllerProvider controller,
    CartThemeColors themeColors,
    CartTheme cartTheme,
  ) {
    return HomeProvider.cartItem.isEmpty
        ? Constant.showEmptyView(message: "No Available Items")
        : NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              // 🔑 OPTIMIZATION: Lazy load on scroll end
              if (scrollNotification is ScrollEndNotification) {
                final metrics = scrollNotification.metrics;
                if (metrics.extentAfter < 300) {
                  // Pre-load more data if needed
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddress(controller),
                  cartProductDetailsImageWidget(controller),
                  const SizedBox(height: 20),
                  _buildOffersSection(controller),
                  _buildBillDetails(controller),
                  _buildDeliveryTips(controller),
                  const SizedBox(height: 20),
                  _buildRemarks(controller),
                ],
              ),
            ),
          );
  }

  Widget _buildDeliveryAddress(CartControllerProvider controller) {
    if (controller.selectedFoodType == 'TakeAway') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          controller.changeLocationFunctionInCart(context: context);
        },
        child: Column(
          children: [
            Container(
              decoration: ShapeDecoration(
                color: AppThemeData.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          "assets/icons/ic_send_one.svg",
                          cacheColorFilter: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.selectedAddress?.addressAs?.toString() ??
                                "No Address Selected",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary300,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SvgPicture.asset(
                          "assets/icons/ic_down.svg",
                          cacheColorFilter: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.selectedAddress?.getFullAddress() ??
                          "Please select a delivery address",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(CartControllerProvider controller) {
    return Padding(
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
              ShowToastDialog.showLoader("Loading coupons...".tr);
              unawaited(
                controller
                    .getCartData()
                    .then((_) {
                      ShowToastDialog.closeLoader();
                      Get.to(const CouponListScreen());
                    })
                    .catchError((e) {
                      ShowToastDialog.closeLoader();
                      ShowToastDialog.showToast("Error loading coupons");
                    }),
              );
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Icon(Icons.keyboard_arrow_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails(CartControllerProvider controller) {
    return billCartWidget(controller, context);
  }

  Widget _buildDeliveryTips(CartControllerProvider controller) {
    if (controller.selectedFoodType == 'TakeAway' ||
        (controller.vendorModel.isSelfDelivery == true &&
            Constant.isSelfDeliveryFeature == true)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "Around the clock, our delivery partners bring you your favorite meals. Show your appreciation with a tip."
                              .tr,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            color: AppThemeData.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        "assets/images/ic_tips.svg",
                        cacheColorFilter: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildTipButton(controller, 5.0),
                      const SizedBox(width: 10),
                      _buildTipButton(controller, 10.0),
                      const SizedBox(width: 10),
                      _buildTipButton(controller, 15.0),
                      const SizedBox(width: 10),
                      _buildOtherTipButton(controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(CartControllerProvider controller, double amount) {
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.deliveryTips = amount;
          controller.calculatePrice();
        },
        child: Container(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: controller.deliveryTips == amount
                    ? AppThemeData.primary300
                    : AppThemeData.grey100,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                Constant.amountShow(amount: amount.toStringAsFixed(0)),
                style: TextStyle(
                  color: AppThemeData.grey900,
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherTipButton(CartControllerProvider controller) {
    return Expanded(
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return tipsDialog(controller);
            },
          );
        },
        child: Container(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: AppThemeData.grey100),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                'Other'.tr,
                style: TextStyle(
                  color: AppThemeData.grey900,
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemarks(CartControllerProvider controller) {
    return Padding(
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
    );
  }
}

// Helper class for unawaited
void unawaited(Future<void> future) {
  future.then((_) {}).catchError((e) {});
}
