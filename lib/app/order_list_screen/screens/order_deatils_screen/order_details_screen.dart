// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
// import 'package:jippymart_customer/app/chat_screens/chat_screen.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
// import 'package:jippymart_customer/app/rate_us_screen/provider/rate_product_provider.dart';
// import 'package:jippymart_customer/app/rate_us_screen/rate_product_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/order_model.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:jippymart_customer/utils/network_image_widget.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/widget/my_separator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:timelines_plus/timelines_plus.dart';
//
// class OrderBillDetails {
//   final double subTotal;
//   final double deliveryCharges;
//   final double originalDeliveryFee;
//   final double couponAmount;
//   final double specialDiscountAmount;
//   final double taxAmount;
//   final double deliveryTips;
//   final double totalAmount;
//   final bool isFreeDelivery;
//
//   OrderBillDetails({
//     required this.subTotal,
//     required this.deliveryCharges,
//     required this.originalDeliveryFee,
//     required this.couponAmount,
//     required this.specialDiscountAmount,
//     required this.taxAmount,
//     required this.deliveryTips,
//     required this.totalAmount,
//     required this.isFreeDelivery,
//   });
// }
//
// class OrderDetailsScreen extends StatelessWidget {
//   const OrderDetailsScreen({super.key, this.surgeFee});
//
//   final double? surgeFee;
//
//   Future<OrderBillDetails> _calculateOrderBillDetails(
//     OrderModel order,
//     VendorModel? vendor,
//     DeliveryCharge deliveryCharge,
//     double totalDistance,
//   ) async {
//     double subTotal = 0.0;
//     double deliveryCharges = 0.0;
//     double originalDeliveryFee = 0.0;
//     double couponAmount = 0.0;
//     double specialDiscountAmount = 0.0;
//     double taxAmount = 0.0;
//     double deliveryTips = double.tryParse(order.tipAmount ?? '0') ?? 0.0;
//     double totalAmount = 0.0;
//
//     // Subtotal - Enhanced promotional detection
//     if (order.products != null) {
//       for (var element in order.products!) {
//         final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
//         final discountPriceValue =
//             double.tryParse(element.discountPrice.toString()) ?? 0.0;
//
//         // Enhanced promotional detection - check both promoId and price comparison
//         final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
//         final isPricePromotional =
//             priceValue > 0 &&
//             discountPriceValue > 0 &&
//             priceValue < discountPriceValue;
//         final isPromotional = hasPromo || isPricePromotional;
//
//         print('DEBUG: Order Details - Processing product: ${element.name}');
//         print(
//           'DEBUG: Order Details - Price: $priceValue, DiscountPrice: $discountPriceValue',
//         );
//         print(
//           'DEBUG: Order Details - Has PromoId: $hasPromo, Is Price Promotional: $isPricePromotional',
//         );
//         print('DEBUG: Order Details - Is Promotional: $isPromotional');
//
//         double itemPrice;
//         if (isPromotional) {
//           // Use the lower price (promotional price) for calculations
//           itemPrice = priceValue < discountPriceValue
//               ? priceValue
//               : discountPriceValue;
//           print('DEBUG: Order Details - Using promotional price: $itemPrice');
//         } else if (discountPriceValue <= 0) {
//           // No discount - use regular price
//           itemPrice = priceValue;
//           print('DEBUG: Order Details - Using regular price: $itemPrice');
//         } else {
//           // Regular discount - use discount price
//           itemPrice = discountPriceValue;
//           print('DEBUG: Order Details - Using discount price: $itemPrice');
//         }
//
//         final quantity = double.parse(element.quantity.toString());
//         final extrasPrice = double.parse(element.extrasPrice.toString());
//
//         final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
//         subTotal += itemTotal;
//         print(
//           'DEBUG: Order Details - Item total: $itemTotal, Running subtotal: $subTotal',
//         );
//       }
//     }
//
//     // Delivery Charges - Enhanced for promotional items
//     const double fallbackThreshold = 299.0;
//     const double fallbackBaseCharge = 23.0;
//     const double fallbackFreeKm = 5.0;
//     const double fallbackPerKm = 7.0;
//
//     final double threshold =
//         (deliveryCharge.itemTotalThreshold ?? fallbackThreshold).toDouble();
//     final double baseCharge =
//         (deliveryCharge.baseDeliveryCharge ?? fallbackBaseCharge).toDouble();
//     final double freeKm =
//         (deliveryCharge.freeDeliveryDistanceKm ?? fallbackFreeKm).toDouble();
//     final double perKm =
//         (deliveryCharge.perKmChargeAboveFreeDistance ?? fallbackPerKm)
//             .toDouble();
//
//     // Check if cart has promotional items
//     final hasPromotionalItems = (order.products ?? []).any((item) {
//       final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//       final discountPriceValue =
//           double.tryParse(item.discountPrice.toString()) ?? 0.0;
//       final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//       final isPricePromotional =
//           priceValue > 0 &&
//           discountPriceValue > 0 &&
//           priceValue < discountPriceValue;
//       return hasPromo || isPricePromotional;
//     });
//
//     print(
//       'DEBUG: Order Details - Has promotional items for delivery calculation: $hasPromotionalItems',
//     );
//
//     if (vendor?.isSelfDelivery == true &&
//         Constant.isSelfDeliveryFeature == true) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = 0.0;
//       print('DEBUG: Order Details - Self delivery - no charge');
//     } else if (hasPromotionalItems) {
//       // Promotional items delivery logic - Get dynamic settings from Firestore
//       final promotionalItems = (order.products ?? []).where((item) {
//         final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//         final discountPriceValue =
//             double.tryParse(item.discountPrice.toString()) ?? 0.0;
//         final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//         final isPricePromotional =
//             priceValue > 0 &&
//             discountPriceValue > 0 &&
//             priceValue < discountPriceValue;
//         return hasPromo || isPricePromotional;
//       }).toList();
//
//       if (promotionalItems.isNotEmpty) {
//         final firstPromoItem = promotionalItems.first;
//
//         try {
//           // Get promotional item details from Firestore (DYNAMIC)
//           final promoDetails =
//               await FireStoreUtils.getActivePromotionForProduct(
//                 productId: firstPromoItem.id ?? '',
//                 restaurantId: firstPromoItem.vendorID ?? '',
//               );
//
//           if (promoDetails != null) {
//             final freeDeliveryKm =
//                 (promoDetails['free_delivery_km'] as num?)?.toDouble() ?? 3.0;
//             final extraKmCharge =
//                 (promoDetails['extra_km_charge'] as num?)?.toDouble() ??
//                 fallbackPerKm;
//             final promoBaseCharge = baseCharge;
//
//             print(
//               'DEBUG: Order Details - Promotional delivery settings from Firestore:',
//             );
//             print('DEBUG: Order Details - Free delivery km: $freeDeliveryKm');
//             print('DEBUG: Order Details - Extra km charge: $extraKmCharge');
//             print('DEBUG: Order Details - Total distance: $totalDistance km');
//
//             if (totalDistance <= freeDeliveryKm) {
//               // Free delivery within promotional distance
//               deliveryCharges = 0.0;
//               originalDeliveryFee = promoBaseCharge.toDouble();
//               print(
//                 'DEBUG: Order Details - Promotional free delivery within ${freeDeliveryKm}km - showing original fee: ₹$promoBaseCharge',
//               );
//             } else {
//               // Paid delivery for promotional items beyond free delivery distance
//               double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
//               deliveryCharges = extraKm * extraKmCharge;
//               originalDeliveryFee = deliveryCharges;
//               print(
//                 'DEBUG: Order Details - Promotional paid delivery beyond ${freeDeliveryKm}km: $extraKm km × ₹$extraKmCharge = ₹$deliveryCharges',
//               );
//             }
//           } else {
//             print(
//               'DEBUG: Order Details - No promotional details found, using regular delivery charge',
//             );
//             // Fallback to regular delivery logic
//             if (subTotal < threshold) {
//               if (totalDistance <= freeKm) {
//                 deliveryCharges = baseCharge.toDouble();
//                 originalDeliveryFee = baseCharge.toDouble();
//               } else {
//                 double extraKm = (totalDistance - freeKm).ceilToDouble();
//                 deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
//                 originalDeliveryFee = deliveryCharges;
//               }
//             } else {
//               if (totalDistance <= freeKm) {
//                 deliveryCharges = 0.0;
//                 originalDeliveryFee = baseCharge.toDouble();
//               } else {
//                 double extraKm = (totalDistance - freeKm).ceilToDouble();
//                 deliveryCharges = (extraKm * perKm).toDouble();
//                 originalDeliveryFee = (baseCharge + (extraKm * perKm))
//                     .toDouble();
//               }
//             }
//           }
//         } catch (e) {
//           print(
//             'DEBUG: Order Details - Error fetching promotional delivery settings: $e',
//           );
//           // Fallback to regular delivery logic
//           if (subTotal < threshold) {
//             if (totalDistance <= freeKm) {
//               deliveryCharges = baseCharge.toDouble();
//               originalDeliveryFee = baseCharge.toDouble();
//             } else {
//               double extraKm = (totalDistance - freeKm).ceilToDouble();
//               deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
//               originalDeliveryFee = deliveryCharges;
//             }
//           } else {
//             if (totalDistance <= freeKm) {
//               deliveryCharges = 0.0;
//               originalDeliveryFee = baseCharge.toDouble();
//             } else {
//               double extraKm = (totalDistance - freeKm).ceilToDouble();
//               deliveryCharges = (extraKm * perKm).toDouble();
//               originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
//             }
//           }
//         }
//       }
//     } else {
//       // Regular items delivery logic
//       if (subTotal < threshold) {
//         if (totalDistance <= freeKm) {
//           deliveryCharges = baseCharge.toDouble();
//           originalDeliveryFee = baseCharge.toDouble();
//         } else {
//           double extraKm = (totalDistance - freeKm).ceilToDouble();
//           deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
//           originalDeliveryFee = deliveryCharges;
//         }
//       } else {
//         if (totalDistance <= freeKm) {
//           deliveryCharges = 0.0;
//           originalDeliveryFee = baseCharge.toDouble();
//         } else {
//           double extraKm = (totalDistance - freeKm).ceilToDouble();
//           deliveryCharges = (extraKm * perKm).toDouble();
//           originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
//         }
//       }
//     }
//
//     // Coupon Discount - Check if promotional items exist
//     if (hasPromotionalItems) {
//       // If cart has promotional items, don't apply coupons
//       couponAmount = 0.0;
//       print(
//         'DEBUG: Order Details - No coupon applied - cart contains promotional items',
//       );
//     } else if (order.couponId != null &&
//         order.couponId!.isNotEmpty &&
//         order.discount != null) {
//       couponAmount = double.tryParse(order.discount.toString()) ?? 0.0;
//       print('DEBUG: Order Details - Coupon applied: ${order.couponId}');
//     } else {
//       couponAmount = 0.0;
//     }
//
//     // Special Discount
//     if (order.specialDiscount != null &&
//         order.specialDiscount!['special_discount'] != null) {
//       specialDiscountAmount =
//           double.tryParse(
//             order.specialDiscount!['special_discount'].toString(),
//           ) ??
//           0.0;
//     }
//
//     // Taxes
//     // 🔑 FIXED: Calculate tax on base delivery charge + extra km charges
//     // When delivery is free (above ₹299) but distance exceeds free km:
//     // - Customer pays only extra km charge (e.g., ₹14 for 2 km)
//     // - But tax should be calculated on base charge (₹23) + extra km (₹14) = ₹37
//     // originalDeliveryFee already contains base + extra km, so always use it when available
//     final double taxableDeliveryFee = originalDeliveryFee > 0
//         ? originalDeliveryFee
//         : (deliveryCharges > 0 ? deliveryCharges : 0.0);
//
//     print(
//       '[TAX_CALC] Order Details - Delivery charges (customer pays): ₹$deliveryCharges, Original fee (base + extra km): ₹$originalDeliveryFee, Taxable fee: ₹$taxableDeliveryFee',
//     );
//
//     double sgst = subTotal * 0.05;
//     double gst = taxableDeliveryFee * 0.18;
//     sgst = sgst.isNaN ? 0.0 : sgst;
//     gst = gst.isNaN ? 0.0 : gst;
//     taxAmount = sgst + gst;
//     print("taxAmount = $taxAmount (SGST: $sgst, GST: $gst)");
//     if (taxAmount == 0.0) {
//       double sgstFallback = subTotal * 0.05; // 5% on subtotal
//       double gstFallback = taxableDeliveryFee > 0
//           ? taxableDeliveryFee * 0.18 // 18% on delivery charges or base charge (even when free delivery)
//           : 0.0;
//       taxAmount = sgstFallback + gstFallback;
//       print(
//         '[TAX_CALC] Order Details - Fallback tax applied → SGST (5% of ₹$subTotal): ₹$sgstFallback, GST (18% of ₹$taxableDeliveryFee): ₹$gstFallback, Total: ₹$taxAmount',
//       );
//     }
//     if (taxAmount.isNaN) taxAmount = 0.0;
//     bool isFreeDelivery = false;
//     if (hasPromotionalItems) {
//       // For promotional items, check if within free delivery distance (dynamic from Firestore)
//       final promotionalItems = (order.products ?? []).where((item) {
//         final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//         final discountPriceValue =
//             double.tryParse(item.discountPrice.toString()) ?? 0.0;
//         final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//         final isPricePromotional =
//             priceValue > 0 &&
//             discountPriceValue > 0 &&
//             priceValue < discountPriceValue;
//         return hasPromo || isPricePromotional;
//       }).toList();
//
//       if (promotionalItems.isNotEmpty) {
//         final firstPromoItem = promotionalItems.first;
//
//         try {
//           // Get promotional item details from Firestore (DYNAMIC)
//           final promoDetails =
//               await FireStoreUtils.getActivePromotionForProduct(
//                 productId: firstPromoItem.id ?? '',
//                 restaurantId: firstPromoItem.vendorID ?? '',
//               );
//
//           if (promoDetails != null) {
//             final freeDeliveryKm =
//                 (promoDetails['free_delivery_km'] as num?)?.toDouble() ?? 3.0;
//             if (totalDistance <= freeDeliveryKm) {
//               isFreeDelivery = true;
//               print(
//                 'DEBUG: Order Details - Promotional free delivery within ${freeDeliveryKm}km - isFreeDelivery: true',
//               );
//             }
//           } else {
//             // Fallback to regular delivery logic
//             if (subTotal >= threshold && totalDistance <= freeKm) {
//               isFreeDelivery = true;
//               print(
//                 'DEBUG: Order Details - Fallback to regular free delivery - isFreeDelivery: true',
//               );
//             }
//           }
//         } catch (e) {
//           print(
//             'DEBUG: Order Details - Error checking promotional free delivery: $e',
//           );
//           // Fallback to regular delivery logic
//           if (subTotal >= threshold && totalDistance <= freeKm) {
//             isFreeDelivery = true;
//             print(
//               'DEBUG: Order Details - Fallback to regular free delivery - isFreeDelivery: true',
//             );
//           }
//         }
//       }
//     } else {
//       // For regular items, use regular delivery settings
//       if (subTotal >= threshold && totalDistance <= freeKm) {
//         isFreeDelivery = true;
//         print(
//           'DEBUG: Order Details - Regular free delivery - isFreeDelivery: true',
//         );
//       }
//     }
//     totalAmount =
//         (subTotal - couponAmount - specialDiscountAmount) +
//         taxAmount +
//         (isFreeDelivery ? 0.0 : deliveryCharges) +
//         deliveryTips;
//     return OrderBillDetails(
//       subTotal: subTotal,
//       deliveryCharges: deliveryCharges,
//       originalDeliveryFee: originalDeliveryFee,
//       couponAmount: couponAmount,
//       specialDiscountAmount: specialDiscountAmount,
//       taxAmount: taxAmount,
//       deliveryTips: deliveryTips,
//       totalAmount: totalAmount,
//       isFreeDelivery: isFreeDelivery,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<OrderDetailsProvider>(
//       builder: (context, controller, _) {
//         final order = controller.orderModel;
//         if (order.products == null || order.products!.isEmpty) {
//           return Scaffold(
//             backgroundColor: AppThemeData.surface,
//             appBar: AppBar(
//               backgroundColor: AppThemeData.surface,
//               centerTitle: false,
//               titleSpacing: 0,
//               title: Text(
//                 "Order Details".tr,
//                 textAlign: TextAlign.start,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.medium,
//                   fontSize: 16,
//                   color: AppThemeData.grey900,
//                 ),
//               ),
//             ),
//             body: Center(
//               child: Text(
//                 "Order details are incomplete. Please contact support.".tr,
//               ),
//             ),
//           );
//         }
//
//         // For mart orders, use the actual vendor data or create default
//         final vendor =
//             order.vendor ??
//             VendorModel(
//               title: "Jippy Mart",
//               location: "Jippy Mart Store",
//               phonenumber: "Contact Support",
//               isSelfDelivery: false,
//               deliveryCharge: DeliveryCharge(
//                 baseDeliveryCharge: 23.0,
//                 itemTotalThreshold: 299.0,
//                 freeDeliveryDistanceKm: 7.0,
//                 perKmChargeAboveFreeDistance: 8.0,
//               ),
//               latitude: 0.0,
//               longitude: 0.0,
//               vType: 'mart', // Mark as mart vendor
//             );
//
//         final deliveryCharge = vendor.deliveryCharge ?? DeliveryCharge();
//         final double displayThreshold =
//             (deliveryCharge.itemTotalThreshold ?? 299).toDouble();
//         final double displayFreeDistance =
//             (deliveryCharge.freeDeliveryDistanceKm ?? 5).toDouble();
//         final double displayBaseCharge =
//             (deliveryCharge.baseDeliveryCharge ?? 23).toDouble();
//         final totalDistance = order.vendor != null
//             ? Constant.calculateDistance(
//                 vendor.latitude ?? 0.0,
//                 vendor.longitude ?? 0.0,
//                 order.address?.location?.latitude ?? 0.0,
//                 order.address?.location?.longitude ?? 0.0,
//               )
//             : 0.0; // Default distance for mart orders
//
//         return FutureBuilder<OrderBillDetails>(
//           future: _calculateOrderBillDetails(
//             order,
//             vendor,
//             deliveryCharge,
//             totalDistance,
//           ),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Scaffold(
//                 backgroundColor: AppThemeData.surface,
//                 appBar: AppBar(
//                   backgroundColor: AppThemeData.surface,
//                   centerTitle: false,
//                   titleSpacing: 0,
//                   title: Text(
//                     "Order Details".tr,
//                     textAlign: TextAlign.start,
//                     style: TextStyle(
//                       fontFamily: AppThemeData.medium,
//                       fontSize: 16,
//                       color: AppThemeData.grey900,
//                     ),
//                   ),
//                 ),
//                 body: Constant.loader(message: "Loading order details...".tr),
//               );
//             }
//
//             if (snapshot.hasError) {
//               return Scaffold(
//                 backgroundColor: AppThemeData.surface,
//                 appBar: AppBar(
//                   backgroundColor: AppThemeData.surface,
//                   centerTitle: false,
//                   titleSpacing: 0,
//                   title: Text(
//                     "Order Details".tr,
//                     textAlign: TextAlign.start,
//                     style: TextStyle(
//                       fontFamily: AppThemeData.medium,
//                       fontSize: 16,
//                       color: AppThemeData.grey900,
//                     ),
//                   ),
//                 ),
//                 body: Center(child: Text("Error loading order details".tr)),
//               );
//             }
//
//             final bill = snapshot.data!;
//             return Scaffold(
//               backgroundColor: AppThemeData.surface,
//               appBar: AppBar(
//                 backgroundColor: AppThemeData.surface,
//                 centerTitle: false,
//                 titleSpacing: 0,
//                 title: Text(
//                   "Order Details".tr,
//                   textAlign: TextAlign.start,
//                   style: TextStyle(
//                     fontFamily: AppThemeData.medium,
//                     fontSize: 16,
//                     color: AppThemeData.grey900,
//                   ),
//                 ),
//               ),
//               body: controller.isLoading
//                   ? Constant.loader(message: "Loading order details...".tr)
//                   : Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: SingleChildScrollView(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "${'Order'.tr} ${Constant.orderId(orderId: controller.orderModel.id.toString())}"
//                                             .tr,
//                                         textAlign: TextAlign.start,
//                                         style: TextStyle(
//                                           fontFamily: AppThemeData.semiBold,
//                                           fontSize: 18,
//                                           color: AppThemeData.grey900,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 RoundedButtonFill(
//                                   title: controller.orderModel.status
//                                       .toString()
//                                       .tr,
//                                   color: Constant.statusColor(
//                                     status: controller.orderModel.status
//                                         .toString(),
//                                   ),
//                                   width: 32,
//                                   height: 4.5,
//                                   radius: 10,
//                                   textColor: Constant.statusText(
//                                     status: controller.orderModel.status
//                                         .toString(),
//                                   ),
//                                   onPress: () async {},
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 14),
//                             controller.orderModel.takeAway == true
//                                 ? Container(
//                                     decoration: ShapeDecoration(
//                                       color: AppThemeData.grey50,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 16,
//                                         vertical: 10,
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   controller
//                                                           .orderModel
//                                                           .vendor
//                                                           ?.title ??
//                                                       'Jippy Mart',
//                                                   textAlign: TextAlign.start,
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.semiBold,
//                                                     fontSize: 16,
//                                                     color:
//                                                         AppThemeData.primary300,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   controller
//                                                           .orderModel
//                                                           .vendor
//                                                           ?.location ??
//                                                       'Jippy Mart Store',
//                                                   textAlign: TextAlign.start,
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.medium,
//                                                     fontSize: 14,
//                                                     color: AppThemeData.grey600,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           InkWell(
//                                             onTap: () {
//                                               final phone =
//                                                   controller
//                                                       .orderModel
//                                                       .vendor
//                                                       ?.phonenumber
//                                                       ?.toString() ??
//                                                   'Contact Support';
//                                               final vendorId =
//                                                   controller
//                                                       .orderModel
//                                                       .vendor
//                                                       ?.author
//                                                       ?.toString() ??
//                                                   'mart_support';
//                                               final orderId =
//                                                   controller.orderModel.id;
//                                               debugPrint('[CALL VENDOR]');
//                                               debugPrint('Collection: vendors');
//                                               debugPrint(
//                                                 'Document ID (vendorId): $vendorId',
//                                               );
//                                               debugPrint('Order ID: $orderId');
//                                               debugPrint('Call Number: $phone');
//                                               debugPrint('Calling: Vendor');
//                                               if (phone != 'Contact Support') {
//                                                 Constant.makePhoneCall(phone);
//                                               } else {
//                                                 ShowToastDialog.showToast(
//                                                   "Please contact Jippy Mart support for assistance.",
//                                                 );
//                                               }
//                                             },
//                                             child: Container(
//                                               width: 42,
//                                               height: 42,
//                                               decoration: ShapeDecoration(
//                                                 shape: RoundedRectangleBorder(
//                                                   side: BorderSide(
//                                                     width: 1,
//                                                     color: AppThemeData.grey200,
//                                                   ),
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                         120,
//                                                       ),
//                                                 ),
//                                               ),
//                                               child: Padding(
//                                                 padding: const EdgeInsets.all(
//                                                   8.0,
//                                                 ),
//                                                 child: SvgPicture.asset(
//                                                   "assets/icons/ic_phone_call.svg",
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(width: 10),
//                                           InkWell(
//                                             onTap: () async {
//                                               ShowToastDialog.showLoader(
//                                                 "Please wait".tr,
//                                               );
//                                               UserModel? customer =
//                                                   await AddressListProvider.getUserProfile(
//                                                     controller
//                                                         .orderModel
//                                                         .authorID
//                                                         .toString(),
//                                                   );
//                                               UserModel? restaurantUser =
//                                                   controller
//                                                           .orderModel
//                                                           .vendor
//                                                           ?.author !=
//                                                       null
//                                                   ? await AddressListProvider.getUserProfile(
//                                                       controller
//                                                           .orderModel
//                                                           .vendor!
//                                                           .author
//                                                           .toString(),
//                                                     )
//                                                   : null;
//                                               VendorModel? vendorModel =
//                                                   await FireStoreUtils.getVendorById(
//                                                     restaurantUser!.vendorID
//                                                         .toString(),
//                                                   );
//                                               ShowToastDialog.closeLoader();
//                                               debugPrint(
//                                                 'VENDOR CHAT BUTTON PRESSED',
//                                               );
//                                               debugPrint(
//                                                 'ChatType: restaurant',
//                                               );
//                                               debugPrint(
//                                                 'To: ${vendorModel!.title} (UserID: ${restaurantUser.id})',
//                                               );
//                                               debugPrint(
//                                                 'Customer: ${customer!.fullName()} (UserID: ${customer.id})',
//                                               );
//                                               final userId =
//                                                   await SqlStorageConst.getFirebaseId();
//                                               Get.to(
//                                                 ChatScreen(userId: userId),
//                                                 arguments: {
//                                                   "customerName": customer
//                                                       .fullName(),
//                                                   "restaurantName":
//                                                       vendorModel.title,
//                                                   "orderId":
//                                                       controller.orderModel.id,
//                                                   "restaurantId":
//                                                       restaurantUser.id,
//                                                   "customerId": customer.id,
//                                                   "customerProfileImage":
//                                                       customer
//                                                           .profilePictureURL,
//                                                   "restaurantProfileImage":
//                                                       vendorModel.photo,
//                                                   "token":
//                                                       restaurantUser.fcmToken,
//                                                   "chatType": "restaurant",
//                                                 },
//                                               );
//                                             },
//                                             child: Container(
//                                               width: 42,
//                                               height: 42,
//                                               decoration: ShapeDecoration(
//                                                 shape: RoundedRectangleBorder(
//                                                   side: BorderSide(
//                                                     width: 1,
//                                                     color: AppThemeData.grey200,
//                                                   ),
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                         120,
//                                                       ),
//                                                 ),
//                                               ),
//                                               child: Padding(
//                                                 padding: const EdgeInsets.all(
//                                                   8.0,
//                                                 ),
//                                                 child: SvgPicture.asset(
//                                                   "assets/icons/ic_wechat.svg",
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   )
//                                 : Container(
//                                     decoration: ShapeDecoration(
//                                       color: AppThemeData.grey50,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 16,
//                                       ),
//                                       child: Column(
//                                         children: [
//                                           Timeline.tileBuilder(
//                                             shrinkWrap: true,
//                                             padding: EdgeInsets.zero,
//                                             physics:
//                                                 const NeverScrollableScrollPhysics(),
//                                             theme: TimelineThemeData(
//                                               nodePosition: 0,
//                                               // indicatorPosition: 0,
//                                             ),
//                                             builder: TimelineTileBuilder.connected(
//                                               contentsAlign:
//                                                   ContentsAlign.basic,
//                                               indicatorBuilder: (context, index) {
//                                                 return SvgPicture.asset(
//                                                   "assets/icons/ic_location.svg",
//                                                 );
//                                               },
//                                               connectorBuilder:
//                                                   (
//                                                     context,
//                                                     index,
//                                                     connectorType,
//                                                   ) {
//                                                     return const DashedLineConnector(
//                                                       color:
//                                                           AppThemeData.grey300,
//                                                       gap: 3,
//                                                     );
//                                                   },
//                                               contentsBuilder: (context, index) {
//                                                 return Padding(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 10,
//                                                         vertical: 10,
//                                                       ),
//                                                   child: index == 0
//                                                       ? Row(
//                                                           children: [
//                                                             Expanded(
//                                                               child: Column(
//                                                                 crossAxisAlignment:
//                                                                     CrossAxisAlignment
//                                                                         .start,
//                                                                 children: [
//                                                                   Text(
//                                                                     controller
//                                                                             .orderModel
//                                                                             .vendor
//                                                                             ?.title ??
//                                                                         'Jippy Mart',
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .start,
//                                                                     style: TextStyle(
//                                                                       fontFamily:
//                                                                           AppThemeData
//                                                                               .semiBold,
//                                                                       fontSize:
//                                                                           16,
//                                                                       color: AppThemeData
//                                                                           .primary300,
//                                                                     ),
//                                                                   ),
//                                                                   Text(
//                                                                     controller
//                                                                             .orderModel
//                                                                             .vendor
//                                                                             ?.location ??
//                                                                         'Jippy Mart Store',
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .start,
//                                                                     style: TextStyle(
//                                                                       fontFamily:
//                                                                           AppThemeData
//                                                                               .medium,
//                                                                       fontSize:
//                                                                           14,
//                                                                       color: AppThemeData
//                                                                           .grey600,
//                                                                     ),
//                                                                   ),
//                                                                 ],
//                                                               ),
//                                                             ),
//                                                             const SizedBox(
//                                                               width: 10,
//                                                             ),
//                                                             InkWell(
//                                                               onTap: () async {
//                                                                 try {
//                                                                   ShowToastDialog.showLoader(
//                                                                     "Please wait"
//                                                                         .tr,
//                                                                   );
//                                                                   UserModel?
//                                                                   customer = await AddressListProvider.getUserProfile(
//                                                                     controller
//                                                                         .orderModel
//                                                                         .authorID
//                                                                         .toString(),
//                                                                   );
//                                                                   // customer = await AddressListProvider.getUserProfile(
//                                                                   //   controller
//                                                                   //       .orderModel
//                                                                   //       .authorID
//                                                                   //       .toString(),
//                                                                   // );
//                                                                   UserModel?
//                                                                   restaurantUser = await AddressListProvider.getUserProfile(
//                                                                     controller
//                                                                         .orderModel
//                                                                         .vendor!
//                                                                         .author
//                                                                         .toString(),
//                                                                   );
//                                                                   await FireStoreUtils.getVendorById(
//                                                                     restaurantUser!
//                                                                         .vendorID
//                                                                         .toString(),
//                                                                   );
//                                                                   ShowToastDialog.closeLoader();
//                                                                   final userId =
//                                                                       await SqlStorageConst.getFirebaseId();
//                                                                   Get.to(
//                                                                     ChatScreen(
//                                                                       userId:
//                                                                           userId,
//                                                                     ),
//                                                                     arguments: {
//                                                                       "customerName":
//                                                                           customer!
//                                                                               .fullName(),
//                                                                       "restaurantName":
//                                                                           restaurantUser
//                                                                               .fullName(),
//                                                                       "orderId":
//                                                                           controller
//                                                                               .orderModel
//                                                                               .id,
//                                                                       "restaurantId":
//                                                                           restaurantUser
//                                                                               .id,
//                                                                       "customerId":
//                                                                           customer
//                                                                               .id,
//                                                                       "customerProfileImage":
//                                                                           customer
//                                                                               .profilePictureURL,
//                                                                       "restaurantProfileImage":
//                                                                           restaurantUser
//                                                                               .profilePictureURL,
//                                                                       "token":
//                                                                           restaurantUser
//                                                                               .fcmToken,
//                                                                       "chatType":
//                                                                           "restaurant",
//                                                                     },
//                                                                   );
//                                                                 } catch (e) {
//                                                                   ShowToastDialog.closeLoader();
//                                                                 }
//                                                               },
//                                                               child: Container(
//                                                                 width: 42,
//                                                                 height: 42,
//                                                                 decoration: ShapeDecoration(
//                                                                   shape: RoundedRectangleBorder(
//                                                                     side: BorderSide(
//                                                                       width: 1,
//                                                                       color: AppThemeData
//                                                                           .grey200,
//                                                                     ),
//                                                                     borderRadius:
//                                                                         BorderRadius.circular(
//                                                                           120,
//                                                                         ),
//                                                                   ),
//                                                                 ),
//                                                                 child: Padding(
//                                                                   padding:
//                                                                       const EdgeInsets.all(
//                                                                         8.0,
//                                                                       ),
//                                                                   child: SvgPicture.asset(
//                                                                     "assets/icons/ic_wechat.svg",
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         )
//                                                       : Column(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .start,
//                                                           children: [
//                                                             Text(
//                                                               "${controller.orderModel.address!.addressAs}",
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .start,
//                                                               style: TextStyle(
//                                                                 fontFamily:
//                                                                     AppThemeData
//                                                                         .semiBold,
//                                                                 fontSize: 16,
//                                                                 color: AppThemeData
//                                                                     .primary300,
//                                                               ),
//                                                             ),
//                                                             Text(
//                                                               controller
//                                                                   .orderModel
//                                                                   .address!
//                                                                   .getFullAddress(),
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .start,
//                                                               style: TextStyle(
//                                                                 fontFamily:
//                                                                     AppThemeData
//                                                                         .medium,
//                                                                 fontSize: 14,
//                                                                 color:
//                                                                     AppThemeData
//                                                                         .grey600,
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                 );
//                                               },
//                                               itemCount: 2,
//                                             ),
//                                           ),
//                                           controller.orderModel.status ==
//                                                   Constant.orderRejected
//                                               ? const SizedBox()
//                                               : Column(
//                                                   children: [
//                                                     Padding(
//                                                       padding:
//                                                           const EdgeInsets.symmetric(
//                                                             vertical: 10,
//                                                           ),
//                                                       child: MySeparator(
//                                                         color: AppThemeData
//                                                             .grey200,
//                                                       ),
//                                                     ),
//                                                     controller
//                                                                     .orderModel
//                                                                     .status ==
//                                                                 Constant
//                                                                     .orderCompleted &&
//                                                             controller
//                                                                     .orderModel
//                                                                     .driver !=
//                                                                 null
//                                                         ? Row(
//                                                             children: [
//                                                               SvgPicture.asset(
//                                                                 "assets/icons/ic_check_small.svg",
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 5,
//                                                               ),
//                                                               Text(
//                                                                 controller
//                                                                     .orderModel
//                                                                     .driver!
//                                                                     .fullName(),
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .right,
//                                                                 style: TextStyle(
//                                                                   color: AppThemeData
//                                                                       .grey800,
//                                                                   fontFamily:
//                                                                       AppThemeData
//                                                                           .semiBold,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .w500,
//                                                                   fontSize: 14,
//                                                                 ),
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 5,
//                                                               ),
//                                                               Text(
//                                                                 "Order Delivered."
//                                                                     .tr,
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .right,
//                                                                 style: TextStyle(
//                                                                   color: AppThemeData
//                                                                       .grey800,
//                                                                   fontFamily:
//                                                                       AppThemeData
//                                                                           .regular,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .w500,
//                                                                   fontSize: 14,
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           )
//                                                         : controller
//                                                                       .orderModel
//                                                                       .status ==
//                                                                   Constant
//                                                                       .orderAccepted ||
//                                                               controller
//                                                                       .orderModel
//                                                                       .status ==
//                                                                   Constant
//                                                                       .driverPending
//                                                         ? Row(
//                                                             crossAxisAlignment:
//                                                                 CrossAxisAlignment
//                                                                     .start,
//                                                             children: [
//                                                               SvgPicture.asset(
//                                                                 "assets/icons/ic_timer.svg",
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 5,
//                                                               ),
//                                                               Expanded(
//                                                                 child: Text(
//                                                                   "${'Your Order has been Preparing and assign to the driver'.tr}\n${'Preparation Time'.tr} ${controller.orderModel.estimatedTimeToPrepare}"
//                                                                       .tr,
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .start,
//                                                                   style: TextStyle(
//                                                                     color: AppThemeData
//                                                                         .warning400,
//                                                                     fontFamily:
//                                                                         AppThemeData
//                                                                             .semiBold,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .w500,
//                                                                     fontSize:
//                                                                         14,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           )
//                                                         : controller
//                                                                   .orderModel
//                                                                   .driver !=
//                                                               null
//                                                         ? Row(
//                                                             children: [
//                                                               ClipOval(
//                                                                 child: NetworkImageWidget(
//                                                                   imageUrl: controller
//                                                                       .orderModel
//                                                                       .author!
//                                                                       .profilePictureURL
//                                                                       .toString(),
//                                                                   fit: BoxFit
//                                                                       .cover,
//                                                                   height:
//                                                                       Responsive.height(
//                                                                         5,
//                                                                         context,
//                                                                       ),
//                                                                   width:
//                                                                       Responsive.width(
//                                                                         10,
//                                                                         context,
//                                                                       ),
//                                                                 ),
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 10,
//                                                               ),
//                                                               Expanded(
//                                                                 child: Column(
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .start,
//                                                                   children: [
//                                                                     Text(
//                                                                       controller
//                                                                           .orderModel
//                                                                           .driver!
//                                                                           .fullName()
//                                                                           .toString(),
//                                                                       textAlign:
//                                                                           TextAlign
//                                                                               .start,
//                                                                       style: TextStyle(
//                                                                         color: AppThemeData
//                                                                             .grey900,
//                                                                         fontFamily:
//                                                                             AppThemeData.semiBold,
//                                                                         fontWeight:
//                                                                             FontWeight.w600,
//                                                                         fontSize:
//                                                                             16,
//                                                                       ),
//                                                                     ),
//                                                                     Text(
//                                                                       controller
//                                                                           .orderModel
//                                                                           .driver!
//                                                                           .email
//                                                                           .toString(),
//                                                                       textAlign:
//                                                                           TextAlign
//                                                                               .start,
//                                                                       style: TextStyle(
//                                                                         color: AppThemeData
//                                                                             .success400,
//                                                                         fontFamily:
//                                                                             AppThemeData.regular,
//                                                                         fontWeight:
//                                                                             FontWeight.w400,
//                                                                         fontSize:
//                                                                             12,
//                                                                       ),
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ),
//                                                               InkWell(
//                                                                 onTap: () {
//                                                                   Constant.makePhoneCall(
//                                                                     controller
//                                                                         .orderModel
//                                                                         .driver!
//                                                                         .phoneNumber
//                                                                         .toString(),
//                                                                   );
//                                                                 },
//                                                                 child: Container(
//                                                                   width: 42,
//                                                                   height: 42,
//                                                                   decoration: ShapeDecoration(
//                                                                     shape: RoundedRectangleBorder(
//                                                                       side: BorderSide(
//                                                                         width:
//                                                                             1,
//                                                                         color: AppThemeData
//                                                                             .grey200,
//                                                                       ),
//                                                                       borderRadius:
//                                                                           BorderRadius.circular(
//                                                                             120,
//                                                                           ),
//                                                                     ),
//                                                                   ),
//                                                                   child: Padding(
//                                                                     padding:
//                                                                         const EdgeInsets.all(
//                                                                           8.0,
//                                                                         ),
//                                                                     child: SvgPicture.asset(
//                                                                       "assets/icons/ic_phone_call.svg",
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 10,
//                                                               ),
//                                                               InkWell(
//                                                                 onTap: () async {
//                                                                   ShowToastDialog.showLoader(
//                                                                     "Please wait"
//                                                                         .tr,
//                                                                   );
//
//                                                                   UserModel?
//                                                                   customer = await AddressListProvider.getUserProfile(
//                                                                     controller
//                                                                         .orderModel
//                                                                         .authorID
//                                                                         .toString(),
//                                                                   );
//                                                                   UserModel?
//                                                                   driverUser = await AddressListProvider.getUserProfile(
//                                                                     controller
//                                                                         .orderModel
//                                                                         .driverID
//                                                                         .toString(),
//                                                                   );
//
//                                                                   ShowToastDialog.closeLoader();
//                                                                   final userId =
//                                                                       await SqlStorageConst.getFirebaseId();
//                                                                   Get.to(
//                                                                     ChatScreen(
//                                                                       userId:
//                                                                           userId,
//                                                                     ),
//                                                                     arguments: {
//                                                                       "customerName":
//                                                                           customer!
//                                                                               .fullName(),
//                                                                       "restaurantName":
//                                                                           driverUser!
//                                                                               .fullName(),
//                                                                       "orderId":
//                                                                           controller
//                                                                               .orderModel
//                                                                               .id,
//                                                                       "restaurantId":
//                                                                           driverUser
//                                                                               .id,
//                                                                       "customerId":
//                                                                           customer
//                                                                               .id,
//                                                                       "customerProfileImage":
//                                                                           customer
//                                                                               .profilePictureURL,
//                                                                       "restaurantProfileImage":
//                                                                           driverUser
//                                                                               .profilePictureURL,
//                                                                       "token":
//                                                                           driverUser
//                                                                               .fcmToken,
//                                                                       "chatType":
//                                                                           "Driver",
//                                                                     },
//                                                                   );
//                                                                 },
//                                                                 child: Container(
//                                                                   width: 42,
//                                                                   height: 42,
//                                                                   decoration: ShapeDecoration(
//                                                                     shape: RoundedRectangleBorder(
//                                                                       side: BorderSide(
//                                                                         width:
//                                                                             1,
//                                                                         color: AppThemeData
//                                                                             .grey200,
//                                                                       ),
//                                                                       borderRadius:
//                                                                           BorderRadius.circular(
//                                                                             120,
//                                                                           ),
//                                                                     ),
//                                                                   ),
//                                                                   child: Padding(
//                                                                     padding:
//                                                                         const EdgeInsets.all(
//                                                                           8.0,
//                                                                         ),
//                                                                     child: SvgPicture.asset(
//                                                                       "assets/icons/ic_wechat.svg",
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           )
//                                                         : const SizedBox(),
//                                                   ],
//                                                 ),
//                                           const SizedBox(height: 10),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                             const SizedBox(height: 14),
//                             Text(
//                               "Your Order".tr,
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.semiBold,
//                                 fontSize: 16,
//                                 color: AppThemeData.grey900,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Container(
//                               decoration: ShapeDecoration(
//                                 color: AppThemeData.grey50,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 10,
//                                 ),
//                                 child: ListView.separated(
//                                   shrinkWrap: true,
//                                   padding: EdgeInsets.zero,
//                                   itemCount:
//                                       controller.orderModel.products!.length,
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   itemBuilder: (context, index) {
//                                     CartProductModel cartProductModel =
//                                         controller.orderModel.products![index];
//                                     return Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.center,
//                                           children: [
//                                             ClipRRect(
//                                               borderRadius:
//                                                   const BorderRadius.all(
//                                                     Radius.circular(14),
//                                                   ),
//                                               child: Stack(
//                                                 children: [
//                                                   NetworkImageWidget(
//                                                     imageUrl: cartProductModel
//                                                         .photo
//                                                         .toString(),
//                                                     height: Responsive.height(
//                                                       8,
//                                                       context,
//                                                     ),
//                                                     width: Responsive.width(
//                                                       16,
//                                                       context,
//                                                     ),
//                                                     fit: BoxFit.cover,
//                                                     fixOrientation: true,
//                                                   ),
//                                                   Container(
//                                                     height: Responsive.height(
//                                                       8,
//                                                       context,
//                                                     ),
//                                                     width: Responsive.width(
//                                                       16,
//                                                       context,
//                                                     ),
//                                                     decoration: BoxDecoration(
//                                                       gradient: LinearGradient(
//                                                         begin: const Alignment(
//                                                           -0.00,
//                                                           -1.00,
//                                                         ),
//                                                         end: const Alignment(
//                                                           0,
//                                                           1,
//                                                         ),
//                                                         colors: [
//                                                           Colors.black
//                                                               .withOpacity(0),
//                                                           const Color(
//                                                             0xFF111827,
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             const SizedBox(width: 10),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Row(
//                                                     children: [
//                                                       Expanded(
//                                                         child: Text(
//                                                           "${cartProductModel.name}",
//                                                           textAlign:
//                                                               TextAlign.start,
//                                                           style: TextStyle(
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .regular,
//                                                             color: AppThemeData
//                                                                 .grey900,
//                                                             fontSize: 16,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         "x ${cartProductModel.quantity}",
//                                                         textAlign:
//                                                             TextAlign.start,
//                                                         style: TextStyle(
//                                                           fontFamily:
//                                                               AppThemeData
//                                                                   .regular,
//                                                           color: AppThemeData
//                                                               .grey900,
//                                                           fontSize: 16,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   (() {
//                                                     // Check if this is a promotional item
//                                                     final priceValue =
//                                                         double.tryParse(
//                                                           cartProductModel.price
//                                                               .toString(),
//                                                         ) ??
//                                                         0.0;
//                                                     final discountPriceValue =
//                                                         double.tryParse(
//                                                           cartProductModel
//                                                               .discountPrice
//                                                               .toString(),
//                                                         ) ??
//                                                         0.0;
//                                                     final hasPromo =
//                                                         cartProductModel
//                                                                 .promoId !=
//                                                             null &&
//                                                         cartProductModel
//                                                             .promoId!
//                                                             .isNotEmpty;
//                                                     final isPricePromotional =
//                                                         priceValue > 0 &&
//                                                         discountPriceValue >
//                                                             0 &&
//                                                         priceValue <
//                                                             discountPriceValue;
//                                                     final isPromotional =
//                                                         hasPromo ||
//                                                         isPricePromotional;
//
//                                                     if (isPromotional) {
//                                                       // For promotional items: price = promotional, discountPrice = original
//                                                       return Row(
//                                                         children: [
//                                                           Text(
//                                                             Constant.amountShow(
//                                                               amount:
//                                                                   cartProductModel
//                                                                       .price
//                                                                       .toString(),
//                                                             ),
//                                                             style: TextStyle(
//                                                               fontSize: 16,
//                                                               color:
//                                                                   AppThemeData
//                                                                       .grey900,
//                                                               fontFamily:
//                                                                   AppThemeData
//                                                                       .semiBold,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w600,
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 5,
//                                                           ),
//                                                           Text(
//                                                             Constant.amountShow(
//                                                               amount: cartProductModel
//                                                                   .discountPrice
//                                                                   .toString(),
//                                                             ),
//                                                             style: TextStyle(
//                                                               fontSize: 14,
//                                                               decoration:
//                                                                   TextDecoration
//                                                                       .lineThrough,
//                                                               decorationColor:
//                                                                   AppThemeData
//                                                                       .grey400,
//                                                               color:
//                                                                   AppThemeData
//                                                                       .grey400,
//                                                               fontFamily:
//                                                                   AppThemeData
//                                                                       .semiBold,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w600,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       );
//                                                     } else if (double.parse(
//                                                           cartProductModel.discountPrice ==
//                                                                       null ||
//                                                                   cartProductModel
//                                                                       .discountPrice!
//                                                                       .isEmpty
//                                                               ? "0.0"
//                                                               : cartProductModel
//                                                                     .discountPrice
//                                                                     .toString(),
//                                                         ) <=
//                                                         0) {
//                                                       // No discount - show regular price
//                                                       return Text(
//                                                         Constant.amountShow(
//                                                           amount:
//                                                               cartProductModel
//                                                                   .price,
//                                                         ),
//                                                         style: TextStyle(
//                                                           fontSize: 16,
//                                                           color: AppThemeData
//                                                               .grey900,
//                                                           fontFamily:
//                                                               AppThemeData
//                                                                   .semiBold,
//                                                           fontWeight:
//                                                               FontWeight.w600,
//                                                         ),
//                                                       );
//                                                     } else {
//                                                       // Regular discount - show discount price prominently, original price strikethrough
//                                                       return Row(
//                                                         children: [
//                                                           Text(
//                                                             Constant.amountShow(
//                                                               amount: cartProductModel
//                                                                   .discountPrice
//                                                                   .toString(),
//                                                             ),
//                                                             style: TextStyle(
//                                                               fontSize: 16,
//                                                               color:
//                                                                   AppThemeData
//                                                                       .grey900,
//                                                               fontFamily:
//                                                                   AppThemeData
//                                                                       .semiBold,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w600,
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 5,
//                                                           ),
//                                                           Text(
//                                                             Constant.amountShow(
//                                                               amount:
//                                                                   cartProductModel
//                                                                       .price,
//                                                             ),
//                                                             style: TextStyle(
//                                                               fontSize: 14,
//                                                               decoration:
//                                                                   TextDecoration
//                                                                       .lineThrough,
//                                                               decorationColor:
//                                                                   AppThemeData
//                                                                       .grey400,
//                                                               color:
//                                                                   AppThemeData
//                                                                       .grey400,
//                                                               fontFamily:
//                                                                   AppThemeData
//                                                                       .semiBold,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w600,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       );
//                                                     }
//                                                   })(),
//                                                   Consumer<RateProductProvider>(
//                                                     builder:
//                                                         (
//                                                           context,
//                                                           rateProductProvider,
//                                                           _,
//                                                         ) {
//                                                           return Align(
//                                                             alignment: Alignment
//                                                                 .centerRight,
//                                                             child: RoundedButtonFill(
//                                                               title:
//                                                                   "Rate us".tr,
//                                                               height: 3.8,
//                                                               width: 20,
//                                                               color: AppThemeData
//                                                                   .warning300,
//                                                               textColor:
//                                                                   AppThemeData
//                                                                       .grey800,
//                                                               onPress: () async {
//                                                                 rateProductProvider.initFunction(
//                                                                   orderModel:
//                                                                       controller
//                                                                           .orderModel,
//                                                                   productId:
//                                                                       cartProductModel
//                                                                           .id
//                                                                           .toString(),
//                                                                 );
//                                                                 Get.to(
//                                                                   const RateProductScreen(),
//                                                                 );
//                                                               },
//                                                             ),
//                                                           );
//                                                         },
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         cartProductModel.variantInfo == null ||
//                                                 cartProductModel
//                                                     .variantInfo!
//                                                     .variantOptions!
//                                                     .isEmpty
//                                             ? Container()
//                                             : Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 5,
//                                                       vertical: 10,
//                                                     ),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       "Variants".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .semiBold,
//                                                         color: AppThemeData
//                                                             .grey600,
//                                                         fontSize: 16,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 5),
//                                                     Wrap(
//                                                       spacing: 6.0,
//                                                       runSpacing: 6.0,
//                                                       children: List.generate(
//                                                         cartProductModel
//                                                             .variantInfo!
//                                                             .variantOptions!
//                                                             .length,
//                                                         (i) {
//                                                           return Container(
//                                                             decoration: ShapeDecoration(
//                                                               color:
//                                                                   AppThemeData
//                                                                       .grey100,
//                                                               shape: RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius.circular(
//                                                                       8,
//                                                                     ),
//                                                               ),
//                                                             ),
//                                                             child: Padding(
//                                                               padding:
//                                                                   const EdgeInsets.symmetric(
//                                                                     horizontal:
//                                                                         16,
//                                                                     vertical: 5,
//                                                                   ),
//                                                               child: Text(
//                                                                 "${cartProductModel.variantInfo!.variantOptions!.keys.elementAt(i)} : ${cartProductModel.variantInfo!.variantOptions![cartProductModel.variantInfo!.variantOptions!.keys.elementAt(i)]}",
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .start,
//                                                                 style: TextStyle(
//                                                                   fontFamily:
//                                                                       AppThemeData
//                                                                           .medium,
//                                                                   color: AppThemeData
//                                                                       .grey400,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           );
//                                                         },
//                                                       ).toList(),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                         cartProductModel.extras == null ||
//                                                 cartProductModel.extras!.isEmpty
//                                             ? const SizedBox()
//                                             : Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Row(
//                                                     children: [
//                                                       Expanded(
//                                                         child: Text(
//                                                           "Addons".tr,
//                                                           textAlign:
//                                                               TextAlign.start,
//                                                           style: TextStyle(
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .semiBold,
//                                                             color: AppThemeData
//                                                                 .grey600,
//                                                             fontSize: 16,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         Constant.amountShow(
//                                                           amount:
//                                                               (double.parse(
//                                                                         cartProductModel
//                                                                             .extrasPrice
//                                                                             .toString(),
//                                                                       ) *
//                                                                       double.parse(
//                                                                         cartProductModel
//                                                                             .quantity
//                                                                             .toString(),
//                                                                       ))
//                                                                   .toString(),
//                                                         ),
//                                                         textAlign:
//                                                             TextAlign.start,
//                                                         style: TextStyle(
//                                                           fontFamily:
//                                                               AppThemeData
//                                                                   .semiBold,
//                                                           color: AppThemeData
//                                                               .primary300,
//                                                           fontSize: 16,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   Wrap(
//                                                     spacing: 6.0,
//                                                     runSpacing: 6.0,
//                                                     children: List.generate(
//                                                       cartProductModel
//                                                           .extras!
//                                                           .length,
//                                                       (i) {
//                                                         return Container(
//                                                           decoration: ShapeDecoration(
//                                                             color: AppThemeData
//                                                                 .grey100,
//                                                             shape: RoundedRectangleBorder(
//                                                               borderRadius:
//                                                                   BorderRadius.circular(
//                                                                     8,
//                                                                   ),
//                                                             ),
//                                                           ),
//                                                           child: Padding(
//                                                             padding:
//                                                                 const EdgeInsets.symmetric(
//                                                                   horizontal:
//                                                                       16,
//                                                                   vertical: 5,
//                                                                 ),
//                                                             child: Text(
//                                                               cartProductModel
//                                                                   .extras![i]
//                                                                   .toString(),
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .start,
//                                                               style: TextStyle(
//                                                                 fontFamily:
//                                                                     AppThemeData
//                                                                         .medium,
//                                                                 color:
//                                                                     AppThemeData
//                                                                         .grey400,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         );
//                                                       },
//                                                     ).toList(),
//                                                   ),
//                                                 ],
//                                               ),
//                                       ],
//                                     );
//                                   },
//                                   separatorBuilder: (context, index) {
//                                     return Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 10,
//                                       ),
//                                       child: MySeparator(
//                                         color: AppThemeData.grey200,
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 14),
//                             Text(
//                               "Bill Details".tr,
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.semiBold,
//                                 fontSize: 16,
//                                 color: AppThemeData.grey900,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Container(
//                               width: Responsive.width(100, context),
//                               decoration: ShapeDecoration(
//                                 color: AppThemeData.grey50,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 14,
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Item totals".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           Constant.amountShow(
//                                             amount: bill.subTotal.toString(),
//                                           ),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Delivery Fee".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         (() {
//                                           // Check if cart has promotional items
//                                           final hasPromotionalItems = order
//                                               .products!
//                                               .any((item) {
//                                                 final priceValue =
//                                                     double.tryParse(
//                                                       item.price.toString(),
//                                                     ) ??
//                                                     0.0;
//                                                 final discountPriceValue =
//                                                     double.tryParse(
//                                                       item.discountPrice
//                                                           .toString(),
//                                                     ) ??
//                                                     0.0;
//                                                 final hasPromo =
//                                                     item.promoId != null &&
//                                                     item.promoId!.isNotEmpty;
//                                                 final isPricePromotional =
//                                                     priceValue > 0 &&
//                                                     discountPriceValue > 0 &&
//                                                     priceValue <
//                                                         discountPriceValue;
//                                                 return hasPromo ||
//                                                     isPricePromotional;
//                                               });
//
//                                           // Self delivery check
//                                           if (vendor.isSelfDelivery == true &&
//                                               Constant.isSelfDeliveryFeature ==
//                                                   true) {
//                                             return Text(
//                                               'Free Delivery',
//                                               textAlign: TextAlign.start,
//                                               style: TextStyle(
//                                                 fontFamily:
//                                                     AppThemeData.regular,
//                                                 color: AppThemeData.success400,
//                                                 fontSize: 16,
//                                               ),
//                                             );
//                                           }
//
//                                           // Promotional items delivery logic
//                                           if (hasPromotionalItems) {
//                                             // For promotional items, check if within free delivery distance (3 km)
//                                             if (totalDistance <= 3.0) {
//                                               // Free delivery for promotional items within 3 km
//                                               return Row(
//                                                 children: [
//                                                   Text(
//                                                     'Free Delivery',
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color: AppThemeData
//                                                           .success400,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(width: 8),
//                                                   Text(
//                                                     Constant.amountShow(
//                                                       amount: '23.00',
//                                                     ),
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color: AppThemeData
//                                                           .danger300,
//                                                       fontSize: 16,
//                                                       decoration: TextDecoration
//                                                           .lineThrough,
//                                                       decorationColor:
//                                                           AppThemeData
//                                                               .danger300,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(width: 8),
//                                                   Text(
//                                                     Constant.amountShow(
//                                                       amount: '0.00',
//                                                     ),
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color:
//                                                           AppThemeData.grey900,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               );
//                                             } else {
//                                               // Paid delivery for promotional items beyond 3 km
//                                               return Row(
//                                                 children: [
//                                                   Text(
//                                                     'Delivery Charge',
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color:
//                                                           AppThemeData.grey900,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(width: 8),
//                                                   Text(
//                                                     Constant.amountShow(
//                                                       amount: bill
//                                                           .deliveryCharges
//                                                           .toString(),
//                                                     ),
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color:
//                                                           AppThemeData.grey900,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               );
//                                             }
//                                           }
//
//                                           if (bill.subTotal >=
//                                                   displayThreshold &&
//                                               totalDistance >
//                                                   displayFreeDistance) {
//                                             return Row(
//                                               children: [
//                                                 // Text(
//                                                 //   'Free Delivery',
//                                                 //   textAlign: TextAlign.start,
//                                                 //   style: TextStyle(
//                                                 //     fontFamily:
//                                                 //         AppThemeData.regular,
//                                                 //     color:
//                                                 //         AppThemeData.success400,
//                                                 //     fontSize: 16,
//                                                 //   ),
//                                                 // ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   Constant.amountShow(
//                                                     amount: bill
//                                                         .originalDeliveryFee
//                                                         .toString(),
//                                                   ),
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.regular,
//                                                     color:
//                                                         AppThemeData.danger300,
//                                                     fontSize: 16,
//                                                     decoration: TextDecoration
//                                                         .lineThrough,
//                                                     decorationColor:
//                                                         AppThemeData.danger300,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   Constant.amountShow(
//                                                     amount: bill.deliveryCharges
//                                                         .toString(),
//                                                   ),
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.regular,
//                                                     color: AppThemeData.grey900,
//                                                     fontSize: 16,
//                                                   ),
//                                                 ),
//                                               ],
//                                             );
//                                           }
//
//                                           if (bill.subTotal >=
//                                                   displayThreshold &&
//                                               totalDistance <=
//                                                   displayFreeDistance) {
//                                             return Row(
//                                               children: [
//                                                 Text(
//                                                   'Free Delivery',
//                                                   textAlign: TextAlign.start,
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.regular,
//                                                     color:
//                                                         AppThemeData.success400,
//                                                     fontSize: 16,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   Constant.amountShow(
//                                                     amount: displayBaseCharge
//                                                         .toString(),
//                                                   ),
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.regular,
//                                                     color:
//                                                         AppThemeData.danger300,
//                                                     fontSize: 16,
//                                                     decoration: TextDecoration
//                                                         .lineThrough,
//                                                     decorationColor:
//                                                         AppThemeData.danger300,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   Constant.amountShow(
//                                                     amount: '0.00',
//                                                   ),
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         AppThemeData.regular,
//                                                     color: AppThemeData.grey900,
//                                                     fontSize: 16,
//                                                   ),
//                                                 ),
//                                               ],
//                                             );
//                                           }
//                                           // Default case - paid delivery
//                                           return Row(
//                                             children: [
//                                               // Text(
//                                               //   'Delivery Charge',
//                                               //   textAlign: TextAlign.start,
//                                               //   style: TextStyle(
//                                               //     fontFamily:
//                                               //         AppThemeData.regular,
//                                               //     color: AppThemeData.grey900,
//                                               //     fontSize: 16,
//                                               //   ),
//                                               // ),
//                                               const SizedBox(width: 8),
//                                               Text(
//                                                 Constant.amountShow(
//                                                   amount: bill.deliveryCharges
//                                                       .toString(),
//                                                 ),
//                                                 style: TextStyle(
//                                                   fontFamily:
//                                                       AppThemeData.regular,
//                                                   color: AppThemeData.grey900,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                             ],
//                                           );
//                                         })(),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Platform Fee".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           '15.00',
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.danger300,
//                                             fontSize: 16,
//                                             decoration:
//                                                 TextDecoration.lineThrough,
//                                             decorationColor:
//                                                 AppThemeData.danger300,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Surge Fee".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           "₹${surgeFee ?? 0.0}",
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     MySeparator(color: AppThemeData.grey200),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Coupon Discount".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           "- (${Constant.amountShow(amount: order.discount.toString())})",
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.danger300,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     order.specialDiscount != null &&
//                                             order.specialDiscount!['special_discount'] !=
//                                                 null
//                                         ? Column(
//                                             children: [
//                                               const SizedBox(height: 10),
//                                               Row(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Expanded(
//                                                     child: Text(
//                                                       "Special Discount".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .regular,
//                                                         color: AppThemeData
//                                                             .grey600,
//                                                         fontSize: 16,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     "- (${Constant.amountShow(amount: order.specialDiscount!['special_discount'].toString())})",
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.regular,
//                                                       color: AppThemeData
//                                                           .danger300,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           )
//                                         : const SizedBox(),
//                                     const SizedBox(height: 10),
//                                     order.takeAway == true ||
//                                             vendor.isSelfDelivery == true
//                                         ? const SizedBox()
//                                         : Row(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Expanded(
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       "Delivery Tips".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .regular,
//                                                         color: AppThemeData
//                                                             .grey600,
//                                                         fontSize: 16,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                               Text(
//                                                 Constant.amountShow(
//                                                   amount: order.tipAmount
//                                                       .toString(),
//                                                 ),
//                                                 textAlign: TextAlign.start,
//                                                 style: TextStyle(
//                                                   fontFamily:
//                                                       AppThemeData.regular,
//                                                   color: AppThemeData.grey900,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                     const SizedBox(height: 10),
//                                     MySeparator(color: AppThemeData.grey200),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Taxes & Charges",
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           Constant.amountShow(
//                                             amount: bill.taxAmount.toString(),
//                                           ),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "To Pay".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           Constant.amountShow(
//                                             amount:
//                                                 "${bill.totalAmount + (surgeFee ?? 0.0)}",
//                                           ),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 14),
//                             Text(
//                               "Order Details".tr,
//                               textAlign: TextAlign.start,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.semiBold,
//                                 fontSize: 16,
//                                 color: AppThemeData.grey900,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Container(
//                               width: Responsive.width(100, context),
//                               decoration: ShapeDecoration(
//                                 color: AppThemeData.grey50,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 14,
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Delivery type".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           order.takeAway == true
//                                               ? "TakeAway".tr
//                                               : order.scheduleTime == null
//                                               ? "Standard".tr
//                                               : "Schedule".tr,
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.medium,
//                                             color: order.scheduleTime != null
//                                                 ? AppThemeData.primary300
//                                                 : AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Payment Method".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           order.paymentMethod.toString(),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             "Date and Time".tr,
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           Constant.timestampToDateTime(
//                                             order.createdAt!,
//                                           ),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey600,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 "Phone Number".tr,
//                                                 textAlign: TextAlign.start,
//                                                 style: TextStyle(
//                                                   fontFamily:
//                                                       AppThemeData.regular,
//                                                   color: AppThemeData.grey600,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         Text(
//                                           order.author!.phoneNumber.toString(),
//                                           textAlign: TextAlign.start,
//                                           style: TextStyle(
//                                             fontFamily: AppThemeData.regular,
//                                             color: AppThemeData.grey900,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 20),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             order.notes == null || order.notes!.isEmpty
//                                 ? const SizedBox()
//                                 : Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Remarks".tr,
//                                         textAlign: TextAlign.start,
//                                         style: TextStyle(
//                                           fontFamily: AppThemeData.semiBold,
//                                           fontSize: 16,
//                                           color: AppThemeData.grey900,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       Container(
//                                         width: Responsive.width(100, context),
//                                         decoration: ShapeDecoration(
//                                           color: AppThemeData.grey50,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 10,
//                                             vertical: 14,
//                                           ),
//                                           child: Text(
//                                             order.notes.toString(),
//                                             textAlign: TextAlign.start,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.regular,
//                                               color: AppThemeData.grey900,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                           ],
//                         ),
//                       ),
//                     ),
//               bottomNavigationBar:
//                   order.status == Constant.orderShipped ||
//                       order.status == Constant.orderInTransit ||
//                       order.status == Constant.orderCompleted
//                   ? Container(
//                       color: AppThemeData.grey50,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 20,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.only(bottom: 20),
//                         child:
//                             order.status == Constant.orderShipped ||
//                                 order.status == Constant.orderInTransit
//                             ? Consumer<LiveTrackingProvider>(
//                                 builder: (context, liveTrackingProvider, _) {
//                                   return RoundedButtonFill(
//                                     title: "Track Order".tr,
//                                     height: 5.5,
//                                     color: AppThemeData.warning300,
//                                     textColor: AppThemeData.grey900,
//                                     onPress: () async {
//                                       liveTrackingProvider.initFunction(
//                                         orderModel: order,
//                                       );
//                                       Get.to(const LiveTrackingScreen());
//                                     },
//                                   );
//                                 },
//                               )
//                             : RoundedButtonFill(
//                                 title: "Reorder".tr,
//                                 height: 5.5,
//                                 color: AppThemeData.primary300,
//                                 textColor: AppThemeData.grey50,
//                                 onPress: () async {
//                                   for (var element in order.products!) {
//                                     controller.addToCart(
//                                       cartProductModel: element,
//                                     );
//                                     ShowToastDialog.showToast(
//                                       "Item Added In a cart".tr,
//                                     );
//                                   }
//                                 },
//                               ),
//                       ),
//                     )
//                   : const SizedBox(),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/chat_screens/chat_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/rate_us_screen/provider/rate_product_provider.dart';
import 'package:jippymart_customer/app/rate_us_screen/rate_product_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

class OrderBillDetails {
  final double subTotal;
  final double deliveryCharges;
  final double originalDeliveryFee;
  final double couponAmount;
  final double specialDiscountAmount;
  final double taxAmount;
  final double deliveryTips;
  final double totalAmount;
  final bool isFreeDelivery;

  OrderBillDetails({
    required this.subTotal,
    required this.deliveryCharges,
    required this.originalDeliveryFee,
    required this.couponAmount,
    required this.specialDiscountAmount,
    required this.taxAmount,
    required this.deliveryTips,
    required this.totalAmount,
    required this.isFreeDelivery,
  });
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, this.surgeFee});

  final double? surgeFee;

  // Cache for promotional details to avoid repeated Firestore calls
  static final Map<String, Map<String, dynamic>> _promoDetailsCache = {};

  // Cached delivery charge fetched from backend (mirrors cart provider behaviour)
  static DeliveryCharge? _cachedMartDeliveryCharge;
  static DateTime? _lastDeliveryChargeFetchTime;
  static const Duration _deliveryChargeCacheExpiry = Duration(minutes: 5);

  // Fallback values used only when API data is unavailable
  static const double _fallbackThreshold = 299.0;
  static const double _fallbackBaseCharge = 23.0;
  static const double _fallbackFreeKm = 5.0;
  static const double _fallbackPerKm = 7.0;
  static const double _promoFreeDeliveryKm = 3.0;

  Future<OrderBillDetails> _calculateOrderBillDetails(
    OrderModel order,
    VendorModel? vendor,
    DeliveryCharge deliveryCharge,
    double totalDistance,
  ) async {
    final DeliveryCharge resolvedDeliveryCharge = await _resolveDeliveryCharge(
      deliveryCharge,
      vendor: vendor,
    );

    // Calculate subtotal first (local calculation)
    final subTotalResult = _calculateSubTotal(order);
    final double subTotal = subTotalResult['subTotal'] as double;
    final bool hasPromotionalItems =
        subTotalResult['hasPromotionalItems'] as bool;

    final double threshold = _getDoubleValue(
      resolvedDeliveryCharge.itemTotalThreshold,
      _fallbackThreshold,
    );
    final double baseCharge = _getDoubleValue(
      resolvedDeliveryCharge.baseDeliveryCharge,
      _fallbackBaseCharge,
    );
    final double freeKm = _getDoubleValue(
      resolvedDeliveryCharge.freeDeliveryDistanceKm,
      _fallbackFreeKm,
    );
    final double perKm = _getDoubleValue(
      resolvedDeliveryCharge.perKmChargeAboveFreeDistance,
      _fallbackPerKm,
    );

    // Delivery charges calculation
    final deliveryResult = await _calculateDeliveryCharges(
      order: order,
      vendor: vendor,
      hasPromotionalItems: hasPromotionalItems,
      subTotal: subTotal,
      totalDistance: totalDistance,
      threshold: threshold,
      baseCharge: baseCharge,
      freeKm: freeKm,
      perKm: perKm,
    );

    // Coupon calculation
    final double couponAmount = _calculateCouponAmount(
      order: order,
      hasPromotionalItems: hasPromotionalItems,
    );

    // Special discount
    final double specialDiscountAmount = _calculateSpecialDiscount(order);

    // Tax calculation
    final double taxAmount = _calculateTaxAmount(
      subTotal: subTotal,
      deliveryCharges: deliveryResult['deliveryCharges'] as double,
      originalDeliveryFee: deliveryResult['originalDeliveryFee'] as double,
    );

    // Check free delivery
    final bool isFreeDelivery = _checkFreeDelivery(
      hasPromotionalItems: hasPromotionalItems,
      subTotal: subTotal,
      totalDistance: totalDistance,
      threshold: threshold,
      freeKm: freeKm,
    );

    // Delivery tips
    final double deliveryTips = _getDoubleValue(order.tipAmount, 0.0);

    // Total amount
    final double totalAmount =
        (subTotal - couponAmount - specialDiscountAmount) +
        taxAmount +
        (isFreeDelivery ? 0.0 : deliveryResult['deliveryCharges'] as double) +
        deliveryTips;

    return OrderBillDetails(
      subTotal: subTotal,
      deliveryCharges: deliveryResult['deliveryCharges'] as double,
      originalDeliveryFee: deliveryResult['originalDeliveryFee'] as double,
      couponAmount: couponAmount,
      specialDiscountAmount: specialDiscountAmount,
      taxAmount: taxAmount,
      deliveryTips: deliveryTips,
      totalAmount: totalAmount,
      isFreeDelivery: isFreeDelivery,
    );
  }

  Future<DeliveryCharge> _resolveDeliveryCharge(
    DeliveryCharge deliveryCharge, {
    VendorModel? vendor,
  }) async {
    if (_hasDeliveryChargeData(deliveryCharge)) {
      return deliveryCharge;
    }

    if (_cachedMartDeliveryCharge != null && _isDeliveryChargeCacheValid()) {
      vendor?.deliveryCharge ??= _cachedMartDeliveryCharge;
      return _cachedMartDeliveryCharge!;
    }

    final apiDeliveryCharge = await FireStoreUtils.getDeliveryCharge();
    if (_hasDeliveryChargeData(apiDeliveryCharge)) {
      _cachedMartDeliveryCharge = apiDeliveryCharge;
      _lastDeliveryChargeFetchTime = DateTime.now();
      vendor?.deliveryCharge = apiDeliveryCharge;
      return apiDeliveryCharge!;
    }

    final fallbackCharge = DeliveryCharge(
      itemTotalThreshold: _fallbackThreshold,
      baseDeliveryCharge: _fallbackBaseCharge,
      freeDeliveryDistanceKm: _fallbackFreeKm,
      perKmChargeAboveFreeDistance: _fallbackPerKm,
    );
    vendor?.deliveryCharge ??= fallbackCharge;
    return fallbackCharge;
  }

  bool _hasDeliveryChargeData(DeliveryCharge? charge) {
    if (charge == null) {
      return false;
    }

    final hasThreshold =
        charge.itemTotalThreshold != null && charge.itemTotalThreshold! > 0;
    final hasBaseCharge =
        charge.baseDeliveryCharge != null && charge.baseDeliveryCharge! > 0;
    final hasFreeKm =
        charge.freeDeliveryDistanceKm != null && charge.freeDeliveryDistanceKm! > 0;
    final hasPerKm = charge.perKmChargeAboveFreeDistance != null &&
        charge.perKmChargeAboveFreeDistance! > 0;

    return hasThreshold || hasBaseCharge || hasFreeKm || hasPerKm;
  }

  bool _isDeliveryChargeCacheValid() {
    if (_lastDeliveryChargeFetchTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastDeliveryChargeFetchTime!) <
        _deliveryChargeCacheExpiry;
  }

  double _getDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> _calculateSubTotal(OrderModel order) {
    double subTotal = 0.0;
    bool hasPromotionalItems = false;

    if (order.products != null) {
      for (var element in order.products!) {
        final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
        final discountPriceValue =
            double.tryParse(element.discountPrice.toString()) ?? 0.0;

        // Check if promotional
        final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
        final isPricePromotional =
            priceValue > 0 &&
            discountPriceValue > 0 &&
            priceValue < discountPriceValue;
        final isPromotional = hasPromo || isPricePromotional;

        if (isPromotional) {
          hasPromotionalItems = true;
        }

        double itemPrice;
        if (isPromotional) {
          itemPrice = priceValue < discountPriceValue
              ? priceValue
              : discountPriceValue;
        } else if (discountPriceValue <= 0) {
          itemPrice = priceValue;
        } else {
          itemPrice = discountPriceValue;
        }

        final quantity = double.parse(element.quantity.toString());
        final extrasPrice = double.parse(element.extrasPrice.toString());
        final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
        subTotal += itemTotal;
      }
    }

    return {'subTotal': subTotal, 'hasPromotionalItems': hasPromotionalItems};
  }

  Future<Map<String, double>> _calculateDeliveryCharges({
    required OrderModel order,
    required VendorModel? vendor,
    required bool hasPromotionalItems,
    required double subTotal,
    required double totalDistance,
    required double threshold,
    required double baseCharge,
    required double freeKm,
    required double perKm,
  }) async {
    double deliveryCharges = 0.0;
    double originalDeliveryFee = 0.0;

    // Self delivery check
    if (vendor?.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      return {'deliveryCharges': 0.0, 'originalDeliveryFee': 0.0};
    }

    if (hasPromotionalItems) {
      // Promotional items delivery logic
      final promotionalItems = (order.products ?? []).where((item) {
        final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
        final discountPriceValue =
            double.tryParse(item.discountPrice.toString()) ?? 0.0;
        final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
        final isPricePromotional =
            priceValue > 0 &&
            discountPriceValue > 0 &&
            priceValue < discountPriceValue;
        return hasPromo || isPricePromotional;
      }).toList();

      if (promotionalItems.isNotEmpty) {
        final firstPromoItem = promotionalItems.first;
        final cacheKey = '${firstPromoItem.id}_${firstPromoItem.vendorID}';

        try {
          // Check cache first
          Map<String, dynamic>? promoDetails;
          if (_promoDetailsCache.containsKey(cacheKey)) {
            promoDetails = _promoDetailsCache[cacheKey];
          } else {
            // Fetch from Firestore if not in cache
            promoDetails = await FireStoreUtils.getActivePromotionForProduct(
              productId: firstPromoItem.id ?? '',
              restaurantId: firstPromoItem.vendorID ?? '',
            );
            if (promoDetails != null) {
              _promoDetailsCache[cacheKey] = promoDetails;
            }
          }

          if (promoDetails != null) {
            final freeDeliveryKm = _getDoubleValue(
              promoDetails['free_delivery_km'],
              3.0,
            );
            final extraKmCharge = _getDoubleValue(
              promoDetails['extra_km_charge'],
              perKm,
            );

            if (totalDistance <= freeDeliveryKm) {
              deliveryCharges = 0.0;
              originalDeliveryFee = baseCharge;
            } else {
              // 🔑 FIX: For promotional items above free km, GST should be on base charge + extra km charges
              double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
              deliveryCharges = extraKm * extraKmCharge;
              originalDeliveryFee = baseCharge + deliveryCharges; // Base charge + extra km for GST
            }
            return {
              'deliveryCharges': deliveryCharges,
              'originalDeliveryFee': originalDeliveryFee,
            };
          }
        } catch (e) {
          // Fall through to regular logic
        }
      }
    }

    // Regular delivery logic (fallback)
    if (subTotal < threshold) {
      if (totalDistance <= freeKm) {
        deliveryCharges = baseCharge;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        deliveryCharges = baseCharge + (extraKm * perKm);
        originalDeliveryFee = deliveryCharges;
      }
    } else {
      if (totalDistance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        deliveryCharges = extraKm * perKm;
        originalDeliveryFee = baseCharge + (extraKm * perKm);
      }
    }

    return {
      'deliveryCharges': deliveryCharges,
      'originalDeliveryFee': originalDeliveryFee,
    };
  }

  double _calculateCouponAmount({
    required OrderModel order,
    required bool hasPromotionalItems,
  }) {
    if (hasPromotionalItems) {
      return 0.0;
    }

    if (order.couponId != null &&
        order.couponId!.isNotEmpty &&
        order.discount != null) {
      return _getDoubleValue(order.discount, 0.0);
    }

    return 0.0;
  }

  double _calculateSpecialDiscount(OrderModel order) {
    if (order.specialDiscount != null &&
        order.specialDiscount!['special_discount'] != null) {
      return _getDoubleValue(order.specialDiscount!['special_discount'], 0.0);
    }
    return 0.0;
  }

  double _calculateTaxAmount({
    required double subTotal,
    required double deliveryCharges,
    required double originalDeliveryFee,
  }) {
    final double taxableDeliveryFee = originalDeliveryFee > 0
        ? originalDeliveryFee
        : (deliveryCharges > 0 ? deliveryCharges : 0.0);

    double sgst = subTotal * 0.05;
    double gst = taxableDeliveryFee * 0.18;
    sgst = sgst.isNaN ? 0.0 : sgst;
    gst = gst.isNaN ? 0.0 : gst;

    double taxAmount = sgst + gst;

    if (taxAmount == 0.0) {
      double sgstFallback = subTotal * 0.05;
      double gstFallback = taxableDeliveryFee > 0
          ? taxableDeliveryFee * 0.18
          : 0.0;
      taxAmount = sgstFallback + gstFallback;
    }

    return taxAmount.isNaN ? 0.0 : taxAmount;
  }

  bool _checkFreeDelivery({
    required bool hasPromotionalItems,
    required double subTotal,
    required double totalDistance,
    required double threshold,
    required double freeKm,
  }) {
    if (hasPromotionalItems) {
      // For promotional items, free delivery within 3km (or use cache)
      return totalDistance <= 3.0;
    } else {
      // For regular items
      return subTotal >= threshold && totalDistance <= freeKm;
    }
  }

  // Optimized widget builder for product item
  Widget _buildProductItem(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    final priceValue =
        double.tryParse(cartProductModel.price.toString()) ?? 0.0;
    final discountPriceValue =
        double.tryParse(cartProductModel.discountPrice.toString()) ?? 0.0;
    final hasPromo =
        cartProductModel.promoId != null &&
        cartProductModel.promoId!.isNotEmpty;
    final isPricePromotional =
        priceValue > 0 &&
        discountPriceValue > 0 &&
        priceValue < discountPriceValue;
    final isPromotional = hasPromo || isPricePromotional;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProductImage(context, cartProductModel),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${cartProductModel.name}",
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.grey900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        "x ${cartProductModel.quantity}",
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  _buildPriceWidget(isPromotional, cartProductModel),
                  _buildRateButton(context, cartProductModel),
                ],
              ),
            ),
          ],
        ),
        _buildVariants(cartProductModel),
        _buildExtras(cartProductModel),
      ],
    );
  }

  Widget _buildProductImage(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Stack(
        children: [
          NetworkImageWidget(
            imageUrl: cartProductModel.photo.toString(),
            height: Responsive.height(8, context),
            width: Responsive.width(16, context),
            fit: BoxFit.cover,
            fixOrientation: true,
          ),
          Container(
            height: Responsive.height(8, context),
            width: Responsive.width(16, context),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.00, -1.00),
                end: const Alignment(0, 1),
                colors: [Colors.black.withOpacity(0), const Color(0xFF111827)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceWidget(
    bool isPromotional,
    CartProductModel cartProductModel,
  ) {
    if (isPromotional) {
      return Row(
        children: [
          Text(
            Constant.amountShow(amount: cartProductModel.price.toString()),
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            Constant.amountShow(
              amount: cartProductModel.discountPrice.toString(),
            ),
            style: TextStyle(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey400,
              color: AppThemeData.grey400,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (double.parse(cartProductModel.discountPrice ?? "0.0") <= 0) {
      return Text(
        Constant.amountShow(amount: cartProductModel.price),
        style: TextStyle(
          fontSize: 16,
          color: AppThemeData.grey900,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Row(
        children: [
          Text(
            Constant.amountShow(
              amount: cartProductModel.discountPrice.toString(),
            ),
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            Constant.amountShow(amount: cartProductModel.price),
            style: TextStyle(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey400,
              color: AppThemeData.grey400,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRateButton(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    return Consumer<RateProductProvider>(
      builder: (context, rateProductProvider, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: RoundedButtonFill(
            title: "Rate us".tr,
            height: 3.8,
            width: 20,
            color: AppThemeData.warning300,
            textColor: AppThemeData.grey800,
            onPress: () async {
              final orderDetailsProvider = Provider.of<OrderDetailsProvider>(
                context,
                listen: false,
              );
              rateProductProvider.initFunction(
                orderModel: orderDetailsProvider.orderModel,
                productId: cartProductModel.id.toString(),
              );
              Get.to(const RateProductScreen());
            },
          ),
        );
      },
    );
  }

  Widget _buildVariants(CartProductModel cartProductModel) {
    if (cartProductModel.variantInfo == null ||
        cartProductModel.variantInfo!.variantOptions!.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Variants".tr,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: cartProductModel.variantInfo!.variantOptions!.entries.map(
              (entry) {
                return Container(
                  decoration: ShapeDecoration(
                    color: AppThemeData.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Text(
                      "${entry.key} : ${entry.value}",
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey400,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtras(CartProductModel cartProductModel) {
    if (cartProductModel.extras == null || cartProductModel.extras!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Addons".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              Constant.amountShow(
                amount:
                    (double.parse(cartProductModel.extrasPrice.toString()) *
                            double.parse(cartProductModel.quantity.toString()))
                        .toString(),
              ),
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.primary300,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: cartProductModel.extras!.map((extra) {
            return Container(
              decoration: ShapeDecoration(
                color: AppThemeData.grey100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Text(
                  extra.toString(),
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeliveryFeeWidget({
    required OrderModel order,
    required OrderBillDetails bill,
    required bool hasPromotionalItems,
    required double totalDistance,
    required VendorModel vendor,
  }) {
    final deliveryChargeModel = vendor.deliveryCharge;
    final double baseCharge = _getDoubleValue(
      deliveryChargeModel?.baseDeliveryCharge,
      _fallbackBaseCharge,
    );
    final double threshold = _getDoubleValue(
      deliveryChargeModel?.itemTotalThreshold,
      _fallbackThreshold,
    );
    final double freeKm = _getDoubleValue(
      deliveryChargeModel?.freeDeliveryDistanceKm,
      _fallbackFreeKm,
    );
    final double payableDeliveryFee =
        bill.deliveryCharges < 0 ? 0.0 : bill.deliveryCharges;

    if (vendor.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      return Text(
        'Free Delivery',
        style: TextStyle(
          fontFamily: AppThemeData.regular,
          color: AppThemeData.success400,
          fontSize: 16,
        ),
      );
    }

    if (hasPromotionalItems) {
      final bool isWithinPromoFreeRadius = totalDistance <= _promoFreeDeliveryKm;
      final double promoCurrentFee =
          isWithinPromoFreeRadius ? 0.0 : payableDeliveryFee;

      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseCharge,
        currentFee: promoCurrentFee,
      );
    }

    final bool qualifiesForFreeByThreshold = bill.subTotal >= threshold;
    if (qualifiesForFreeByThreshold) {
      final bool isWithinFreeDistance = totalDistance <= freeKm;
      final double currentFee = isWithinFreeDistance ? 0.0 : payableDeliveryFee;

      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseCharge,
        currentFee: currentFee,
      );
    }

    return buildDeliveryFeeUI(
      isFreeDelivery: false,
      originalFee: 0.0,
      currentFee: payableDeliveryFee,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsProvider>(
      builder: (context, controller, _) {
        final order = controller.orderModel;

        if (order.products == null || order.products!.isEmpty) {
          return _buildErrorScreen(
            "Order details are incomplete. Please contact support.".tr,
          );
        }

        final vendor = order.vendor ?? _createDefaultMartVendor();
        final deliveryCharge = vendor.deliveryCharge ?? DeliveryCharge();
        final totalDistance = order.vendor != null
            ? Constant.calculateDistance(
                vendor.latitude ?? 0.0,
                vendor.longitude ?? 0.0,
                order.address?.location?.latitude ?? 0.0,
                order.address?.location?.longitude ?? 0.0,
              )
            : 0.0;

        return FutureBuilder<OrderBillDetails>(
          future: _calculateOrderBillDetails(
            order,
            vendor,
            deliveryCharge,
            totalDistance,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (snapshot.hasError) {
              return _buildErrorScreen("Error loading order details".tr);
            }

            final bill = snapshot.data!;
            final hasPromotionalItems =
                _calculateSubTotal(order)['hasPromotionalItems'] as bool;

            return Scaffold(
              backgroundColor: AppThemeData.surface,
              appBar: AppBar(
                backgroundColor: AppThemeData.surface,
                centerTitle: false,
                titleSpacing: 0,
                title: Text(
                  "Order Details".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 16,
                    color: AppThemeData.grey900,
                  ),
                ),
              ),
              body: controller.isLoading
                  ? Constant.loader(message: "Loading order details...".tr)
                  : _buildContent(
                      context,
                      controller,
                      order,
                      vendor,
                      bill,
                      hasPromotionalItems,
                      totalDistance,
                    ),
              bottomNavigationBar: _buildBottomNavigationBar(
                context,
                controller,
                order,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: Constant.loader(message: "Loading order details...".tr),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: Center(child: Text(message.tr)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
    VendorModel vendor,
    OrderBillDetails bill,
    bool hasPromotionalItems,
    double totalDistance,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            _buildOrderHeader(controller, order),
            const SizedBox(height: 14),

            // Vendor/Address section
            order.takeAway == true
                ? _buildTakeAwaySection(context, controller, order)
                : _buildDeliverySection(context, controller, order),
            const SizedBox(height: 14),

            // Your Order section
            _buildYourOrderSection(context, controller),
            const SizedBox(height: 14),

            // Bill Details section
            _buildBillDetailsSection(
              order,
              bill,
              hasPromotionalItems,
              totalDistance,
              vendor,
            ),
            const SizedBox(height: 14),

            // Order Details section
            _buildOrderDetailsSection(order),

            // Remarks section (conditional)
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRemarksSection(order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetailsProvider controller, OrderModel order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${'Order'.tr} ${Constant.orderId(orderId: order.id.toString())}"
                    .tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                  color: AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ),
        RoundedButtonFill(
          title: order.status.toString().tr,
          color: Constant.statusColor(status: order.status.toString()),
          width: 32,
          height: 4.5,
          radius: 10,
          textColor: Constant.statusText(status: order.status.toString()),
          onPress: () {},
        ),
      ],
    );
  }

  Widget _buildTakeAwaySection(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.vendor?.title ?? 'Jippy Mart',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16,
                      color: AppThemeData.primary300,
                    ),
                  ),
                  Text(
                    order.vendor?.location ?? 'Jippy Mart Store',
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: AppThemeData.grey600,
                    ),
                  ),
                ],
              ),
            ),
            _buildContactButtons(context, controller, order, isTakeAway: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Timeline.tileBuilder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              theme: TimelineThemeData(nodePosition: 0),
              builder: TimelineTileBuilder.connected(
                contentsAlign: ContentsAlign.basic,
                indicatorBuilder: (context, index) {
                  return SvgPicture.asset("assets/icons/ic_location.svg");
                },
                connectorBuilder: (context, index, connectorType) {
                  return const DashedLineConnector(
                    color: AppThemeData.grey300,
                    gap: 3,
                  );
                },
                contentsBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: index == 0
                        ? _buildVendorInfo(context, controller, order)
                        : _buildDeliveryAddress(order),
                  );
                },
                itemCount: 2,
              ),
            ),
            if (order.status != Constant.orderRejected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: MySeparator(color: AppThemeData.grey200),
              ),
              _buildDriverInfo(context, controller, order),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfo(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.vendor?.title ?? 'Jippy Mart',
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 16,
                  color: AppThemeData.primary300,
                ),
              ),
              Text(
                order.vendor?.location ?? 'Jippy Mart Store',
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 14,
                  color: AppThemeData.grey600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildChatButton(context, controller, order, isVendor: true),
      ],
    );
  }

  Widget _buildDeliveryAddress(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${order.address!.addressAs}",
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.primary300,
          ),
        ),
        Text(
          order.address!.getFullAddress(),
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 14,
            color: AppThemeData.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    if (order.status == Constant.orderCompleted && order.driver != null) {
      return Row(
        children: [
          SvgPicture.asset("assets/icons/ic_check_small.svg"),
          const SizedBox(width: 5),
          Text(
            order.driver!.fullName(),
            style: TextStyle(
              color: AppThemeData.grey800,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            "Order Delivered.".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontFamily: AppThemeData.regular,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else if (order.status == Constant.orderAccepted ||
        order.status == Constant.driverPending) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset("assets/icons/ic_timer.svg"),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              "${'Your Order has been Preparing and assign to the driver'.tr}\n${'Preparation Time'.tr} ${order.estimatedTimeToPrepare}"
                  .tr,
              style: TextStyle(
                color: AppThemeData.warning400,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    } else if (order.driver != null) {
      return Row(
        children: [
          ClipOval(
            child: NetworkImageWidget(
              imageUrl: order.driver!.profilePictureURL.toString(),
              fit: BoxFit.cover,
              height: Responsive.height(5, context),
              width: Responsive.width(10, context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driver!.fullName().toString(),
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  order.driver!.email.toString(),
                  style: TextStyle(
                    color: AppThemeData.success400,
                    fontFamily: AppThemeData.regular,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildContactButtons(context, controller, order, isDriver: true),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildContactButtons(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isTakeAway = false,
    bool isDriver = false,
  }) {
    final phone = isDriver
        ? order.driver?.phoneNumber?.toString()
        : order.vendor?.phonenumber?.toString();

    return Row(
      children: [
        if (phone != null && phone != 'Contact Support') ...[
          InkWell(
            onTap: () => Constant.makePhoneCall(phone),
            child: Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: AppThemeData.grey200),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset("assets/icons/ic_phone_call.svg"),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        InkWell(
          onTap: () => _onChatButtonPressed(
            context,
            controller,
            order,
            isDriver: isDriver,
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: AppThemeData.grey200),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isVendor = false,
  }) {
    return InkWell(
      onTap: () =>
          _onChatButtonPressed(context, controller, order, isVendor: isVendor),
      child: Container(
        width: 42,
        height: 42,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: AppThemeData.grey200),
            borderRadius: BorderRadius.circular(120),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
        ),
      ),
    );
  }

  Future<void> _onChatButtonPressed(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isVendor = false,
    bool isDriver = false,
  }) async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      UserModel? customer = await AddressListProvider.getUserProfile(
        order.authorID.toString(),
      );

      UserModel? otherUser;
      if (isDriver) {
        otherUser = await AddressListProvider.getUserProfile(
          order.driverID.toString(),
        );
      } else if (isVendor) {
        otherUser = await AddressListProvider.getUserProfile(
          order.vendor!.author.toString(),
        );
      }

      ShowToastDialog.closeLoader();

      if (customer != null && otherUser != null) {
        final userId = await SqlStorageConst.getFirebaseId();
        Get.to(
          ChatScreen(userId: userId),
          arguments: {
            "customerName": customer.fullName(),
            "restaurantName": otherUser.fullName(),
            "orderId": order.id,
            "restaurantId": otherUser.id,
            "customerId": customer.id,
            "customerProfileImage": customer.profilePictureURL,
            "restaurantProfileImage": otherUser.profilePictureURL,
            "token": otherUser.fcmToken,
            "chatType": isDriver ? "Driver" : "restaurant",
          },
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
    }
  }

  Widget _buildYourOrderSection(
    BuildContext context,
    OrderDetailsProvider controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Order".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.orderModel.products!.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildProductItem(
                  context,
                  controller.orderModel.products![index],
                );
              },
              separatorBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: MySeparator(color: AppThemeData.grey200),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillDetailsSection(
    OrderModel order,
    OrderBillDetails bill,
    bool hasPromotionalItems,
    double totalDistance,
    VendorModel vendor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bill Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                _buildBillRow(
                  label: "Item totals".tr,
                  value: Constant.amountShow(amount: bill.subTotal.toString()),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Delivery Fee".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildDeliveryFeeWidget(
                      order: order,
                      bill: bill,
                      hasPromotionalItems: hasPromotionalItems,
                      totalDistance: totalDistance,
                      vendor: vendor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Platform Fee".tr,
                  value: '15.00',
                  isStrikethrough: true,
                  color: AppThemeData.danger300,
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Surge Fee".tr,
                  value: "₹${surgeFee ?? 0.0}",
                ),
                const SizedBox(height: 10),
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Coupon Discount".tr,
                  value:
                      "- (${Constant.amountShow(amount: order.discount.toString())})",
                  color: AppThemeData.danger300,
                ),
                if (order.specialDiscount != null &&
                    order.specialDiscount!['special_discount'] != null) ...[
                  const SizedBox(height: 10),
                  _buildBillRow(
                    label: "Special Discount".tr,
                    value:
                        "- (${Constant.amountShow(amount: order.specialDiscount!['special_discount'].toString())})",
                    color: AppThemeData.danger300,
                  ),
                ],
                if (order.takeAway != true &&
                    vendor.isSelfDelivery != true) ...[
                  const SizedBox(height: 10),
                  _buildBillRow(
                    label: "Delivery Tips".tr,
                    value: Constant.amountShow(
                      amount: order.tipAmount.toString(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Taxes & Charges",
                  value: Constant.amountShow(amount: bill.taxAmount.toString()),
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "To Pay".tr,
                  value: Constant.amountShow(
                    amount: "${bill.totalAmount + (surgeFee ?? 0.0)}",
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow({
    required String label,
    required String value,
    Color? color,
    bool isStrikethrough = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: color ?? AppThemeData.grey900,
            fontSize: 16,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: color ?? AppThemeData.danger300,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                _buildOrderDetailRow(
                  label: "Delivery type".tr,
                  value: order.takeAway == true
                      ? "TakeAway".tr
                      : order.scheduleTime == null
                      ? "Standard".tr
                      : "Schedule".tr,
                  valueColor: order.scheduleTime != null
                      ? AppThemeData.primary300
                      : AppThemeData.grey900,
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Payment Method".tr,
                  value: order.paymentMethod.toString(),
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Date and Time".tr,
                  value: Constant.timestampToDateTime(order.createdAt!),
                  valueColor: AppThemeData.grey600,
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Phone Number".tr,
                  value: order.author!.phoneNumber.toString(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailRow({
    required String label,
    required String value,
    Color valueColor = AppThemeData.grey900,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: valueColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Remarks".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Text(
              order.notes.toString(),
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    if (order.status == Constant.orderShipped ||
        order.status == Constant.orderInTransit ||
        order.status == Constant.orderCompleted) {
      return Container(
        color: AppThemeData.grey50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              order.status == Constant.orderShipped ||
                  order.status == Constant.orderInTransit
              ? Consumer<LiveTrackingProvider>(
                  builder: (context, liveTrackingProvider, _) {
                    return RoundedButtonFill(
                      title: "Track Order".tr,
                      height: 5.5,
                      color: AppThemeData.warning300,
                      textColor: AppThemeData.grey900,
                      onPress: () {
                        liveTrackingProvider.initFunction(orderModel: order);
                        Get.to(const LiveTrackingScreen());
                      },
                    );
                  },
                )
              : RoundedButtonFill(
                  title: "Reorder".tr,
                  height: 5.5,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );
                    await orderProvider.reorderOrder(order, context);
                  },
                ),
        ),
      );
    }
    return const SizedBox();
  }

  VendorModel _createDefaultMartVendor() {
    final cachedDeliveryCharge = _cachedMartDeliveryCharge;
    final deliveryCharge = (cachedDeliveryCharge != null &&
            _isDeliveryChargeCacheValid())
        ? cachedDeliveryCharge
        : null;

    return VendorModel(
      title: "Jippy Mart",
      location: "Jippy Mart Store",
      phonenumber: "Contact Support",
      isSelfDelivery: false,
      deliveryCharge: deliveryCharge,
      latitude: 0.0,
      longitude: 0.0,
      vType: 'mart',
    );
  }
}
