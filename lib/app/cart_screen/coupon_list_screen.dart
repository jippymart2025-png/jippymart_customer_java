// import 'dart:ui';
//
// import 'package:flutter_svg/svg.dart';
// import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
//     show CartControllerProvider;
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/coupon_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/text_field_widget.dart';
// import 'package:jippymart_customer/utils/utils/color_const.dart';
// import 'package:jippymart_customer/utils/utils/image_const.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:dotted_border/src/dotted_border_options.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// class CouponListScreen extends StatefulWidget {
//   const CouponListScreen({super.key});
//
//   @override
//   State<CouponListScreen> createState() => _CouponListScreenState();
// }
//
// class _CouponListScreenState extends State<CouponListScreen> {
//   bool _hasInitialized = false;
//   final TextEditingController _couponCodeController = TextEditingController();
//   CouponModel? _selectedCoupon;
//
//   @override
//   void initState() {
//     super.initState();
//     // 🔑 OPTIMIZATION: Initialize immediately without postFrameCallback delay
//     // This allows cached coupons to show instantly
//     if (!_hasInitialized) {
//       _hasInitialized = true;
//       // Use microtask to avoid blocking but still be fast
//       Future.microtask(() {
//         if (mounted) {
//           final controller = Provider.of<CartControllerProvider>(
//             context,
//             listen: false,
//           );
//           _initializeWithCachedCoupons(controller);
//         }
//       });
//     }
//   }
//
//   void _initializeWithCachedCoupons(CartControllerProvider controller) {
//     // 🔑 OPTIMIZATION: Show cached coupons immediately, refresh in background if needed
//     if (controller.couponList.isNotEmpty) {
//       // Coupons are already loaded and cached, no need to reload
//       // Just trigger a background refresh if cache might be stale
//       controller.ensureCouponsLoaded();
//     } else {
//       // If no coupons in cache, trigger a load
//       controller.ensureCouponsLoaded();
//     }
//   }
//
//   void _applyCoupon(CartControllerProvider controller, CouponModel coupon) {
//     if (coupon.isEnabled == false) {
//       ShowToastDialog.showToast("You have already used this coupon".tr);
//       return;
//     }
//
//     final enteredCode = _couponCodeController.text.trim().toLowerCase();
//     final couponCode = coupon.code?.toLowerCase() ?? '';
//
//     // Validate coupon code matches
//     if (enteredCode.isNotEmpty && enteredCode != couponCode) {
//       ShowToastDialog.showToast("Coupon code doesn't match".tr);
//       return;
//     }
//
//     double minValue = double.tryParse(coupon.itemValue ?? '0') ?? 0.0;
//     if (controller.subTotal < minValue) {
//       ShowToastDialog.showToast(
//         "This coupon can only be applied for orders above ₹${minValue.toStringAsFixed(0)}.",
//       );
//       return;
//     }
//
//     // Calculate discount to validate
//     double couponAmount = Constant.calculateDiscount(
//       amount: controller.subTotal.toString(),
//       offerModel: coupon,
//     );
//
//     if (couponAmount >= controller.subTotal) {
//       ShowToastDialog.showToast("Coupon discount cannot exceed order total".tr);
//       return;
//     }
//
//     // Apply the coupon
//     _selectedCoupon = coupon;
//     _couponCodeController.text = coupon.code ?? '';
//
//     // Update the controller
//     controller.selectedCouponModel = coupon;
//     controller.couponCodeController.text = coupon.code ?? '';
//     controller.calculatePrice();
//
//     ShowToastDialog.showToast("Coupon applied successfully!".tr);
//     Get.back();
//   }
//
//   void _applyManualCoupon(CartControllerProvider controller) {
//     final enteredCode = _couponCodeController.text.trim();
//     if (enteredCode.isEmpty) {
//       ShowToastDialog.showToast("Please enter a coupon code".tr);
//       return;
//     }
//
//     final foundCoupons = controller.allCouponList
//         .where(
//           (coupon) => coupon.code?.toLowerCase() == enteredCode.toLowerCase(),
//         )
//         .toList();
//
//     if (foundCoupons.isEmpty) {
//       ShowToastDialog.showToast("Invalid coupon code".tr);
//       return;
//     }
//
//     final coupon = foundCoupons.first;
//     _applyCoupon(controller, coupon);
//   }
//
//   Widget _buildCouponItem(
//     CartControllerProvider controller,
//     CouponModel coupon,
//     int index,
//   ) {
//     final isLoading = controller.isLoadingCoupons;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Container(
//         color: Colors.transparent,
//         child: GestureDetector(
//           onTap: isLoading
//               ? null
//               : coupon.isEnabled == false
//                   ? () {
//                       ShowToastDialog.showToast("Coupon already used".tr);
//                     }
//                   : () {
//                       _applyCoupon(controller, coupon);
//                     },
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: SvgPicture.asset(
//                     color: coupon.isEnabled == true ? null : Colors.grey,
//                     ImageConst.cupon,
//                     fit: BoxFit.fill,
//                   ),
//                 ),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: 60,
//                       height: 125,
//                       child: Padding(
//                         padding: const EdgeInsets.only(left: 10),
//                         child: Align(
//                           alignment: Alignment.center,
//                           child: RotatedBox(
//                             quarterTurns: -1,
//                             child: Text(
//                               "${coupon.discountType == "Fix Price" ? Constant.amountShow(amount: coupon.discount) : "${coupon.discount}%"} ${'Off'.tr}",
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.semiBold,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 20,
//                                 color: AppThemeData.surface,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     SizedBox(
//                       height: 80,
//                       child: DottedBorder(
//                         options: CustomPathDottedBorderOptions(
//                           dashPattern: const [8, 8],
//                           strokeWidth: 4,
//                           color: ColorConst.white,
//                           customPath: (size) {
//                             return Path()
//                               ..moveTo(size.width / 2, 0)
//                               ..lineTo(size.width / 2, size.height);
//                           },
//                         ),
//                         child: const SizedBox(width: 2),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Coupon",
//                             textAlign: TextAlign.start,
//                             style: TextStyle(
//                               fontFamily: AppThemeData.semiBold,
//                               fontSize: 40,
//                               color: AppThemeData.surface,
//                             ),
//                           ),
//                           Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               SvgPicture.asset(
//                                 ImageConst.codeCupon,
//                                 fit: BoxFit.fill,
//                                 height: 40,
//                                 width: 40,
//                               ),
//                               Center(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const SizedBox(height: 5),
//                                     Text(
//                                       coupon.code ?? "",
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         fontFamily: AppThemeData.semiBold,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 14,
//                                         color: AppThemeData.surface,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           SizedBox(
//                             width: 220,
//                             child: Text(
//                               coupon.description ?? "",
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.medium,
//                                 fontSize: 16,
//                                 color: AppThemeData.surface,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           if (coupon.isEnabled == false)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.red.withOpacity(0.8),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "Already Used",
//                                 style: TextStyle(
//                                   color: AppThemeData.surface,
//                                   fontFamily: AppThemeData.medium,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.confirmation_num_outlined,
//             size: 64,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No coupons available',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade600,
//               fontFamily: AppThemeData.medium,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Check back later for new offers',
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CartControllerProvider>(
//       builder: (context, controller, _) {
//         // 🔑 OPTIMIZATION: Get coupons once to avoid multiple lookups
//         final coupons = controller.couponList;
//         final isLoading = controller.isLoadingCoupons;
//
//         return Scaffold(
//           backgroundColor: AppThemeData.surface,
//           appBar: AppBar(
//             backgroundColor: AppThemeData.surface,
//             centerTitle: false,
//             titleSpacing: 0,
//             title: Text(
//               "Coupon Code".tr,
//               textAlign: TextAlign.start,
//               style: TextStyle(
//                 fontFamily: AppThemeData.medium,
//                 fontSize: 16,
//                 color: AppThemeData.grey900,
//               ),
//             ),
//             bottom: PreferredSize(
//               preferredSize: const Size.fromHeight(75),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 10,
//                 ),
//                 child: Column(
//                   children: [
//                     TextFieldWidget(
//                       hintText: 'Enter coupon code'.tr,
//                       controller: _couponCodeController,
//                       enable: !isLoading,
//                       suffix: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
//                         child: InkWell(
//                           onTap: isLoading ? null : () => _applyManualCoupon(controller),
//                           child: Text(
//                             "Apply".tr,
//                             textAlign: TextAlign.start,
//                             style: TextStyle(
//                               fontFamily: AppThemeData.semiBold,
//                               fontSize: 16,
//                               color: isLoading ? Colors.grey : AppThemeData.primary300,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     if (isLoading)
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 14,
//                               height: 14,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   AppThemeData.primary300,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               "Loading coupons...".tr,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     else if (coupons.isNotEmpty)
//                       Text(
//                         "${coupons.length} coupons available",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           body: isLoading && coupons.isEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           AppThemeData.primary300,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "Loading coupons...".tr,
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                           fontFamily: AppThemeData.medium,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : coupons.isEmpty
//                   ? _buildEmptyState()
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: coupons.length,
//                       itemBuilder: (context, index) {
//                         return _buildCouponItem(controller, coupons[index], index);
//                       },
//                     ),
//         );
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _couponCodeController.dispose();
//     super.dispose();
//   }
// }
// // import 'dart:ui';
// //
// // import 'package:flutter_svg/svg.dart';
// // import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
// //     show CartControllerProvider;
// // import 'package:jippymart_customer/constant/constant.dart';
// // import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// // import 'package:jippymart_customer/models/coupon_model.dart';
// // import 'package:jippymart_customer/themes/app_them_data.dart';
// // import 'package:jippymart_customer/themes/text_field_widget.dart';
// // import 'package:jippymart_customer/utils/utils/color_const.dart';
// // import 'package:jippymart_customer/utils/utils/image_const.dart';
// // import 'package:dotted_border/dotted_border.dart';
// // import 'package:dotted_border/src/dotted_border_options.dart';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:provider/provider.dart';
// //
// // class CouponListScreen extends StatefulWidget {
// //   const CouponListScreen({super.key});
// //
// //   @override
// //   State<CouponListScreen> createState() => _CouponListScreenState();
// // }
// //
// // class _CouponListScreenState extends State<CouponListScreen> {
// //   bool _hasInitialized = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!_hasInitialized) {
// //         _hasInitialized = true;
// //         final controller = Provider.of<CartControllerProvider>(
// //           context,
// //           listen: false,
// //         );
// //         controller.ensureCouponsLoaded();
// //       }
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<CartControllerProvider>(
// //       builder: (context, controller, _) {
// //         if (controller.couponList.isEmpty) {
// //           return Scaffold(
// //             backgroundColor: AppThemeData.surface,
// //             appBar: AppBar(
// //               backgroundColor: AppThemeData.surface,
// //               centerTitle: false,
// //               titleSpacing: 0,
// //               title: Text(
// //                 "Coupon Code".tr,
// //                 textAlign: TextAlign.start,
// //                 style: TextStyle(
// //                   fontFamily: AppThemeData.medium,
// //                   fontSize: 16,
// //                   color: AppThemeData.grey900,
// //                 ),
// //               ),
// //             ),
// //             body: Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Text(
// //                     'No coupons available',
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         }
// //         return Scaffold(
// //           backgroundColor: AppThemeData.surface,
// //           appBar: AppBar(
// //             backgroundColor: AppThemeData.surface,
// //             centerTitle: false,
// //             titleSpacing: 0,
// //             title: Text(
// //               "Coupon Code".tr,
// //               textAlign: TextAlign.start,
// //               style: TextStyle(
// //                 fontFamily: AppThemeData.medium,
// //                 fontSize: 16,
// //                 color: AppThemeData.grey900,
// //               ),
// //             ),
// //             bottom: PreferredSize(
// //               preferredSize: const Size.fromHeight(55),
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// //                 child: TextFieldWidget(
// //                   hintText: 'Enter coupon code'.tr,
// //                   controller: controller.couponCodeController,
// //                   suffix: Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 16,
// //                       vertical: 12,
// //                     ),
// //                     child: InkWell(
// //                       onTap: () {
// //                         final enteredCode = controller
// //                             .couponCodeController
// //                             .value
// //                             .text
// //                             .toLowerCase();
// //                         final found = controller.allCouponList.where(
// //                           (p0) => p0.code!.toLowerCase() == enteredCode,
// //                         );
// //                         if (found.isNotEmpty) {
// //                           CouponModel element = found.first;
// //                           if (element.isEnabled == false) {
// //                             ShowToastDialog.showToast(
// //                               "You have already used this coupon".tr,
// //                             );
// //                             return;
// //                           }
// //                           double minValue =
// //                               double.tryParse(element.itemValue ?? '0') ?? 0.0;
// //                           if (controller.subTotal <= minValue) {
// //                             ShowToastDialog.showToast(
// //                               "This coupon can only be applied for orders above ₹${minValue.toStringAsFixed(0)}.",
// //                             );
// //                             return;
// //                           }
// //                           controller.selectedCouponModel = element;
// //                           controller.calculatePrice();
// //                           Get.back();
// //                         } else {
// //                           ShowToastDialog.showToast("Invalid Coupon".tr);
// //                         }
// //                       },
// //                       child: Text(
// //                         "Apply",
// //                         textAlign: TextAlign.start,
// //                         style: TextStyle(
// //                           fontFamily: AppThemeData.semiBold,
// //                           fontSize: 16,
// //                           color: AppThemeData.primary300,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //           body: controller.couponList.isEmpty
// //               ? Center(
// //                   child: Text(
// //                     'No coupons available',
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 )
// //               : ListView.builder(
// //                   shrinkWrap: true,
// //                   itemCount: controller.couponList.length,
// //                   itemBuilder: (context, index) {
// //                     CouponModel couponModel = controller.couponList[index];
// //                     return Padding(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 16,
// //                         vertical: 10,
// //                       ),
// //                       child: Container(
// //                         color: Colors.transparent,
// //                         // decoration: ShapeDecoration(
// //                         //   color: couponModel.isEnabled == false
// //                         //       ? (themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey200)
// //                         //       : (themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50),
// //                         //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //                         //
// //                         // ),
// //                         // decoration: ShapeDecoration(
// //                         //   color: couponModel.isEnabled == false
// //                         //       ? (themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey200)
// //                         //       : (themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50),
// //                         //   shape: RoundedRectangleBorder(
// //                         //     borderRadius: BorderRadius.circular(10),
// //                         //   ),
// //                         //   shadows: const [ // optional elevation
// //                         //     BoxShadow(
// //                         //       color: Colors.black26,
// //                         //       blurRadius: 6,
// //                         //       offset: Offset(0, 3),
// //                         //     ),
// //                         //   ],
// //                         // ),
// //                         child: GestureDetector(
// //                           onTap: couponModel.isEnabled == false
// //                               ? () {
// //                                   ShowToastDialog.showToast("Coupon Expired");
// //                                 }
// //                               : () {
// //                                   double minValue =
// //                                       double.tryParse(
// //                                         couponModel.itemValue ?? '0',
// //                                       ) ??
// //                                       0.0;
// //                                   if (controller.subTotal <= minValue) {
// //                                     ShowToastDialog.showToast(
// //                                       "This coupon can only be applied for orders above ₹${minValue.toStringAsFixed(0)}.",
// //                                     );
// //                                     return;
// //                                   }
// //                                   double couponAmount =
// //                                       Constant.calculateDiscount(
// //                                         amount: controller.subTotal.toString(),
// //                                         offerModel: couponModel,
// //                                       );
// //                                   if (couponAmount < controller.subTotal) {
// //                                     controller.selectedCouponModel =
// //                                         couponModel;
// //                                     controller.couponCodeController.text =
// //                                         couponModel.code ?? '';
// //                                     controller.calculatePrice();
// //                                     Get.back();
// //                                   } else {
// //                                     ShowToastDialog.showToast(
// //                                       "Coupon code not applied".tr,
// //                                     );
// //                                   }
// //                                 },
// //                           child: ClipRRect(
// //                             borderRadius: BorderRadius.circular(10),
// //                             child: Stack(
// //                               children: [
// //                                 Positioned.fill(
// //                                   child: SvgPicture.asset(
// //                                     color: couponModel.isEnabled == true
// //                                         ? null
// //                                         : Colors.grey,
// //                                     ImageConst.cupon,
// //                                     fit: BoxFit.fill,
// //                                   ),
// //                                 ),
// //                                 Row(
// //                                   crossAxisAlignment: CrossAxisAlignment.center,
// //                                   children: [
// //                                     SizedBox(
// //                                       width: 60,
// //                                       height: 125,
// //                                       child: Padding(
// //                                         padding: const EdgeInsets.only(
// //                                           left: 10,
// //                                         ),
// //                                         child: Align(
// //                                           alignment: Alignment.center,
// //                                           child: RotatedBox(
// //                                             quarterTurns: -1,
// //                                             child: Text(
// //                                               "${couponModel.discountType == "Fix Price" ? Constant.amountShow(amount: couponModel.discount) : "${couponModel.discount}%"} ${'Off'.tr}",
// //                                               textAlign: TextAlign.start,
// //                                               style: TextStyle(
// //                                                 fontFamily:
// //                                                     AppThemeData.semiBold,
// //                                                 fontWeight: FontWeight.bold,
// //                                                 fontSize: 20,
// //                                                 color: AppThemeData.surface,
// //                                               ),
// //                                             ),
// //                                           ),
// //                                         ),
// //                                       ),
// //                                     ),
// //                                     SizedBox(width: 20),
// //                                     SizedBox(
// //                                       height: 80,
// //                                       child: DottedBorder(
// //                                         options: CustomPathDottedBorderOptions(
// //                                           dashPattern: [8, 8],
// //                                           strokeWidth: 4,
// //                                           color: ColorConst.white,
// //                                           customPath: (size) {
// //                                             return Path()
// //                                               ..moveTo(size.width / 2, 0)
// //                                               ..lineTo(
// //                                                 size.width / 2,
// //                                                 size.height,
// //                                               );
// //                                           },
// //                                         ),
// //                                         child: const SizedBox(
// //                                           width: 2,
// //                                         ), // just a thin column
// //                                       ),
// //                                     ),
// //                                     SizedBox(width: 10),
// //                                     Column(
// //                                       children: [
// //                                         Text(
// //                                           "Coupon",
// //                                           textAlign: TextAlign.start,
// //                                           style: TextStyle(
// //                                             fontFamily: AppThemeData.semiBold,
// //                                             // fontWeight: FontWeight.bold,
// //                                             fontSize: 40,
// //                                             color: AppThemeData.surface,
// //                                           ),
// //                                         ),
// //                                         Stack(
// //                                           alignment: Alignment.center,
// //                                           // ✅ centers all children
// //                                           children: [
// //                                             SvgPicture.asset(
// //                                               ImageConst.codeCupon,
// //                                               fit: BoxFit.fill,
// //                                               height: 40,
// //                                               width: 40,
// //                                             ),
// //                                             Center(
// //                                               // ✅ ensures the text stays centered
// //                                               child: Column(
// //                                                 mainAxisSize: MainAxisSize.min,
// //                                                 children: [
// //                                                   SizedBox(height: 5),
// //                                                   Text(
// //                                                     "${couponModel.code}",
// //                                                     textAlign: TextAlign.center,
// //                                                     style: TextStyle(
// //                                                       fontFamily:
// //                                                           AppThemeData.semiBold,
// //                                                       fontWeight:
// //                                                           FontWeight.bold,
// //                                                       fontSize: 14,
// //                                                       color:
// //                                                           AppThemeData.surface,
// //                                                     ),
// //                                                   ),
// //                                                 ],
// //                                               ),
// //                                             ),
// //                                           ],
// //                                         ),
// //                                         SizedBox(height: 10),
// //                                         SizedBox(
// //                                           width: 220,
// //                                           child: Text(
// //                                             "${couponModel.description}",
// //                                             textAlign: TextAlign.start,
// //                                             style: TextStyle(
// //                                               fontFamily: AppThemeData.medium,
// //                                               fontSize: 16,
// //                                               color: AppThemeData.surface,
// //                                             ),
// //                                             maxLines: 2,
// //                                           ),
// //                                         ),
// //                                         SizedBox(height: 10),
// //                                       ],
// //                                     ),
// //                                     // Expanded(
// //                                     //   child: Padding(
// //                                     //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
// //                                     //     child: Column(
// //                                     //       crossAxisAlignment: CrossAxisAlignment.start,
// //                                     //       mainAxisSize: MainAxisSize.min,
// //                                     //       children: [
// //                                     //         Row(
// //                                     //           children: [
// //                                     //             DottedBorder(
// //                                     //               options: RoundedRectDottedBorderOptions(
// //                                     //                 color: couponModel.isEnabled == false
// //                                     //                     ? (themeChange.getThem()
// //                                     //                     ? AppThemeData.grey600
// //                                     //                     : AppThemeData.grey400)
// //                                     //                     : (themeChange.getThem()
// //                                     //                     ? AppThemeData.grey400
// //                                     //                     : AppThemeData.grey500),
// //                                     //                 strokeWidth: 1,
// //                                     //                 radius: const Radius.circular(6),
// //                                     //                 dashPattern: const [6, 6],
// //                                     //               ),
// //                                     //               child: Padding(
// //                                     //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// //                                     //                 child: Text(
// //                                     //                   "${couponModel.code}",
// //                                     //                   textAlign: TextAlign.start,
// //                                     //                   style: TextStyle(
// //                                     //                     fontFamily: AppThemeData.semiBold,
// //                                     //                     fontSize: 16,
// //                                     //                     color: couponModel.isEnabled == false
// //                                     //                         ? (themeChange.getThem()
// //                                     //                         ? AppThemeData.grey600
// //                                     //                         : AppThemeData.grey400)
// //                                     //                         : (themeChange.getThem()
// //                                     //                         ? AppThemeData.grey400
// //                                     //                         : AppThemeData.grey500),
// //                                     //                   ),
// //                                     //                 ),
// //                                     //               ),
// //                                     //             ),
// //                                     //             const SizedBox(width: 8),
// //                                     //             if (couponModel.isEnabled == false)
// //                                     //               Container(
// //                                     //                 padding: const EdgeInsets.symmetric(
// //                                     //                     horizontal: 8, vertical: 2),
// //                                     //                 decoration: BoxDecoration(
// //                                     //                   color: themeChange.getThem()
// //                                     //                       ? AppThemeData.grey700
// //                                     //                       : AppThemeData.grey300,
// //                                     //                   borderRadius: BorderRadius.circular(6),
// //                                     //                 ),
// //                                     //                 child: Text(
// //                                     //                   "Used",
// //                                     //                   style: TextStyle(
// //                                     //                     color: themeChange.getThem()
// //                                     //                         ? AppThemeData.grey200
// //                                     //                         : AppThemeData.grey800,
// //                                     //                     fontFamily: AppThemeData.medium,
// //                                     //                     fontSize: 12,
// //                                     //                   ),
// //                                     //                 ),
// //                                     //               ),
// //                                     //             const Expanded(child: SizedBox(height: 10)),
// //                                     //             InkWell(
// //                                     //               onTap: couponModel.isEnabled == false
// //                                     //                   ? null
// //                                     //                   : () {
// //                                     //                 double minValue = double.tryParse(
// //                                     //                     couponModel.itemValue ?? '0') ??
// //                                     //                     0.0;
// //                                     //                 if (controller.subTotal.value <= minValue) {
// //                                     //                   ShowToastDialog.showToast(
// //                                     //                     "This coupon can only be applied for orders above ₹${minValue.toStringAsFixed(0)}.",
// //                                     //                   );
// //                                     //                   return;
// //                                     //                 }
// //                                     //                 double couponAmount = Constant
// //                                     //                     .calculateDiscount(
// //                                     //                     amount: controller.subTotal.value
// //                                     //                         .toString(),
// //                                     //                     offerModel: couponModel);
// //                                     //                 if (couponAmount < controller.subTotal.value) {
// //                                     //                   controller.selectedCouponModel.value =
// //                                     //                       couponModel;
// //                                     //                   controller.couponCodeController.value.text =
// //                                     //                       couponModel.code ?? '';
// //                                     //                   controller.calculatePrice();
// //                                     //                   Get.back();
// //                                     //                 } else {
// //                                     //                   ShowToastDialog.showToast(
// //                                     //                       "Coupon code not applied".tr);
// //                                     //                 }
// //                                     //               },
// //                                     //               child: Text(
// //                                     //                 couponModel.isEnabled == false
// //                                     //                     ? "Used"
// //                                     //                     : "Tap To Apply".tr,
// //                                     //                 textAlign: TextAlign.start,
// //                                     //                 style: TextStyle(
// //                                     //                   fontFamily: AppThemeData.medium,
// //                                     //                   color: couponModel.isEnabled == false
// //                                     //                       ? (themeChange.getThem()
// //                                     //                       ? AppThemeData.grey600
// //                                     //                       : AppThemeData.grey400)
// //                                     //                       : (themeChange.getThem()
// //                                     //                       ? AppThemeData.primary300
// //                                     //                       : AppThemeData.primary300),
// //                                     //                 ),
// //                                     //               ),
// //                                     //             ),
// //                                     //           ],
// //                                     //         ),
// //                                     //         const SizedBox(height: 20),
// //                                     //         MySeparator(
// //                                     //             color: themeChange.getThem()
// //                                     //                 ? AppThemeData.grey700
// //                                     //                 : AppThemeData.grey200),
// //                                     //         const SizedBox(height: 20),
// //                                     //         Text(
// //                                     //           "${couponModel.description}",
// //                                     //           textAlign: TextAlign.start,
// //                                     //           style: TextStyle(
// //                                     //             fontFamily: AppThemeData.medium,
// //                                     //             fontSize: 16,
// //                                     //             color: themeChange.getThem()
// //                                     //                 ? AppThemeData.grey50
// //                                     //                 : AppThemeData.grey900,
// //                                     //           ),
// //                                     //         ),
// //                                     //       ],
// //                                     //     ),
// //                                     //   ),
// //                                     // ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                         // child: Row(
// //                         //   crossAxisAlignment: CrossAxisAlignment.start, // This makes the orange banner fill the card height
// //                         //   children: [
// //                         //     ClipRRect(
// //                         //       borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
// //                         //       child: SizedBox(
// //                         //         width: 60,
// //                         //         height: 125,
// //                         //         child: Stack(
// //                         //           children: [
// //                         //             Positioned.fill(
// //                         //               child: Image.asset(
// //                         //                 "assets/images/ic_coupon_image.png",
// //                         //                 fit: BoxFit.fill,
// //                         //               ),
// //                         //             ),
// //                         //             Padding(
// //                         //               padding: const EdgeInsets.only(left: 10),
// //                         //               child: Align(
// //                         //                 alignment: Alignment.center,
// //                         //                 child: RotatedBox(
// //                         //                   quarterTurns: -1,
// //                         //                   child: Text(
// //                         //                     "${couponModel.discountType == "Fix Price" ? Constant.amountShow(amount: couponModel.discount) : "${couponModel.discount}%"} ${'Off'.tr}",
// //                         //                     textAlign: TextAlign.start,
// //                         //                     style: TextStyle(
// //                         //                       fontFamily: AppThemeData.semiBold,
// //                         //                       fontSize: 16,
// //                         //                       color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50,
// //                         //                     ),
// //                         //                   ),
// //                         //                 ),
// //                         //               ),
// //                         //             ),
// //                         //           ],
// //                         //         ),
// //                         //       ),
// //                         //     ),
// //                         //     Expanded(
// //                         //       child: Padding(
// //                         //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
// //                         //         child: Column(
// //                         //           crossAxisAlignment: CrossAxisAlignment.start,
// //                         //           mainAxisSize: MainAxisSize.min,
// //                         //           children: [
// //                         //             Row(
// //                         //               children: [
// //                         //                 DottedBorder(
// //                         //                   options: RoundedRectDottedBorderOptions(
// //                         //                     color: couponModel.isEnabled == false
// //                         //                         ? (themeChange.getThem() ? AppThemeData.grey600 : AppThemeData.grey400)
// //                         //                         : (themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500),
// //                         //                     strokeWidth: 1,
// //                         //                     radius: const Radius.circular(6),
// //                         //                     dashPattern: const [6, 6],
// //                         //                   ),
// //                         //                   child: Padding(
// //                         //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// //                         //                     child: Text(
// //                         //                       "${couponModel.code}",
// //                         //                       textAlign: TextAlign.start,
// //                         //                       style: TextStyle(
// //                         //                         fontFamily: AppThemeData.semiBold,
// //                         //                         fontSize: 16,
// //                         //                         color: couponModel.isEnabled == false
// //                         //                             ? (themeChange.getThem() ? AppThemeData.grey600 : AppThemeData.grey400)
// //                         //                             : (themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500),
// //                         //                       ),
// //                         //                     ),
// //                         //                   ),
// //                         //                 ),
// //                         //                 const SizedBox(width: 8),
// //                         //                 if (couponModel.isEnabled == false)
// //                         //                   Container(
// //                         //                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //                         //                     decoration: BoxDecoration(
// //                         //                       color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey300,
// //                         //                       borderRadius: BorderRadius.circular(6),
// //                         //                     ),
// //                         //                     child: Text(
// //                         //                       "Used",
// //                         //                       style: TextStyle(
// //                         //                         color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey800,
// //                         //                         fontFamily: AppThemeData.medium,
// //                         //                         fontSize: 12,
// //                         //                       ),
// //                         //                     ),
// //                         //                   ),
// //                         //                 const Expanded(child: SizedBox(height: 10)),
// //                         //                 InkWell(
// //                         //                   onTap: couponModel.isEnabled == false
// //                         //                       ? null
// //                         //                       : () {
// //                         //                     double minValue = double.tryParse(couponModel.itemValue ?? '0') ?? 0.0;
// //                         //                     if (controller.subTotal.value <= minValue) {
// //                         //                       ShowToastDialog.showToast(
// //                         //                         "This coupon can only be applied for orders above ₹${minValue.toStringAsFixed(0)}."
// //                         //                       );
// //                         //                       return;
// //                         //                     }
// //                         //                     double couponAmount = Constant.calculateDiscount(amount: controller.subTotal.value.toString(), offerModel: couponModel);
// //                         //                     if (couponAmount < controller.subTotal.value) {
// //                         //                       controller.selectedCouponModel.value = couponModel;
// //                         //                       controller.couponCodeController.value.text = couponModel.code ?? '';
// //                         //                       controller.calculatePrice();
// //                         //                       Get.back();
// //                         //                     } else {
// //                         //                       ShowToastDialog.showToast("Coupon code not applied".tr);
// //                         //                     }
// //                         //                   },
// //                         //                   child: Text(
// //                         //                     couponModel.isEnabled == false ? "Used" : "Tap To Apply".tr,
// //                         //                     textAlign: TextAlign.start,
// //                         //                     style: TextStyle(
// //                         //                       fontFamily: AppThemeData.medium,
// //                         //                       color: couponModel.isEnabled == false
// //                         //                           ? (themeChange.getThem() ? AppThemeData.grey600 : AppThemeData.grey400)
// //                         //                           : (themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300),
// //                         //                     ),
// //                         //                   ),
// //                         //                 ),
// //                         //               ],
// //                         //             ),
// //                         //             const SizedBox(
// //                         //               height: 20,
// //                         //             ),
// //                         //             MySeparator(color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
// //                         //             const SizedBox(
// //                         //               height: 20,
// //                         //             ),
// //                         //             Text(
// //                         //               "${couponModel.description}",
// //                         //               textAlign: TextAlign.start,
// //                         //               style: TextStyle(
// //                         //                 fontFamily: AppThemeData.medium,
// //                         //                 fontSize: 16,
// //                         //                 color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
// //                         //               ),
// //                         //             )
// //                         //           ],
// //                         //         ),
// //                         //       ),
// //                         //     ),
// //                         //   ],
// //                         // ),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //         );
// //       },
// //     );
// //   }
// // }
//

import 'package:flutter_svg/svg.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dotted_border/src/dotted_border_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  bool _hasInitialized = false;
  final TextEditingController _couponCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      Future.microtask(() {
        if (mounted) {
          final controller = Provider.of<CartControllerProvider>(
            context,
            listen: false,
          );
          controller.ensureCouponsLoaded();
        }
      });
    }
  }

  void _applyCoupon(CartControllerProvider controller, CouponModel coupon) {
    if (coupon.isEnabled == false) {
      ShowToastDialog.showToast('You have already used this coupon'.tr);
      return;
    }
    final enteredCode = _couponCodeController.text.trim().toLowerCase();
    final couponCode = coupon.code?.toLowerCase() ?? '';
    if (enteredCode.isNotEmpty && enteredCode != couponCode) {
      ShowToastDialog.showToast("Coupon code doesn't match".tr);
      return;
    }
    double minValue = double.tryParse(coupon.itemValue ?? '0') ?? 0.0;
    if (controller.subTotal < minValue) {
      ShowToastDialog.showToast(
        'Apply on orders above ₹${minValue.toStringAsFixed(0)}',
      );
      return;
    }
    double couponAmount = Constant.calculateDiscount(
      amount: controller.subTotal.toString(),
      offerModel: coupon,
    );
    if (couponAmount >= controller.subTotal) {
      ShowToastDialog.showToast('Coupon discount cannot exceed order total'.tr);
      return;
    }
    controller.selectedCouponModel = coupon;
    controller.couponCodeController.text = coupon.code ?? '';
    controller.calculatePrice();
    ShowToastDialog.showToast('Coupon applied!'.tr);
    Get.back();
  }

  void _applyManualCoupon(CartControllerProvider controller) {
    final enteredCode = _couponCodeController.text.trim();
    if (enteredCode.isEmpty) {
      ShowToastDialog.showToast('Please enter a coupon code'.tr);
      return;
    }
    final found = controller.allCouponList
        .where((c) => c.code?.toLowerCase() == enteredCode.toLowerCase())
        .toList();
    if (found.isEmpty) {
      ShowToastDialog.showToast('Invalid coupon code'.tr);
      return;
    }
    _applyCoupon(controller, found.first);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        final coupons = controller.couponList;
        final isLoading = controller.isLoadingCoupons;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Apply Coupon',
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 18,
                color: AppThemeData.grey900,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(isLoading ? 80 : 70),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Search / enter coupon field
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppThemeData.grey50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppThemeData.grey200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.confirmation_num_outlined,
                            color: AppThemeData.grey400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _couponCodeController,
                              enabled: !isLoading,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                color: AppThemeData.grey900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppThemeData.grey400,
                                  fontFamily: AppThemeData.regular,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => _applyManualCoupon(controller),
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppThemeData.primary300,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Apply',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppThemeData.primary300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading coupons...',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppThemeData.grey500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (coupons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${coupons.length} offer${coupons.length > 1 ? 's' : ''} available',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppThemeData.grey500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading && coupons.isEmpty
              ? _buildFullLoader()
              : coupons.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) =>
                      _buildCouponCard(controller, coupons[index]),
                ),
        );
      },
    );
  }

  Widget _buildCouponCard(
    CartControllerProvider controller,
    CouponModel coupon,
  ) {
    final isUsed = coupon.isEnabled == false;
    final discountLabel = coupon.discountType == 'Fix Price'
        ? Constant.amountShow(amount: coupon.discount)
        : '${coupon.discount}% OFF';

    return GestureDetector(
      onTap: isUsed
          ? () => ShowToastDialog.showToast('Coupon already used'.tr)
          : () => _applyCoupon(controller, coupon),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Opacity(
          opacity: isUsed ? 0.6 : 1.0,
          child: Row(
            children: [
              // ── Left discount badge ────────────────────────────────────
              Container(
                width: 72,
                constraints: const BoxConstraints(minHeight: 90),
                decoration: BoxDecoration(
                  color: isUsed
                      ? AppThemeData.grey200
                      : AppThemeData.primary300,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUsed ? 'USED' : discountLabel.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isUsed && coupon.discountType != 'Fix Price') ...[
                      const SizedBox(height: 2),
                      const Text(
                        'OFF',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Notch
              CustomPaint(size: const Size(12, 90), painter: _NotchPainter()),

              // ── Right content ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppThemeData.primary200,
                                  style: isUsed
                                      ? BorderStyle.solid
                                      : BorderStyle.solid,
                                ),
                              ),
                              child: Text(
                                coupon.code ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppThemeData.semiBold,
                                  color: AppThemeData.primary300,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              coupon.description ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.regular,
                                color: AppThemeData.grey600,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (coupon.itemValue != null &&
                                coupon.itemValue != '0') ...[
                              const SizedBox(height: 4),
                              Text(
                                'Min order ₹${double.tryParse(coupon.itemValue ?? '0')?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.grey400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Apply button / Used tag
                      if (isUsed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Used',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.grey500,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppThemeData.primary300),
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary300,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppThemeData.primary300),
          const SizedBox(height: 16),
          Text(
            'Finding best offers...',
            style: TextStyle(fontSize: 14, color: AppThemeData.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppThemeData.grey50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.confirmation_num_outlined,
              size: 36,
              color: AppThemeData.grey300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No coupons available',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for great deals',
            style: TextStyle(fontSize: 13, color: AppThemeData.grey400),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }
}

// ─── Notch painter for coupon card ───────────────────────────────────────────
class _NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F5F5);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.35)
      ..arcToPoint(
        Offset(size.width, size.height * 0.65),
        radius: const Radius.circular(12),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    // Dashed line
    final dashPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 4),
        dashPaint,
      );
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
