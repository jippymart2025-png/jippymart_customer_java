// import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
// import 'package:jippymart_customer/app/cart_screen/coupon_list_screen.dart';
// import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
// import 'package:jippymart_customer/app/cart_screen/widget/cart_bill_details_widget.dart';
// import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
// import 'package:jippymart_customer/app/cart_screen/select_payment_screen.dart';
// import 'package:jippymart_customer/app/cart_screen/widget/cart_navigation_bar_widget.dart';
// import 'package:jippymart_customer/app/cart_screen/widget/cart_product_details_image_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
// import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/mart_theme.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/themes/text_field_widget.dart';
// import 'package:jippymart_customer/utils/mart_zone_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:jippymart_customer/utils/utils/color_const.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
//
// class CartScreen extends StatefulWidget {
//   final bool hideBackButton;
//   final String? source;
//   final bool isFromMartNavigation;
//
//   const CartScreen({
//     super.key,
//     this.hideBackButton = false,
//     this.source,
//     this.isFromMartNavigation = false,
//   });
//
//   @override
//   _CartScreenState createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   late CartControllerProvider controller;
//   bool _isRefreshing = false;
//   DateTime? _lastRefreshTime;
//   Timer? _refreshDebounceTimer;
//   Timer? _performanceTimer;
//   Stopwatch _performanceStopwatch = Stopwatch();
//   static const Duration _minRefreshInterval = Duration(seconds: 2);
//
//   @override
//   void initState() {
//     super.initState();
//     _performanceStopwatch.start();
//     controller = Provider.of<CartControllerProvider>(context, listen: false);
//
//     // 🔑 OPTIMIZED: Use microtask for immediate initialization
//     Future.microtask(() {
//       _refreshCartData();
//       _performanceStopwatch.stop();
//       print(
//         '[CART_SCREEN] 🚀 Initialized in ${_performanceStopwatch.elapsedMilliseconds}ms',
//       );
//     });
//
//     // Sync wallet balance from WalletProvider (same as wallet screen) so cart shows same value
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       final wp = Provider.of<WalletProvider>(context, listen: false);
//       final cartController = Provider.of<CartControllerProvider>(context, listen: false);
//       wp.refreshWallet().then((_) {
//         if (mounted) cartController.syncWalletBalanceFromWallet(wp.moneyBalanceRupees);
//       });
//     });
//
//     // Start performance monitoring
//     _performanceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
//       controller.logPerformance();
//     });
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Debounced refresh to prevent excessive calls
//     _scheduleRefresh();
//   }
//
//   void _scheduleRefresh() {
//     _refreshDebounceTimer?.cancel();
//     _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
//       final now = DateTime.now();
//       if (_lastRefreshTime == null ||
//           now.difference(_lastRefreshTime!) > _minRefreshInterval) {
//         _refreshCartData();
//       }
//     });
//   }
//
//   // In CartScreen class, update the refresh method
//   Future<void> _refreshCartData() async {
//     if (_isRefreshing) return;
//
//     _isRefreshing = true;
//     _lastRefreshTime = DateTime.now();
//
//     print('[CART_SCREEN] 🔄 Starting comprehensive cart refresh...');
//
//     try {
//       // Run operations in sequence to avoid conflicts
//       await controller.forceRefreshCart();
//
//       if (controller.selectedAddress == null ||
//           controller.selectedAddress!.location?.latitude == null ||
//           controller.selectedAddress!.location?.longitude == null) {
//         await controller.initializeAddress(context);
//       } else {
//         await controller.syncAddressWithHomeLocation(context);
//       }
//
//       controller.checkAndUpdatePaymentMethod();
//
//       // 🔑 CRITICAL: Force immediate price sync (not in background)
//       print('[CART_SCREEN] 🔄 Starting immediate price sync...');
//       await controller.syncCartPricesInBackground();
//
//       print('[CART_SCREEN] ✅ Cart refresh complete with price sync');
//     } catch (e) {
//       print('[CART_SCREEN] ❌ Error refreshing cart: $e');
//
//       // Fallback: Try basic refresh
//       try {
//         await controller.getCartData();
//         await controller.calculatePrice();
//       } catch (fallbackError) {
//         print('[CART_SCREEN] ❌ Fallback also failed: $fallbackError');
//       }
//     } finally {
//       _isRefreshing = false;
//     }
//   }
//
//   // In your CartScreen's build method, update the button logic:
//
//   Future<void> _handlePlaceOrder(CartControllerProvider controller) async {
//     try {
//       await controller.processPayment(controller, context);
//     } catch (e) {
//       print('❌ [CART_SCREEN] Error placing order: $e');
//       // The controller should handle its own state cleanup
//     }
//   }
//
//   CartThemeColors _getThemeColors(CartTheme theme) {
//     switch (theme) {
//       case CartTheme.mart:
//         return CartThemeColors(
//           primary: MartTheme.jippyMartButton,
//           primaryDark: ColorConst.martPrimary,
//           accent: ColorConst.martPrimary,
//           surface: Colors.white,
//           onSurface: Colors.black87,
//         );
//       case CartTheme.food:
//         return CartThemeColors(
//           primary: const Color(0xFFFF6B35),
//           primaryDark: const Color(0xFFE55A2B),
//           accent: const Color(0xFFFF8A65),
//           surface: AppThemeData.surface,
//           onSurface: Colors.black87,
//         );
//       case CartTheme.mixed:
//         return CartThemeColors(
//           primary: const Color(0xFF607D8B),
//           primaryDark: const Color(0xFF455A64),
//           accent: const Color(0xFF78909C),
//           surface: AppThemeData.surface,
//           onSurface: Colors.black87,
//         );
//     }
//   }
//
//   CartTheme _getCartTheme() {
//     if (widget.source != null) {
//       if (widget.source == 'mart') return CartTheme.mart;
//       if (widget.source == 'food') return CartTheme.food;
//     }
//
//     bool hasMartItems = HomeProvider.cartItem.any(
//       (item) =>
//           item.vendorID?.contains('mart') == true ||
//           item.vendorID?.startsWith('demo_') == true ||
//           item.vendorID?.contains('vendor') == true,
//     );
//
//     bool hasFoodItems = HomeProvider.cartItem.any(
//       (item) =>
//           !(item.vendorID?.contains('mart') == true ||
//               item.vendorID?.startsWith('demo_') == true ||
//               item.vendorID?.contains('vendor') == true),
//     );
//
//     if (hasMartItems && !hasFoodItems) return CartTheme.mart;
//     if (hasFoodItems && !hasMartItems) return CartTheme.food;
//     return CartTheme.mixed;
//   }
//
//   @override
//   void dispose() {
//     _refreshDebounceTimer?.cancel();
//     _performanceTimer?.cancel();
//     _performanceStopwatch.stop();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartTheme = _getCartTheme();
//     final themeColors = _getThemeColors(cartTheme);
//
//     return Consumer<CartControllerProvider>(
//       builder: (context, controller, _) {
//         // 🔑 OPTIMIZATION: Use selective listening
//         final _ = controller.priceSyncVersion;
//
//         return WillPopScope(
//           onWillPop: () async {
//             if (controller.isGlobalLocked) {
//               ShowToastDialog.showToast(
//                 "Please wait, payment is processing...",
//               );
//               return false;
//             }
//             return true;
//           },
//           child: Scaffold(
//             backgroundColor: themeColors.surface,
//             appBar: AppBar(
//               backgroundColor: ColorConst.martPrimary,
//               foregroundColor: Colors.white,
//               automaticallyImplyLeading: !widget.hideBackButton,
//               leading: widget.hideBackButton
//                   ? null
//                   : IconButton(
//                       icon: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         color: Colors.white,
//                       ),
//                       onPressed: () {
//                         if (widget.source == 'mart' &&
//                             widget.isFromMartNavigation) {
//                           try {
//                             final martNavController =
//                                 Provider.of<MartNavigationProvider>(
//                                   context,
//                                   listen: false,
//                                 );
//                             martNavController.goToHome();
//                           } catch (e) {
//                             Get.back();
//                           }
//                         } else {
//                           Get.back();
//                         }
//                       },
//                     ),
//               title: Text(
//                 cartTheme == CartTheme.mart ? 'Mart Cart' : 'Cart',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             body: _buildBody(controller, themeColors, cartTheme),
//             floatingActionButtonLocation:
//                 FloatingActionButtonLocation.centerFloat,
//             bottomNavigationBar: HomeProvider.cartItem.isEmpty
//                 ? null
//                 : cartNavigationBarWidget(context),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildBody(
//     CartControllerProvider controller,
//     CartThemeColors themeColors,
//     CartTheme cartTheme,
//   ) {
//     return HomeProvider.cartItem.isEmpty
//         ? Constant.showEmptyView(message: "No Available Items")
//         : NotificationListener<ScrollNotification>(
//             onNotification: (scrollNotification) {
//               // 🔑 OPTIMIZATION: Lazy load on scroll end
//               if (scrollNotification is ScrollEndNotification) {
//                 final metrics = scrollNotification.metrics;
//                 if (metrics.extentAfter < 300) {
//                   // Pre-load more data if needed
//                 }
//               }
//               return false;
//             },
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildDeliveryAddress(controller),
//                   cartProductDetailsImageWidget(controller),
//                   const SizedBox(height: 20),
//                   _buildOffersSection(controller),
//                   _buildBillDetails(controller),
//                   _buildPaymentMethodRow(controller),
//                   _buildDeliveryTips(controller),
//                   const SizedBox(height: 20),
//                   _buildRemarks(controller),
//                 ],
//               ),
//             ),
//           );
//   }
//
//   Widget _buildDeliveryAddress(CartControllerProvider controller) {
//     if (controller.selectedFoodType == 'TakeAway') return const SizedBox();
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: InkWell(
//         onTap: () {
//           controller.changeLocationFunctionInCart(context: context);
//         },
//         child: Column(
//           children: [
//             Container(
//               decoration: ShapeDecoration(
//                 color: AppThemeData.grey50,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SvgPicture.asset(
//                           "assets/icons/ic_send_one.svg",
//                           cacheColorFilter: true,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             controller.selectedAddress?.addressAs?.toString() ??
//                                 "No Address Selected",
//                             textAlign: TextAlign.start,
//                             style: TextStyle(
//                               fontFamily: AppThemeData.semiBold,
//                               color: AppThemeData.primary300,
//                               fontSize: 16,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         SvgPicture.asset(
//                           "assets/icons/ic_down.svg",
//                           cacheColorFilter: true,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       controller.selectedAddress?.getFullAddress() ??
//                           "Please select a delivery address",
//                       textAlign: TextAlign.start,
//                       style: TextStyle(
//                         fontFamily: AppThemeData.medium,
//                         color: AppThemeData.grey500,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOffersSection(CartControllerProvider controller) {
//     final couponDisabled = controller.isCouponDisabledByWallet;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Offers & Benefits".tr,
//             textAlign: TextAlign.start,
//             style: TextStyle(
//               fontFamily: AppThemeData.semiBold,
//               color: AppThemeData.grey900,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Opacity(
//             opacity: couponDisabled ? 0.5 : 1,
//             child: InkWell(
//               onTap: couponDisabled
//                   ? null
//                   : () async {
//                       ShowToastDialog.showLoader("Loading coupons...".tr);
//                       unawaited(
//                         controller
//                             .getCartData()
//                             .then((_) {
//                               ShowToastDialog.closeLoader();
//                               Get.to(const CouponListScreen());
//                             })
//                             .catchError((e) {
//                               ShowToastDialog.closeLoader();
//                               ShowToastDialog.showToast("Error loading coupons");
//                             }),
//                       );
//                     },
//               child: Container(
//                 width: Responsive.width(100, context),
//                 decoration: ShapeDecoration(
//                   color: AppThemeData.grey50,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   shadows: const [
//                     BoxShadow(
//                       color: Color(0x14000000),
//                       blurRadius: 52,
//                       offset: Offset(0, 0),
//                       spreadRadius: 0,
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 14,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               "Apply Coupons".tr,
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.semiBold,
//                                 color: AppThemeData.grey900,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                           const Icon(Icons.keyboard_arrow_right),
//                         ],
//                       ),
//                       if (couponDisabled) ...[
//                         const SizedBox(height: 6),
//                         Text(
//                           "Coupons cannot be applied when wallet is used.".tr,
//                           style: TextStyle(
//                             fontFamily: AppThemeData.regular,
//                             fontSize: 12,
//                             color: AppThemeData.grey600,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBillDetails(CartControllerProvider controller) {
//     return billCartWidget(controller, context);
//   }
//
//   Widget _buildPaymentMethodRow(CartControllerProvider controller) {
//     final moneyRupees = controller.walletBalanceRupees;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: InkWell(
//         onTap: () {
//           unawaited(controller.refreshWalletBalance());
//           Get.to(const SelectPaymentScreen());
//         },
//         child: Container(
//           width: Responsive.width(100, context),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: AppThemeData.primary50,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: AppThemeData.primary200),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.account_balance_wallet, color: AppThemeData.primary300, size: 28),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Wallet balance".tr,
//                       style: TextStyle(
//                         fontFamily: AppThemeData.medium,
//                         fontSize: 14,
//                         color: AppThemeData.grey600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       Constant.amountShow(amount: moneyRupees.toStringAsFixed(2)),
//                       style: TextStyle(
//                         fontFamily: AppThemeData.semiBold,
//                         fontSize: 22,
//                         color: AppThemeData.primary300,
//                       ),
//                     ),
//                     if (controller.useWalletBalance && controller.walletToUse > 0) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         "${'Using'.tr} ${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))} ${'from wallet'.tr}",
//                         style: TextStyle(
//                           fontFamily: AppThemeData.medium,
//                           fontSize: 12,
//                           color: AppThemeData.grey600,
//                         ),
//                       ),
//                     ] else
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Text(
//                           "Tap to use wallet or change payment".tr,
//                           style: TextStyle(
//                             fontFamily: AppThemeData.regular,
//                             fontSize: 12,
//                             color: AppThemeData.grey600,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.chevron_right, color: AppThemeData.grey500),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDeliveryTips(CartControllerProvider controller) {
//     if (controller.selectedFoodType == 'TakeAway' ||
//         (controller.vendorModel.isSelfDelivery == true &&
//             Constant.isSelfDeliveryFeature == true)) {
//       return const SizedBox();
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 20),
//           Text(
//             "Thanks with a tip!".tr,
//             textAlign: TextAlign.start,
//             style: TextStyle(
//               fontFamily: AppThemeData.semiBold,
//               color: AppThemeData.grey900,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Container(
//             width: Responsive.width(100, context),
//             decoration: ShapeDecoration(
//               color: AppThemeData.grey50,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               shadows: const [
//                 BoxShadow(
//                   color: Color(0x14000000),
//                   blurRadius: 52,
//                   offset: Offset(0, 0),
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//               child: Column(
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           "Around the clock, our delivery partners bring you your favorite meals. Show your appreciation with a tip."
//                               .tr,
//                           textAlign: TextAlign.start,
//                           style: TextStyle(
//                             fontFamily: AppThemeData.medium,
//                             color: AppThemeData.grey600,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       SvgPicture.asset(
//                         "assets/images/ic_tips.svg",
//                         cacheColorFilter: true,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       _buildTipButton(controller, 5.0),
//                       const SizedBox(width: 10),
//                       _buildTipButton(controller, 10.0),
//                       const SizedBox(width: 10),
//                       _buildTipButton(controller, 15.0),
//                       const SizedBox(width: 10),
//                       _buildOtherTipButton(controller),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTipButton(CartControllerProvider controller, double amount) {
//     return Expanded(
//       child: InkWell(
//         onTap: () {
//           controller.deliveryTips = amount;
//           controller.calculatePrice();
//         },
//         child: Container(
//           decoration: ShapeDecoration(
//             shape: RoundedRectangleBorder(
//               side: BorderSide(
//                 width: 1,
//                 color: controller.deliveryTips == amount
//                     ? AppThemeData.primary300
//                     : AppThemeData.grey100,
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Center(
//               child: Text(
//                 Constant.amountShow(amount: amount.toStringAsFixed(0)),
//                 style: TextStyle(
//                   color: AppThemeData.grey900,
//                   fontSize: 14,
//                   fontFamily: AppThemeData.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOtherTipButton(CartControllerProvider controller) {
//     return Expanded(
//       child: InkWell(
//         onTap: () {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return tipsDialog(controller);
//             },
//           );
//         },
//         child: Container(
//           decoration: ShapeDecoration(
//             shape: RoundedRectangleBorder(
//               side: BorderSide(width: 1, color: AppThemeData.grey100),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Center(
//               child: Text(
//                 'Other'.tr,
//                 style: TextStyle(
//                   color: AppThemeData.grey900,
//                   fontSize: 14,
//                   fontFamily: AppThemeData.medium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRemarks(CartControllerProvider controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         children: [
//           TextFieldWidget(
//             title: 'Remarks'.tr,
//             controller: controller.reMarkController,
//             hintText: 'Write remarks for the restaurant'.tr,
//             maxLine: 4,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Helper class for unawaited
// void unawaited(Future<void> future) {
//   future.then((_) {}).catchError((e) {});
// }

import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/cart_screen/coupon_list_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_bill_details_widget.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/cart_screen/select_payment_screen.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_navigation_bar_widget.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_product_details_image_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
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
  final Stopwatch _performanceStopwatch = Stopwatch();
  static const Duration _minRefreshInterval = Duration(seconds: 2);

  // ─── THEME COLORS (unchanged logic) ───────────────────────────────────────

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

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _performanceStopwatch.start();
    controller = Provider.of<CartControllerProvider>(context, listen: false);
    Future.microtask(() {
      _refreshCartData();
      _performanceStopwatch.stop();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wp = Provider.of<WalletProvider>(context, listen: false);
      final cartController = Provider.of<CartControllerProvider>(
        context,
        listen: false,
      );
      wp.refreshWallet().then((_) {
        if (mounted) {
          cartController.syncWalletBalanceFromWallet(wp.moneyBalanceRupees);
        }
      });
    });
    _performanceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      controller.logPerformance();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  Future<void> _refreshCartData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();
    try {
      await controller.forceRefreshCart();
      if (controller.selectedAddress == null ||
          controller.selectedAddress!.location?.latitude == null ||
          controller.selectedAddress!.location?.longitude == null) {
        await controller.initializeAddress(context);
      } else {
        await controller.syncAddressWithHomeLocation(context);
      }
      controller.checkAndUpdatePaymentMethod();
      await controller.syncCartPricesInBackground();
    } catch (e) {
      try {
        await controller.getCartData();
        await controller.calculatePrice();
      } catch (_) {}
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handlePlaceOrder(CartControllerProvider controller) async {
    try {
      await controller.processPayment(controller, context);
    } catch (e) {
      debugPrint('❌ [CART_SCREEN] Error placing order: $e');
    }
  }

  @override
  void dispose() {
    _refreshDebounceTimer?.cancel();
    _performanceTimer?.cancel();
    _performanceStopwatch.stop();
    super.dispose();
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartTheme = _getCartTheme();
    final themeColors = _getThemeColors(cartTheme);

    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
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
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: _buildAppBar(cartTheme),
            body: _buildBody(controller, themeColors, cartTheme),
            bottomNavigationBar: HomeProvider.cartItem.isEmpty
                ? null
                : cartNavigationBarWidget(context),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CartTheme cartTheme) {
    return AppBar(
      backgroundColor: ColorConst.martPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: !widget.hideBackButton,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: widget.hideBackButton
          ? null
          : IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (widget.source == 'mart' && widget.isFromMartNavigation) {
                  try {
                    final martNavController =
                        Provider.of<MartNavigationProvider>(
                          context,
                          listen: false,
                        );
                    martNavController.goToHome();
                  } catch (_) {
                    Get.back();
                  }
                } else {
                  Get.back();
                }
              },
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cartTheme == CartTheme.mart ? 'Mart Cart' : 'Your Cart',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (HomeProvider.cartItem.isNotEmpty)
            Text(
              '${HomeProvider.cartItem.length} item${HomeProvider.cartItem.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    CartControllerProvider controller,
    CartThemeColors themeColors,
    CartTheme cartTheme,
  ) {
    if (HomeProvider.cartItem.isEmpty) {
      return _buildEmptyCart();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Delivery Address ──────────────────────────────────────────────
          _buildDeliveryAddress(controller),

          // ── Products Card ─────────────────────────────────────────────────
          _buildSectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: cartProductDetailsImageWidget(controller),
          ),

          const SizedBox(height: 8),

          // ── Coupon / Offers ───────────────────────────────────────────────
          _buildOffersSection(controller),

          const SizedBox(height: 8),

          // ── Bill Details ──────────────────────────────────────────────────
          _buildBillDetails(controller),

          const SizedBox(height: 8),

          // ── Payment Method ────────────────────────────────────────────────
          // _buildPaymentMethodRow(controller),
          const SizedBox(height: 8),

          // ── Delivery Tips ─────────────────────────────────────────────────
          _buildDeliveryTips(controller),

          const SizedBox(height: 8),

          // ── Remarks ───────────────────────────────────────────────────────
          _buildRemarks(controller),

          const SizedBox(height: 100), // space for bottom nav
        ],
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppThemeData.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: AppThemeData.primary300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION WRAPPER ───────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── DELIVERY ADDRESS ──────────────────────────────────────────────────────

  Widget _buildDeliveryAddress(CartControllerProvider controller) {
    if (controller.selectedFoodType == 'TakeAway') return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.changeLocationFunctionInCart(context: context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Pin icon with colored background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppThemeData.primary50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppThemeData.primary300,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Address text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Delivering to',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.grey500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.selectedAddress?.addressAs?.toString() ??
                                'Home',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      controller.selectedAddress?.getFullAddress() ??
                          'Select delivery address',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Change label
              Text(
                'Change',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.primary300,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppThemeData.primary300,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OFFERS / COUPONS ──────────────────────────────────────────────────────

  Widget _buildOffersSection(CartControllerProvider controller) {
    final couponDisabled = controller.isCouponDisabledByWallet;
    final hasCoupon =
        controller.selectedCouponModel.id != null &&
        controller.selectedCouponModel.id!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: couponDisabled
            ? null
            : () async {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Offer icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasCoupon
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasCoupon
                      ? Icons.check_circle_outline
                      : Icons.local_offer_outlined,
                  color: hasCoupon
                      ? const Color(0xFF43A047)
                      : const Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCoupon ? 'Coupon Applied 🎉' : 'Apply Coupon',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.semiBold,
                        color: hasCoupon
                            ? const Color(0xFF43A047)
                            : AppThemeData.grey900,
                      ),
                    ),
                    if (hasCoupon) ...[
                      const SizedBox(height: 2),
                      Text(
                        controller.selectedCouponModel.code ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.grey600,
                        ),
                      ),
                    ] else if (couponDisabled) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Not applicable with wallet',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey500,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        'Save more on your order',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!couponDisabled)
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: AppThemeData.grey400,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BILL DETAILS ──────────────────────────────────────────────────────────

  Widget _buildBillDetails(CartControllerProvider controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: billCartWidget(controller, context),
    );
  }

  // ─── PAYMENT METHOD ────────────────────────────────────────────────────────

  // Widget _buildPaymentMethodRow(CartControllerProvider controller) {
  //   final moneyRupees = controller.walletBalanceRupees;
  //   final isWalletActive =
  //       controller.useWalletBalance && controller.walletToUse > 0;
  //
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(12),
  //       onTap: () {
  //         unawaited(controller.refreshWalletBalance());
  //         Get.to(const SelectPaymentScreen());
  //       },
  //       child: Padding(
  //         padding: const EdgeInsets.all(14),
  //         child: Row(
  //           children: [
  //             // Wallet icon
  //             Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: isWalletActive
  //                     ? AppThemeData.primary50
  //                     : AppThemeData.grey50,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Icon(
  //                 Icons.account_balance_wallet_outlined,
  //                 color: isWalletActive
  //                     ? AppThemeData.primary300
  //                     : AppThemeData.grey400,
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       Text(
  //                         'Wallet',
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           fontFamily: AppThemeData.semiBold,
  //                           color: AppThemeData.grey900,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 8,
  //                           vertical: 2,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: AppThemeData.primary50,
  //                           borderRadius: BorderRadius.circular(20),
  //                           border: Border.all(color: AppThemeData.primary200),
  //                         ),
  //                         child: Text(
  //                           Constant.amountShow(
  //                             amount: moneyRupees.toStringAsFixed(2),
  //                           ),
  //                           style: TextStyle(
  //                             fontSize: 12,
  //                             fontFamily: AppThemeData.semiBold,
  //                             color: AppThemeData.primary300,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     isWalletActive
  //                         ? 'Using ${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))} from wallet'
  //                         : 'Tap to manage payment options',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       fontFamily: AppThemeData.regular,
  //                       color: isWalletActive
  //                           ? AppThemeData.primary300
  //                           : AppThemeData.grey500,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Icon(
  //               Icons.keyboard_arrow_right_rounded,
  //               color: AppThemeData.grey400,
  //               size: 22,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ─── DELIVERY TIPS ─────────────────────────────────────────────────────────

  Widget _buildDeliveryTips(CartControllerProvider controller) {
    if (controller.selectedFoodType == 'TakeAway' ||
        (controller.vendorModel.isSelfDelivery == true &&
            Constant.isSelfDeliveryFeature == true)) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '🤝',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip your delivery partner',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.grey900,
                        ),
                      ),
                      Text(
                        'They bring your order rain or shine',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.deliveryTips > 0)
                  GestureDetector(
                    onTap: () {
                      controller.deliveryTips = 0;
                      controller.calculatePrice();
                    },
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.danger300,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildTipChip(controller, 5.0, '⭐ ₹5'),
                const SizedBox(width: 8),
                _buildTipChip(controller, 10.0, '💚 ₹10'),
                const SizedBox(width: 8),
                _buildTipChip(controller, 15.0, '🙏 ₹15'),
                const SizedBox(width: 8),
                _buildCustomTipChip(controller),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipChip(
    CartControllerProvider controller,
    double amount,
    String label,
  ) {
    final isSelected = controller.deliveryTips == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.deliveryTips = amount;
          controller.calculatePrice();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppThemeData.primary300 : AppThemeData.grey50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppThemeData.primary300
                  : AppThemeData.grey200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.semiBold,
                color: isSelected ? Colors.white : AppThemeData.grey700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipChip(CartControllerProvider controller) {
    final isCustom =
        controller.deliveryTips > 0 &&
        controller.deliveryTips != 5.0 &&
        controller.deliveryTips != 10.0 &&
        controller.deliveryTips != 15.0;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => tipsDialog(controller),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isCustom ? AppThemeData.primary300 : AppThemeData.grey50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCustom ? AppThemeData.primary300 : AppThemeData.grey200,
            ),
          ),
          child: Center(
            child: Text(
              isCustom
                  ? Constant.amountShow(
                      amount: controller.deliveryTips.toStringAsFixed(0),
                    )
                  : 'Other',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.semiBold,
                color: isCustom ? Colors.white : AppThemeData.grey700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── REMARKS ───────────────────────────────────────────────────────────────

  Widget _buildRemarks(CartControllerProvider controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note_outlined,
                  color: AppThemeData.grey500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Cooking Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeData.grey100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.regular,
                      color: AppThemeData.grey500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFieldWidget(
              controller: controller.reMarkController,
              hintText: 'e.g. Less spicy, extra napkins...'.tr,
              maxLine: 3,
            ),
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {
  future.then((_) {}).catchError((e) {});
}
