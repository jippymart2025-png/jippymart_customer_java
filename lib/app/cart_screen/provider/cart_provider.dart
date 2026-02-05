import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:jippymart_customer/payment/rozorpayConroller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/oder_placing_screens.dart';
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/provider/order_placing_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart'
    hide Variants;
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/send_notification.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/payment_model/cod_setting_model.dart';
import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/tax_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/payment/rozorpayConroller.dart';

import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/coupon_filter_service.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/services/mart_vendor_service.dart';
import 'package:jippymart_customer/services/promotional_cache_service.dart';
import 'package:jippymart_customer/utils/anr_prevention.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/razorpay_crash_prevention.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widgets/delivery_zone_alert_dialog.dart'
    show DeliveryZoneAlertDialog;
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../models/mart_item_model.dart';
import '../../../services/mart_firestore_service.dart';
import '../cart_screen.dart';

/// Price update result for cart price validation
// enum PriceStatus { noChange, priceChanged, productNotFound, error }
//
// class PriceUpdateResult {
//   final String productId;
//   final PriceStatus status;
//   final String? oldPrice;
//   final String? newPrice;
//   final String? productName;
//   final String? error;
//
//   PriceUpdateResult({
//     required this.productId,
//     required this.status,
//     this.oldPrice,
//     this.newPrice,
//     this.productName,
//     this.error,
//   });
//
//   bool get hasPriceChange => status == PriceStatus.priceChanged;
//
//   bool get isError =>
//       status == PriceStatus.error || status == PriceStatus.productNotFound;
// }
//
// class CartControllerProvider extends ChangeNotifier {
//   late OrderPlacingProvider orderPlacingProvider;
//
//   Future<void> processPayment(
//     CartControllerProvider controller,
//     BuildContext context,
//   ) async {
//     final canProceed = await controller.validateAndPlaceOrderBulletproof(
//       context,
//     );
//     if (!canProceed) {
//       controller.endOrderProcessing();
//       return;
//     }
//     if ((controller.couponAmount >= 1) &&
//         (controller.couponAmount > controller.totalAmount)) {
//       ShowToastDialog.showToast(
//         "The total price must be greater than or equal to the coupon discount value for the code to apply. Please review your cart total."
//             .tr,
//       );
//       controller.endOrderProcessing();
//       return;
//     }
//     if ((controller.specialDiscountAmount >= 1) &&
//         (controller.specialDiscountAmount > controller.totalAmount)) {
//       ShowToastDialog.showToast(
//         "The total price must be greater than or equal to the special discount value for the code to apply. Please review your cart total."
//             .tr,
//       );
//       controller.endOrderProcessing();
//       return;
//     }
//
//     // 🔑 CRITICAL: Validate payment method is selected
//     if (controller.selectedPaymentMethod.isEmpty) {
//       ShowToastDialog.showToast("Please select payment method".tr);
//       controller.endOrderProcessing();
//       return;
//     }
//
//     if (controller.selectedPaymentMethod == PaymentGateway.cod.name) {
//       // 🔑 CRITICAL: For COD, verify it's allowed
//       if (controller.subTotal >
//           controller.cashOnDeliverySettingModel.getMaxAmount()) {
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for orders above ₹${controller.cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select online payment."
//               .tr,
//         );
//         controller.endOrderProcessing();
//         return;
//       }
//       if (controller.hasPromotionalItems()) {
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for promotional items. Please select online payment."
//               .tr,
//         );
//         controller.endOrderProcessing();
//         return;
//       }
//       controller.placeOrder(context);
//       print(" controller.placeOrder(context); ");
//     } else if (controller.selectedPaymentMethod ==
//         PaymentGateway.razorpay.name) {
//       // 🔑 CRITICAL: Ensure Razorpay is properly configured
//       if (controller.razorPayModel.razorpayKey == null ||
//           controller.razorPayModel.razorpayKey!.isEmpty) {
//         print('❌ [RAZORPAY] Razorpay key is missing or empty');
//         ShowToastDialog.showToast(
//           "Payment configuration error. Please contact support.".tr,
//         );
//         controller.endOrderProcessing();
//         return;
//       }
//
//       print(
//         '✅ [RAZORPAY] Razorpay key found: ${controller.razorPayModel.razorpayKey!.substring(0, 10)}...',
//       );
//
//       // 🔑 CRITICAL: Reset payment state before starting new payment
//       controller.isPaymentInProgress = false;
//       controller.isPaymentCompleted = false;
//       controller._lastPaymentId = null;
//
//       print(
//         '🔑 [RAZORPAY] Starting payment flow for amount: ${controller.totalAmount}',
//       );
//
//       // 🔑 OPTIMIZATION: Show loading immediately and ensure Razorpay is initialized
//       ShowToastDialog.showLoader("Opening payment gateway...".tr);
//
//       // 🔑 OPTIMIZATION: Ensure Razorpay is initialized (should already be from pre-init, but double-check)
//       if (!controller._razorpayCrashPrevention.isInitialized) {
//         print('🔑 [RAZORPAY] Razorpay not initialized, initializing now...');
//         final initialized = await controller._razorpayCrashPrevention
//             .safeInitialize(
//               onSuccess: controller.handlePaymentSuccess,
//               onFailure: controller.handlePaymentError,
//               onExternalWallet: controller.handleExternalWallet,
//             );
//         if (!initialized) {
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast(
//             "Payment system is temporarily unavailable. Please try again later."
//                 .tr,
//           );
//           controller.endOrderProcessing();
//           return;
//         }
//       }
//
//       try {
//         // 🔑 OPTIMIZATION: Create order and open checkout in parallel where possible
//         // Show payment page as soon as order is created
//         final orderResult = await RazorPayController().createOrderRazorPay(
//           amount: double.parse(controller.totalAmount.toString()),
//           razorpayModel: controller.razorPayModel,
//         );
//
//         if (orderResult == null) {
//           print('❌ [RAZORPAY] Order creation returned null');
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast(
//             "Something went wrong, please contact admin.".tr,
//           );
//           controller.endOrderProcessing();
//           return;
//         }
//
//         print('✅ [RAZORPAY] Order created successfully: ${orderResult.id}');
//         print(
//           '🔑 [RAZORPAY] Order amount (paise): ${orderResult.amount}, Order ID: ${orderResult.id}',
//         );
//
//         // 🔑 CRITICAL: Convert amount from paise to rupees for openCheckout
//         // orderResult.amount is in paise, but openCheckout expects rupees and converts to paise internally
//         final amountInRupees = orderResult.amount / 100.0;
//         print('🔑 [RAZORPAY] Amount in rupees: $amountInRupees');
//
//         // 🔑 OPTIMIZATION: Close loader before opening checkout for instant UI
//         ShowToastDialog.closeLoader();
//
//         // 🔑 CRITICAL: Check if checkout opens successfully
//         print('🔑 [RAZORPAY] Attempting to open checkout...');
//         final checkoutOpened = await controller.openCheckout(
//           amount: amountInRupees,
//           orderId: orderResult.id,
//         );
//
//         if (!checkoutOpened) {
//           print('❌ [RAZORPAY] Checkout failed to open');
//           // 🔑 CRITICAL: If checkout failed to open, prevent order placement
//           ShowToastDialog.showToast(
//             "Failed to open payment gateway. Please try again.".tr,
//           );
//           controller.endOrderProcessing();
//           return;
//         }
//
//         print('✅ [RAZORPAY] Checkout opened successfully');
//       } catch (error, stackTrace) {
//         // 🔑 CRITICAL: Handle any errors during RazorPay order creation
//         print('❌ [RAZORPAY] Exception in payment flow: $error');
//         print('❌ [RAZORPAY] Stack trace: $stackTrace');
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Failed to create payment order. Please try again.".tr,
//         );
//         controller.endOrderProcessing();
//       }
//     } else {
//       ShowToastDialog.showToast("Please select payment method".tr);
//       // 🔑 CRITICAL: Reset processing flag when no payment method is selected
//       controller.endOrderProcessing();
//     }
//     notifyListeners();
//   }
//
//   void changeLocationFunctionInCart({required BuildContext context}) {
//     Get.to(const AddressListScreen())!.then((value) async {
//       if (value != null) {
//         ShippingAddress addressModel = value;
//         print(" changeLocationFunctionInCart  13 ${addressModel.locality}");
//         print(
//           " changeLocationFunctionInCart  12 ${addressModel.location?.latitude}   ${addressModel.location?.latitude}",
//         );
//         print(" changeLocationFunctionInCart  1 ${addressModel.latitude}");
//         if (addressModel.location?.latitude != null &&
//             addressModel.location?.longitude != null) {
//           try {
//             if (addressModel.zoneId != null &&
//                 addressModel.zoneId!.isNotEmpty) {
//               print(
//                 '✅ [CART_ADDRESS_CHANGE] Using zoneId from addressModel: ${addressModel.zoneId}',
//               );
//             } else if (Constant.selectedLocation.zoneId != null &&
//                 Constant.selectedLocation.zoneId!.isNotEmpty) {
//               addressModel.zoneId = Constant.selectedLocation.zoneId;
//               notifyListeners();
//               print(
//                 '✅ [CART_ADDRESS_CHANGE] Using zoneId from Constant.selectedLocation: ${addressModel.zoneId}',
//               );
//             } else if (Constant.selectedZone != null) {
//               addressModel.zoneId = Constant.selectedZone!.id;
//               print(
//                 '✅ [CART_ADDRESS_CHANGE] Using zoneId from Constant.selectedZone: ${addressModel.zoneId}',
//               );
//               notifyListeners();
//             } else {
//               final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
//                 addressModel.location!.latitude!,
//                 addressModel.location!.longitude!,
//                 context,
//               );
//               if (zoneId.isNotEmpty) {
//                 addressModel.zoneId = zoneId;
//                 print(
//                   '✅ [CART_ADDRESS_CHANGE] Detected zone from coordinates: $zoneId',
//                 );
//               } else {
//                 print(
//                   '⚠️ [CART_ADDRESS_CHANGE] No zone detected for coordinates - leaving zoneId as null',
//                 );
//               }
//             }
//           } catch (e) {
//             print('❌ [CART_ADDRESS_CHANGE] Error detecting zone: $e');
//             // Continue without zone ID if detection fails
//           }
//         } else {
//           print(
//             '⚠️ [CART_ADDRESS_CHANGE] No coordinates available for zone detection',
//           );
//         }
//         selectedAddress = addressModel;
//         _addressInitialized =
//             true; // 🔑 Mark as initialized when user explicitly changes address
//         await _loadFreshVendorForCart();
//         notifyListeners();
//         await calculatePrice();
//       }
//     });
//   }
//
//   // ProductModel? productModelImageDetails;
//   //
//   // void cartProductDetailsImageProductListFunction() {
//   //   CartProductModel cartProductModel = cartItem[index];
//   //   ProductModel? productModel;
//   //   FireStoreUtils.getProductById(cartProductModel.id!.split('~').first).then((
//   //     value,
//   //   ) {
//   //     productModelImageDetails = value;
//   //     notifyListeners();
//   //   });
//   // }
//   Future<bool> showPaymentMethodDialog(BuildContext context) async {
//     // Validate before showing dialog - if validation fails, don't show dialog
//     final canProceed = await validateAndPlaceOrderBulletproof(context);
//     if (!canProceed) {
//       // Validation failed - ensure processing flag is reset (in case it was stuck from previous attempt)
//       endOrderProcessing();
//       return false;
//     }
//     final String initialSelection = selectedPaymentMethod;
//     final result = await Get.dialog<bool>(
//       WillPopScope(
//         onWillPop: () async {
//           // User cancelled via back button - restore initial selection
//           selectedPaymentMethod = initialSelection;
//           notifyListeners();
//           Get.back(result: false); // Return false to indicate cancellation
//           return false; // Prevent default back behavior since we handled it
//         },
//         child: StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: Row(
//                 children: [
//                   Icon(Icons.payment, color: Colors.orange, size: 24),
//                   SizedBox(width: 10),
//                   Text(
//                     "Select Payment Method",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Choose how you want to pay for your order:",
//                     style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                   ),
//                   SizedBox(height: 20),
//                   Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey[300]!),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: RadioListTile<String>(
//                       contentPadding: EdgeInsets.all(4),
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Image.asset(
//                             "assets/images/ic_cash.png",
//                             width: 30,
//                             height: 30,
//                           ),
//                           SizedBox(
//                             width: 150,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Cash on Delivery",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 Text(
//                                   "Pay when you receive your order",
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                   ),
//                                   maxLines: 2,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       value: PaymentGateway.cod.name,
//                       groupValue: selectedPaymentMethod,
//                       onChanged: (value) {
//                         if (value != null) {
//                           setState(() {
//                             selectedPaymentMethod = value;
//                           });
//                           notifyListeners(); // 🔑 CRITICAL: Update provider state
//                         }
//                       },
//                       activeColor: Colors.orange,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   // Razorpay Option
//                   Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey[300]!),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: RadioListTile<String>(
//                       contentPadding: EdgeInsets.all(4),
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Image.asset(
//                             "assets/images/razorpay.png",
//                             width: 30,
//                             height: 30,
//                           ),
//                           SizedBox(
//                             width: 150,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Online Payment",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 Text(
//                                   "Pay securely with Razorpay",
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       value: PaymentGateway.razorpay.name,
//                       groupValue: selectedPaymentMethod,
//                       onChanged: (value) {
//                         if (value != null) {
//                           setState(() {
//                             selectedPaymentMethod = value;
//                           });
//                           notifyListeners(); // 🔑 CRITICAL: Update provider state
//                         }
//                       },
//                       activeColor: Colors.orange,
//                     ),
//                   ),
//
//                   SizedBox(height: 10),
//                   // Validation messages
//                   if (subTotal > cashOnDeliverySettingModel.getMaxAmount() &&
//                       selectedPaymentMethod == PaymentGateway.cod.name)
//                     Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.orange[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info, color: Colors.orange, size: 16),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "COD not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.orange[800],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   if (hasPromotionalItems() &&
//                       selectedPaymentMethod == PaymentGateway.cod.name)
//                     Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.orange[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info, color: Colors.orange, size: 16),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "COD not available for promotional items",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.orange[800],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     // User cancelled - clear payment method
//                     selectedPaymentMethod = "";
//                     notifyListeners();
//                     Get.back(
//                       result: false,
//                     ); // Return false to indicate cancellation
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.grey[600],
//                   ),
//                   child: Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (selectedPaymentMethod.isEmpty) {
//                       ShowToastDialog.showToast(
//                         "Please select a payment method".tr,
//                       );
//                       return;
//                     }
//                     // Validate selection
//                     if (selectedPaymentMethod == PaymentGateway.cod.name) {
//                       if (subTotal >
//                           cashOnDeliverySettingModel.getMaxAmount()) {
//                         ShowToastDialog.showToast(
//                           "COD not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select online payment."
//                               .tr,
//                         );
//                         return;
//                       }
//                       if (hasPromotionalItems()) {
//                         ShowToastDialog.showToast(
//                           "COD not available for promotional items. Please select online payment."
//                               .tr,
//                         );
//                         return;
//                       }
//                     }
//
//                     Get.back(
//                       result: true,
//                     ); // Return true to indicate confirmation
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text("Confirm Payment"),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//       barrierDismissible: false,
//     );
//
//     // After dialog closes, ensure UI reflects the current selection
//     notifyListeners();
//
//     // Return true if payment was confirmed, false if cancelled
//     return result == true && selectedPaymentMethod.isNotEmpty;
//   }
//
//   Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
//     print(" getWeather ");
//     const apiKey = "7885eed00855633516f769cf3646aace"; // 🔑 Add your key
//     final url =
//         "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception("Failed to load weather");
//     }
//   }
//
//   Future<Map<String, dynamic>> getSurgeRules() async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse('${AppConst.baseUrl}mobile/surge-rules'),
//             headers: await getHeaders(),
//           )
//           .timeout(const Duration(seconds: 10));
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           print("API response data: ${responseData['data']}");
//           return responseData['data'] ?? {};
//         } else {
//           print(
//             '[CART_PROVIDER] Surge rules API returned unsuccessful response',
//           );
//           return {}; // Return empty map instead of throwing
//         }
//       } else if (response.statusCode == 429) {
//         print('[CART_PROVIDER] Rate limited when fetching surge rules');
//         return {}; // Return empty map on rate limit
//       } else {
//         print(
//           '[CART_PROVIDER] Failed to fetch surge rules: ${response.statusCode}',
//         );
//         return {}; // Return empty map instead of throwing
//       }
//     } on TimeoutException {
//       print('[CART_PROVIDER] Timeout fetching surge rules');
//       return {}; // Return empty map on timeout
//     } catch (e) {
//       print('[CART_PROVIDER] Error fetching surge rules: $e');
//       return {}; // Return empty map instead of throwing
//     }
//   }
//
//   Future<String> getAdminSurgeFee() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${AppConst.baseUrl}mobile/surge-rules/admin-fee'),
//         headers: await getHeaders(),
//       );
//       print("getAdminSurgeFee ${response.body} ");
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         if (responseData['success'] == true) {
//           final adminSurgeFee = responseData['data']['admin_surge_fee']
//               .toString();
//           print("Admin Surge Fee: $adminSurgeFee");
//           return adminSurgeFee;
//         } else {
//           throw Exception("API returned unsuccessful response");
//         }
//       } else {
//         throw Exception(
//           "Failed to fetch admin surge fee: ${response.statusCode}",
//         );
//       }
//     } catch (e) {
//       throw Exception("Error fetching admin surge fee: $e");
//     }
//   }
//
//   double calculateSurgeFee(
//     Map<String, dynamic> weather,
//     Map<String, dynamic> rules,
//   ) {
//     double surge = 0;
//     String condition = weather['weather'][0]['main'].toLowerCase();
//     if (condition.contains("rain")) surge += rules["rain"];
//     double temp = weather['main']['temp'];
//     if (temp > 45) surge += rules["summer"]; // hot weather
//     if (temp < 10) surge += rules["bad_weather"]; // cold/winter
//     return surge; // percentage
//   }
//
//   final CartProvider cartProvider = CartProvider();
//   TextEditingController reMarkController = TextEditingController();
//   Map<String, dynamic>? _martDeliverySettings;
//   TextEditingController couponCodeController = TextEditingController();
//   TextEditingController tipsController = TextEditingController();
//
//   // Add debouncing mechanism to prevent duplicate orders
//   bool isProcessingOrder = false;
//   DateTime? lastOrderAttempt;
//   static const Duration orderDebounceTime = Duration(seconds: 3);
//
//   // Add order idempotency tracking
//   bool _orderInProgress = false;
//
//   // 🔑 CRITICAL: Debouncing for price calculation to prevent continuous updates
//   bool _isCalculatingPrice = false;
//   DateTime? _lastPriceCalculationTime;
//
//   // 🔑 RAZORPAY PAYMENT STATE MANAGEMENT
//   bool isPaymentInProgress = false;
//   bool isPaymentCompleted = false;
//   String? _lastPaymentId;
//   DateTime? _lastPaymentTime;
//   static const Duration paymentTimeout = Duration(minutes: 5);
//
//   // 🔑 CRITICAL: Prevent duplicate order creation
//   bool _isOrderBeingCreated = false;
//   Set<String> _processedPaymentIds = {}; // Track processed payment IDs
//   static const int _maxProcessedPaymentIds =
//       100; // Limit to prevent memory issues
//
//   // 🔑 CRITICAL: Static lock to prevent concurrent order creation across all instances
//   static bool _isOrderCreationInProgress = false;
//   static String?
//   _currentOrderPaymentId; // Track payment ID for current order creation
//   static DateTime? _lastOrderCreationTime;
//   static const Duration _orderCreationCooldown = Duration(
//     seconds: 10,
//   ); // Cooldown period
//
//   // 🔑 PERSISTENT PAYMENT STATE STORAGE (SURVIVES APP KILLS)
//   static const String _paymentStateKey = 'razorpay_payment_state';
//   static const String _paymentIdKey = 'razorpay_payment_id';
//   static const String _paymentSignatureKey = 'razorpay_payment_signature';
//   static const String _paymentTimeKey = 'razorpay_payment_time';
//   static const String _paymentMethodKey = 'razorpay_payment_method';
//   static const String _paymentAmountKey = 'razorpay_payment_amount';
//   static const String _paymentOrderIdKey = 'razorpay_order_id';
//
//   // Add profile validation state
//   bool isProfileValid = false;
//   bool isProfileValidating = false;
//
//   // 🔑 CRITICAL: Track if address has been initialized to prevent repeated changes
//   bool _addressInitialized = false;
//
//   // Add caching for better performance
//   VendorModel? _cachedVendorModel;
//   DeliveryCharge? _cachedDeliveryCharge;
//   List<CouponModel>? _cachedCouponList;
//   DateTime? _lastCacheTime;
//   static const Duration cacheExpiry = Duration(minutes: 5);
//
//   // Flag to prevent multiple simultaneous coupon loads
//   bool _isLoadingCoupons = false;
//
//   // Context detection for coupon filtering
//   String _currentContext = "restaurant"; // Default to restaurant
//
//   // **ULTRA-FAST CALCULATION CACHE FOR INSTANT CART UPDATES**
//   final Map<String, Map<String, dynamic>> _promotionalCalculationCache = {};
//   final Map<String, double> _cachedFreeDeliveryKm = {};
//   final Map<String, double> _cachedExtraKmCharge = {};
//   List<TaxModel>? _cachedTaxList;
//   bool _calculationCacheLoaded = false;
//
//   // **PRODUCT CACHE FOR CART - LOAD ONCE, USE MANY TIMES**
//   final Map<String, ProductModel?> _productCache = {};
//   bool _isLoadingProducts = false;
//   bool _productsLoaded = false;
//
//   // Getters for product cache state
//   bool get isLoadingProducts => _isLoadingProducts;
//
//   bool get productsLoaded => _productsLoaded;
//
//   // Getter for coupon loading state
//   bool get isLoadingCoupons => _isLoadingCoupons;
//
//   ShippingAddress? selectedAddress = ShippingAddress();
//   VendorModel vendorModel = VendorModel();
//   DeliveryCharge deliveryChargeModel = DeliveryCharge();
//   UserModel userModel = UserModel();
//   List<CouponModel> couponList = <CouponModel>[];
//   List<CouponModel> allCouponList = <CouponModel>[];
//   String selectedFoodType = "Delivery";
//
//   String selectedPaymentMethod = '';
//
//   String deliveryType = "instant";
//   DateTime scheduleDateTime = DateTime.now();
//   double totalDistance = 0.0;
//   double deliveryCharges = 0.0;
//   double subTotal = 0.0;
//   double couponAmount = 0.0;
//
//   double specialDiscountAmount = 0.0;
//   double specialDiscount = 0.0;
//   String specialType = "";
//   double deliveryTips = 0.0;
//   double taxAmount = 0.0;
//   double totalAmount = 0.0;
//   double surgePercent = 0.0;
//
//   // Add UI state management
//   bool isCartReady = false;
//   bool isPaymentReady = false;
//   bool isAddressValid = false;
//   CouponModel selectedCouponModel = CouponModel();
//
//   double originalDeliveryFee = 0.0;
//
//   // Price sync state to trigger UI updates
//   int _priceSyncVersion = 0;
//
//   int get priceSyncVersion => _priceSyncVersion;
//
//   /// Public method to initialize address (for external calls)
//   Future<void> initializeAddress(BuildContext context) async {
//     await _initializeAddressWithPriority(context);
//   }
//
//   Future<void> initialLiseSurgeValue(double lat, double lon) async {
//     try {
//       Map<String, dynamic> weather = await getWeather(lat, lon);
//       Map<String, dynamic> rules = await getSurgeRules();
//       surgePercent = calculateSurgeFee(weather, rules);
//       notifyListeners();
//     } catch (e) {
//       print('[CART_PROVIDER] Error initializing surge value: $e');
//       // Set default surge percent on error
//       surgePercent = 0;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _initializeAddressWithPriority(BuildContext context) async {
//     try {
//       // 🔑 CRITICAL: If address is already initialized and valid, don't change it
//       if (_addressInitialized &&
//           selectedAddress != null &&
//           selectedAddress!.location?.latitude != null &&
//           selectedAddress!.location?.longitude != null) {
//         print(
//           '🏠 [ADDRESS_PRIORITY] ✅ Address already initialized, skipping auto-change',
//         );
//         return;
//       }
//
//       // PRIORITY 1: Check for saved addresses in user profile (DEFAULT LOCATION)
//       if (Constant.userModel != null &&
//           Constant.userModel!.shippingAddress != null &&
//           Constant.userModel!.shippingAddress!.isNotEmpty) {
//         final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
//           (a) => a.isDefault == true,
//           orElse: () => Constant.userModel!.shippingAddress!.first,
//         );
//         selectedAddress = defaultAddress;
//         _addressInitialized = true; // Mark as initialized
//         await initialLiseSurgeValue(
//           defaultAddress.location?.latitude ?? 0.0,
//           defaultAddress.location?.longitude ?? 0.0,
//         );
//         // 🔑 CRITICAL: Load vendor and calculate price after address is set
//         // Only load vendor if cart has items
//         if (HomeProvider.cartItem.isNotEmpty) {
//           await _loadFreshVendorForCart();
//           // Ensure vendor is loaded before calculating price
//           if (vendorModel.id != null) {
//             await calculatePrice();
//           }
//         }
//         notifyListeners();
//         print('🏠 [ADDRESS_PRIORITY] ✅ Using default saved address');
//         return;
//       }
//
//       // PRIORITY 2: Only use current location if no default address exists
//       final homeScreenAddress = await _getCurrentLocationAddress(context);
//       if (homeScreenAddress != null) {
//         selectedAddress = homeScreenAddress;
//         _addressInitialized = true; // Mark as initialized
//         await initialLiseSurgeValue(
//           homeScreenAddress.location?.latitude ?? 0.0,
//           homeScreenAddress.location?.longitude ?? 0.0,
//         );
//         // 🔑 CRITICAL: Load vendor and calculate price after address is set
//         // Only load vendor if cart has items
//         if (HomeProvider.cartItem.isNotEmpty) {
//           await _loadFreshVendorForCart();
//           // Ensure vendor is loaded before calculating price
//           if (vendorModel.id != null) {
//             await calculatePrice();
//           }
//         }
//         notifyListeners();
//         print(
//           '🏠 [ADDRESS_PRIORITY] ✅ Using current location (no default address)',
//         );
//         return;
//       }
//       selectedAddress = null;
//       _addressInitialized = false;
//       notifyListeners();
//       // _showAddressRequiredAlert();
//     } catch (e) {
//       print('🏠 [ADDRESS_PRIORITY] ❌ ERROR in address initialization: $e');
//       selectedAddress = null;
//       _addressInitialized = false;
//       // _showAddressRequiredAlert();
//     }
//     notifyListeners();
//   }
//
//   /// Get home screen address (Constant.selectedLocation) as address
//   Future<ShippingAddress?> _getCurrentLocationAddress(
//     BuildContext context,
//   ) async {
//     try {
//       if (Constant.selectedLocation.location?.latitude != null &&
//           Constant.selectedLocation.location?.longitude != null) {
//         final lat = Constant.selectedLocation.location!.latitude!;
//         final lng = Constant.selectedLocation.location!.longitude!;
//         if (lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0) {
//           String address = Constant.selectedLocation.address ?? '';
//           String locality = Constant.selectedLocation.locality ?? '';
//           if (address.isEmpty ||
//               locality.isEmpty ||
//               address == 'Current Location' ||
//               locality == 'Current Location' ||
//               address.contains('Current Location') ||
//               locality.contains('Current Location')) {
//             return null;
//           }
//           // Try multiple sources for zone ID
//           String? detectedZoneId;
//
//           // PRIORITY 1: Use zoneId from Constant.selectedLocation if available
//           if (Constant.selectedLocation.zoneId != null &&
//               Constant.selectedLocation.zoneId!.isNotEmpty) {
//             detectedZoneId = Constant.selectedLocation.zoneId;
//             print(
//               '[HOME_SCREEN_ADDRESS] ✅ Using zoneId from Constant.selectedLocation: $detectedZoneId',
//             );
//           }
//           // PRIORITY 2: Use zoneId from Constant.selectedZone if available
//           else if (Constant.selectedZone?.id != null &&
//               Constant.selectedZone!.id!.isNotEmpty) {
//             detectedZoneId = Constant.selectedZone!.id;
//             print(
//               '[HOME_SCREEN_ADDRESS] ✅ Using zoneId from Constant.selectedZone: $detectedZoneId',
//             );
//           }
//           // PRIORITY 3: Try to detect zone ID from coordinates
//           else {
//             detectedZoneId = await _detectZoneIdForCoordinates(
//               lat,
//               lng,
//               context,
//             );
//             if (detectedZoneId != null) {
//               print(
//                 '[HOME_SCREEN_ADDRESS] ✅ Detected zoneId from coordinates: $detectedZoneId',
//               );
//             } else {
//               print(
//                 '[HOME_SCREEN_ADDRESS] ⚠️ Could not detect zoneId from coordinates',
//               );
//             }
//           }
//
//           notifyListeners();
//           return ShippingAddress(
//             id: 'home_screen_address_${DateTime.now().millisecondsSinceEpoch}',
//             addressAs:
//                 Constant.selectedLocation.addressAs ?? 'Home Screen Address',
//             address: address,
//             locality: locality,
//             location: UserLocation(latitude: lat, longitude: lng),
//             isDefault: false,
//             zoneId: detectedZoneId, // 🔑 Add detected zone ID
//           );
//         }
//       }
//
//       return null;
//     } catch (e) {
//       print('📍 [HOME_SCREEN_ADDRESS] ❌ Error getting home screen address: $e');
//       return null;
//     }
//   }
//
//   /// Sync selectedAddress with Constant.selectedLocation if needed
//   /// This ensures cart address stays in sync when location changes on home screen
//   /// 🔑 CRITICAL: Only syncs if address is not initialized or user explicitly changes location
//   Future<void> syncAddressWithHomeLocation(BuildContext context) async {
//     try {
//       // 🔑 CRITICAL: Don't auto-sync if address is already initialized with a saved/default address
//       // Only sync if address is null or invalid, or if user explicitly changed location
//       if (_addressInitialized &&
//           selectedAddress != null &&
//           selectedAddress!.id != null &&
//           !selectedAddress!.id!.startsWith('home_screen_address_')) {
//         // Address is a saved address (not temporary), don't auto-change it
//         print(
//           '[CART_SYNC] ⚠️ Address is a saved address, skipping auto-sync to prevent repeated changes',
//         );
//         // Only sync zoneId if missing, don't change the address itself
//         if ((selectedAddress?.zoneId == null ||
//                 selectedAddress!.zoneId!.isEmpty) &&
//             Constant.selectedLocation.zoneId != null &&
//             Constant.selectedLocation.zoneId!.isNotEmpty) {
//           selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
//           print(
//             '[CART_SYNC] ✅ Synced zoneId only (address unchanged): ${selectedAddress!.zoneId}',
//           );
//           notifyListeners();
//         }
//         return;
//       }
//
//       // Check if Constant.selectedLocation has valid coordinates
//       if (Constant.selectedLocation.location?.latitude != null &&
//           Constant.selectedLocation.location?.longitude != null) {
//         final homeLat = Constant.selectedLocation.location!.latitude!;
//         final homeLng = Constant.selectedLocation.location!.longitude!;
//
//         // Check if current selectedAddress matches Constant.selectedLocation
//         final currentLat = selectedAddress?.location?.latitude;
//         final currentLng = selectedAddress?.location?.longitude;
//
//         // If coordinates don't match AND address is not initialized, sync the address
//         if (currentLat == null ||
//             currentLng == null ||
//             currentLat != homeLat ||
//             currentLng != homeLng) {
//           // Only sync if address is not initialized (first time) or is a temporary address
//           if (!_addressInitialized ||
//               selectedAddress == null ||
//               selectedAddress!.id == null ||
//               selectedAddress!.id!.startsWith('home_screen_address_')) {
//             final homeScreenAddress = await _getCurrentLocationAddress(context);
//             if (homeScreenAddress != null) {
//               selectedAddress = homeScreenAddress;
//               _addressInitialized = true; // Mark as initialized after sync
//               // Ensure zoneId is set (it should be set by _getCurrentLocationAddress, but verify)
//               if ((selectedAddress!.zoneId == null ||
//                       selectedAddress!.zoneId!.isEmpty) &&
//                   Constant.selectedLocation.zoneId != null &&
//                   Constant.selectedLocation.zoneId!.isNotEmpty) {
//                 selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
//                 print(
//                   '[CART_SYNC] ✅ Set zoneId from Constant.selectedLocation: ${selectedAddress!.zoneId}',
//                 );
//               }
//               // Update surge value for new location
//               await initialLiseSurgeValue(homeLat, homeLng);
//               // Recalculate prices with new address - await to ensure calculation completes
//               await calculatePrice();
//               print(
//                 '[CART_SYNC] ✅ Synced selectedAddress with Constant.selectedLocation (zoneId: ${selectedAddress!.zoneId})',
//               );
//               notifyListeners();
//             }
//           }
//         } else {
//           // Coordinates match, but check if zoneId needs syncing
//           if ((selectedAddress?.zoneId == null ||
//                   selectedAddress!.zoneId!.isEmpty) &&
//               Constant.selectedLocation.zoneId != null &&
//               Constant.selectedLocation.zoneId!.isNotEmpty) {
//             selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
//             print(
//               '[CART_SYNC] ✅ Synced zoneId while coordinates match: ${selectedAddress!.zoneId}',
//             );
//             notifyListeners();
//           }
//         }
//       }
//     } catch (e) {
//       print('[CART_SYNC] ❌ Error syncing address with home location: $e');
//     }
//   }
//
//   /// Show alert when address is required
//   // void _showAddressRequiredAlert() {
//   //   Get.dialog(
//   //     AlertDialog(
//   //       title: Text('Address Required'.tr),
//   //       content: Text(
//   //         'Please add a delivery address to continue with your order.'.tr,
//   //       ),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () {
//   //             Get.back();
//   //             Get.to(() => const AddressListScreen());
//   //           },
//   //           child: Text('Add Address'.tr),
//   //         ),
//   //         TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   ///
//   Future<String?> _detectZoneIdForCoordinates(
//     double latitude,
//     double longitude,
//     BuildContext context,
//   ) async {
//     try {
//       final zoneModel = await HomeProvider.getCurrentZone(latitude, longitude);
//       notifyListeners();
//       if (zoneModel == null || zoneModel.zone == null) {
//         print('[DEBUG] No zone available');
//         return null;
//       }
//       final zone = zoneModel.zone!;
//       print('[DEBUG] Checking zone: ${zone.name} (${zone.id})');
//       if (zone.area != null && zone.area!.isNotEmpty) {
//         if (Constant.isPointInPolygon(
//           LatLng(latitude, longitude),
//           zone.area!.cast<GeoPoint>(),
//         )) {
//           print('[DEBUG] Zone detected: ${zone.name} (${zone.id})');
//           return zone.id;
//         }
//       }
//       notifyListeners();
//       print('[DEBUG] Coordinates not within the service zone');
//       return null;
//     } catch (e) {
//       print('[DEBUG] Error detecting zone: $e');
//       return null;
//     }
//   }
//
//   void initFunction(BuildContext context) {
//     Future.delayed(const Duration(seconds: 3), () {
//       _restorePaymentState().then((_) {
//         if (isPaymentInProgress && _lastPaymentId != null) {
//           _checkPendingPaymentAndRecover();
//         }
//       });
//       _initializeAddressWithPriority(context);
//       getCartData();
//       getPaymentSettings();
//       validateUserProfile();
//       Timer.periodic(const Duration(seconds: 1), (timer) {
//         if (subTotal > cashOnDeliverySettingModel.getMaxAmount() &&
//             selectedPaymentMethod == PaymentGateway.cod.name) {
//           selectedPaymentMethod = PaymentGateway.razorpay.name;
//         }
//       });
//     });
//     orderPlacingProvider = Provider.of<OrderPlacingProvider>(
//       context,
//       listen: false,
//     );
//     notifyListeners();
//   }
//
//   /// 🔑 BULLETPROOF PROFILE VALIDATION - NEVER FAILS
//   Future<void> validateUserProfileBulletproof() async {
//     isProfileValidating = true;
//     try {
//       UserModel? user;
//       int attempts = 0;
//       const maxAttempts = 3;
//       while (user == null && attempts < maxAttempts) {
//         attempts++;
//
//         try {
//           final userId = await SqlStorageConst.getFirebaseId();
//           user = await AddressListProvider.getUserProfile(
//             userId.toString(),
//           ).timeout(const Duration(seconds: 10));
//           if (user != null) {
//             break;
//           } else {}
//         } catch (e) {
//           if (attempts == 2 && Constant.userModel != null) {
//             user = Constant.userModel;
//
//             break;
//           }
//
//           // Strategy 3: Wait and retry for network issues
//           if (attempts < maxAttempts) {
//             await Future.delayed(const Duration(seconds: 2));
//             print(
//               '🔒 [BULLETPROOF_PROFILE] Wait completed, proceeding to next attempt',
//             );
//           }
//         }
//       }
//       notifyListeners();
//
//       if (user == null) {
//         isProfileValid = false;
//         ShowToastDialog.showToast(
//           "Unable to verify profile. Please check your internet connection and try again."
//               .tr,
//         );
//         return;
//       }
//
//       final hasFirstName =
//           user.firstName != null &&
//           user.firstName!.trim().isNotEmpty &&
//           user.firstName!.trim().length >= 2;
//
//       final hasPhoneNumber =
//           user.phoneNumber != null &&
//           user.phoneNumber!.trim().isNotEmpty &&
//           user.phoneNumber!.trim().length >= 10;
//
//       final hasEmail =
//           user.email != null &&
//           user.email!.trim().isNotEmpty &&
//           user.email!.contains('@') &&
//           user.email!.contains('.');
//
//       isProfileValid = hasFirstName && hasPhoneNumber && hasEmail;
//
//       userModel = user;
//       Constant.userModel = user; // Update global cache
//       notifyListeners();
//       if (!isProfileValid) {
//         final missingFields = <String>[];
//         if (!hasFirstName) missingFields.add('First Name (min 2 chars)');
//         if (!hasPhoneNumber) missingFields.add('Phone Number (min 10 digits)');
//         if (!hasEmail) missingFields.add('Valid Email Address');
//       }
//       notifyListeners();
//     } catch (e) {
//       isProfileValid = false;
//       ShowToastDialog.showToast(
//         "Error validating profile. Please try again.".tr,
//       );
//       notifyListeners();
//     } finally {
//       isProfileValidating = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> validateUserProfile() async {
//     await validateUserProfileBulletproof();
//   }
//
//   Future<bool> validateAndPlaceOrderBulletproof(BuildContext context) async {
//     await validateUserProfileBulletproof();
//     if (!isProfileValid) {
//       final user = userModel;
//       List<String> missingFields = [];
//       if (user.firstName == null ||
//           user.firstName!.trim().isEmpty ||
//           user.firstName!.trim().length < 2) {
//         missingFields.add("First Name (minimum 2 characters)");
//       }
//       if (user.phoneNumber == null ||
//           user.phoneNumber!.trim().isEmpty ||
//           user.phoneNumber!.trim().length < 10) {
//         missingFields.add("Phone Number (minimum 10 digits)");
//       }
//       if (user.email == null ||
//           user.email!.trim().isEmpty ||
//           !user.email!.contains('@')) {
//         missingFields.add("Valid Email Address");
//       }
//       String message = "Please complete your profile before placing an order.";
//       if (missingFields.isNotEmpty) {
//         message =
//             "Missing required fields: ${missingFields.join(', ')}. Please complete your profile.";
//       }
//       notifyListeners();
//       ShowToastDialog.showToast(message);
//       return false;
//     }
//     final addressValid = await _validateAddressBulletproof(context);
//     if (!addressValid) {
//       return false;
//     }
//     try {
//       await validateMinimumOrderValue();
//     } catch (e) {
//       return false;
//     }
//     notifyListeners();
//     return true;
//   }
//
//   // Method to check if cache is valid
//   bool _isCacheValid() {
//     return _lastCacheTime != null &&
//         DateTime.now().difference(_lastCacheTime!) < cacheExpiry;
//   }
//
//   // Method to update cache timestamp
//   void _updateCacheTime() {
//     _lastCacheTime = DateTime.now();
//   }
//
//   // **ULTRA-FAST METHOD TO PRELOAD ALL CALCULATION DATA FOR INSTANT CART UPDATES**
//   Future<void> _loadCalculationCache() async {
//     if (_calculationCacheLoaded) return;
//     try {
//       // Load tax list once and cache it
//       _cachedTaxList ??= await FireStoreUtils.getTaxList();
//       final futures = <Future>[];
//       for (var item in HomeProvider.cartItem) {
//         if (item.promoId != null && item.promoId!.isNotEmpty) {
//           final cacheKey = '${item.id}-${item.vendorID}';
//           if (!_promotionalCalculationCache.containsKey(cacheKey)) {
//             futures.add(
//               _cachePromotionalData(
//                 item.id ?? '',
//                 item.vendorID ?? '',
//                 cacheKey,
//               ),
//             );
//           }
//         }
//       }
//       await Future.wait(futures);
//       _calculationCacheLoaded = true;
//     } catch (e) {}
//     notifyListeners();
//   }
//
//   Future<void> _cachePromotionalData(
//     String productId,
//     String restaurantId,
//     String cacheKey,
//   ) async {
//     try {
//       final promoDetails = await FireStoreUtils.getActivePromotionForProduct(
//         productId: productId,
//         restaurantId: restaurantId,
//       );
//       if (promoDetails != null) {
//         _promotionalCalculationCache[cacheKey] = promoDetails;
//         final freeDeliveryKm =
//             (promoDetails['free_delivery_km'] as num?)?.toDouble() ?? 3.0;
//         final extraKmCharge =
//             (promoDetails['extra_km_charge'] as num?)?.toDouble() ?? 7.0;
//         _cachedFreeDeliveryKm[cacheKey] = freeDeliveryKm;
//         _cachedExtraKmCharge[cacheKey] = extraKmCharge;
//       }
//       notifyListeners();
//     } catch (e) {
//       print('DEBUG: Error caching promotional data for $cacheKey: $e');
//     }
//     notifyListeners();
//   }
//
//   double _getCachedFreeDeliveryKm(String productId, String restaurantId) {
//     final cacheKey = '$productId-$restaurantId';
//     return _cachedFreeDeliveryKm[cacheKey] ?? 3.0;
//   }
//
//   // **INSTANT METHOD TO GET CACHED EXTRA KM CHARGE (ZERO ASYNC)**
//   double _getCachedExtraKmCharge(String productId, String restaurantId) {
//     final cacheKey = '$productId-$restaurantId';
//     return _cachedExtraKmCharge[cacheKey] ?? 7.0;
//   }
//
//   // **REMOVED: getMartDeliveryFreeDistance() - NO FREE DELIVERY for mart items**
//
//   // Method to check if cart has promotional items
//   bool hasPromotionalItems() {
//     return HomeProvider.cartItem.any(
//       (item) => item.promoId != null && item.promoId!.isNotEmpty,
//     );
//   }
//
//   // Method to get promotional item limit
//   // Future<int?> getPromotionalItemLimit(String productId, String restaurantId) async {
//   /// **ULTRA-FAST PROMOTIONAL ITEM LIMIT (INSTANT - ZERO ASYNC)**
//   int? getPromotionalItemLimit(String productId, String restaurantId) {
//     try {
//       final limit = PromotionalCacheService.getPromotionalItemLimit(
//         productId,
//         restaurantId,
//       );
//       if (limit != null) {
//       } else {}
//       notifyListeners();
//       return limit;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// **ULTRA-FAST PROMOTIONAL ITEM QUANTITY CHECK (INSTANT - ZERO ASYNC)**
//   bool isPromotionalItemQuantityAllowed(
//     String productId,
//     String restaurantId,
//     int currentQuantity,
//   ) {
//     if (currentQuantity <= 0) {
//       return true; // Allow decrement
//     }
//     final isAllowed = PromotionalCacheService.isPromotionalItemQuantityAllowed(
//       productId,
//       restaurantId,
//       currentQuantity,
//     );
//     notifyListeners();
//     return isAllowed;
//   }
//
//   bool canProcessOrder() {
//     if (isProcessingOrder) {
//       return false;
//     }
//
//     if (lastOrderAttempt != null) {
//       final timeSinceLastAttempt = DateTime.now().difference(lastOrderAttempt!);
//       if (timeSinceLastAttempt < orderDebounceTime) {
//         return false;
//       }
//     }
//     notifyListeners();
//     return true;
//   }
//
//   // Method to end order processing
//   void endOrderProcessing() {
//     _endOrderProcessing();
//   }
//
//   // Method to check and update payment method based on order total, promotional items, and mart items
//   void checkAndUpdatePaymentMethod() {
//     final hasPromoItems = hasPromotionalItems();
//
//     if (hasPromoItems) {
//       if (selectedPaymentMethod == PaymentGateway.cod.name ||
//           selectedPaymentMethod.isEmpty) {
//         selectedPaymentMethod = PaymentGateway.razorpay.name;
//       }
//     } else if (subTotal > 599) {
//       if (selectedPaymentMethod == PaymentGateway.cod.name ||
//           selectedPaymentMethod.isEmpty) {
//         selectedPaymentMethod = PaymentGateway.razorpay.name;
//       }
//     }
//     notifyListeners();
//   }
//
//   /// Check if cart is ready for payment
//   bool isCartReadyForPayment() {
//     final cartNotEmpty = HomeProvider.cartItem.isNotEmpty;
//     final subTotalValid = subTotal > 0;
//     final totalValid = totalAmount > 0;
//     final paymentMethodSelected = selectedPaymentMethod.isNotEmpty;
//     final profileValid = isProfileValid;
//     final notProcessing = !isProcessingOrder;
//     final notPaymentInProgress = !isPaymentInProgress;
//     final notPaymentCompleted = !isPaymentCompleted;
//
//     final isReady =
//         cartNotEmpty &&
//         subTotalValid &&
//         totalValid &&
//         paymentMethodSelected &&
//         profileValid &&
//         notProcessing &&
//         notPaymentInProgress &&
//         notPaymentCompleted;
//     notifyListeners();
//     return isReady;
//   }
//
//   /// Update cart readiness state
//   void updateCartReadiness() {
//     isCartReady = HomeProvider.cartItem.isNotEmpty && subTotal > 0;
//     isPaymentReady = isCartReadyForPayment();
//     isAddressValid = selectedAddress?.id != null;
//     notifyListeners();
//   }
//
//   /// Force refresh cart data and recalculate prices
//   Future<void> forceRefreshCart() async {
//     await cartProvider.refreshCart();
//     // Refresh vendor details so delivery distance can be recalculated
//     await _loadFreshVendorForCart();
//     // Preload all products for cart display (load once, use many times)
//     await preloadCartProducts(forceRefresh: true);
//     // Reset delivery tips when cart refreshes (for new orders)
//     deliveryTips = 0.0;
//     await calculatePrice();
//     checkAndUpdatePaymentMethod();
//     updateCartReadiness();
//     notifyListeners();
//   }
//
//   /// Preload all products in cart - called once when cart screen opens
//   /// If forceRefresh is true, clears cache and reloads all products
//   Future<void> preloadCartProducts({bool forceRefresh = false}) async {
//     if (_isLoadingProducts && !forceRefresh) {
//       return; // Already loading
//     }
//
//     if (forceRefresh) {
//       _productCache.clear();
//       _productsLoaded = false;
//     }
//
//     _isLoadingProducts = true;
//
//     try {
//       // Get all unique product IDs from cart
//       final Set<String> productIds = {};
//
//       for (final cartItem in HomeProvider.cartItem) {
//         if (cartItem.id != null &&
//             cartItem.id!.isNotEmpty &&
//             cartItem.id!.toLowerCase() != 'null') {
//           final parts = cartItem.id!.split('~');
//           if (parts.isNotEmpty &&
//               parts.first.isNotEmpty &&
//               parts.first.toLowerCase() != 'null') {
//             productIds.add(parts.first);
//           }
//         }
//       }
//
//       // Only load products that aren't already cached (unless force refresh)
//       final Set<String> productsToLoad = forceRefresh
//           ? productIds
//           : productIds.where((id) => !_productCache.containsKey(id)).toSet();
//
//       if (productsToLoad.isEmpty) {
//         _productsLoaded = true;
//         notifyListeners();
//         return;
//       }
//
//       // Load all products in parallel
//       final List<Future<void>> loadFutures = productsToLoad.map((
//         productId,
//       ) async {
//         try {
//           // Check if it's a mart item by finding the cart item
//           final cartItem = HomeProvider.cartItem.firstWhere((item) {
//             if (item.id == null || item.id!.isEmpty) return false;
//             final parts = item.id!.split('~');
//             return parts.isNotEmpty && parts.first == productId;
//           }, orElse: () => CartProductModel());
//
//           final isMartItem = _isMartItem(cartItem);
//
//           if (isMartItem) {
//             // For mart items, we don't have ProductModel - use cart data
//             // Mart items are displayed using cartProductModel data
//             _productCache[productId] =
//                 null; // Mark as loaded (null = use cart data)
//           } else {
//             // For restaurant items, fetch ProductModel
//             final product = await FireStoreUtils.getProductById(productId);
//             _productCache[productId] = product;
//           }
//         } catch (e) {
//           print('[CART_PRODUCT] Error loading product $productId: $e');
//           _productCache[productId] = null;
//         }
//       }).toList();
//
//       await Future.wait(loadFutures);
//       _productsLoaded = true;
//       notifyListeners();
//       print(
//         '[CART_PRODUCT] Preloaded ${_productCache.length} products (${productsToLoad.length} new)',
//       );
//     } catch (e) {
//       print('[CART_PRODUCT] Error preloading products: $e');
//     } finally {
//       _isLoadingProducts = false;
//     }
//   }
//
//   /// Get cached product by ID - returns null if not cached
//   ProductModel? getCachedProduct(String? productId) {
//     if (productId == null ||
//         productId.isEmpty ||
//         productId.toLowerCase() == 'null') {
//       return null;
//     }
//     return _productCache[productId];
//   }
//
//   /// Clear product cache (call when cart changes significantly)
//   void clearProductCache() {
//     _productCache.clear();
//     _productsLoaded = false;
//     notifyListeners();
//   }
//
//   /// Validates and updates cart prices against current backend prices
//   /// Works for both food (restaurant) and mart items
//   /// Validates and updates cart prices against current backend prices
//   /// Works for both food (restaurant) and mart items
//   /// SKIPS promotional items - their prices should remain fixed
//   /// Validates and updates cart prices against current backend prices
//   /// Works for both food (restaurant) and mart items
//   Future<Map<String, PriceUpdateResult>> validateAndUpdateCartPrices() async {
//     final Map<String, PriceUpdateResult> results = {};
//
//     print(
//       '[PRICE_SYNC] Validating prices for ${HomeProvider.cartItem.length} cart items',
//     );
//
//     for (var cartItem in HomeProvider.cartItem) {
//       try {
//         if (cartItem.id == null || cartItem.id!.isEmpty) {
//           results[cartItem.id ?? 'unknown'] = PriceUpdateResult(
//             productId: cartItem.id ?? 'unknown',
//             status: PriceStatus.error,
//             oldPrice: cartItem.price,
//             newPrice: null,
//             error: 'Product ID is null or empty',
//           );
//           continue;
//         }
//
//         final isPromotionalItem =
//             cartItem.promoId != null && cartItem.promoId!.isNotEmpty;
//         final isMart = _isMartItem(cartItem);
//         final itemType = isMart ? 'MART' : 'FOOD';
//
//         // Fetch current product from backend
//         dynamic currentProduct;
//
//         if (isMart) {
//           // For mart items - direct price, no commission needed
//           try {
//             final martService = Get.find<MartFirestoreService>();
//             currentProduct = await martService.getItemById(cartItem.id!);
//             if (currentProduct != null && currentProduct is MartItemModel) {
//               print(
//                 '[PRICE_SYNC] [$itemType] ✅ Fetched mart item: ${cartItem.name}',
//               );
//             }
//           } catch (e) {
//             print(
//               '[PRICE_SYNC] [$itemType] ❌ Error fetching mart item ${cartItem.id}: $e',
//             );
//             results[cartItem.id!] = PriceUpdateResult(
//               productId: cartItem.id!,
//               status: PriceStatus.error,
//               oldPrice: cartItem.price,
//               newPrice: null,
//               error: e.toString(),
//             );
//             continue;
//           }
//         } else {
//           // For restaurant items - may need commission calculation
//           try {
//             currentProduct = await FireStoreUtils.getProductById(cartItem.id!);
//             if (currentProduct != null && currentProduct is ProductModel) {
//               print(
//                 '[PRICE_SYNC] [$itemType] ✅ Fetched restaurant item: ${cartItem.name}',
//               );
//             }
//           } catch (e) {
//             print(
//               '[PRICE_SYNC] [$itemType] Error fetching restaurant item ${cartItem.id}: $e',
//             );
//             results[cartItem.id!] = PriceUpdateResult(
//               productId: cartItem.id!,
//               status: PriceStatus.error,
//               oldPrice: cartItem.price,
//               newPrice: null,
//               error: e.toString(),
//             );
//             continue;
//           }
//         }
//
//         if (currentProduct == null) {
//           results[cartItem.id!] = PriceUpdateResult(
//             productId: cartItem.id!,
//             status: PriceStatus.productNotFound,
//             oldPrice: cartItem.price,
//             newPrice: null,
//             productName: cartItem.name,
//           );
//           continue;
//         }
//
//         // Get current price (considering variants, promotions, etc.)
//         final currentPrice = _getCurrentProductPrice(currentProduct, cartItem);
//
//         // For promotional items, we should compare against the ORIGINAL price, not the promotional price
//         // But we should NOT update the promotional price in cart
//         if (isPromotionalItem) {
//           print(
//             '[PRICE_SYNC] 🎯 [$itemType] Promotional item detected: ${cartItem.name}',
//           );
//           print('[PRICE_SYNC] 🎯   Promo ID: ${cartItem.promoId}');
//           print(
//             '[PRICE_SYNC] 🎯   Promotional price in cart: ₹${cartItem.price} (FIXED - will not change)',
//           );
//           print('[PRICE_SYNC] 🎯   Current backend price: ₹$currentPrice');
//
//           // For promotional items, always return noChange status
//           // The promotional price should remain fixed even if backend price changes
//           results[cartItem.id!] = PriceUpdateResult(
//             productId: cartItem.id!,
//             status: PriceStatus.noChange,
//             // Force no change for promotional items
//             oldPrice: cartItem.price,
//             newPrice: cartItem.price,
//             // Keep same price
//             productName: cartItem.name,
//           );
//           continue; // Skip to next item
//         }
//
//         // For non-promotional items, proceed with normal price comparison
//
//         // For comparison, use the price that's actually displayed in cart
//         final storedDiscountPrice =
//             double.tryParse(cartItem.discountPrice ?? "0") ?? 0.0;
//         final storedRegularPrice =
//             double.tryParse(cartItem.price ?? "0") ?? 0.0;
//         final storedDisplayPrice =
//             storedDiscountPrice > 0 && storedDiscountPrice < storedRegularPrice
//             ? storedDiscountPrice
//             : storedRegularPrice;
//
//         print(
//           '[PRICE_SYNC] 💰 [$itemType] Price comparison for ${cartItem.name}:',
//         );
//         print(
//           '[PRICE_SYNC]   Stored in cart: Regular=₹$storedRegularPrice, Discount=₹$storedDiscountPrice, Display=₹$storedDisplayPrice',
//         );
//         print('[PRICE_SYNC]   Calculated current price: ₹$currentPrice');
//
//         if ((currentPrice - storedDisplayPrice).abs() > 0.01) {
//           // Price has changed (using 0.01 tolerance for floating point comparison)
//           print(
//             '[PRICE_SYNC]   ✅ PRICE CHANGE DETECTED: ₹$storedDisplayPrice → ₹$currentPrice',
//           );
//           results[cartItem.id!] = PriceUpdateResult(
//             productId: cartItem.id!,
//             status: PriceStatus.priceChanged,
//             oldPrice: storedDisplayPrice.toStringAsFixed(2),
//             newPrice: currentPrice.toStringAsFixed(2),
//             productName: cartItem.name,
//           );
//         } else {
//           print(
//             '[PRICE_SYNC]   ℹ️ No price change (difference: ${(currentPrice - storedDisplayPrice).abs()})',
//           );
//           results[cartItem.id!] = PriceUpdateResult(
//             productId: cartItem.id!,
//             status: PriceStatus.noChange,
//             oldPrice: storedDisplayPrice.toStringAsFixed(2),
//             newPrice: currentPrice.toStringAsFixed(2),
//           );
//         }
//       } catch (e) {
//         results[cartItem.id ?? 'unknown'] = PriceUpdateResult(
//           productId: cartItem.id ?? 'unknown',
//           status: PriceStatus.error,
//           oldPrice: cartItem.price,
//           newPrice: null,
//           error: e.toString(),
//         );
//       }
//     }
//
//     return results;
//   }
//
//   /// Helper to get current product price considering variants and promotions
//   double _getCurrentProductPrice(dynamic product, CartProductModel cartItem) {
//     try {
//       // Handle variants for restaurant products
//       if (cartItem.variantInfo != null &&
//           product is ProductModel &&
//           product.itemAttribute != null) {
//         final variantSku = cartItem.variantInfo!.variantSku;
//         Variants? variant;
//         try {
//           variant = product.itemAttribute!.variants?.firstWhere(
//             (v) => v.variantSku == variantSku,
//           );
//         } catch (e) {
//           // Variant not found, will use regular price
//           variant = null;
//         }
//
//         if (variant != null && variant.variantPrice != null) {
//           // Get vendor for commission calculation
//           if (vendorModel.id != null) {
//             return double.parse(
//               Constant.productCommissionPrice(
//                 vendorModel,
//                 variant.variantPrice ?? product.price ?? "0",
//               ),
//             );
//           }
//           return double.tryParse(variant.variantPrice ?? "0") ?? 0.0;
//         }
//       }
//
//       // Handle mart items - use finalPrice (discount price if available, else regular price)
//       if (product is MartItemModel) {
//         // Use finalPrice which returns disPrice if available and less than price, else price
//         return product.finalPrice;
//       }
//
//       // Handle regular restaurant product price with commission
//       if (product is ProductModel) {
//         // Check for promotional price
//         if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) {
//           if (vendorModel.id != null) {
//             return double.parse(
//               Constant.productCommissionPrice(
//                 vendorModel,
//                 product.price ?? "0",
//               ),
//             );
//           }
//           return double.tryParse(product.price ?? "0") ?? 0.0;
//         }
//
//         // Check for discount
//         if (product.disPrice != null &&
//             double.tryParse(product.disPrice!) != null &&
//             double.tryParse(product.price ?? "0") != null) {
//           final disPrice = double.parse(product.disPrice!);
//           final regPrice = double.parse(product.price ?? "0");
//           if (disPrice > 0 && disPrice < regPrice) {
//             if (vendorModel.id != null) {
//               return double.parse(
//                 Constant.productCommissionPrice(
//                   vendorModel,
//                   product.disPrice ?? "0",
//                 ),
//               );
//             }
//             return disPrice;
//           }
//         }
//
//         // Regular price
//         if (vendorModel.id != null) {
//           return double.parse(
//             Constant.productCommissionPrice(vendorModel, product.price ?? "0"),
//           );
//         }
//         return double.tryParse(product.price ?? "0") ?? 0.0;
//       }
//     } catch (e) {
//       print('Error getting current product price: $e');
//     }
//
//     return 0.0;
//   }
//
//   /// Syncs cart prices in background (call when cart screen opens)
//   /// Works for both food (restaurant) and mart items
//   /// Syncs cart prices in background (call when cart screen opens)
//   /// Works for both food (restaurant) and mart items
//   /// SKIPS promotional items - their prices remain fixed
//   /// Syncs cart prices in background (call when cart screen opens)
//   /// Works for both food (restaurant) and mart items
//   /// Promotional items keep their fixed prices
//   /// Non-promotional items get updated if prices changed
//   Future<void> syncCartPricesInBackground() async {
//     try {
//       print('[PRICE_SYNC] ========== STARTING PRICE SYNC ==========');
//
//       // Only sync if cart has items
//       if (HomeProvider.cartItem.isEmpty) {
//         print('[PRICE_SYNC] ❌ Cart is empty, skipping sync');
//         return;
//       }
//
//       // Count promotional vs non-promotional items
//       final promotionalItems = HomeProvider.cartItem
//           .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
//           .toList();
//
//       final nonPromotionalItems = HomeProvider.cartItem
//           .where((item) => item.promoId == null || item.promoId!.isEmpty)
//           .toList();
//
//       print('[PRICE_SYNC] 📦 Cart summary:');
//       print('[PRICE_SYNC]   Total items: ${HomeProvider.cartItem.length}');
//       print(
//         '[PRICE_SYNC]   Promotional items: ${promotionalItems.length} (prices fixed)',
//       );
//       print(
//         '[PRICE_SYNC]   Non-promotional items: ${nonPromotionalItems.length} (prices will sync)',
//       );
//
//       if (promotionalItems.isNotEmpty) {
//         print('[PRICE_SYNC] 🎯 Promotional items (prices will NOT change):');
//         for (var promoItem in promotionalItems) {
//           print(
//             '[PRICE_SYNC]   - ${promoItem.name}: Promo ID: ${promoItem.promoId}, Price: ₹${promoItem.price}',
//           );
//         }
//       }
//
//       if (nonPromotionalItems.isEmpty) {
//         print(
//           '[PRICE_SYNC] ⏭️  All items are promotional - skipping price sync',
//         );
//         return;
//       }
//
//       print('[PRICE_SYNC] 🔍 Validating prices for non-promotional items...');
//
//       // For food items, ensure vendor is loaded before price validation
//       final hasFoodItems = nonPromotionalItems.any(
//         (item) =>
//             item.vendorID != null &&
//             item.vendorID!.isNotEmpty &&
//             item.vendorID!.contains('vendor') == true,
//       );
//
//       if (hasFoodItems && (vendorModel.id == null || vendorModel.id!.isEmpty)) {
//         print(
//           '[PRICE_SYNC] 🏪 Food items detected, loading vendor for commission calculation...',
//         );
//         try {
//           // Find the first non-promotional food item's vendor ID
//           final foodItem = nonPromotionalItems.firstWhere(
//             (item) =>
//                 item.vendorID != null &&
//                 item.vendorID!.isNotEmpty &&
//                 item.vendorID!.contains('vendor') == true,
//             orElse: () => CartProductModel(),
//           );
//
//           if (foodItem.vendorID != null && foodItem.vendorID!.isNotEmpty) {
//             final vendorId = foodItem.vendorID!.split('~').first;
//             final freshVendor = await FireStoreUtils.getVendorById(vendorId);
//             if (freshVendor != null) {
//               vendorModel = freshVendor;
//               print(
//                 '[PRICE_SYNC] ✅ Vendor loaded: ${vendorModel.title} (${vendorModel.id})',
//               );
//             }
//           }
//         } catch (e) {
//           print('[PRICE_SYNC] ❌ Error loading vendor: $e');
//         }
//       }
//
//       // Validate prices for ALL items (promotional items will return noChange status)
//       final priceUpdates = await validateAndUpdateCartPrices();
//
//       print('[PRICE_SYNC] 📊 Validation results:');
//       for (var entry in priceUpdates.entries) {
//         final result = entry.value;
//         final cartItem = HomeProvider.cartItem.firstWhere(
//           (item) => item.id == result.productId,
//           orElse: () => CartProductModel(),
//         );
//         final isPromo =
//             cartItem.promoId != null && cartItem.promoId!.isNotEmpty;
//
//         if (isPromo) {
//           print(
//             '[PRICE_SYNC]   🎯 ${result.productName ?? result.productId}: PROMOTIONAL - Price fixed at ₹${result.oldPrice}',
//           );
//         } else {
//           print(
//             '[PRICE_SYNC]   📦 ${result.productName ?? result.productId}: ${result.status.name}',
//           );
//           if (result.hasPriceChange) {
//             print(
//               '[PRICE_SYNC]     Price change: ₹${result.oldPrice ?? "N/A"} → ₹${result.newPrice ?? "N/A"}',
//             );
//           }
//         }
//       }
//
//       bool hasUpdates = false;
//       int updateCount = 0;
//
//       // Update prices ONLY for non-promotional items that have changed
//       print(
//         '[PRICE_SYNC] 🔄 Processing price updates (only non-promotional items)...',
//       );
//
//       for (var entry in priceUpdates.entries) {
//         final result = entry.value;
//
//         // Check if this is a promotional item
//         final cartItem = HomeProvider.cartItem.firstWhere(
//           (item) => item.id == result.productId,
//           orElse: () => CartProductModel(),
//         );
//
//         final isPromo =
//             cartItem.promoId != null && cartItem.promoId!.isNotEmpty;
//         if (isPromo) {
//           print(
//             '[PRICE_SYNC] 🎯 Skipping promotional item: ${result.productName} (price remains fixed)',
//           );
//           continue; // Skip promotional items
//         }
//
//         // Only process non-promotional items with price changes
//         if (result.hasPriceChange &&
//             result.oldPrice != null &&
//             result.newPrice != null) {
//           try {
//             final oldPrice = double.tryParse(result.oldPrice!) ?? 0.0;
//             final newPrice = double.tryParse(result.newPrice!) ?? 0.0;
//
//             if (oldPrice > 0) {
//               final changePercent = ((newPrice - oldPrice) / oldPrice * 100)
//                   .abs();
//
//               print(
//                 '[PRICE_SYNC] 💰 Updating ${result.productName ?? result.productId}: ₹$oldPrice → ₹$newPrice (${changePercent.toStringAsFixed(1)}%)',
//               );
//
//               // Find and update cart item
//               final cartItemIndex = HomeProvider.cartItem.indexWhere(
//                 (item) => item.id == result.productId,
//               );
//
//               if (cartItemIndex < 0) {
//                 print(
//                   '[PRICE_SYNC] ⚠️ Item not found in cart: ${result.productId}',
//                 );
//                 continue;
//               }
//
//               print('[PRICE_SYNC] ✅ Found item at index $cartItemIndex');
//
//               if (cartItemIndex >= 0) {
//                 final cartItem = HomeProvider.cartItem[cartItemIndex];
//
//                 try {
//                   // Store old values for logging
//                   final oldPriceValue = cartItem.price;
//                   final oldDiscountValue = cartItem.discountPrice;
//
//                   // Fetch current product to get updated prices
//                   dynamic currentProduct;
//                   final isMart = _isMartItem(cartItem);
//
//                   if (isMart) {
//                     // Mart items
//                     try {
//                       final martService = Get.find<MartFirestoreService>();
//                       currentProduct = await martService.getItemById(
//                         cartItem.id!,
//                       );
//                     } catch (e) {
//                       currentProduct = null;
//                     }
//                   } else {
//                     // Restaurant items
//                     try {
//                       currentProduct = await FireStoreUtils.getProductById(
//                         cartItem.id!,
//                       );
//                     } catch (e) {
//                       currentProduct = null;
//                     }
//                   }
//
//                   if (currentProduct != null) {
//                     // Update prices based on product type
//                     if (currentProduct is MartItemModel) {
//                       cartItem.price = currentProduct.price.toStringAsFixed(2);
//                       if (currentProduct.disPrice != null &&
//                           currentProduct.disPrice! < currentProduct.price &&
//                           currentProduct.disPrice! > 0) {
//                         cartItem.discountPrice = currentProduct.disPrice!
//                             .toStringAsFixed(2);
//                       } else {
//                         cartItem.discountPrice = "0";
//                       }
//                     } else if (currentProduct is ProductModel) {
//                       cartItem.price = result.newPrice;
//                       if (currentProduct.disPrice != null &&
//                           double.tryParse(currentProduct.disPrice!) != null &&
//                           double.tryParse(currentProduct.price ?? "0") !=
//                               null) {
//                         final disPrice = double.parse(currentProduct.disPrice!);
//                         final regPrice = double.parse(
//                           currentProduct.price ?? "0",
//                         );
//                         if (disPrice > 0 && disPrice < regPrice) {
//                           if (vendorModel.id != null) {
//                             cartItem.discountPrice =
//                                 Constant.productCommissionPrice(
//                                   vendorModel,
//                                   currentProduct.disPrice ?? "0",
//                                 );
//                           } else {
//                             cartItem.discountPrice = currentProduct.disPrice;
//                           }
//                         } else {
//                           cartItem.discountPrice = "0";
//                         }
//                       } else {
//                         cartItem.discountPrice = "0";
//                       }
//                     }
//                   } else {
//                     // Fallback - just update price
//                     cartItem.price = result.newPrice;
//                   }
//
//                   // Save to database
//                   await DatabaseHelper.instance.updateCartProduct(cartItem);
//
//                   // CRITICAL: Update the item in HomeProvider.cartItem in place
//                   HomeProvider.cartItem[cartItemIndex] = cartItem;
//
//                   hasUpdates = true;
//                   updateCount++;
//
//                   final itemType = isMart ? 'MART' : 'FOOD';
//                   print(
//                     '[PRICE_SYNC] ✅ [$itemType] Updated price for ${result.productName ?? cartItem.name}: ₹$oldPrice → ₹$newPrice',
//                   );
//
//                   // Show notification for large changes (> 5%) on non-promotional items
//                   if (changePercent >= 5) {
//                     _showPriceChangeNotification(result);
//                   }
//                 } catch (e) {
//                   // Fallback
//                   cartItem.price = result.newPrice;
//                   await DatabaseHelper.instance.updateCartProduct(cartItem);
//                   HomeProvider.cartItem[cartItemIndex] = cartItem;
//                   hasUpdates = true;
//                   print('[PRICE_SYNC] Error updating price (fallback): $e');
//                 }
//               }
//             }
//           } catch (e) {
//             print(
//               '[PRICE_SYNC] Error updating price for ${result.productId}: $e',
//             );
//           }
//         }
//       }
//
//       // Refresh cart from database to ensure UI is updated
//       if (hasUpdates) {
//         print(
//           '[PRICE_SYNC] 🔄 Refreshing cart after $updateCount price updates...',
//         );
//
//         // Refresh cart items from database
//         print('[PRICE_SYNC] 📥 Fetching updated cart from database...');
//         await cartProvider.refreshCart();
//
//         // Force a complete refresh of HomeProvider.cartItem
//         final finalCartItems = await DatabaseHelper.instance
//             .fetchCartProducts();
//         print(
//           '[PRICE_SYNC] 📦 Fetched ${finalCartItems.length} items from database',
//         );
//
//         // Verify the prices were actually updated in database
//         print('[PRICE_SYNC] 🔍 Verifying database updates:');
//         for (var item in finalCartItems) {
//           final isPromo = item.promoId != null && item.promoId!.isNotEmpty;
//           print(
//             '[PRICE_SYNC]   - ${item.name}: ${isPromo ? "🎯 PROMO" : "Regular"} Price=₹${item.price}, Discount=₹${item.discountPrice}',
//           );
//         }
//
//         // Clear and rebuild HomeProvider.cartItem
//         HomeProvider.cartItem.clear();
//         HomeProvider.cartItem.addAll(finalCartItems);
//         print(
//           '[PRICE_SYNC] ✅ Updated HomeProvider.cartItem (${HomeProvider.cartItem.length} items)',
//         );
//
//         // Force update the cart stream
//         cartProvider.forceStreamUpdate();
//         print('[PRICE_SYNC] ✅ Forced cart stream update');
//
//         print('[PRICE_SYNC] 🧮 Recalculating totals...');
//
//         // Recalculate totals with updated prices
//         if (vendorModel.id != null ||
//             HomeProvider.cartItem.any((item) => _isMartItem(item))) {
//           await calculatePrice();
//           print(
//             '[PRICE_SYNC] ✅ Totals recalculated: SubTotal=₹$subTotal, Total=₹$totalAmount',
//           );
//         } else {
//           print(
//             '[PRICE_SYNC] ⚠️ Vendor not loaded, skipping total recalculation',
//           );
//         }
//
//         // Increment version to force UI rebuild
//         _priceSyncVersion++;
//         print(
//           '[PRICE_SYNC] 🔢 Incremented priceSyncVersion to $_priceSyncVersion',
//         );
//
//         // CRITICAL: Notify listeners to trigger UI rebuild
//         notifyListeners();
//         print('[PRICE_SYNC] 📢 Notified CartControllerProvider listeners');
//
//         // Small delay then notify again to ensure UI catches the update
//         await Future.delayed(Duration(milliseconds: 300));
//         _priceSyncVersion++;
//         notifyListeners();
//         print(
//           '[PRICE_SYNC] 🔢 Final priceSyncVersion: $_priceSyncVersion, notified again',
//         );
//
//         print('[PRICE_SYNC] ========== PRICE SYNC COMPLETE ==========');
//         print('[PRICE_SYNC] ✅ Updated $updateCount non-promotional items');
//         print(
//           '[PRICE_SYNC] 🎯 Promotional items: ${promotionalItems.length} items (prices fixed)',
//         );
//         print('[PRICE_SYNC] 📋 Final cart state:');
//         for (var item in finalCartItems) {
//           final isPromo = item.promoId != null && item.promoId!.isNotEmpty;
//           print(
//             '[PRICE_SYNC]   - ${item.name}: ${isPromo ? "🎯 PROMO" : "Regular"} Price=₹${item.price}, Discount=₹${item.discountPrice}, Qty=${item.quantity}',
//           );
//         }
//       } else {
//         print(
//           '[PRICE_SYNC] No price changes detected for non-promotional items',
//         );
//         print(
//           '[PRICE_SYNC] 🎯 Promotional items: ${promotionalItems.length} items (prices fixed)',
//         );
//       }
//     } catch (e, stackTrace) {
//       print('[PRICE_SYNC] ❌ Error syncing cart prices: $e');
//       print('[PRICE_SYNC] Stack trace: $stackTrace');
//     }
//   }
//
//   /// Show notification for significant price changes
//   /// Show notification for significant price changes (skips promotional items)
//   void _showPriceChangeNotification(PriceUpdateResult result) {
//     try {
//       // Check if this is a promotional item
//       final cartItem = HomeProvider.cartItem.firstWhere(
//         (item) => item.id == result.productId,
//         orElse: () => CartProductModel(),
//       );
//
//       final isPromo = cartItem.promoId != null && cartItem.promoId!.isNotEmpty;
//       if (isPromo) {
//         print(
//           '[PRICE_SYNC] ⏭️  Skipping price change notification for promotional item: ${result.productName}',
//         );
//         return; // Don't show notifications for promotional items
//       }
//
//       if (result.productName == null ||
//           result.oldPrice == null ||
//           result.newPrice == null) {
//         return;
//       }
//
//       final oldPrice = double.tryParse(result.oldPrice!) ?? 0.0;
//       final newPrice = double.tryParse(result.newPrice!) ?? 0.0;
//       final changePercent = oldPrice > 0
//           ? ((newPrice - oldPrice) / oldPrice * 100).abs()
//           : 0.0;
//
//       final isIncrease = newPrice > oldPrice;
//       final changeText = isIncrease ? 'increased' : 'decreased';
//
//       Get.snackbar(
//         'Price Update'.tr,
//         '${result.productName}: Price $changeText from ₹${oldPrice.toStringAsFixed(2)} to ₹${newPrice.toStringAsFixed(2)} (${changePercent.toStringAsFixed(1)}% change)',
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 4),
//         backgroundColor: isIncrease ? Colors.orange[100] : Colors.green[100],
//         colorText: Colors.black87,
//         margin: EdgeInsets.all(16),
//         isDismissible: true,
//       );
//     } catch (e) {
//       print('[PRICE_SYNC] Error showing price change notification: $e');
//     }
//   }
//
//   // Method to clear cart data on logout
//   Future<void> clearCart() async {
//     try {
//       // Clear cart items from memory
//       HomeProvider.cartItem.clear();
//       await DatabaseHelper.instance.deleteAllCartProducts();
//       subTotal = 0.0;
//       totalAmount = 0.0;
//       deliveryCharges = 0.0;
//       couponAmount = 0.0;
//       specialDiscountAmount = 0.0;
//       taxAmount = 0.0;
//       deliveryTips = 0.0;
//       selectedPaymentMethod = '';
//
//       // 🔑 CRITICAL: Reset payment state when clearing cart
//       _resetPaymentState();
//       _processedPaymentIds.clear();
//       _isOrderBeingCreated = false;
//
//       // 🔑 CRITICAL: Reset address initialization flag when clearing cart
//       _addressInitialized = false;
//
//       // Verify cart is actually empty
//       final remainingItems = await DatabaseHelper.instance.fetchCartProducts();
//       if (remainingItems.isNotEmpty) {}
//       notifyListeners();
//     } catch (e) {}
//     notifyListeners();
//   }
//
//   /// 🔑 CLEAR VENDOR CACHE WHEN CART CHANGES
//   void _clearVendorCache() {
//     _cachedVendorModel = null;
//     _lastCacheTime = null;
//     vendorModel = VendorModel();
//     notifyListeners();
//   }
//
//   /// 🔑 LOAD FRESH VENDOR DATA - NO CACHING
//   Future<void> _loadFreshVendorForCart() async {
//     try {
//       final martItems = HomeProvider.cartItem
//           .where((item) => _isMartItem(item))
//           .toList();
//       final restaurantItems = HomeProvider.cartItem
//           .where((item) => !_isMartItem(item))
//           .toList();
//       // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
//       if (martItems.isNotEmpty) {
//         await _loadFreshMartVendor(martItems);
//       } else if (restaurantItems.isNotEmpty) {
//         await _loadFreshRestaurantVendor(restaurantItems.first.vendorID);
//       } else {}
//       // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
//     } catch (e) {}
//     // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
//   }
//
//   /// 🔑 LOAD FRESH MART VENDOR
//   Future<void> _loadFreshMartVendor(List<CartProductModel> martItems) async {
//     try {
//       final firstMartItem = martItems.first;
//       final vendorId = firstMartItem.vendorID;
//       MartVendorModel? martVendor;
//       if (vendorId != null && vendorId.isNotEmpty) {
//         martVendor = await MartVendorService.getMartVendorById(vendorId);
//         martVendor ??= await MartVendorService.getDefaultMartVendor();
//       } else {
//         martVendor = await MartVendorService.getDefaultMartVendor();
//       }
//       if (martVendor != null) {
//         // 🔑 FIX: Ensure zoneId is set - use vendor zoneId or fallback to address zoneId
//         String? finalZoneId = martVendor.zoneId;
//         if ((finalZoneId == null || finalZoneId.isEmpty) &&
//             selectedAddress?.zoneId != null &&
//             selectedAddress!.zoneId!.isNotEmpty) {
//           finalZoneId = selectedAddress!.zoneId;
//         } else if ((finalZoneId == null || finalZoneId.isEmpty) &&
//             Constant.selectedLocation.zoneId != null &&
//             Constant.selectedLocation.zoneId!.isNotEmpty) {
//           finalZoneId = Constant.selectedLocation.zoneId;
//         }
//
//         vendorModel = VendorModel(
//           id: martVendor.id,
//           author: martVendor.author,
//           title: martVendor.title,
//           latitude: martVendor.latitude,
//           longitude: martVendor.longitude,
//           isSelfDelivery: false,
//           vType: martVendor.vType,
//           zoneId: finalZoneId,
//           isOpen: martVendor.isOpen,
//         );
//       }
//       notifyListeners();
//     } catch (e) {}
//   }
//
//   /// 🔑 LOAD FRESH RESTAURANT VENDOR
//   Future<void> _loadFreshRestaurantVendor(String? vendorId) async {
//     try {
//       if (vendorId == null) {
//         return;
//       }
//       final freshVendor = await FireStoreUtils.getVendorById(vendorId);
//       if (freshVendor != null) {
//         vendorModel = freshVendor;
//       } else {}
//       notifyListeners();
//     } catch (e) {}
//   }
//
//   getCartData() async {
//     cartProvider.cartStream.listen((event) async {
//       HomeProvider.cartItem.clear();
//       HomeProvider.cartItem.addAll(event);
//       if (HomeProvider.cartItem.isNotEmpty) {
//         final firstItemVendor = HomeProvider.cartItem.first.vendorID;
//         if (_cachedVendorModel?.id != firstItemVendor) {
//           _clearVendorCache();
//         }
//       }
//       if (HomeProvider.cartItem.isNotEmpty) {
//         await _loadFreshVendorForCart();
//       }
//       if (HomeProvider.cartItem.isNotEmpty) {
//         final martItems = HomeProvider.cartItem
//             .where((item) => _isMartItem(item))
//             .toList();
//         if (martItems.isNotEmpty) {
//           try {
//             final firstMartItem = martItems.first;
//             final vendorId = firstMartItem.vendorID;
//             MartVendorModel? martVendor;
//             if (vendorId != null && vendorId.isNotEmpty) {
//               martVendor = await MartVendorService.getMartVendorById(vendorId);
//               if (martVendor != null) {
//               } else {
//                 // Fallback to default mart vendor
//                 martVendor = await MartVendorService.getDefaultMartVendor();
//               }
//             } else {
//               martVendor = await MartVendorService.getDefaultMartVendor();
//             }
//             if (martVendor != null) {
//               // 🔑 FIX: Ensure zoneId is set - use vendor zoneId or fallback to address zoneId
//               String? finalZoneId = martVendor.zoneId;
//               if ((finalZoneId == null || finalZoneId.isEmpty) &&
//                   selectedAddress?.zoneId != null &&
//                   selectedAddress!.zoneId!.isNotEmpty) {
//                 finalZoneId = selectedAddress!.zoneId;
//               } else if ((finalZoneId == null || finalZoneId.isEmpty) &&
//                   Constant.selectedLocation.zoneId != null &&
//                   Constant.selectedLocation.zoneId!.isNotEmpty) {
//                 finalZoneId = Constant.selectedLocation.zoneId;
//               }
//
//               vendorModel = VendorModel(
//                 id: martVendor.id,
//                 author: martVendor.author,
//                 title: martVendor.title,
//                 latitude: martVendor.latitude,
//                 longitude: martVendor.longitude,
//                 isSelfDelivery: false,
//                 vType: martVendor.vType,
//                 zoneId: finalZoneId,
//                 isOpen: martVendor.isOpen,
//                 // Add other necessary fields as needed
//               );
//               _cachedVendorModel = vendorModel;
//               _updateCacheTime();
//               // 🔑 Reload coupons after mart vendor is loaded
//               _detectCurrentContext();
//               if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
//                 await _loadCoupons(restaurantId: vendorModel.id.toString());
//               }
//             } else {
//               // Don't set hardcoded values - let the system handle this gracefully
//               vendorModel = VendorModel();
//             }
//             notifyListeners();
//           } catch (e) {
//             vendorModel = VendorModel();
//           }
//           notifyListeners();
//         } else {
//           if (_cachedVendorModel != null && _isCacheValid()) {
//             vendorModel = _cachedVendorModel!;
//           } else {
//             await FireStoreUtils.getVendorById(
//               HomeProvider.cartItem.first.vendorID.toString(),
//             ).then((value) async {
//               if (value != null) {
//                 vendorModel = value;
//                 _cachedVendorModel = value;
//                 _updateCacheTime();
//                 // 🔑 Reload coupons after restaurant vendor is loaded
//                 _detectCurrentContext();
//                 if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
//                   await _loadCoupons(restaurantId: vendorModel.id.toString());
//                 }
//                 notifyListeners();
//               }
//             });
//             notifyListeners();
//           }
//         }
//       }
//       notifyListeners();
//       await _loadCalculationCache();
//       // 🔑 OPTIMIZED: Preload products when cart data changes (incremental loading)
//       // This ensures products are ready when UI renders
//       // Load in background without blocking price calculation
//       _loadNewProductsIncrementally().catchError((e) {
//         print('[CART_DATA] Error loading products: $e');
//       });
//       await calculatePrice();
//       checkAndUpdatePaymentMethod();
//       updateCartReadiness();
//     });
//     selectedFoodType = Preferences.getString(
//       Preferences.foodDeliveryType,
//       defaultValue: "Delivery".tr,
//     );
//
//     if (userModel.id == null) {
//       final userId = await SqlStorageConst.getFirebaseId();
//       await AddressListProvider.getUserProfile(userId.toString()).then((value) {
//         if (value != null) {
//           userModel = value;
//         }
//       });
//     }
//     if (_cachedDeliveryCharge != null && _isCacheValid()) {
//       deliveryChargeModel = _cachedDeliveryCharge!;
//     } else {
//       await FireStoreUtils.getDeliveryCharge().then((value) {
//         if (value != null) {
//           deliveryChargeModel = value;
//           _cachedDeliveryCharge = value;
//           _updateCacheTime();
//           calculatePrice();
//         }
//       });
//     }
//     // 🔑 Load coupons with proper context detection
//     // Detect context first based on cart items
//     _detectCurrentContext();
//
//     if (vendorModel.id != null &&
//         (!_isCacheValid() || _cachedCouponList == null)) {
//       await _loadCoupons(restaurantId: vendorModel.id.toString());
//     } else {
//       if (vendorModel.id != null && _cachedCouponList == null) {
//         await _loadCoupons(restaurantId: vendorModel.id.toString());
//       } else if (vendorModel.id == null && HomeProvider.cartItem.isNotEmpty) {
//         // 🔑 Vendor not loaded yet, but we have cart items - try to get vendor ID from items
//         final martItems = HomeProvider.cartItem
//             .where((item) => _isMartItem(item))
//             .toList();
//         if (martItems.isNotEmpty) {
//           final vendorId = martItems.first.vendorID;
//           if (vendorId != null && vendorId.isNotEmpty) {
//             await _loadCoupons(restaurantId: vendorId);
//           } else {
//             await _loadGlobalCouponsOnly();
//           }
//         } else {
//           final vendorId = HomeProvider.cartItem.first.vendorID;
//           if (vendorId != null && vendorId.isNotEmpty) {
//             await _loadCoupons(restaurantId: vendorId);
//           } else {
//             await _loadGlobalCouponsOnly();
//           }
//         }
//       } else if (vendorModel.id == null) {
//         // No vendor and no cart items - load global coupons
//         await _loadGlobalCouponsOnly();
//       }
//     }
//     notifyListeners();
//   }
//
//   Future<void> _loadCoupons({required String restaurantId}) async {
//     // Prevent multiple simultaneous calls
//     if (_isLoadingCoupons) {
//       print('[COUPON_LOAD] ⚠️ Coupon load already in progress, skipping...');
//       return;
//     }
//
//     // Validate restaurant ID before making API call
//     if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
//       print('[COUPON_LOAD] ⚠️ Skipping coupon load: empty restaurant ID');
//       await _loadGlobalCouponsOnly();
//       return;
//     }
//     _isLoadingCoupons = true;
//     try {
//       // 🔑 CRITICAL: Detect context BEFORE loading coupons
//       // This ensures we call the correct API (mart vs restaurant)
//       _detectCurrentContext();
//       print(
//         '[COUPON_LOAD] 🔍 Loading coupons for vendor: $restaurantId, Context: $_currentContext',
//       );
//
//       // 🔑 CRITICAL: Call the correct API based on context
//       // If mart items in cart → call getMartCoupons API
//       // If restaurant items in cart → call getRestaurantCoupons API
//       final allCoupons = _currentContext == "mart"
//           ? await RestaurantApiHelper.getMartCoupons(
//               restaurantId: restaurantId,
//             ).timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print('[COUPON_LOAD] ⏱️ Mart coupon API call timed out');
//                 return <CouponModel>[];
//               },
//             )
//           : await RestaurantApiHelper.getRestaurantCoupons(
//               restaurantId: restaurantId,
//             ).timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print('[COUPON_LOAD] ⏱️ Restaurant coupon API call timed out');
//                 return <CouponModel>[];
//               },
//             );
//
//       print(
//         '[COUPON_LOAD] ✅ Received ${allCoupons.length} coupons from ${_currentContext} API',
//       );
//
//       final filteredGlobalCoupons = allCoupons
//           .where(
//             (c) =>
//                 c.resturantId == null ||
//                 c.resturantId == '' ||
//                 c.resturantId?.toUpperCase() == 'ALL',
//           )
//           .toList();
//
//       // Filter vendor-specific coupons
//       final vendorCoupons = allCoupons
//           .where(
//             (c) =>
//                 c.resturantId != null &&
//                 c.resturantId!.isNotEmpty &&
//                 c.resturantId!.toUpperCase() != 'ALL' &&
//                 c.resturantId == restaurantId,
//           )
//           .toList();
//
//       // Combine vendor and global coupons
//       final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
//       final combinedAllCoupons = [...allCoupons];
//
//       // 🔑 CRITICAL: Filter coupons by context (mart vs restaurant)
//       final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
//         coupons: combinedCoupons.cast<CouponModel>(),
//         contextType: _currentContext,
//         fallbackEnabled: true, // Enable fallback for backward compatibility
//       );
//
//       final contextFilteredAllCoupons =
//           CouponFilterService.filterCouponsByContext(
//             coupons: combinedAllCoupons.cast<CouponModel>(),
//             contextType: _currentContext,
//             fallbackEnabled: true,
//           );
//
//       print(
//         '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} coupons for context: $_currentContext (from ${combinedCoupons.length} total)',
//       );
//
//       _cachedCouponList = contextFilteredCoupons;
//       _updateCacheTime();
//
//       couponList = contextFilteredCoupons;
//       allCouponList = contextFilteredAllCoupons;
//       // Mark used coupons BEFORE notifying listeners
//       // This ensures coupons are validated before UI shows them
//       await _markUsedCoupons();
//       notifyListeners();
//     } on SocketException catch (e) {
//       print('[COUPON_LOAD] ❌ Connection error: $e');
//       // Use cached coupons if available, otherwise empty list
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } on http.ClientException catch (e) {
//       print(
//         '[COUPON_LOAD] ❌ ClientException (connection refused or network error): $e',
//       );
//       // Use cached coupons if available, otherwise empty list
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } catch (e) {
//       print('[COUPON_LOAD] ❌ Error loading coupons: $e');
//       // Check for rate limit (429) or other errors
//       final errorString = e.toString();
//       if (errorString.contains('429') ||
//           errorString.contains('Status code: 429')) {
//         print(
//           '[COUPON_LOAD] ⚠️ Rate limit (429) - using cached coupons if available',
//         );
//         if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//           couponList = _cachedCouponList!;
//           allCouponList = _cachedCouponList!;
//           // Mark used coupons before showing cached coupons
//           await _markUsedCoupons();
//           notifyListeners();
//         } else {
//           couponList = [];
//           allCouponList = [];
//           notifyListeners();
//         }
//       } else {
//         // Try fallback method only for non-rate-limit errors
//         await _loadCouponsWithoutFiltering(restaurantId: restaurantId);
//         notifyListeners();
//       }
//     } finally {
//       _isLoadingCoupons = false;
//       notifyListeners();
//     }
//   }
//
//   // Fallback method to load coupons without context filtering
//   Future<void> _loadCouponsWithoutFiltering({
//     required String restaurantId,
//   }) async {
//     // Prevent multiple simultaneous calls
//     if (_isLoadingCoupons) {
//       print(
//         '[COUPON_LOAD] ⚠️ Fallback coupon load already in progress, skipping...',
//       );
//       return;
//     }
//
//     // Validate restaurant ID
//     if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
//       print('[COUPON_LOAD] ⚠️ Fallback: Skipping - empty restaurant ID');
//       // Use cached coupons if available
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//       return;
//     }
//
//     _isLoadingCoupons = true;
//
//     try {
//       // 🔑 CRITICAL: Detect context BEFORE loading coupons
//       _detectCurrentContext();
//       print(
//         '[COUPON_LOAD] 🔍 Fallback: Loading coupons for vendor: $restaurantId, Context: $_currentContext',
//       );
//
//       // 🔑 CRITICAL: Call the correct API based on context
//       // If mart items in cart → call getMartCoupons API
//       // If restaurant items in cart → call getRestaurantCoupons API
//       final allCoupons = _currentContext == "mart"
//           ? await RestaurantApiHelper.getMartCoupons(
//               restaurantId: restaurantId,
//             ).timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print(
//                   '[COUPON_LOAD] ⏱️ Fallback: Mart coupon API call timed out',
//                 );
//                 return <CouponModel>[];
//               },
//             )
//           : await RestaurantApiHelper.getRestaurantCoupons(
//               restaurantId: restaurantId,
//             ).timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print(
//                   '[COUPON_LOAD] ⏱️ Fallback: Restaurant coupon API call timed out',
//                 );
//                 return <CouponModel>[];
//               },
//             );
//
//       print(
//         '[COUPON_LOAD] ✅ Fallback: Received ${allCoupons.length} coupons from ${_currentContext} API',
//       );
//
//       final filteredGlobalCoupons = allCoupons
//           .where(
//             (c) =>
//                 c.resturantId == null ||
//                 c.resturantId == '' ||
//                 c.resturantId?.toUpperCase() == 'ALL',
//           )
//           .toList();
//
//       final vendorCoupons = allCoupons
//           .where(
//             (c) =>
//                 c.resturantId != null &&
//                 c.resturantId!.isNotEmpty &&
//                 c.resturantId!.toUpperCase() != 'ALL' &&
//                 c.resturantId == restaurantId,
//           )
//           .toList();
//
//       final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
//       final combinedAllCoupons = [...allCoupons];
//
//       _cachedCouponList = combinedCoupons.cast<CouponModel>();
//       _updateCacheTime();
//
//       // Update observable lists
//       couponList = combinedCoupons.cast<CouponModel>();
//       allCouponList = combinedAllCoupons.cast<CouponModel>();
//       // Mark used coupons BEFORE notifying listeners
//       // This ensures coupons are validated before UI shows them
//       await _markUsedCoupons();
//       notifyListeners();
//     } on SocketException catch (e) {
//       print('[COUPON_LOAD] ❌ Fallback: Connection error: $e');
//       // Use cached coupons if available
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } on http.ClientException catch (e) {
//       print(
//         '[COUPON_LOAD] ❌ Fallback: ClientException (connection refused or network error): $e',
//       );
//       // Use cached coupons if available
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } catch (e) {
//       print('[COUPON_LOAD] ❌ Fallback coupon loading also failed: $e');
//       // Check for rate limit (429) or other errors
//       final errorString = e.toString();
//       if (errorString.contains('429') ||
//           errorString.contains('Status code: 429')) {
//         print(
//           '[COUPON_LOAD] ⚠️ Fallback: Rate limit (429) - using cached coupons if available',
//         );
//         if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//           couponList = _cachedCouponList!;
//           allCouponList = _cachedCouponList!;
//           // Mark used coupons before showing cached coupons
//           await _markUsedCoupons();
//           notifyListeners();
//         } else {
//           couponList = [];
//           allCouponList = [];
//           notifyListeners();
//         }
//       } else {
//         // Use cached coupons if available, otherwise empty list
//         if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//           couponList = _cachedCouponList!;
//           allCouponList = _cachedCouponList!;
//           // Mark used coupons before showing cached coupons
//           await _markUsedCoupons();
//           notifyListeners();
//         } else {
//           couponList = [];
//           allCouponList = [];
//           notifyListeners();
//         }
//       }
//     } finally {
//       _isLoadingCoupons = false;
//     }
//   }
//
//   // Detect current context based on cart items
//   // NOTE: This method should NOT call notifyListeners() as it may be called during build
//   void _detectCurrentContext() {
//     try {
//       bool hasMartItems = false;
//       bool hasRestaurantItems = false;
//
//       for (final item in HomeProvider.cartItem) {
//         // Check if item is from mart (you may need to adjust this logic based on your item structure)
//         if (_isMartItem(item)) {
//           hasMartItems = true;
//         } else {
//           hasRestaurantItems = true;
//         }
//       }
//
//       // Determine context based on cart contents
//       if (hasMartItems && !hasRestaurantItems) {
//         _currentContext = "mart";
//       } else if (hasRestaurantItems && !hasMartItems) {
//         _currentContext = "restaurant";
//       } else {
//         // Mixed cart or empty cart - prioritize mart if it has items
//         if (hasMartItems) {
//           _currentContext = "mart";
//         } else {
//           _currentContext = "restaurant";
//         }
//       }
//       // Removed notifyListeners() to prevent setState during build errors
//       // The caller should call notifyListeners() if needed after this method
//     } catch (e) {
//       _currentContext = "restaurant";
//       // Removed notifyListeners() to prevent setState during build errors
//     }
//   }
//
//   // Helper method to determine if an item is from mart
//   // NOTE: This is a pure function and should NEVER call notifyListeners()
//   // It may be called during widget build, so it must not trigger state changes
//   bool _isMartItem(CartProductModel item) {
//     try {
//       if (item.vendorID != null && item.vendorID!.startsWith("mart_")) {
//         return true;
//       }
//
//       if (item.vendorID != null) {
//         final vendorId = item.vendorID!.toLowerCase();
//         if (vendorId.startsWith("demo_") ||
//             vendorId.contains("mart") ||
//             vendorId.contains("vendor")) {
//           return true;
//         }
//       }
//
//       if (item.vendorName != null) {
//         final vendorName = item.vendorName!.toLowerCase();
//         if (vendorName.contains("jippy mart") || vendorName.contains("mart")) {
//           return true;
//         }
//       }
//
//       // Method 4: Check category patterns that indicate mart items
//       if (item.categoryId != null) {
//         final categoryId = item.categoryId!.toLowerCase();
//         if (categoryId.contains("grocery") ||
//             categoryId.contains("mart") ||
//             categoryId.contains("retail")) {
//           return true;
//         }
//       }
//       return false; // Default to restaurant if no mart indicators found
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Check if cart has mart items
//   // NOTE: This is a pure function and should NEVER call notifyListeners()
//   // It may be called during widget build, so it must not trigger state changes
//   bool hasMartItemsInCart() {
//     try {
//       return HomeProvider.cartItem.any((item) => _isMartItem(item));
//     } catch (e) {
//       return false;
//     }
//   }
//
//   bool isMartDeliveryFree() {
//     try {
//       if (!hasMartItemsInCart()) {
//         return false;
//       }
//
//       // 🔑 Use same deliveryChargeModel as restaurant (₹299 threshold from backend)
//       final dc = deliveryChargeModel;
//       final itemThreshold = dc.itemTotalThreshold ?? 299; // Same as restaurant
//       final freeDeliveryKm =
//           dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant
//
//       final isEligible =
//           subTotal >= itemThreshold && totalDistance <= freeDeliveryKm;
//
//       notifyListeners();
//       return isEligible;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Temporary method to force restaurant context for testing
//
//   // Ensure coupons are loaded when cart screen opens
//   void ensureCouponsLoaded() {
//     if (_isLoadingCoupons) {
//       print('[COUPON_LOAD] ⚠️ Coupon load already in progress, skipping...');
//       return;
//     }
//
//     // 🔑 CRITICAL: Detect context FIRST based on cart items (not vendor model)
//     // This ensures correct context even if vendor is not loaded yet
//     _detectCurrentContext();
//     print('[COUPON_LOAD] 🔍 Detected context: $_currentContext');
//
//     if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//       if (couponList.isEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         notifyListeners();
//       }
//       // 🔑 Check if cache is valid AND context matches
//       if (_isCacheValid()) {
//         // Re-filter cached coupons with current context to ensure correct filtering
//         final reFilteredCoupons = CouponFilterService.filterCouponsByContext(
//           coupons: _cachedCouponList!,
//           contextType: _currentContext,
//           fallbackEnabled: true,
//         );
//         if (reFilteredCoupons.length != couponList.length) {
//           // Context changed, need to reload
//           print('[COUPON_LOAD] 🔄 Context changed, reloading coupons...');
//         } else {
//           return; // Cache is still valid and context matches
//         }
//       }
//     }
//
//     // 🔑 Try to get vendor ID - for mart items, vendor might not be loaded yet
//     String? vendorId;
//     if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
//       vendorId = vendorModel.id.toString();
//     } else if (HomeProvider.cartItem.isNotEmpty) {
//       // 🔑 For mart items, try to get vendor ID from cart items
//       final martItems = HomeProvider.cartItem
//           .where((item) => _isMartItem(item))
//           .toList();
//       if (martItems.isNotEmpty) {
//         final firstMartItem = martItems.first;
//         vendorId = firstMartItem.vendorID;
//         print('[COUPON_LOAD] 🔍 Using vendor ID from mart item: $vendorId');
//       } else {
//         // For restaurant items, try to get vendor ID from first item
//         final firstItem = HomeProvider.cartItem.first;
//         vendorId = firstItem.vendorID;
//         print(
//           '[COUPON_LOAD] 🔍 Using vendor ID from restaurant item: $vendorId',
//         );
//       }
//     }
//
//     if (vendorId != null && vendorId.isNotEmpty) {
//       _loadCoupons(restaurantId: vendorId);
//     } else {
//       // No vendor ID available, load global coupons with context filtering
//       _loadGlobalCouponsOnly();
//     }
//   }
//
//   // Load only global coupons when no vendor ID is available
//   Future<void> _loadGlobalCouponsOnly() async {
//     // Prevent multiple simultaneous calls
//     if (_isLoadingCoupons) {
//       print(
//         '[COUPON_LOAD] ⚠️ Global coupon load already in progress, skipping...',
//       );
//       return;
//     }
//
//     _isLoadingCoupons = true;
//
//     try {
//       // 🔑 CRITICAL: Detect context BEFORE loading coupons
//       // This ensures we call the correct API (mart vs restaurant)
//       _detectCurrentContext();
//       print('[COUPON_LOAD] 🔍 Global coupon load - Context: $_currentContext');
//
//       // 🔑 CRITICAL: Call the correct API based on context
//       // If mart items in cart → call getMartCoupons API
//       // If restaurant items in cart → call getRestaurantCoupons API
//       final globalCoupons = _currentContext == "mart"
//           ? await RestaurantApiHelper.getMartCoupons(restaurantId: '').timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print('[COUPON_LOAD] ⏱️ Global mart coupon API call timed out');
//                 return <CouponModel>[];
//               },
//             )
//           : await RestaurantApiHelper.getRestaurantCoupons(
//               restaurantId: '',
//             ).timeout(
//               const Duration(seconds: 10),
//               onTimeout: () {
//                 print(
//                   '[COUPON_LOAD] ⏱️ Global restaurant coupon API call timed out',
//                 );
//                 return <CouponModel>[];
//               },
//             );
//
//       print(
//         '[COUPON_LOAD] ✅ Received ${globalCoupons.length} global coupons from ${_currentContext} API',
//       );
//
//       final filteredGlobalCoupons = globalCoupons
//           .where(
//             (c) =>
//                 c.resturantId == null ||
//                 c.resturantId == '' ||
//                 c.resturantId?.toUpperCase() == 'ALL',
//           )
//           .toList();
//
//       // 🔑 CRITICAL: Filter global coupons by context (mart vs restaurant)
//       final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
//         coupons: filteredGlobalCoupons.cast<CouponModel>(),
//         contextType: _currentContext,
//         fallbackEnabled: true,
//       );
//
//       print(
//         '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} global coupons for context: $_currentContext (from ${filteredGlobalCoupons.length} total)',
//       );
//
//       _cachedCouponList = contextFilteredCoupons;
//       _updateCacheTime();
//
//       // Update observable lists
//       couponList = contextFilteredCoupons;
//       allCouponList = filteredGlobalCoupons.cast<CouponModel>();
//       // Mark used coupons BEFORE notifying listeners
//       // This ensures coupons are validated before UI shows them
//       await _markUsedCoupons();
//       notifyListeners();
//     } on SocketException catch (e) {
//       print('[COUPON_LOAD] ❌ Global: Connection error: $e');
//       // Use cached coupons if available
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } on http.ClientException catch (e) {
//       print('[COUPON_LOAD] ❌ Global: ClientException: $e');
//       // Use cached coupons if available
//       if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//         couponList = _cachedCouponList!;
//         allCouponList = _cachedCouponList!;
//         // Mark used coupons before showing cached coupons
//         await _markUsedCoupons();
//         notifyListeners();
//       } else {
//         couponList = [];
//         allCouponList = [];
//         notifyListeners();
//       }
//     } catch (e) {
//       print('[COUPON_DEBUG] ❌ Error loading global coupons: $e');
//       // Check for rate limit (429) or bad request (400)
//       final errorString = e.toString();
//       if (errorString.contains('429') ||
//           errorString.contains('400') ||
//           errorString.contains('Status code: 429') ||
//           errorString.contains('Status code: 400')) {
//         print(
//           '[COUPON_LOAD] ⚠️ Global: Rate limit or bad request - using cached coupons if available',
//         );
//         if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//           couponList = _cachedCouponList!;
//           allCouponList = _cachedCouponList!;
//           // Mark used coupons before showing cached coupons
//           await _markUsedCoupons();
//           notifyListeners();
//         } else {
//           couponList = [];
//           allCouponList = [];
//           notifyListeners();
//         }
//       } else {
//         // For other errors, try to use cached data
//         if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
//           couponList = _cachedCouponList!;
//           allCouponList = _cachedCouponList!;
//           await _markUsedCoupons();
//           notifyListeners();
//         }
//       }
//     } finally {
//       await Future.delayed(Duration(seconds: 1));
//       _isLoadingCoupons = false;
//     }
//   }
//
//   // Separate method to mark used coupons
//   // Separate method to mark used coupons
//   Future<void> _markUsedCoupons() async {
//     try {
//       final userId = await SqlStorageConst.getFirebaseId();
//       final response = await http.get(
//         Uri.parse('${AppConst.baseUrl}mobile/coupons/used?userId=$userId'),
//         headers: await getHeaders(),
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           final List<dynamic> usedCoupons = responseData['data']['coupons'];
//           final usedCouponIds = usedCoupons
//               .map((coupon) => coupon['couponId'] as String)
//               .toSet();
//           for (var coupon in couponList) {
//             coupon.isEnabled = !usedCouponIds.contains(coupon.id);
//           }
//           for (var coupon in allCouponList) {
//             coupon.isEnabled = !usedCouponIds.contains(coupon.id);
//           }
//           notifyListeners();
//         } else {
//           print('DEBUG: API returned unsuccessful response');
//         }
//       } else {
//         print('DEBUG: Failed to fetch used coupons: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('DEBUG: Error marking used coupons: $e');
//     }
//   }
//
//   Future<void> calculatePrice() async {
//     // 🔑 CRITICAL: Debounce price calculation to prevent continuous updates
//     if (_isCalculatingPrice) {
//       print(
//         '[PRICE_CALC] ⚠️ Price calculation already in progress, skipping duplicate call',
//       );
//       return;
//     }
//
//     // 🔑 FIX: Improved debounce - increase debounce time to prevent rapid calls
//     if (_lastPriceCalculationTime != null) {
//       final timeSinceLastCalc = DateTime.now().difference(
//         _lastPriceCalculationTime!,
//       );
//       // Increased debounce from default to 300ms to prevent UI flickering
//       final debounceTime = Duration(milliseconds: 300);
//       if (timeSinceLastCalc < debounceTime) {
//         print(
//           '[PRICE_CALC] ⚠️ Price calculation debounced (${timeSinceLastCalc.inMilliseconds}ms < ${debounceTime.inMilliseconds}ms)',
//         );
//         // Schedule calculation after debounce period
//         Future.delayed(debounceTime - timeSinceLastCalc, () {
//           if (!_isCalculatingPrice) {
//             calculatePrice();
//           }
//         });
//         return;
//       }
//     }
//
//     _isCalculatingPrice = true;
//     _lastPriceCalculationTime = DateTime.now();
//
//     try {
//       await ANRPrevention.executeWithANRPrevention('CartController_calculatePrice', () async {
//         if (_cachedTaxList != null) {
//           Constant.taxList = _cachedTaxList;
//           // 🔑 REMOVED: notifyListeners() - will call at end
//         } else if (Constant.taxList == null) {
//           Constant.taxList = await FireStoreUtils.getTaxList();
//           _cachedTaxList = Constant.taxList;
//           // 🔑 REMOVED: notifyListeners() - will call at end
//         }
//         print(
//           'DEBUG: Using cached tax list with ${Constant.taxList?.length ?? 0} items',
//         );
//         // 🔑 FIX: Store previous values to prevent UI showing 0 during calculation
//         final previousSubTotal = subTotal;
//         final previousTotalAmount = totalAmount;
//         final previousDeliveryCharges = deliveryCharges;
//         final previousTaxAmount = taxAmount;
//
//         // Reset all values
//         deliveryCharges = 0.0;
//         subTotal = 0.0;
//         couponAmount = 0.0;
//         specialDiscountAmount = 0.0;
//         taxAmount = 0.0;
//         totalAmount = 0.0;
//         // 🔑 REMOVED: notifyListeners() - will call at end
//         if (HomeProvider.cartItem.isEmpty) {
//           _isCalculatingPrice = false;
//           notifyListeners(); // Only notify once when cart is empty
//           return;
//         }
//         if (vendorModel.id == null) {
//           final martItems = HomeProvider.cartItem
//               .where((item) => _isMartItem(item))
//               .toList();
//           if (martItems.isNotEmpty) {
//             print(
//               '[VENDOR_LOAD] 🔧 Fallback: Loading mart vendor in calculatePrice...',
//             );
//             try {
//               final firstMartItem = martItems.first;
//               final vendorId = firstMartItem.vendorID;
//               print(
//                 '[VENDOR_LOAD] 🔧 Fallback: Loading mart vendor for vendorID: $vendorId',
//               );
//
//               MartVendorModel? martVendor;
//
//               if (vendorId != null && vendorId.isNotEmpty) {
//                 // Try to get the specific mart vendor by ID first
//                 martVendor = await MartVendorService.getMartVendorById(
//                   vendorId,
//                 );
//                 if (martVendor != null) {
//                   print(
//                     '[VENDOR_LOAD] ✅ Fallback: Found specific mart vendor: ${martVendor.title} (${martVendor.id})',
//                   );
//                 } else {
//                   print(
//                     '[VENDOR_LOAD] ⚠️ Fallback: Specific mart vendor not found, trying default mart vendor...',
//                   );
//                   // Fallback to default mart vendor
//                   martVendor = await MartVendorService.getDefaultMartVendor();
//                 }
//               } else {
//                 print(
//                   '[VENDOR_LOAD] ⚠️ Fallback: No vendorID in mart item, trying default mart vendor...',
//                 );
//                 martVendor = await MartVendorService.getDefaultMartVendor();
//               }
//               if (martVendor != null) {
//                 // 🔑 FIX: Ensure zoneId is set - use vendor zoneId or fallback to address zoneId
//                 String? finalZoneId = martVendor.zoneId;
//                 if ((finalZoneId == null || finalZoneId.isEmpty) &&
//                     selectedAddress?.zoneId != null &&
//                     selectedAddress!.zoneId!.isNotEmpty) {
//                   finalZoneId = selectedAddress!.zoneId;
//                   print(
//                     '[VENDOR_LOAD] ⚠️ Mart vendor zoneId is missing, using address zoneId: $finalZoneId',
//                   );
//                 } else if ((finalZoneId == null || finalZoneId.isEmpty) &&
//                     Constant.selectedLocation.zoneId != null &&
//                     Constant.selectedLocation.zoneId!.isNotEmpty) {
//                   finalZoneId = Constant.selectedLocation.zoneId;
//                   print(
//                     '[VENDOR_LOAD] ⚠️ Mart vendor zoneId is missing, using Constant.selectedLocation.zoneId: $finalZoneId',
//                   );
//                 }
//                 vendorModel = VendorModel(
//                   id: martVendor.id,
//                   title: martVendor.title,
//                   latitude: martVendor.latitude,
//                   longitude: martVendor.longitude,
//                   isSelfDelivery: false,
//                   // Mart vendors don't have self delivery, use false
//                   vType: martVendor.vType,
//                   zoneId: finalZoneId,
//                   isOpen: martVendor.isOpen,
//                 );
//                 print(
//                   '[VENDOR_LOAD] ✅ Fallback: Mart vendor loaded: ${martVendor.title} (${martVendor.id}) with zoneId: $finalZoneId',
//                 );
//               }
//             } catch (e) {
//               print('[VENDOR_LOAD] ❌ Fallback: Error loading mart vendor: $e');
//             }
//           }
//         }
//
//         // 1. Calculate subtotal first - Use promotional price if available
//         subTotal = 0.0;
//         // 🔑 REMOVED: notifyListeners() - will call at end
//         for (var element in HomeProvider.cartItem) {
//           // Check if this item has a promotional price
//           final hasPromo =
//               element.promoId != null && element.promoId!.isNotEmpty;
//
//           double itemPrice;
//           if (hasPromo) {
//             // Use promotional price for calculations
//             itemPrice = double.parse(element.price.toString());
//           } else if (double.parse(element.discountPrice.toString()) <= 0) {
//             // No promotion, no discount - use regular price
//             itemPrice = double.parse(element.price.toString());
//           } else {
//             // Regular discount (non-promo) - use discount price
//             itemPrice = double.parse(element.discountPrice.toString());
//           }
//
//           final quantity = double.parse(element.quantity.toString());
//           final extrasPrice = double.parse(element.extrasPrice.toString());
//
//           subTotal += (itemPrice * quantity) + (extrasPrice * quantity);
//           // 🔑 CRITICAL: REMOVED notifyListeners() from inside loop - causes continuous updates!
//         }
//
//         if (HomeProvider.cartItem.isNotEmpty) {
//           if (selectedFoodType == "Delivery") {
//             if (selectedAddress?.location?.latitude != null &&
//                 selectedAddress?.location?.longitude != null &&
//                 vendorModel.latitude != null &&
//                 vendorModel.longitude != null) {
//               final customerLat = selectedAddress?.location!.latitude;
//               final customerLng = selectedAddress?.location!.longitude;
//               final vendorLat = vendorModel.latitude!;
//               final vendorLng = vendorModel.longitude!;
//               final distanceString = Constant.getDistance(
//                 lat1: customerLat.toString(),
//                 lng1: customerLng.toString(),
//                 lat2: vendorLat.toString(),
//                 lng2: vendorLng.toString(),
//               );
//               totalDistance = double.parse(distanceString);
//             } else {
//               totalDistance = 0.0;
//             }
//             final hasPromotionalItems = HomeProvider.cartItem.any(
//               (item) => item.promoId != null && item.promoId!.isNotEmpty,
//             );
//             final hasMartItems = hasMartItemsInCart();
//             if (hasPromotionalItems) {
//               calculatePromotionalDeliveryChargeFast();
//             } else if (hasMartItems) {
//               calculateMartDeliveryCharge();
//             } else {
//               calculateRegularDeliveryCharge();
//             }
//           }
//           // 🔑 REMOVED: notifyListeners() - will call at end
//         }
//         // 🔑 REMOVED: notifyListeners() - will call at end
//         CouponModel? activeCoupon;
//         if (selectedCouponModel.id != null &&
//             selectedCouponModel.id!.isNotEmpty) {
//           activeCoupon = selectedCouponModel;
//         } else if (couponCodeController.text.isNotEmpty) {
//           activeCoupon = couponList
//               .where((element) => element.code == couponCodeController.text)
//               .firstOrNull;
//           // 🔑 REMOVED: notifyListeners() - will call at end
//         }
//         final hasPromotionalItems = HomeProvider.cartItem.any((item) {
//           final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//           final discountPriceValue =
//               double.tryParse(item.discountPrice.toString()) ?? 0.0;
//           final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//           final isPricePromotional =
//               priceValue > 0 &&
//               discountPriceValue > 0 &&
//               priceValue < discountPriceValue;
//           return hasPromo || isPricePromotional;
//         });
//
//         if (hasPromotionalItems && activeCoupon != null) {
//           ShowToastDialog.showToast(
//             "Coupons cannot be applied to promotional items".tr,
//           );
//           couponCodeController.text = "";
//           selectedCouponModel = CouponModel();
//           couponAmount = 0.0;
//           // 🔑 REMOVED: notifyListeners() - will call at end
//           print('DEBUG: Coupon removed - cart contains promotional items');
//         } else if (activeCoupon != null) {
//           // Check minimum order value first
//           final minimumValue =
//               double.tryParse(activeCoupon.itemValue ?? '0') ?? 0.0;
//           if (subTotal < minimumValue) {
//             ShowToastDialog.showToast(
//               "Minimum order value for this coupon is ${Constant.amountShow(amount: activeCoupon.itemValue ?? '0')}"
//                   .tr,
//             );
//             couponCodeController.text = "";
//             selectedCouponModel = CouponModel();
//             couponAmount = 0.0;
//           } else {
//             // Calculate coupon discount
//             if (activeCoupon.discountType == "percentage") {
//               couponAmount =
//                   (subTotal * double.parse(activeCoupon.discount.toString())) /
//                   100;
//             } else {
//               couponAmount = double.parse(activeCoupon.discount.toString());
//             }
//             print('DEBUG: Coupon applied successfully - ${activeCoupon.code}');
//           }
//         } else {
//           couponAmount = 0.0;
//         }
//         // 🔑 REMOVED: notifyListeners() - will call at end
//         if (specialDiscountAmount > 0) {
//           specialDiscountAmount = (subTotal * specialDiscountAmount) / 100;
//         }
//         double sgst = 0.0;
//         double gst = 0.0;
//         final hasPromotionalItemsForTax = HomeProvider.cartItem.any(
//           (item) => item.promoId != null && item.promoId!.isNotEmpty,
//         );
//         final hasMartItems = hasMartItemsInCart();
//         // 🔑 FIXED: Calculate tax on base delivery charge + extra km charges
//         // When delivery is free (above ₹299) but distance exceeds free km:
//         // - Customer pays only extra km charge (e.g., ₹14 for 2 km)
//         // - But tax should be calculated on base charge (₹23) + extra km (₹14) = ₹37
//         // originalDeliveryFee already contains base + extra km, so always use it when available
//         final double taxableDeliveryFee = originalDeliveryFee > 0
//             ? originalDeliveryFee
//             : (deliveryCharges > 0 ? deliveryCharges : 0.0);
//
//         print(
//           '[TAX_CALC] Delivery charges (customer pays): ₹$deliveryCharges, Original fee (base + extra km): ₹$originalDeliveryFee, Taxable fee: ₹$taxableDeliveryFee',
//         );
//
//         if (Constant.taxList != null) {
//           for (var element in Constant.taxList!) {
//             if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
//               sgst = Constant.calculateTax(
//                 amount: subTotal.toString(),
//                 taxModel: element,
//               );
//               if (hasPromotionalItemsForTax) {
//               } else if (hasMartItems) {
//               } else {}
//             } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
//               gst = Constant.calculateTax(
//                 amount: taxableDeliveryFee.toString(),
//                 taxModel: element,
//               );
//               if (hasPromotionalItemsForTax) {
//               } else if (hasMartItems) {
//               } else {}
//             }
//           }
//         }
//         sgst = sgst.isNaN ? 0.0 : sgst;
//         gst = gst.isNaN ? 0.0 : gst;
//         taxAmount = sgst + gst;
//         print(
//           '[TAX_CALC] Tax from tax list: SGST: ₹$sgst, GST: ₹$gst, Total: ₹$taxAmount',
//         );
//         if (taxAmount == 0.0) {
//           double sgstFallback = subTotal * 0.05; // 5% on subtotal
//           double gstFallback = taxableDeliveryFee > 0
//               ? taxableDeliveryFee *
//                     0.18 // 18% on delivery charges or base charge (even when free delivery)
//               : 0.0;
//           taxAmount = sgstFallback + gstFallback;
//           print(
//             '[TAX_CALC] Fallback tax applied → SGST (5% of ₹$subTotal): ₹$sgstFallback, GST (18% of ₹$taxableDeliveryFee): ₹$gstFallback, Total: ₹$taxAmount',
//           );
//         }
//         if (taxAmount.isNaN) taxAmount = 0.0;
//         print("Fallback tax applied → SGST:: $taxAmount");
//         // sgst = (sgst.isNaN) ? 0.0 : sgst;
//         // gst = (gst.isNaN) ? 0.0 : gst;
//         // taxAmount = sgst + gst;
//         // print("taxAmount = $taxAmount (SGST: $sgst, GST: $gst)");
//         //
//         // if (taxAmount.isNaN) taxAmount = 0.0;
//
//         // if (taxAmount == 0.0) {
//         //   double sgsts = subTotal * 0.05;
//         //   double gsts = originalDeliveryFee * 0.18;
//         //   taxAmount = sgsts + gsts;
//         // }
//         print("taxAmounttaxAmount  $taxAmount");
//         // 🔑 REMOVED: notifyListeners() - will call at end
//         if (hasPromotionalItemsForTax) {
//         } else if (hasMartItems) {
//         } else {}
//         bool isFreeDelivery = false;
//         if (HomeProvider.cartItem.isNotEmpty &&
//             selectedFoodType == "Delivery") {
//           // Check if cart has promotional items or mart items
//           final hasPromotionalItems = HomeProvider.cartItem.any(
//             (item) => item.promoId != null && item.promoId!.isNotEmpty,
//           );
//           final hasMartItems = hasMartItemsInCart();
//           if (hasPromotionalItems) {
//             final promotionalItems = HomeProvider.cartItem
//                 .where(
//                   (item) => item.promoId != null && item.promoId!.isNotEmpty,
//                 )
//                 .toList();
//             final firstPromoItem = promotionalItems.first;
//
//             // Use cached data instead of Firebase query - INSTANT RESPONSE
//             final freeDeliveryKm = _getCachedFreeDeliveryKm(
//               firstPromoItem.id ?? '',
//               firstPromoItem.vendorID ?? '',
//             );
//
//             if (totalDistance <= freeDeliveryKm) {
//               isFreeDelivery = true;
//             }
//
//             // 🔑 REMOVED: notifyListeners() - will call at end
//           } else if (hasMartItems) {
//             // 🔑 Use same deliveryChargeModel as restaurant (₹299 threshold from backend)
//             final dc = deliveryChargeModel;
//             final threshold =
//                 dc.itemTotalThreshold ?? 299; // Same as restaurant
//             final freeKm = dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant
//             if (subTotal >= threshold && totalDistance <= freeKm) {
//               isFreeDelivery = true;
//             } else {
//               isFreeDelivery = false;
//             }
//             // 🔑 REMOVED: notifyListeners() - will call at end
//           } else {
//             // For regular items, use regular delivery settings
//             final dc = deliveryChargeModel;
//             final subtotal = subTotal;
//             final threshold = dc.itemTotalThreshold ?? 299;
//             final freeKm = dc.freeDeliveryDistanceKm ?? 7;
//             if (subtotal >= threshold && totalDistance <= freeKm) {
//               isFreeDelivery = true;
//               // 🔑 REMOVED: notifyListeners() - will call at end
//             }
//             // 🔑 REMOVED: notifyListeners() - will call at end
//           }
//           // 🔑 REMOVED: notifyListeners() - will call at end
//         }
//         totalAmount =
//             (subTotal - couponAmount - specialDiscountAmount) +
//             taxAmount +
//             (isFreeDelivery ? 0.0 : deliveryCharges) +
//             deliveryTips +
//             surgePercent;
//
//         // 🔑 FIX: Ensure values are valid before updating UI
//         // If calculation resulted in invalid values, keep previous values
//         // Also check for zero values when cart is not empty (indicates calculation error)
//         final bool isCartEmpty = HomeProvider.cartItem.isEmpty;
//         final bool hasInvalidValues =
//             subTotal < 0 ||
//             totalAmount < 0 ||
//             subTotal.isNaN ||
//             totalAmount.isNaN ||
//             subTotal.isInfinite ||
//             totalAmount.isInfinite ||
//             (!isCartEmpty && (subTotal == 0.0 || totalAmount == 0.0));
//
//         if (hasInvalidValues) {
//           print(
//             '[PRICE_CALC] ⚠️ Invalid values calculated (subTotal: $subTotal, totalAmount: $totalAmount, cartEmpty: $isCartEmpty), restoring previous values',
//           );
//           subTotal = previousSubTotal;
//           totalAmount = previousTotalAmount;
//           deliveryCharges = previousDeliveryCharges;
//           taxAmount = previousTaxAmount;
//         }
//
//         checkAndUpdatePaymentMethod();
//         // 🔑 CRITICAL: Only ONE notifyListeners() call at the very end
//         notifyListeners();
//       }, timeout: const Duration(seconds: 5));
//     } finally {
//       _isCalculatingPrice = false;
//     }
//   }
//
//   void calculatePromotionalDeliveryChargeFast() {
//     final promotionalItems = HomeProvider.cartItem
//         .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
//         .toList();
//
//     if (promotionalItems.isEmpty) {
//       print('DEBUG: No promotional items found, using regular delivery charge');
//       calculateRegularDeliveryCharge();
//       return;
//     }
//     final firstPromoItem = promotionalItems.first;
//     final freeDeliveryKm = _getCachedFreeDeliveryKm(
//       firstPromoItem.id ?? '',
//       firstPromoItem.vendorID ?? '',
//     );
//     final extraKmCharge = _getCachedExtraKmCharge(
//       firstPromoItem.id ?? '',
//       firstPromoItem.vendorID ?? '',
//     );
//     final baseCharge = 23.0; // Base delivery charge for promotional items
//     //finded
//     _calculateDeliveryCharge(
//       orderType: 'promotional',
//       freeDeliveryKm: freeDeliveryKm,
//       perKmCharge: extraKmCharge,
//       baseCharge: baseCharge,
//       logPrefix: '[PROMOTIONAL_DELIVERY]',
//     );
//     // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
//   }
//
//   void _calculateDeliveryCharge({
//     required String orderType,
//     required double freeDeliveryKm,
//     required double perKmCharge,
//     required double baseCharge,
//     required String logPrefix,
//   }) {
//     if (vendorModel.isSelfDelivery == true &&
//         Constant.isSelfDeliveryFeature == true) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = 0.0;
//     } else if (totalDistance <= freeDeliveryKm) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = baseCharge;
//     } else {
//       double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
//       deliveryCharges = extraKm * perKmCharge;
//       // Always calculate tax on base charge (₹23) + extra charges for all order types
//       originalDeliveryFee = baseCharge + deliveryCharges;
//     }
//     // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
//   }
//
//   /// Calculate delivery charge for mart items - Use same backend settings as restaurant
//   void calculateMartDeliveryCharge() {
//     // Get mart items from cart
//     final martItems = HomeProvider.cartItem
//         .where((item) => _isMartItem(item))
//         .toList();
//     notifyListeners();
//     if (martItems.isEmpty) {
//       calculateRegularDeliveryCharge();
//       return;
//     }
//     _calculateMartDeliveryWithBackendSettings();
//   }
//
//   /// 🔑 Calculate mart delivery using same backend settings as restaurant
//   void _calculateMartDeliveryWithBackendSettings() {
//     // Use same deliveryChargeModel as restaurant items
//     final dc = deliveryChargeModel;
//     final subtotal = subTotal;
//     final threshold = dc.itemTotalThreshold ?? 299; // Same as restaurant (₹299)
//     final baseCharge = dc.baseDeliveryCharge ?? 23;
//     final freeKm = dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant
//     final perKm = dc.perKmChargeAboveFreeDistance ?? 8; // Same as restaurant
//     final distance = totalDistance;
//
//     print("_calculateMartDeliveryWithBackendSettings $threshold ");
//     if (vendorModel.isSelfDelivery == true &&
//         Constant.isSelfDeliveryFeature == true) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = 0.0;
//     } else if (subtotal < threshold) {
//       // Below threshold - regular paid delivery
//       if (distance <= freeKm) {
//         deliveryCharges = baseCharge.toDouble();
//         originalDeliveryFee = baseCharge.toDouble();
//       } else {
//         double extraKm = (distance - freeKm).ceilToDouble();
//         deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
//         originalDeliveryFee = deliveryCharges;
//       }
//     } else {
//       if (distance <= freeKm) {
//         deliveryCharges = 0.0;
//         originalDeliveryFee = baseCharge.toDouble();
//       } else {
//         double extraKm = (distance - freeKm).ceilToDouble();
//         originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
//         deliveryCharges = (extraKm * perKm).toDouble();
//       }
//     }
//     print(
//       "calculateMartDeliveryCharge ${deliveryCharges} (threshold: ₹$threshold, subtotal: ₹$subtotal)",
//     );
//     // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
//   }
//
//   /// Fetch mart delivery charge settings from Firestore
//   Future<Map<String, dynamic>?> _fetchMartDeliveryChargeSettings() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${AppConst.baseUrl}mobile/settings/mart-delivery-charge'),
//         headers: await getHeaders(),
//       );
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           final data = responseData['data'];
//           return data;
//         } else {
//           return null;
//         }
//       } else {
//         return null;
//       }
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Calculate delivery charge for regular (non-promotional) items
//   ///
//   //finded here
//   void calculateRegularDeliveryCharge() {
//     final dc = deliveryChargeModel;
//     final subtotal = subTotal;
//     final threshold = dc.itemTotalThreshold ?? 299;
//     final baseCharge = dc.baseDeliveryCharge ?? 23;
//     final freeKm = dc.freeDeliveryDistanceKm ?? 7;
//     final perKm = dc.perKmChargeAboveFreeDistance ?? 8;
//     print("calculateRegularDeliveryCharge ${threshold} ");
//     if (vendorModel.isSelfDelivery == true &&
//         Constant.isSelfDeliveryFeature == true) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = 0.0;
//     } else if (subtotal < threshold) {
//       if (totalDistance <= freeKm) {
//         deliveryCharges = baseCharge.toDouble();
//         originalDeliveryFee = baseCharge.toDouble();
//       } else {
//         double extraKm = (totalDistance - freeKm).ceilToDouble();
//         deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
//         originalDeliveryFee = deliveryCharges;
//       }
//     } else {
//       // Above threshold - free delivery within distance
//       if (totalDistance <= freeKm) {
//         deliveryCharges = 0.0;
//         originalDeliveryFee = baseCharge.toDouble();
//       } else {
//         double extraKm = (totalDistance - freeKm).ceilToDouble();
//         originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
//         deliveryCharges = (extraKm * perKm).toDouble();
//       }
//     }
//     print("calculateRegularDeliveryCharge ${deliveryCharges} ");
//     // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
//   }
//
//   Future<bool> addToCart({
//     required CartProductModel cartProductModel,
//     required bool isIncrement,
//     required int quantity,
//   }) async {
//     // Check if user is logged in before adding to cart (only for increment)
//     if (isIncrement) {
//       final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//       if (!isLoggedIn) {
//         _showLoginRequiredDialog(Get.context!);
//         return false;
//       }
//     }
//
//     if (isIncrement) {
//       if (cartProductModel.promoId != null &&
//           cartProductModel.promoId!.isNotEmpty) {
//         final isAllowed = isPromotionalItemQuantityAllowed(
//           cartProductModel.id ?? '',
//           cartProductModel.vendorID ?? '',
//           quantity,
//         );
//         if (!isAllowed) {
//           final limit = getPromotionalItemLimit(
//             cartProductModel.id ?? '',
//             cartProductModel.vendorID ?? '',
//           );
//           ShowToastDialog.showToast(
//             "Maximum $limit items allowed for this promotional offer".tr,
//           );
//           return false;
//         }
//       }
//       final success = await cartProvider.addToCart(
//         Get.context!,
//         cartProductModel,
//         quantity,
//       );
//       notifyListeners();
//       if (!success) {
//         return false;
//       }
//     } else {
//       print("addToCart removeFromCart");
//       cartProvider.removeFromCart(cartProductModel, quantity);
//       notifyListeners();
//     }
//     // 🔑 OPTIMIZED: Only refresh prices and load new products incrementally
//     // Don't clear cache or reload everything
//     await _incrementalCartUpdate();
//     notifyListeners();
//     return true;
//   }
//
//   void _showLoginRequiredDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return CustomDialogBox(
//           title: "Login Required".tr,
//           descriptions:
//               "Please login to add items to your cart and continue shopping."
//                   .tr,
//           positiveString: "Login".tr,
//           negativeString: "Cancel".tr,
//           positiveClick: () {
//             Get.back(); // Close dialog
//             Get.to(() => PhoneNumberScreen());
//           },
//           negativeClick: () {
//             Get.back(); // Close dialog
//           },
//           img: Image.asset(
//             'assets/images/ic_launcher.png',
//             height: 50,
//             width: 50,
//           ),
//         );
//       },
//     );
//   }
//
//   /// 🔑 OPTIMIZED: Incremental cart update - only loads new products and recalculates prices
//   /// This is much faster than forceRefreshCart() which clears cache
//   Future<void> _incrementalCartUpdate() async {
//     try {
//       // Load any new products that aren't cached yet (incremental loading)
//       await _loadNewProductsIncrementally();
//       // Recalculate prices (this is fast, no network calls)
//       await calculatePrice();
//       // Update payment method if needed
//       checkAndUpdatePaymentMethod();
//
//       // Update cart readiness
//       updateCartReadiness();
//
//       notifyListeners();
//     } catch (e) {
//       print('[CART_UPDATE] Error in incremental update: $e');
//       // Fallback to full refresh only on error
//       await forceRefreshCart();
//     }
//   }
//
//   /// 🔑 Load only new products that aren't in cache (incremental loading)
//   Future<void> _loadNewProductsIncrementally() async {
//     try {
//       // Get all product IDs from current cart
//       final Set<String> productIds = {};
//       for (final cartItem in HomeProvider.cartItem) {
//         if (cartItem.id != null &&
//             cartItem.id!.isNotEmpty &&
//             cartItem.id!.toLowerCase() != 'null') {
//           final parts = cartItem.id!.split('~');
//           if (parts.isNotEmpty &&
//               parts.first.isNotEmpty &&
//               parts.first.toLowerCase() != 'null') {
//             productIds.add(parts.first);
//           }
//         }
//       }
//
//       // Find products that need to be loaded (not in cache)
//       final Set<String> productsToLoad = productIds
//           .where((id) => !_productCache.containsKey(id))
//           .toSet();
//
//       if (productsToLoad.isEmpty) {
//         // All products already cached - no loading needed
//         return;
//       }
//
//       // Load new products in parallel (non-blocking)
//       // Don't set _isLoadingProducts to true here to avoid blocking UI
//       final List<Future<void>> loadFutures = productsToLoad.map((
//         productId,
//       ) async {
//         try {
//           // Check if it's a mart item
//           final isMartItem = _isMartItem(
//             HomeProvider.cartItem.firstWhere(
//               (item) => item.id?.split('~').first == productId,
//               orElse: () => CartProductModel(),
//             ),
//           );
//
//           ProductModel? product;
//           if (isMartItem) {
//             // For mart items, we don't have ProductModel - use cart data
//             // Mart items are displayed using cartProductModel data
//             _productCache[productId] =
//                 null; // Mark as loaded (null = use cart data)
//           } else {
//             // For restaurant items, fetch ProductModel
//             product = await FireStoreUtils.getProductById(productId);
//             _productCache[productId] = product;
//           }
//
//           // Notify listeners after each product loads (for progressive rendering)
//           notifyListeners();
//         } catch (e) {
//           print('[CART_PRODUCT] Error loading product $productId: $e');
//           _productCache[productId] = null; // Mark as loaded even on error
//         }
//       }).toList();
//
//       // Wait for all new products to load
//       await Future.wait(loadFutures);
//
//       _productsLoaded = true;
//       notifyListeners();
//       print(
//         '[CART_PRODUCT] Incrementally loaded ${productsToLoad.length} new products',
//       );
//     } catch (e) {
//       print('[CART_PRODUCT] Error in incremental product loading: $e');
//     }
//   }
//
//   List<CartProductModel> tempProduc = [];
//
//   /// Check if order is already in progress (idempotency)
//   // bool _isOrderInProgress() {
//   //   return _orderInProgress || isProcessingOrder;
//   // }
//
//   /// Start order processing with idempotency
//   void _startOrderProcessing() {
//     _orderInProgress = true;
//     isProcessingOrder = true;
//     notifyListeners();
//   }
//
//   /// End order processing
//   void _endOrderProcessing() {
//     _orderInProgress = false;
//     isProcessingOrder = false;
//     notifyListeners();
//   }
//
//   /// Public method to start order processing (for use in widgets)
//   void startOrderProcessing() {
//     _startOrderProcessing();
//   }
//
//   ///finded
//
//   placeOrder(BuildContext context) async {
//     // if (_isOrderInProgress()) {
//     //   ShowToastDialog.showToast(
//     //     "Order is already being processed. Please wait...".tr,
//     //   );
//     //   return;
//     // }
//     if (lastOrderAttempt != null &&
//         DateTime.now().difference(lastOrderAttempt!) < orderDebounceTime) {
//       ShowToastDialog.showToast("Please wait before trying again...".tr);
//       return;
//     }
//     _startOrderProcessing();
//     lastOrderAttempt = DateTime.now();
//     // 🔑 FIXED: Don't reset deliveryTips here - user has already selected the tip amount
//     // Tips should only be reset when cart screen initializes (for new order sessions)
//     try {
//       if (!await validateOrderBeforePayment(context)) {
//         _endOrderProcessing();
//         return;
//       }
//
//       // 🔑 CRITICAL: Validate calculations before placing order
//       // Ensure all values are valid and not zero
//       if (HomeProvider.cartItem.isEmpty) {
//         ShowToastDialog.showToast(
//           "Cart is empty. Please add items to cart.".tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       // Recalculate price to ensure latest values
//       await calculatePrice();
//
//       // Validate calculations are valid
//       if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
//         print('❌ [ORDER_VALIDATION] Invalid subTotal: $subTotal');
//         ShowToastDialog.showToast(
//           "Order calculation error. Please refresh and try again.".tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       if (totalAmount <= 0 || totalAmount.isNaN || totalAmount.isInfinite) {
//         print('❌ [ORDER_VALIDATION] Invalid totalAmount: $totalAmount');
//         ShowToastDialog.showToast(
//           "Order total is invalid. Please refresh and try again.".tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       // Validate cart items have valid prices
//       bool hasInvalidItems = false;
//       for (var item in HomeProvider.cartItem) {
//         final itemPrice = double.tryParse(item.price ?? '0') ?? 0.0;
//         if (itemPrice <= 0 || itemPrice.isNaN) {
//           hasInvalidItems = true;
//           print(
//             '❌ [ORDER_VALIDATION] Invalid item price: ${item.name} - ${item.price}',
//           );
//           break;
//         }
//       }
//
//       if (hasInvalidItems) {
//         ShowToastDialog.showToast(
//           "Some items have invalid prices. Please refresh and try again.".tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       print(
//         '✅ [ORDER_VALIDATION] Calculations validated - SubTotal: ₹$subTotal, Total: ₹$totalAmount',
//       );
//
//       // 🔑 CRITICAL: Validate payment method is selected
//       if (selectedPaymentMethod.isEmpty) {
//         ShowToastDialog.showToast("Please select payment method".tr);
//         endOrderProcessing();
//         return;
//       }
//
//       // 🔑 CRITICAL: For Razorpay, ensure payment was completed
//       if (selectedPaymentMethod == PaymentGateway.razorpay.name) {
//         if (!isPaymentCompleted || _lastPaymentId == null) {
//           ShowToastDialog.showToast(
//             "Payment not completed. Please complete payment before placing order."
//                 .tr,
//           );
//           endOrderProcessing();
//           return;
//         }
//       }
//
//       // 🔑 CRITICAL: Validate COD is enabled before allowing COD orders
//       if (selectedPaymentMethod == PaymentGateway.cod.name) {
//         if (cashOnDeliverySettingModel.isEnabled != true) {
//           ShowToastDialog.showToast(
//             "Cash on Delivery is currently disabled. Please select another payment method."
//                 .tr,
//           );
//           endOrderProcessing();
//           return;
//         }
//       }
//
//       if (selectedPaymentMethod == PaymentGateway.cod.name &&
//           subTotal > cashOnDeliverySettingModel.getMaxAmount()) {
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select another payment method."
//               .tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//       if (selectedPaymentMethod == PaymentGateway.cod.name &&
//           hasPromotionalItems()) {
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for promotional items. Please select another payment method."
//               .tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//       if (isPaymentCompleted &&
//           _lastPaymentId != null &&
//           (selectedPaymentMethod.isEmpty ||
//               selectedPaymentMethod == PaymentGateway.cod.name)) {
//         selectedPaymentMethod = PaymentGateway.razorpay.name;
//       }
//       if (selectedPaymentMethod == PaymentGateway.wallet.name) {
//         if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
//           await setOrder();
//         } else {
//           ShowToastDialog.showToast(
//             "You don't have sufficient wallet balance to place order".tr,
//           );
//           endOrderProcessing();
//         }
//       } else {
//         await setOrder();
//       }
//     } catch (e) {
//       print('DEBUG: Error in placeOrder: $e');
//       if (e.toString().contains('Delivery zone validation failed') ||
//           e.toString().contains('Delivery distance validation failed')) {
//       } else {
//         ShowToastDialog.showToast(
//           "An error occurred while placing your order. Please try again.".tr,
//         );
//       }
//       endOrderProcessing();
//     }
//     notifyListeners();
//   }
//
//   // Validate order before payment to prevent payment without order
//   // Validate order before payment to prevent payment without order
//   Future<bool> validateOrderBeforePayment(BuildContext context) async {
//     try {
//       if (HomeProvider.cartItem.isEmpty) {
//         ShowToastDialog.showToast(
//           "Your cart is empty. Please add items before placing order.".tr,
//         );
//         return false;
//       }
//       try {
//         await validateMinimumOrderValue();
//       } catch (e) {
//         return false;
//       }
//       final addressValid = await _validateAddressBulletproof(context);
//       if (!addressValid) {
//         return false;
//       }
//
//       if (vendorModel.id != null) {
//         final latestVendor = await FireStoreUtils.getVendorById(
//           vendorModel.id!,
//         );
//         if (latestVendor != null) {
//           if (latestVendor.vType == 'mart') {
//             if (latestVendor.isOpen == false) {
//               ShowToastDialog.showToast(
//                 "Jippy Mart is temporarily closed. Please try again later.",
//               );
//               return false;
//             }
//           } else {
//             // For restaurant vendors, use restaurant status system
//             if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
//               // final status = RestaurantStatusUtils.getRestaurantStatus(
//               //   latestVendor,
//               // );
//               ShowToastDialog.showToast("Restaurant Closed");
//               return false;
//             }
//           }
//         }
//       } else {
//         // Handle case where vendor model is not set (e.g., mart items)
//       }
//
//       // First, validate all items in cart for availability
//       for (var item in HomeProvider.cartItem) {
//         bool isMartItem = item.vendorID?.startsWith('mart_') == true;
//
//         if (isMartItem) {
//           // For mart items, fetch from API instead of Firebase
//           try {
//             // final martItems = await getMartItems();
//             // final martItem = martItems.firstWhere(
//             //       (mart) => mart.id == item.id!,
//             //   orElse: () => MartItemModel(),
//             // );
//             final martItems = await MartFirestoreService().getMartItems();
//             final martItem = martItems.firstWhere(
//               (mart) => mart.id == item.id!,
//               orElse: () => MartItemModel(
//                 id: '',
//                 name: '',
//                 description: '',
//                 price: 0,
//                 photo: '',
//                 isAvailable: false,
//                 publish: false,
//                 veg: false,
//                 nonveg: false,
//                 quantity: 0,
//               ),
//             );
//
//             final availableQuantity = martItem.quantity;
//             final orderedQuantity = item.quantity ?? 0;
//             if (availableQuantity != -1 &&
//                 availableQuantity < orderedQuantity) {
//               final itemName = martItem.displayName;
//               ShowToastDialog.showToast(
//                 "$itemName is out of stock. Available: $availableQuantity, Ordered: $orderedQuantity",
//               );
//               return false;
//             }
//           } catch (e) {
//             print('[ORDER VALIDATION] ❌ Error validating mart items: $e');
//             ShowToastDialog.showToast(
//               "Error validating mart items. Please try again.",
//             );
//             return false;
//           }
//         } else {
//           final productId = item.id;
//           if (productId == null ||
//               productId.isEmpty ||
//               productId == 'null' ||
//               productId.trim().isEmpty) {
//             print('[CART_VALIDATION] Invalid product ID: $productId');
//             ShowToastDialog.showToast(
//               "Some items in your cart have invalid product information.".tr,
//             );
//             return false;
//           }
//           // Extract base product ID if it contains variant separator
//           final baseProductId = productId.contains('~')
//               ? productId.split('~').first
//               : productId;
//
//           final product = await FireStoreUtils.getProductById(baseProductId);
//           if (product == null) {
//             ShowToastDialog.showToast(
//               "Some items in your cart are no longer available.".tr,
//             );
//             return false;
//           }
//
//           // Check stock availability (skip unlimited stock items)
//           if (product.quantity != -1) {
//             int availableQuantity = product.quantity ?? 0;
//             int orderedQuantity = item.quantity ?? 0;
//
//             if (availableQuantity < orderedQuantity) {
//               ShowToastDialog.showToast(
//                 "${product.name} is out of stock. Available: $availableQuantity, Ordered: $orderedQuantity"
//                     .tr,
//               );
//               return false;
//             }
//           }
//         }
//       }
//       for (int i = 0; i < tempProduc.length; i++) {
//         // Check if this is a mart item (has 'mart_' prefix in vendorID)
//         bool isMartItem = tempProduc[i].vendorID?.startsWith('mart_') == true;
//
//         if (isMartItem) {
//           // TODO: You'll need to implement an API endpoint to update mart item quantities
//           // For now, we'll skip the quantity update for mart items via API
//           // since getMartItems() is a GET request and doesn't update quantities
//           print(
//             '[ORDER VALIDATION] ⚠️ Mart item quantity update skipped - API update needed',
//           );
//           // If you have an API endpoint to update quantities, you would call it here:
//           // await updateMartItemQuantity(tempProduc[i].id!.split('~').first, tempProduc[i].quantity!);
//         } else {
//           await FireStoreUtils.getProductById(
//             tempProduc[i].id!.split('~').first,
//           ).then((value) async {
//             ProductModel? productModel = value;
//             if (tempProduc[i].variantInfo != null) {
//               if (productModel!.itemAttribute != null) {
//                 for (
//                   int j = 0;
//                   j < productModel.itemAttribute!.variants!.length;
//                   j++
//                 ) {
//                   if (productModel.itemAttribute!.variants![j].variantId ==
//                       tempProduc[i].id!.split('~').last) {
//                     if (productModel
//                             .itemAttribute!
//                             .variants![j]
//                             .variantQuantity !=
//                         "-1") {
//                       int newVariantQuantity =
//                           int.parse(
//                             productModel
//                                 .itemAttribute!
//                                 .variants![j]
//                                 .variantQuantity
//                                 .toString(),
//                           ) -
//                           tempProduc[i].quantity!;
//                       if (newVariantQuantity < 0) newVariantQuantity = 0;
//                       productModel.itemAttribute!.variants![j].variantQuantity =
//                           newVariantQuantity.toString();
//                     }
//                   }
//                 }
//               } else {
//                 if (productModel.quantity != -1) {
//                   int newQuantity =
//                       productModel.quantity! - tempProduc[i].quantity!;
//                   if (newQuantity < 0) newQuantity = 0;
//                   productModel.quantity = newQuantity;
//                 }
//               }
//             } else {
//               if (productModel!.quantity != -1) {
//                 int newQuantity =
//                     productModel.quantity! - tempProduc[i].quantity!;
//                 if (newQuantity < 0) newQuantity = 0;
//                 productModel.quantity = newQuantity;
//               }
//             }
//
//             await FireStoreUtils.setProduct(productModel);
//           });
//         }
//         notifyListeners();
//       }
//
//       notifyListeners();
//       return true;
//     } catch (e) {
//       // Check if this is a zone validation error and show specific message
//       if (e.toString().contains('Delivery zone validation failed') ||
//           e.toString().contains('Delivery distance validation failed')) {
//         // Handle zone validation errors if needed
//       } else {
//         // Generic validation error
//         ShowToastDialog.showToast(
//           "Error validating order. Please try again.".tr,
//         );
//       }
//       notifyListeners();
//       return false;
//     }
//   }
//
//   // Rollback mechanism for failed orders
//   Future<void> rollbackFailedOrder(
//     String orderId,
//     List<CartProductModel> products,
//   ) async {
//     try {
//       // Prepare the request body
//       final Map<String, dynamic> requestBody = {
//         "order_id": orderId,
//         "products": products
//             .map((product) => {"id": product.id, "quantity": product.quantity})
//             .toList(),
//       };
//       final response = await http.post(
//         Uri.parse('${AppConst.baseUrl}/mobile/orders/rollback-failed'),
//         headers: await getHeaders(),
//         body: jsonEncode(requestBody),
//       );
//       if (response.statusCode == 200) {
//         print('Order rollback successful for order: $orderId');
//         notifyListeners();
//       } else {
//         // Handle API error
//         print('Failed to rollback order: ${response.statusCode}');
//         throw Exception('Failed to rollback order: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error rolling back order: $e');
//       // Re-throw the exception or handle it as needed
//       rethrow;
//     }
//   }
//
//   /// finderone
//   setOrder() async {
//     await FireStoreUtils.getVendorById(vendorModel.id ?? '');
//     if (vendorModel.id != null) {
//       final latestVendor = await FireStoreUtils.getVendorById(
//         vendorModel.id.toString(),
//       );
//       if (latestVendor != null) {
//         if (latestVendor.vType == 'mart') {
//           if (latestVendor.isOpen == false) {
//             ShowToastDialog.closeLoader();
//             ShowToastDialog.showToast(
//               "Jippy Mart is temporarily closed. Please try again later.",
//             );
//             endOrderProcessing();
//             return;
//           }
//         } else {
//           if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
//             ShowToastDialog.closeLoader();
//             ShowToastDialog.showToast("Restaurant Closed");
//             endOrderProcessing();
//             return;
//           }
//         }
//       }
//     } else {}
//     notifyListeners();
//     return await _setOrderInternal();
//   }
//
//   void providerInitializer({required BuildContext context}) {
//     orderPlacingProvider = Provider.of<OrderPlacingProvider>(
//       context,
//       listen: false,
//     );
//   }
//
//   ///issue finded
//   Future<void> _setOrderInternal() async {
//     // 🔑 CRITICAL: Prevent concurrent order creation at the API level
//     // Only block if it's the SAME payment ID - allow different payment IDs to proceed
//     if (_isOrderCreationInProgress &&
//         _currentOrderPaymentId == _lastPaymentId) {
//       print(
//         '⚠️ [ORDER_CREATION] Order creation already in progress for payment ID $_lastPaymentId, preventing duplicate',
//       );
//       return; // Prevent concurrent order creation for same payment
//     }
//     // 🔑 CRITICAL: Check cooldown period to prevent rapid duplicate calls
//     // Only apply cooldown if it's the SAME payment ID
//     if (_lastOrderCreationTime != null &&
//         _currentOrderPaymentId == _lastPaymentId) {
//       final timeSinceLastOrder = DateTime.now().difference(
//         _lastOrderCreationTime!,
//       );
//       if (timeSinceLastOrder < _orderCreationCooldown) {
//         print(
//           '⚠️ [ORDER_CREATION] Order creation cooldown active, preventing duplicate for payment ID: $_lastPaymentId',
//         );
//         return; // Prevent duplicate orders within cooldown period
//       }
//     }
//
//     // Set static lock immediately - this prevents other instances from creating orders
//     _isOrderCreationInProgress = true;
//     _currentOrderPaymentId = _lastPaymentId;
//     _lastOrderCreationTime = DateTime.now();
//
//     print(
//       '✅ [ORDER_CREATION] Starting order creation for payment ID: $_lastPaymentId',
//     );
//
//     // 🔑 CRITICAL: Final validation before creating order
//     // Ensure calculations are valid and not zero
//     if (HomeProvider.cartItem.isEmpty) {
//       print('❌ [ORDER_CREATION] Cart is empty, cannot create order');
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Cart is empty. Please add items to cart.".tr);
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//       endOrderProcessing();
//       return;
//     }
//
//     // Recalculate to ensure latest values
//     await calculatePrice();
//
//     if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
//       print(
//         '❌ [ORDER_CREATION] Invalid subTotal: $subTotal, cannot create order',
//       );
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast(
//         "Order calculation error. Please refresh and try again.".tr,
//       );
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//       endOrderProcessing();
//       return;
//     }
//
//     if (totalAmount <= 0 || totalAmount.isNaN || totalAmount.isInfinite) {
//       print(
//         '❌ [ORDER_CREATION] Invalid totalAmount: $totalAmount, cannot create order',
//       );
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast(
//         "Order total is invalid. Please refresh and try again.".tr,
//       );
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//       endOrderProcessing();
//       return;
//     }
//
//     print(
//       '✅ [ORDER_CREATION] Final validation passed - SubTotal: ₹$subTotal, Total: ₹$totalAmount',
//     );
//
//     String? orderId;
//     List<CartProductModel> orderedProducts = [];
//     OrderModel? orderModel;
//     try {
//       tempProduc.clear();
//       if ((Constant.isSubscriptionModelApplied == true ||
//               Constant.adminCommission?.isEnabled == true) &&
//           vendorModel.subscriptionPlan != null &&
//           vendorModel.id != null) {
//         final vender = await FireStoreUtils.getVendorById(
//           vendorModel.id.toString(),
//         );
//         if (vender?.subscriptionTotalOrders == '0' ||
//             vender?.subscriptionTotalOrders == null) {
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast(
//             "This vendor has reached their maximum order capacity. Please select a different vendor or try again later."
//                 .tr,
//           );
//           endOrderProcessing();
//           return;
//         }
//       }
//       for (CartProductModel cartProduct in HomeProvider.cartItem) {
//         CartProductModel tempCart = cartProduct;
//         if (cartProduct.extrasPrice == '0') {
//           tempCart.extras = [];
//         }
//         tempProduc.add(tempCart);
//         orderedProducts.add(tempCart);
//         notifyListeners();
//       }
//       Map<String, dynamic> specialDiscountMap = {
//         'special_discount': specialDiscountAmount,
//         'special_discount_label': specialDiscount,
//         'specialType': specialType,
//       };
//       orderModel = OrderModel();
//       int maxNumber = 5;
//       try {
//         final response = await http.get(
//           Uri.parse('${AppConst.baseUrl}firestore/getLatestOrderInRange'),
//           headers: await getHeaders(),
//         );
//         if (response.statusCode == 200) {
//           final responseData = json.decode(response.body);
//           if (responseData['success'] == true &&
//               responseData['order'] != null) {
//             final orderData = responseData['order'];
//             final String orderIdFromApi = orderData['id'].toString();
//             final match = RegExp(r'Jippy3(\d+)').firstMatch(orderIdFromApi);
//             if (match != null) {
//               final num = int.tryParse(match.group(1)!);
//               if (num != null && num > maxNumber) {
//                 maxNumber = num;
//               }
//               notifyListeners();
//             }
//           }
//         } else {
//           print('⚠️ API call failed with status: ${response.statusCode}');
//           // Continue with default maxNumber
//         }
//       } catch (e) {
//         print('⚠️ Error fetching latest order: $e');
//         // Continue with default maxNumber
//       }
//       orderModel.address = selectedAddress;
//       orderModel.authorID = await SqlStorageConst.getFirebaseId();
//       orderModel.author = userModel;
//       orderModel.vendorID = vendorModel.id;
//       orderModel.vendor = vendorModel;
//       orderModel.products = tempProduc;
//       orderModel.specialDiscount = specialDiscountMap;
//       orderModel.paymentMethod = selectedPaymentMethod;
//       orderModel.status = Constant.orderPlaced;
//       orderModel.createdAt = Timestamp.now();
//       orderModel.couponId = selectedCouponModel.id ?? '';
//       orderModel.couponCode = selectedCouponModel.code ?? '';
//       orderModel.discount = couponAmount;
//       orderModel.deliveryCharge = deliveryCharges.toString();
//       orderModel.tipAmount = deliveryTips.toString();
//       orderModel.toPayAmount = totalAmount;
//       orderModel.scheduleTime = Timestamp.fromDate(scheduleDateTime);
//       notifyListeners();
//       Map<String, dynamic> orderPayload = {
//         "author_id": await SqlStorageConst.getFirebaseId(),
//         "cart_items": tempProduc.map((item) => item.toJson()).toList(),
//         "selected_address": {
//           "isDefault": selectedAddress?.isDefault,
//           "address": selectedAddress?.address,
//           "addressAs": selectedAddress?.addressAs,
//           "locality": selectedAddress?.locality,
//           "location": {
//             "latitude": selectedAddress?.location?.latitude,
//             "longitude": selectedAddress?.location?.longitude,
//           },
//           "id": selectedAddress?.id,
//           "landmark": selectedAddress?.landmark,
//         },
//         // "selected_address": {
//         //   "address_id": selectedAddress?.id,
//         //   "label": selectedAddress?.address,
//         //   "address_line": selectedAddress?.address,
//         //   "city": selectedAddress?.addressAs,
//         //   "lat": selectedAddress?.location?.latitude,
//         //   "lng": selectedAddress?.location?.longitude,
//         // },
//         "payment_method": selectedPaymentMethod,
//         "payment_id": _lastPaymentId ?? '',
//         // 🔑 CRITICAL: Include payment ID for reconciliation
//         "razorpay_payment_id": _lastPaymentId ?? '',
//         // 🔑 CRITICAL: Include Razorpay payment ID
//         "total_amount": totalAmount,
//         "delivery_charges": deliveryCharges.toString(),
//         "tip_amount": deliveryTips.toString(),
//         "coupon_id": selectedCouponModel.id ?? '',
//         "coupon_code": selectedCouponModel.code ?? '',
//         "discount": couponAmount,
//         "schedule_time": scheduleDateTime.toIso8601String(),
//         "surge_percent": surgePercent,
//         "admin_surge_fee": await getAdminSurgeFee(),
//         "special_discount": specialDiscountMap,
//         "vendor_id": vendorModel.id ?? 'mart_default',
//         "status": Constant.orderPlaced,
//         "created_at": DateTime.now().toIso8601String(),
//       };
//       notifyListeners();
//       log(
//         const JsonEncoder.withIndent('  ').convert(orderPayload),
//         name: "ORDER_PAYLOAD",
//       );
//       // **API CALL: Store the order**
//       print(
//         '🌐 [ORDER_CREATION] Creating order via API for payment ID: $_lastPaymentId',
//       );
//       print('🌐 [ORDER_CREATION] API URL: ${AppConst.baseUrl}mobile/orders');
//
//       final response = await http
//           .post(
//             Uri.parse('${AppConst.baseUrl}mobile/orders'),
//             headers: await getHeaders(),
//             body: json.encode(orderPayload),
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () {
//               throw Exception(
//                 'Order creation API call timed out after 30 seconds',
//               );
//             },
//           );
//
//       print('🌐 [ORDER_CREATION] API response status: ${response.statusCode}');
//       print('🌐 [ORDER_CREATION] API response body: ${response.body}');
//
//       if (response.statusCode != 200 && response.statusCode != 201) {
//         print(
//           '❌ [ORDER_CREATION] API returned error status: ${response.statusCode}',
//         );
//         print('❌ [ORDER_CREATION] Response body: ${response.body}');
//         throw Exception(
//           'API returned status code: ${response.statusCode}. Response: ${response.body}',
//         );
//       }
//
//       final responseData = json.decode(response.body);
//
//       if (responseData['success'] != true) {
//         print(
//           '❌ [ORDER_CREATION] API returned error: ${responseData['message']}',
//         );
//         throw Exception('API returned error: ${responseData['message']}');
//       }
//
//       if (responseData['data'] == null ||
//           responseData['data']['order_id'] == null) {
//         print('❌ [ORDER_CREATION] API response missing order_id');
//         throw Exception('API response missing order_id');
//       }
//
//       orderModel.id = responseData['data']['order_id'];
//       print(
//         '✅ [ORDER_CREATION] Order created successfully with ID: ${orderModel.id} for payment ID: $_lastPaymentId',
//       );
//
//       ///finded new
//       print('✅ Order created successfully via API');
//       final additionalTasks = <Future>[];
//       if (selectedCouponModel.id != null &&
//           selectedCouponModel.id!.isNotEmpty) {
//         additionalTasks.add(markCouponAsUsed(selectedCouponModel.id!));
//         notifyListeners();
//       }
//       String adminFee = "0";
//       if (surgePercent > 0) {
//         adminFee = await getAdminSurgeFee();
//         notifyListeners();
//       }
//       additionalTasks.add(
//         _createOrderBilling(
//           responseData['data']['order_id'],
//           totalAmount.toString(),
//           surgePercent.toInt(),
//           adminFee,
//         ),
//       );
//       print(
//         " additionalTasks author  ${vendorModel.id}   ${vendorModel.author}",
//       );
//       if (vendorModel.id != null && vendorModel.author != null) {
//         print(" additionalTasks author ");
//         additionalTasks.add(
//           AddressListProvider.getUserProfile(
//             vendorModel.author.toString(),
//           ).then((value) {
//             if (value != null) {
//               print("additionalTasks author  ${value.toJson()}");
//               if (scheduleDateTime.isAfter(DateTime.now())) {
//                 SendNotification.sendFcmMessage(
//                   Constant.scheduleOrder,
//                   value.fcmToken ?? '',
//                   {},
//                 );
//               } else {
//                 SendNotification.sendFcmMessage(
//                   Constant.newOrderPlaced,
//                   value.fcmToken ?? '',
//                   {},
//                 );
//               }
//             }
//           }),
//         );
//       }
//       print(
//         " additionalTasks author1  ${vendorModel.id}   ${vendorModel.author}",
//       );
//       additionalTasks.add(Constant.sendOrderEmail(orderModel: orderModel));
//       await Future.wait(additionalTasks);
//
//       // 🔑 CRITICAL: Clear all order creation flags after successful order creation
//       _isOrderBeingCreated = false;
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//
//       // 🔑 CRITICAL: Keep payment ID in processed set to prevent duplicate orders
//       // Don't clear _processedPaymentIds here - keep it to prevent duplicates
//
//       isPaymentInProgress = false;
//       isPaymentCompleted = false;
//       _lastPaymentId = null;
//       _lastPaymentTime = null;
//       selectedCouponModel = CouponModel();
//       couponCodeController.text = '';
//       couponAmount = 0.0;
//       calculatePrice();
//       await _clearPersistentPaymentState();
//       ShowToastDialog.closeLoader();
//       endOrderProcessing();
//       notifyListeners();
//       // Navigate to order success screen
//       orderPlacingProvider.initFunction(orderModels: orderModel);
//       Get.off(() => OrderPlacingScreen());
//       notifyListeners();
//     } catch (e) {
//       print("OrderPlacingScreen  $e");
//       // 🔑 CRITICAL: Reset all order creation flags on error
//       _isOrderBeingCreated = false;
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//       ShowToastDialog.closeLoader();
//       endOrderProcessing();
//       if (isPaymentCompleted && _lastPaymentId != null) {
//         // Remove from processed set to allow retry
//         _processedPaymentIds.remove(_lastPaymentId!);
//         // Don't reset payment state here - let user retry
//         ShowToastDialog.showToast(
//           "Order placement failed. Your payment is safe. Please try again.".tr,
//         );
//       } else {
//         // Reset payment state for non-payment related errors
//         _resetPaymentState();
//         ShowToastDialog.showToast(
//           "Failed to place order. Please try again.".tr,
//         );
//       }
//       // Rollback order if it was created before error
//       if (orderModel?.id != null && orderModel!.id!.isNotEmpty) {
//         await rollbackFailedOrder(orderModel.id!, orderedProducts);
//       }
//       notifyListeners();
//     }
//   }
//
//   // Helper method to create order billing via API
//   Future<void> _createOrderBilling(
//     String orderId,
//     String totalAmount,
//     int surgePercent,
//     String adminFee,
//   ) async {
//     try {
//       final billingPayload = {
//         'order_id': orderId,
//         'to_pay': totalAmount,
//         'created_at': DateTime.now().toIso8601String(),
//         'surge_fee': surgePercent,
//         'admin_surge_fee': adminFee,
//       };
//       print("billingPayload ${billingPayload} ");
//       final response = await http.post(
//         Uri.parse('${AppConst.baseUrl}order-billing'),
//         headers: await getHeaders(),
//         body: json.encode(billingPayload),
//       );
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('✅ Order billing created successfully');
//       } else {
//         print('⚠️ Failed to create order billing: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error creating order billing: $e');
//     }
//   }
//
//   CodSettingModel cashOnDeliverySettingModel = CodSettingModel();
//   RazorPayModel razorPayModel = RazorPayModel();
//
//   getPaymentSettings() async {
//     try {
//       await FireStoreUtils.getPaymentSettingsData()
//           .then((value) {
//             try {
//               final razorpaySettingsStr = Preferences.getString(
//                 Preferences.razorpaySettings,
//               );
//               final codSettingsStr = Preferences.getString(
//                 Preferences.codSettings,
//               );
//               if (razorpaySettingsStr.isNotEmpty) {
//                 razorPayModel = RazorPayModel.fromJson(
//                   jsonDecode(razorpaySettingsStr),
//                 );
//               }
//
//               if (codSettingsStr.isNotEmpty) {
//                 cashOnDeliverySettingModel = CodSettingModel.fromJson(
//                   jsonDecode(codSettingsStr),
//                 );
//               }
//
//               // 🔑 CRITICAL: If COD is disabled and currently selected, switch to another payment method
//               if (selectedPaymentMethod == PaymentGateway.cod.name &&
//                   cashOnDeliverySettingModel.isEnabled != true) {
//                 selectedPaymentMethod = '';
//                 print(
//                   '[PAYMENT_SETTINGS] COD is disabled, clearing COD selection',
//                 );
//               }
//
//               if (cashOnDeliverySettingModel.isEnabled == true &&
//                   subTotal <= cashOnDeliverySettingModel.getMaxAmount() &&
//                   !hasMartItemsInCart()) {
//                 selectedPaymentMethod = PaymentGateway.cod.name;
//               } else if (razorPayModel.isEnabled == true) {
//                 selectedPaymentMethod = PaymentGateway.razorpay.name;
//               }
//
//               // 🔑 OPTIMIZATION: Pre-initialize Razorpay when settings are loaded
//               // This eliminates initialization delay when user clicks "Confirm Payment"
//               if (razorPayModel.isEnabled == true &&
//                   razorPayModel.razorpayKey != null &&
//                   razorPayModel.razorpayKey!.isNotEmpty) {
//                 _preInitializeRazorpay();
//               }
//
//               // 🔑 CRITICAL FIX: DO NOT register event listeners here
//               // Event listeners are already registered in RazorpayCrashPrevention.safeInitialize()
//               // Registering them again causes duplicate callbacks and multiple orders
//               // The crash prevention utility handles all event listener registration
//               print(
//                 '✅ [PAYMENT_SETTINGS] Event listeners are managed by RazorpayCrashPrevention, skipping duplicate registration',
//               );
//
//               checkAndUpdatePaymentMethod();
//             } catch (e) {
//               print('[CART_PROVIDER] Error parsing payment settings: $e');
//               // Continue with default payment method selection
//               if (razorPayModel.isEnabled == true) {
//                 selectedPaymentMethod = PaymentGateway.razorpay.name;
//                 // Try to pre-initialize even on error
//                 _preInitializeRazorpay();
//               }
//             }
//           })
//           .catchError((e) {
//             print('[CART_PROVIDER] Error fetching payment settings: $e');
//             // Set default payment method on error
//             if (razorPayModel.isEnabled == true) {
//               selectedPaymentMethod = PaymentGateway.razorpay.name;
//               // Try to pre-initialize even on error
//               _preInitializeRazorpay();
//             }
//           });
//     } catch (e) {
//       print('[CART_PROVIDER] Error in getPaymentSettings: $e');
//     }
//     notifyListeners();
//   }
//
//   /// 🔑 OPTIMIZATION: Pre-initialize Razorpay in background
//   /// This eliminates the initialization delay when user clicks "Confirm Payment"
//   Future<void> _preInitializeRazorpay() async {
//     try {
//       // Only pre-initialize if not already initialized
//       if (!_razorpayCrashPrevention.isInitialized) {
//         print('🔑 [RAZORPAY_PREINIT] Pre-initializing Razorpay...');
//         await _razorpayCrashPrevention.safeInitialize(
//           onSuccess: handlePaymentSuccess,
//           onFailure: handlePaymentError,
//           onExternalWallet: handleExternalWallet,
//         );
//         print('✅ [RAZORPAY_PREINIT] Razorpay pre-initialized successfully');
//       } else {
//         print('✅ [RAZORPAY_PREINIT] Razorpay already initialized');
//       }
//     } catch (e) {
//       print(
//         '⚠️ [RAZORPAY_PREINIT] Pre-initialization failed (will initialize on demand): $e',
//       );
//       // Don't throw - initialization will happen on demand in openCheckout
//     }
//   }
//
//   final RazorpayCrashPrevention _razorpayCrashPrevention =
//       RazorpayCrashPrevention();
//
//   Razorpay? get razorPay => _razorpayCrashPrevention.razorpayInstance;
//
//   Future<bool> openCheckout({required amount, required orderId}) async {
//     print(
//       '🔑 [RAZORPAY_CHECKOUT] Starting openCheckout - amount: $amount, orderId: $orderId',
//     );
//
//     if (isPaymentInProgress) {
//       print('⚠️ [RAZORPAY_CHECKOUT] Payment already in progress');
//       ShowToastDialog.showToast(
//         "Payment is already in progress. Please wait...".tr,
//       );
//       return false;
//     }
//
//     if (isPaymentCompleted) {
//       print('⚠️ [RAZORPAY_CHECKOUT] Payment already completed');
//       ShowToastDialog.showToast(
//         "Payment already completed. Please refresh the page.".tr,
//       );
//       return false;
//     }
//
//     // 🔑 OPTIMIZATION: Razorpay should already be initialized from pre-init
//     // Only initialize if absolutely necessary (shouldn't happen in normal flow)
//     if (!_razorpayCrashPrevention.isInitialized) {
//       print(
//         '⚠️ [RAZORPAY_CHECKOUT] Razorpay not initialized (unexpected), initializing now...',
//       );
//       final initialized = await _razorpayCrashPrevention.safeInitialize(
//         onSuccess: handlePaymentSuccess,
//         onFailure: handlePaymentError,
//         onExternalWallet: handleExternalWallet,
//       );
//
//       if (!initialized) {
//         print('❌ [RAZORPAY_CHECKOUT] Razorpay initialization failed');
//         ShowToastDialog.showToast(
//           "Payment system is temporarily unavailable. Please try again later."
//               .tr,
//         );
//         return false;
//       }
//       print('✅ [RAZORPAY_CHECKOUT] Razorpay initialized (fallback)');
//     } else {
//       print(
//         '✅ [RAZORPAY_CHECKOUT] Razorpay already initialized (pre-initialized)',
//       );
//     }
//
//     // 🔑 SET PAYMENT IN PROGRESS STATE
//     isPaymentInProgress = true;
//     print('🔑 [RAZORPAY_CHECKOUT] Payment in progress flag set');
//
//     // 🔑 CRITICAL FIX: Validate Razorpay configuration before creating options
//     if (razorPayModel.razorpayKey == null ||
//         razorPayModel.razorpayKey!.isEmpty) {
//       print('❌ [RAZORPAY_CHECKOUT] Razorpay key is null or empty');
//       isPaymentInProgress = false;
//       ShowToastDialog.showToast(
//         "Payment configuration error. Please contact support.".tr,
//       );
//       return false;
//     }
//
//     if (!razorPayModel.razorpayKey!.startsWith('rzp_')) {
//       print(
//         '❌ [RAZORPAY_CHECKOUT] Invalid Razorpay key format: ${razorPayModel.razorpayKey}',
//       );
//       isPaymentInProgress = false;
//       ShowToastDialog.showToast(
//         "Payment configuration error. Please contact support.".tr,
//       );
//       return false;
//     }
//
//     // 🔑 CRITICAL FIX: Convert amount to int to pass validation
//     int amountInPaise;
//     if (amount is int) {
//       amountInPaise = amount;
//     } else if (amount is double) {
//       amountInPaise = (amount * 100).round();
//     } else {
//       amountInPaise = (double.parse(amount.toString()) * 100).round();
//     }
//
//     print('🔑 [RAZORPAY_CHECKOUT] Amount in paise: $amountInPaise');
//
//     var options = {
//       'key': razorPayModel.razorpayKey,
//       'amount': amountInPaise, // ✅ FIXED: Now using int instead of double
//       'name': 'JIPPY MART',
//       'order_id': orderId,
//       "currency": "INR",
//       'description': 'Order Payment',
//       'retry': {'enabled': true, 'max_count': 1},
//       'send_sms_hash': true,
//       'prefill': {'contact': userModel.phoneNumber, 'email': userModel.email},
//       'external': {
//         'wallets': ['paytm'],
//       },
//     };
//
//     print(
//       '🔑 [RAZORPAY_CHECKOUT] Payment options prepared: ${options.toString().replaceAll(razorPayModel.razorpayKey!, 'rzp_***')}',
//     );
//     notifyListeners();
//
//     try {
//       print('🔑 [RAZORPAY_CHECKOUT] Calling safeOpenPayment...');
//       final success = await _razorpayCrashPrevention.safeOpenPayment(options);
//
//       if (success) {
//         print('✅ [RAZORPAY_CHECKOUT] Payment gateway opened successfully');
//         return true;
//       } else {
//         print('❌ [RAZORPAY_CHECKOUT] safeOpenPayment returned false');
//         isPaymentInProgress = false;
//         ShowToastDialog.showToast(
//           "Failed to open payment gateway. Please try again.".tr,
//         );
//         return false;
//       }
//     } catch (e, stackTrace) {
//       // 🔑 RESET PAYMENT STATE ON ERROR
//       print('❌ [RAZORPAY_CHECKOUT] Exception in openCheckout: $e');
//       print('❌ [RAZORPAY_CHECKOUT] Stack trace: $stackTrace');
//       isPaymentInProgress = false;
//       ShowToastDialog.showToast(
//         "Failed to open payment gateway. Please try again.".tr,
//       );
//       return false;
//     }
//   }
//
//   bool isGlobalLocked = false;
//
//   /// ✅ NEW: Safe payment success handler with crash prevention
//   /// 🔑 CRITICAL FIX: Added idempotency check to prevent duplicate orders
//   void handlePaymentSuccess(PaymentSuccessResponse response) {
//     try {
//       final paymentId = response.paymentId;
//       print("handlePaymentSuccess  ${paymentId}");
//       // 🔑 CRITICAL: Validate payment ID is not null
//       if (paymentId == null || paymentId.isEmpty) {
//         print('❌ [PAYMENT_SUCCESS] Invalid payment ID, ignoring callback');
//         return;
//       }
//
//       // 🔑 CRITICAL: Check if this payment ID has already been processed
//       if (_processedPaymentIds.contains(paymentId)) {
//         print(
//           '⚠️ [DUPLICATE_PREVENTION] Payment ID $paymentId already processed, ignoring duplicate callback',
//         );
//         return; // Ignore duplicate payment success callbacks
//       }
//
//       // 🔑 CRITICAL: Check if order is already being created
//       if (_isOrderBeingCreated) {
//         print(
//           '⚠️ [DUPLICATE_PREVENTION] Order is already being created, ignoring duplicate callback',
//         );
//         return; // Prevent concurrent order creation
//       }
//
//       // 🔑 CRITICAL: Check if payment is already completed
//       if (isPaymentCompleted && _lastPaymentId == paymentId) {
//         print(
//           '⚠️ [DUPLICATE_PREVENTION] Payment already completed for ID $paymentId, ignoring duplicate callback',
//         );
//         return; // Prevent duplicate processing
//       }
//
//       print('✅ [PAYMENT_SUCCESS] Processing payment ID: $paymentId');
//
//       // Mark payment ID as being processed immediately
//       _processedPaymentIds.add(paymentId);
//
//       // 🔑 CRITICAL: Clean up old payment IDs to prevent memory issues
//       if (_processedPaymentIds.length > _maxProcessedPaymentIds) {
//         // Remove oldest entries (keep most recent)
//         final idsToRemove = _processedPaymentIds
//             .take(_processedPaymentIds.length - _maxProcessedPaymentIds)
//             .toList();
//         for (final id in idsToRemove) {
//           _processedPaymentIds.remove(id);
//         }
//       }
//
//       isGlobalLocked = true;
//       _lastPaymentId = paymentId;
//       _lastPaymentTime = DateTime.now();
//       isPaymentCompleted = true;
//       // 🔑 CRITICAL: DON'T set _isOrderBeingCreated here - set it in placeOrderAfterPayment
//       // Setting it here causes placeOrderAfterPayment to return early and never create order!
//
//       ShowToastDialog.showLoader("Processing payment and placing order...".tr);
//
//       Future.delayed(const Duration(milliseconds: 500), () async {
//         try {
//           print(
//             '🔑 [PAYMENT_SUCCESS] Starting order placement after delay for payment ID: $paymentId',
//           );
//           await placeOrderAfterPayment();
//         } catch (e, stackTrace) {
//           print('❌ [PAYMENT_SUCCESS] Error in placeOrderAfterPayment: $e');
//           print('❌ [PAYMENT_SUCCESS] Stack trace: $stackTrace');
//           // On error, allow retry by removing from processed set (but keep payment completed flag)
//           _processedPaymentIds.remove(paymentId);
//           _isOrderBeingCreated = false;
//           // 🔑 CRITICAL: Reset static lock on error
//           _isOrderCreationInProgress = false;
//           _currentOrderPaymentId = null;
//           ShowToastDialog.showToast(
//             "Order placement failed. Your payment is safe. Please try again."
//                 .tr,
//           );
//         } finally {
//           isGlobalLocked = false;
//         }
//       });
//       notifyListeners();
//     } catch (e) {
//       print('❌ [PAYMENT_SUCCESS] Exception in handlePaymentSuccess: $e');
//       isGlobalLocked = false;
//       isPaymentInProgress = false;
//       _isOrderBeingCreated = false;
//       if (response.paymentId != null) {
//         _processedPaymentIds.remove(response.paymentId);
//       }
//       ShowToastDialog.showToast(
//         "Payment processing failed. Please try again.".tr,
//       );
//       notifyListeners();
//     }
//   }
//
//   /// ✅ NEW: Safe payment error handler with crash prevention
//   void handlePaymentError(PaymentFailureResponse response) {
//     try {
//       // Reset payment state
//       isPaymentInProgress = false;
//       // 🔑 CRITICAL: Reset order processing flag when payment fails
//       endOrderProcessing();
//
//       // Show error message
//       ShowToastDialog.showToast("Payment failed: ${response.message}".tr);
//       notifyListeners();
//     } catch (e) {
//       isPaymentInProgress = false;
//       // 🔑 CRITICAL: Reset order processing flag on error
//       endOrderProcessing();
//       ShowToastDialog.showToast("Payment failed. Please try again.".tr);
//       notifyListeners();
//     }
//   }
//
//   /// ✅ NEW: Safe external wallet handler with crash prevention
//   void handleExternalWallet(ExternalWalletResponse response) {
//     try {
//       ShowToastDialog.showToast(
//         "External wallet selected: ${response.walletName}".tr,
//       );
//       notifyListeners();
//     } catch (e) {
//       isPaymentInProgress = false;
//       ShowToastDialog.showToast("External wallet error. Please try again.".tr);
//       notifyListeners();
//     }
//   }
//
//   void handleExternalWaller(ExternalWalletResponse response) {
//     Get.back();
//     ShowToastDialog.showToast("Payment Processing!! via".tr);
//   }
//
//   Future<void> _processOrderWithRetry() async {
//     const maxRetries = 3;
//     int retryCount = 0;
//
//     while (retryCount < maxRetries) {
//       try {
//         if (retryCount > 0) {
//           await Future.delayed(Duration(seconds: retryCount * 2));
//         }
//
//         await placeOrderAfterPayment();
//         notifyListeners();
//         return;
//       } catch (e) {
//         retryCount++;
//
//         if (retryCount >= maxRetries) {
//           await _handleOrderPlacementFailure();
//           return;
//         }
//         await placeOrderAfterPayment();
//         ShowToastDialog.showLoader(
//           "Retrying order placement... ($retryCount/$maxRetries)".tr,
//         );
//       }
//     }
//   }
//
//   Future<void> _handleOrderPlacementFailure() async {
//     ShowToastDialog.closeLoader();
//     // Show critical error dialog
//     Get.dialog(
//       AlertDialog(
//         title: Text("Order Placement Failed"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Your payment was successful, but we couldn't place your order.",
//             ),
//             SizedBox(height: 10),
//             Text(
//               "Don't worry - your money is safe and will be refunded within 24 hours.",
//             ),
//             SizedBox(height: 10),
//             Text("Please contact support with Payment ID: $_lastPaymentId"),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back();
//               _resetPaymentState();
//             },
//             child: Text("OK"),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               _retryOrderPlacement();
//             },
//             child: Text("Retry Order"),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );
//     notifyListeners();
//   }
//
//   void _resetPaymentState() {
//     isPaymentInProgress = false;
//     isPaymentCompleted = false;
//     _lastPaymentId = null;
//     _lastPaymentTime = null;
//     _isOrderBeingCreated = false;
//     // 🔑 CRITICAL: Clear static order creation flags
//     _isOrderCreationInProgress = false;
//     _currentOrderPaymentId = null;
//     // 🔑 CRITICAL: Clear processed payment IDs when resetting payment state
//     // This allows retry after a full reset
//     _processedPaymentIds.clear();
//     notifyListeners();
//   }
//
//   // 🔑 RESTORE PAYMENT STATE FROM PERSISTENT STORAGE
//   Future<void> _restorePaymentState() async {
//     final paymentState = Preferences.getString(_paymentStateKey);
//     if (paymentState == 'true') {
//       isPaymentInProgress = true;
//       _lastPaymentId = Preferences.getString(_paymentIdKey);
//       final paymentTimeStr = Preferences.getString(_paymentTimeKey);
//       final paymentMethodStr = Preferences.getString(_paymentMethodKey);
//
//       if (paymentTimeStr.isNotEmpty && paymentTimeStr != '') {
//         _lastPaymentTime = DateTime.fromMillisecondsSinceEpoch(
//           int.parse(paymentTimeStr),
//         );
//       }
//       // 🔑 RESTORE PAYMENT METHOD FROM PERSISTENT STORAGE
//       if (paymentMethodStr.isNotEmpty && paymentMethodStr != '') {
//         selectedPaymentMethod = paymentMethodStr;
//       } else if (_lastPaymentId != null && _lastPaymentId!.isNotEmpty) {
//         selectedPaymentMethod = PaymentGateway.razorpay.name;
//       }
//       notifyListeners();
//     }
//   }
//
//   // 🔑 CLEAR PERSISTENT PAYMENT STATE
//   Future<void> _clearPersistentPaymentState() async {
//     try {
//       await Preferences.setString(_paymentStateKey, '');
//       await Preferences.setString(_paymentIdKey, '');
//       await Preferences.setString(_paymentSignatureKey, '');
//       await Preferences.setString(_paymentTimeKey, '');
//       await Preferences.setString(_paymentMethodKey, '');
//       await Preferences.setString(_paymentAmountKey, '');
//       await Preferences.setString(_paymentOrderIdKey, '');
//     } catch (e) {}
//   }
//
//   // 🔑 CHECK PENDING PAYMENT AND RECOVER (HANDLES APP KILLS)
//   Future<void> _checkPendingPaymentAndRecover() async {
//     try {
//       if (_lastPaymentTime != null) {
//         final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
//         if (timeSincePayment > paymentTimeout) {
//           print('🔑 Payment session expired, clearing state');
//           await _clearPersistentPaymentState();
//           _resetPaymentState();
//           ShowToastDialog.showToast(
//             "Payment session expired. Please try again.".tr,
//           );
//           return;
//         }
//       }
//
//       // Show recovery dialog to user (matching app's address alert style)
//       Get.dialog(
//         AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.payment, color: Colors.orange, size: 24),
//               SizedBox(width: 10),
//               Text(
//                 "Payment Recovery",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "We detected a successful payment from before the app was closed.",
//                 style: TextStyle(fontSize: 14, color: Colors.black87),
//               ),
//               SizedBox(height: 15),
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green, size: 20),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         "Payment ID: $_lastPaymentId",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.green.shade700,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 15),
//               Text(
//                 "Please complete your order to continue.",
//                 style: TextStyle(fontSize: 14, color: Colors.black87),
//               ),
//             ],
//           ),
//           actions: [
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Get.back();
//                   _completePendingOrder();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   "Complete Order",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         barrierDismissible: false,
//       );
//       notifyListeners();
//     } catch (e) {
//       await _clearPersistentPaymentState();
//       _resetPaymentState();
//       notifyListeners();
//     }
//   }
//
//   // 🔑 COMPLETE PENDING ORDER
//   Future<void> _completePendingOrder() async {
//     try {
//       ShowToastDialog.showLoader("Completing your order...".tr);
//       isPaymentCompleted = true;
//
//       await _processOrderWithRetry();
//       notifyListeners();
//     } catch (e) {
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast(
//         "Failed to complete order. Please try again.".tr,
//       );
//       await _clearPersistentPaymentState();
//       _resetPaymentState();
//       notifyListeners();
//     }
//   }
//
//   // 🔑 RETRY ORDER PLACEMENT
//   Future<void> _retryOrderPlacement() async {
//     if (_lastPaymentId != null && _lastPaymentTime != null) {
//       // Check if payment is still valid (within timeout)
//       final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
//       if (timeSincePayment < paymentTimeout) {
//         ShowToastDialog.showLoader("Retrying order placement...".tr);
//         await _processOrderWithRetry();
//       } else {
//         ShowToastDialog.showToast(
//           "Payment session expired. Please try again.".tr,
//         );
//         _resetPaymentState();
//       }
//     } else {
//       ShowToastDialog.showToast("No valid payment found. Please try again.".tr);
//       _resetPaymentState();
//     }
//     notifyListeners();
//   }
//
//   // 🔑 ENHANCED PLACE ORDER AFTER PAYMENT - NEW IMPLEMENTATION
//   placeOrderAfterPayment() async {
//     try {
//       // 🔑 VALIDATE PAYMENT STATE BEFORE PROCEEDING
//       if (!isPaymentCompleted || _lastPaymentId == null) {
//         print(
//           '❌ [ORDER_PLACEMENT] Payment validation failed - no valid payment found',
//         );
//         throw Exception('Payment validation failed - no valid payment found');
//       }
//
//       // 🔑 CRITICAL: Check if order is already being created for THIS payment ID
//       // Only prevent if it's the same payment ID AND order is being created
//       if (_isOrderBeingCreated && _currentOrderPaymentId == _lastPaymentId) {
//         print(
//           '⚠️ [ORDER_PLACEMENT] Order is already being created for payment ID $_lastPaymentId, preventing duplicate',
//         );
//         return; // Prevent concurrent order creation for same payment
//       }
//
//       // 🔑 CRITICAL: Check static lock to prevent concurrent order creation across instances
//       if (_isOrderCreationInProgress &&
//           _currentOrderPaymentId == _lastPaymentId) {
//         print(
//           '⚠️ [ORDER_PLACEMENT] Order creation already in progress for payment ID $_lastPaymentId',
//         );
//         return; // Prevent duplicate order creation
//       }
//
//       // Set flags to prevent concurrent calls
//       _isOrderBeingCreated = true;
//       print(
//         '✅ [ORDER_PLACEMENT] Starting order creation for payment ID: $_lastPaymentId',
//       );
//
//       // 🔑 CHECK PAYMENT TIMEOUT
//       if (_lastPaymentTime != null) {
//         final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
//         if (timeSincePayment > paymentTimeout) {
//           throw Exception('Payment session expired');
//         }
//       }
//
//       // 🔑 CRITICAL: Validate calculations before creating order after payment
//       if (HomeProvider.cartItem.isEmpty) {
//         print('❌ [ORDER_PLACEMENT] Cart is empty, cannot create order');
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Cart is empty. Please add items to cart.".tr,
//         );
//         _isOrderBeingCreated = false;
//         _isOrderCreationInProgress = false;
//         _currentOrderPaymentId = null;
//         endOrderProcessing();
//         return;
//       }
//
//       // Recalculate to ensure latest values
//       await calculatePrice();
//
//       if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
//         print(
//           '❌ [ORDER_PLACEMENT] Invalid subTotal: $subTotal, cannot create order',
//         );
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Order calculation error. Please refresh and try again.".tr,
//         );
//         _isOrderBeingCreated = false;
//         _isOrderCreationInProgress = false;
//         _currentOrderPaymentId = null;
//         endOrderProcessing();
//         return;
//       }
//
//       if (totalAmount <= 0 || totalAmount.isNaN || totalAmount.isInfinite) {
//         print(
//           '❌ [ORDER_PLACEMENT] Invalid totalAmount: $totalAmount, cannot create order',
//         );
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Order total is invalid. Please refresh and try again.".tr,
//         );
//         _isOrderBeingCreated = false;
//         _isOrderCreationInProgress = false;
//         _currentOrderPaymentId = null;
//         endOrderProcessing();
//         return;
//       }
//
//       print(
//         '✅ [ORDER_PLACEMENT] Calculations validated - SubTotal: ₹$subTotal, Total: ₹$totalAmount',
//       );
//
//       // 🔑 ENSURE PAYMENT METHOD IS SET CORRECTLY FOR PREPAID ORDERS
//       if (selectedPaymentMethod.isEmpty ||
//           selectedPaymentMethod == PaymentGateway.cod.name) {
//         // If payment method is empty or COD, but we have a successful payment, set it to razorpay
//         selectedPaymentMethod = PaymentGateway.razorpay.name;
//       }
//
//       // Prevent order if fallback location is used - apply to ALL payment methods
//       if (selectedAddress?.locality == 'Ongole, Andhra Pradesh, India' ||
//           selectedAddress?.addressAs == 'Ongole Center') {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Please select your actual address or use current location to place order."
//               .tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       // 🔑 CRITICAL: Validate COD is enabled before allowing COD orders
//       if (selectedPaymentMethod == PaymentGateway.cod.name) {
//         if (cashOnDeliverySettingModel.isEnabled != true) {
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast(
//             "Cash on Delivery is currently disabled. Please select another payment method."
//                 .tr,
//           );
//           endOrderProcessing();
//           return;
//         }
//       }
//
//       if (selectedPaymentMethod == PaymentGateway.cod.name &&
//           subTotal > cashOnDeliverySettingModel.getMaxAmount()) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select another payment method."
//               .tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       if (selectedPaymentMethod == PaymentGateway.cod.name &&
//           hasPromotionalItems()) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           "Cash on Delivery is not available for promotional items. Please select another payment method."
//               .tr,
//         );
//         endOrderProcessing();
//         return;
//       }
//
//       // 🔑 CRITICAL: Ensure we have valid payment before creating order
//       if (_lastPaymentId == null || _lastPaymentId!.isEmpty) {
//         throw Exception('Payment ID is missing - cannot create order');
//       }
//
//       print(
//         '🔑 [ORDER_PLACEMENT] Payment validated, proceeding to create order for payment ID: $_lastPaymentId',
//       );
//       print('🔑 [ORDER_PLACEMENT] Payment method: $selectedPaymentMethod');
//       print('🔑 [ORDER_PLACEMENT] Total amount: $totalAmount');
//
//       if (selectedPaymentMethod == PaymentGateway.wallet.name) {
//         if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
//           print(
//             '🔑 [ORDER_PLACEMENT] Using wallet payment, calling _setOrderInternal',
//           );
//           await _setOrderInternal();
//         } else {
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast(
//             "You don't have sufficient wallet balance to place order".tr,
//           );
//           endOrderProcessing();
//           _isOrderBeingCreated = false;
//           _isOrderCreationInProgress = false;
//           _currentOrderPaymentId = null;
//           return;
//         }
//       } else {
//         print(
//           '🔑 [ORDER_PLACEMENT] Using Razorpay payment, calling _setOrderInternal',
//         );
//         await _setOrderInternal();
//       }
//
//       // 🔑 CRITICAL: Clear order creation flag only after successful order creation
//       _isOrderBeingCreated = false;
//       print(
//         '✅ [ORDER_PLACEMENT] Order creation completed successfully for payment ID: $_lastPaymentId',
//       );
//       notifyListeners();
//     } catch (e, stackTrace) {
//       // 🔑 CRITICAL: Reset all order creation flags on error to allow retry
//       _isOrderBeingCreated = false;
//       _isOrderCreationInProgress = false;
//       _currentOrderPaymentId = null;
//
//       if (_lastPaymentId != null) {
//         // Remove from processed set to allow retry on error
//         _processedPaymentIds.remove(_lastPaymentId);
//       }
//
//       ShowToastDialog.closeLoader();
//       if (e.toString().contains('Delivery zone validation failed') ||
//           e.toString().contains('Delivery distance validation failed')) {
//         // Zone validation errors are handled separately
//       } else {
//         ShowToastDialog.showToast(
//           "An error occurred while placing your order. Your payment is safe. Please try again."
//               .tr,
//         );
//       }
//       endOrderProcessing();
//       print('❌ [ORDER_PLACEMENT] Error in placeOrderAfterPayment: $e');
//       print('❌ [ORDER_PLACEMENT] Stack trace: $stackTrace');
//
//       // 🔑 CRITICAL: Re-throw error so handlePaymentSuccess can catch it and show proper message
//       rethrow;
//     }
//     notifyListeners();
//   }
//
//   static String accessToken = '';
//   static String payToken = '';
//   static String orderId = '';
//   static String amount = '';
//
//   // In CartControllerProvider class
//   Future<void> markCouponAsUsed(String couponId) async {
//     try {
//       await SqlStorageConst.getFirebaseId(); // Get user ID for authentication context
//       final response = await http.post(
//         Uri.parse('${AppConst.baseUrl}mobile/coupons/$couponId/used'),
//         headers: await getHeaders(),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('✅ Coupon marked as used: $couponId');
//
//         // Update local state to mark coupon as used
//         for (var coupon in couponList) {
//           if (coupon.id == couponId) {
//             coupon.isEnabled = false;
//           }
//         }
//         for (var coupon in allCouponList) {
//           if (coupon.id == couponId) {
//             coupon.isEnabled = false;
//           }
//         }
//         notifyListeners();
//       } else {
//         print('❌ Failed to mark coupon as used: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error marking coupon as used: $e');
//     }
//   }
//
//   // Add this method to mark a coupon as used for the current user
//   // Future<void> markCouponAsUsed(String couponId) async {
//   //   try {
//   //     final headers = await getHeaders();
//   //     final response = await http.post(
//   //       Uri.parse('${AppConst.baseUrl}mobile/coupons/$couponId/used'),
//   //       headers: headers,
//   //     );
//   //
//   //     if (response.statusCode == 200 || response.statusCode == 201) {
//   //       print('Coupon marked as used successfully');
//   //       await getCartData();
//   //     } else {
//   //       throw Exception(
//   //         'Failed to mark coupon as used: ${response.statusCode}',
//   //       );
//   //     }
//   //   } catch (e) {
//   //     print('Error marking coupon as used: $e');
//   //     throw Exception('Failed to mark coupon as used: $e');
//   //   }
//   // }
//
//   bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
//     final currentDate = DateTime.now();
//     return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
//   }
//
//   //Paypal - Commented out to reduce APK size
//   void paypalPaymentSheet(String amount, BuildContext context) {
//     ShowToastDialog.showToast(
//       "PayPal payment is disabled for APK size optimization".tr,
//     );
//   }
//
//   /// Validate minimum order value for mart items
//   Future<void> validateMinimumOrderValue() async {
//     try {
//       // Check if cart contains any mart items
//       bool hasMartItems = HomeProvider.cartItem.any(
//         (item) => item.vendorID?.startsWith('mart_') == true,
//       );
//       if (!hasMartItems) {
//         return;
//       }
//       double minOrderValue = 99.0; // Default value
//       String minOrderMessage = 'Min Item value is ₹99';
//       bool isSettingsActive = true; // Default to active
//
//       if (_martDeliverySettings != null) {
//         isSettingsActive = _martDeliverySettings!['is_active'] ?? true;
//         minOrderValue =
//             (_martDeliverySettings!['min_order_value'] as num?)?.toDouble() ??
//             99.0;
//         minOrderMessage =
//             _martDeliverySettings!['min_order_message'] ??
//             'Min Item value is ₹${minOrderValue.toInt()}';
//       } else {
//         final settings = await _fetchMartDeliveryChargeSettings();
//         if (settings != null) {
//           _martDeliverySettings = settings;
//           isSettingsActive = settings['is_active'] ?? true;
//           minOrderValue =
//               (settings['min_order_value'] as num?)?.toDouble() ?? 99.0;
//           minOrderMessage =
//               settings['min_order_message'] ??
//               'Min Item value is ₹${minOrderValue.toInt()}';
//         }
//       }
//       if (!isSettingsActive) {
//         return; // Skip validation if settings are inactive
//       }
//
//       final currentSubTotal = subTotal;
//
//       // Check if current subtotal meets minimum order requirement
//       if (currentSubTotal < minOrderValue) {
//         ShowToastDialog.showToast(minOrderMessage);
//         throw Exception('Minimum order value not met');
//       }
//
//       notifyListeners();
//     } catch (e) {
//       // Re-throw the exception to stop the order process
//       rethrow;
//     }
//     notifyListeners();
//   }
//
//   /// 🔑 BULLETPROOF ADDRESS VALIDATION - NEVER FAILS
//   Future<bool> _validateAddressBulletproof(
//     BuildContext context, {
//     bool isRetry = false,
//   }) async {
//     try {
//       if (!isRetry &&
//           (selectedAddress == null ||
//               selectedAddress!.location?.latitude == null ||
//               selectedAddress!.location?.longitude == null ||
//               selectedAddress!.location!.latitude == 0.0 ||
//               selectedAddress!.location!.longitude == 0.0 ||
//               selectedAddress!.address == null ||
//               selectedAddress!.address!.isEmpty ||
//               selectedAddress!.address == 'Current Location')) {
//         final homeScreenAddress = await _getCurrentLocationAddress(context);
//         if (homeScreenAddress != null) {
//           selectedAddress = homeScreenAddress;
//           print(
//             '[CART_VALIDATION] ✅ Synced selectedAddress with Constant.selectedLocation',
//           );
//         }
//       }
//
//       if (selectedAddress == null) {
//         ShowToastDialog.showToast(
//           "Delivery address is required. Please add an address to continue.".tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       final address = selectedAddress!;
//       // CRITICAL CHECK 2: Address must have valid ID
//       if (address.id == null || address.id!.trim().isEmpty) {
//         ShowToastDialog.showToast(
//           "Invalid address detected. Please select a valid delivery address."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.address == null ||
//           address.address!.trim().isEmpty ||
//           address.address!.trim() == 'null') {
//         ShowToastDialog.showToast(
//           "Please select a valid delivery address with complete address details."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.address!.trim() == 'Current Location' &&
//           (address.location?.latitude == null ||
//               address.location?.longitude == null)) {
//         ShowToastDialog.showToast(
//           "Current location address must have valid coordinates. Please add a proper address."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.locality == null ||
//           address.locality!.trim().isEmpty ||
//           address.locality!.trim() == 'null') {
//         ShowToastDialog.showToast(
//           "Please select a valid delivery address with complete location details."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.locality!.trim() == 'Current Location' &&
//           (address.location?.latitude == null ||
//               address.location?.longitude == null)) {
//         ShowToastDialog.showToast(
//           "Current location must have valid coordinates. Please add a proper address."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       print(
//         '🏠 [BULLETPROOF_ADDRESS] ✅ CHECK 4 PASSED - Valid locality: "${address.locality}"',
//       );
//       if (address.location == null ||
//           address.location!.latitude == null ||
//           address.location!.longitude == null ||
//           address.location!.latitude == 0.0 ||
//           address.location!.longitude == 0.0) {
//         print('[CART_VALIDATION] ❌ CHECK 5 FAILED - Invalid coordinates');
//         print('[CART_VALIDATION] Location: ${address.location?.toJson()}');
//         print('[CART_VALIDATION] Address: ${address.address}');
//         print('[CART_VALIDATION] Locality: ${address.locality}');
//         if (!isRetry) {
//           final homeScreenAddress = await _getCurrentLocationAddress(context);
//           if (homeScreenAddress != null &&
//               homeScreenAddress.location?.latitude != null &&
//               homeScreenAddress.location?.longitude != null) {
//             selectedAddress = homeScreenAddress;
//             print(
//               '[CART_VALIDATION] ✅ Retry sync successful - using home screen address',
//             );
//             return await _validateAddressBulletproof(context, isRetry: true);
//           }
//         }
//         ShowToastDialog.showToast(
//           "Please select a delivery address with valid location coordinates."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.id!.startsWith('fallback_zone_') ||
//           address.address == 'Ongole' ||
//           address.address == 'Service Area' ||
//           address.locality == 'Ongole' ||
//           address.locality == 'Service Area' ||
//           address.id!.contains('ongole_fallback_zone')) {
//         ShowToastDialog.showToast(
//           "Please add a valid delivery address. Fallback zones are not allowed."
//               .tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       final lat = address.location!.latitude!;
//       final lng = address.location!.longitude!;
//       if (lat < 6.0 || lat > 37.0 || lng < 68.0 || lng > 97.0) {
//         ShowToastDialog.showToast(
//           "Please select a delivery address within our service area.".tr,
//         );
//         Get.to(() => const AddressListScreen());
//         return false;
//       }
//       if (address.zoneId == null || address.zoneId!.isEmpty) {
//         String? detectedZoneId;
//
//         // PRIORITY 1: Try to use zoneId from Constant.selectedLocation
//         if (Constant.selectedLocation.zoneId != null &&
//             Constant.selectedLocation.zoneId!.isNotEmpty) {
//           detectedZoneId = Constant.selectedLocation.zoneId;
//           print(
//             '[CART_VALIDATION] ✅ Using zoneId from Constant.selectedLocation: $detectedZoneId',
//           );
//         }
//         // PRIORITY 2: Try to use zoneId from Constant.selectedZone
//         else if (Constant.selectedZone?.id != null &&
//             Constant.selectedZone!.id!.isNotEmpty) {
//           detectedZoneId = Constant.selectedZone!.id;
//           print(
//             '[CART_VALIDATION] ✅ Using zoneId from Constant.selectedZone: $detectedZoneId',
//           );
//         }
//         // PRIORITY 3: Try to detect zone ID from coordinates
//         else {
//           detectedZoneId = await _detectZoneIdForCoordinates(
//             address.location!.latitude!,
//             address.location!.longitude!,
//             context,
//           );
//           if (detectedZoneId != null) {
//             print(
//               '[CART_VALIDATION] ✅ Detected zoneId from coordinates: $detectedZoneId',
//             );
//           }
//         }
//         if (detectedZoneId != null && detectedZoneId.isNotEmpty) {
//           address.zoneId = detectedZoneId;
//           Constant.selectedLocation.zoneId = detectedZoneId;
//           print(
//             '[CART_VALIDATION] ✅ Zone ID set successfully: $detectedZoneId',
//           );
//         } else {
//           print('[CART_VALIDATION] ❌ All zone detection methods failed');
//           print(
//             '[CART_VALIDATION] Constant.selectedLocation.zoneId: ${Constant.selectedLocation.zoneId}',
//           );
//           print(
//             '[CART_VALIDATION] Constant.selectedZone?.id: ${Constant.selectedZone?.id}',
//           );
//           ShowToastDialog.showToast(
//             "Address zone not detected. Please update your address or contact support."
//                 .tr,
//           );
//           Get.to(() => const AddressListScreen());
//           return false;
//         }
//       }
//       // 🔑 FIX: Try to load/reload vendor zoneId if missing (especially for mart vendors)
//       if (vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) {
//         // Try to reload vendor model, especially for mart vendors
//         if (vendorModel.id != null) {
//           final hasMartItems = HomeProvider.cartItem.any(
//             (item) => item.vendorID?.startsWith('mart_') == true,
//           );
//
//           if (hasMartItems) {
//             try {
//               print(
//                 '[CART_VALIDATION] ⚠️ Vendor zoneId is missing for mart vendor, attempting to reload...',
//               );
//               final vendorId = vendorModel.id;
//               MartVendorModel? martVendor;
//
//               if (vendorId != null && vendorId.isNotEmpty) {
//                 martVendor = await MartVendorService.getMartVendorById(
//                   vendorId,
//                 );
//               }
//               martVendor ??= await MartVendorService.getDefaultMartVendor();
//
//               if (martVendor != null &&
//                   martVendor.zoneId != null &&
//                   martVendor.zoneId!.isNotEmpty) {
//                 vendorModel.zoneId = martVendor.zoneId;
//                 print(
//                   '[CART_VALIDATION] ✅ Reloaded mart vendor zoneId: ${vendorModel.zoneId}',
//                 );
//               } else if (address.zoneId != null && address.zoneId!.isNotEmpty) {
//                 // Use address zoneId as fallback
//                 vendorModel.zoneId = address.zoneId;
//                 print(
//                   '[CART_VALIDATION] ⚠️ Using address zoneId as fallback: ${vendorModel.zoneId}',
//                 );
//               }
//             } catch (e) {
//               print('[CART_VALIDATION] ❌ Error reloading mart vendor: $e');
//             }
//           }
//         }
//
//         // Final check - if still empty, try using address zoneId
//         if ((vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) &&
//             address.zoneId != null &&
//             address.zoneId!.isNotEmpty) {
//           vendorModel.zoneId = address.zoneId;
//           print(
//             '[CART_VALIDATION] ⚠️ Using address zoneId as fallback: ${vendorModel.zoneId}',
//           );
//         }
//
//         // Additional fallback - try using Constant.selectedLocation.zoneId
//         if ((vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) &&
//             Constant.selectedLocation.zoneId != null &&
//             Constant.selectedLocation.zoneId!.isNotEmpty) {
//           vendorModel.zoneId = Constant.selectedLocation.zoneId;
//           print(
//             '[CART_VALIDATION] ⚠️ Using Constant.selectedLocation.zoneId as fallback: ${vendorModel.zoneId}',
//           );
//         }
//
//         // Last resort fallback - try using Constant.selectedZone?.id
//         if ((vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) &&
//             Constant.selectedZone?.id != null &&
//             Constant.selectedZone!.id!.isNotEmpty) {
//           vendorModel.zoneId = Constant.selectedZone!.id;
//           print(
//             '[CART_VALIDATION] ⚠️ Using Constant.selectedZone.id as final fallback: ${vendorModel.zoneId}',
//           );
//         }
//
//         // Only show error if zoneId is still missing after all attempts
//         if (vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) {
//           ShowToastDialog.showToast(
//             "Vendor zone not configured. Please contact support.".tr,
//           );
//           return false;
//         }
//       }
//       if (address.zoneId != vendorModel.zoneId) {
//         // Show zone mismatch alert dialog
//         DeliveryZoneAlertDialog.showZoneMismatchError();
//         return false;
//       }
//
//       if (vendorModel.latitude != null && vendorModel.longitude != null) {
//         final distance = Constant.calculateDistance(
//           address.location!.latitude!,
//           address.location!.longitude!,
//           vendorModel.latitude!,
//           vendorModel.longitude!,
//         );
//
//         // Set maximum delivery distance (20km - adjust as needed)
//         const maxDeliveryDistance = 16.0;
//
//         if (distance > maxDeliveryDistance) {
//           // Show distance too far alert dialog
//           DeliveryZoneAlertDialog.showDistanceTooFarError();
//           return false;
//         }
//         notifyListeners();
//       }
//       notifyListeners();
//       return true;
//     } catch (e) {
//       ShowToastDialog.showToast(
//         "Error validating address. Please select a valid delivery address.".tr,
//       );
//
//       Get.to(() => const AddressListScreen());
//       return false;
//     }
//   }
// }
//
// enum PaymentGateway { razorpay, cod, wallet }

/// Price update result for cart price validation
enum PriceStatus { noChange, priceChanged, productNotFound, error }

class PriceUpdateResult {
  final String productId;
  final PriceStatus status;
  final String? oldPrice;
  final String? newPrice;
  final String? productName;
  final String? error;

  PriceUpdateResult({
    required this.productId,
    required this.status,
    this.oldPrice,
    this.newPrice,
    this.productName,
    this.error,
  });

  bool get hasPriceChange => status == PriceStatus.priceChanged;

  bool get isError =>
      status == PriceStatus.error || status == PriceStatus.productNotFound;
}

class PerformanceMetric {
  final DateTime startTime;
  final String operationId;
  DateTime? endTime;
  Duration? duration;

  PerformanceMetric({required this.startTime, required this.operationId});
}

class CartControllerProvider extends ChangeNotifier {
  // 🔑 PERFORMANCE OPTIMIZATION FIELDS
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  final Map<String, int> _operationCounts = {};
  static const Duration _rateLimitDuration = Duration(milliseconds: 100);
  Timer? _cleanupTimer;
  Timer? _batchUpdateTimer;
  Timer? _priceSyncTimer;
  bool _isBatchUpdateScheduled = false;
  bool _isPriceSyncScheduled = false;
  bool _orderInProgress = false;

  // Add these fields to the class variables section:
  bool _isGlobalLocked = false;
  bool isProfileValid = false;
  bool isProfileValidating = false;
  List<Function()> _pendingUpdates = [];

  // 🔑 SMART SYNC FIELDS
  final Set<String> _recentlySyncedItems = {};
  final Set<String> _itemsPendingSync = {};
  static const Duration _syncCooldown = Duration(minutes: 5);

  // 🔑 MEMORY MANAGEMENT
  final List<String> _recentlyUpdatedProductIds = [];
  static const int _maxRecentUpdates = 50;
  static const int _maxProcessedPaymentIds = 100;

  // 🔑 UI STATE MANAGEMENT
  bool _isCalculatingPrice = false;
  DateTime? _lastPriceCalculationTime;

  // 🔑 PAYMENT STATE
  bool isPaymentInProgress = false;
  bool isPaymentCompleted = false;
  String? _lastPaymentId;
  DateTime? _lastPaymentTime;
  static const Duration paymentTimeout = Duration(minutes: 5);

  // 🔑 ORDER PROCESSING
  bool _isOrderBeingCreated = false;
  Set<String> _processedPaymentIds = {};
  static bool _isOrderCreationInProgress = false;
  static String? _currentOrderPaymentId;
  static DateTime? _lastOrderCreationTime;
  static const Duration _orderCreationCooldown = Duration(seconds: 10);

  // 🔑 ADDRESS MANAGEMENT
  bool _addressInitialized = false;

  // 🔑 CACHING
  VendorModel? _cachedVendorModel;
  DeliveryCharge? _cachedDeliveryCharge;
  List<CouponModel>? _cachedCouponList;
  List<CouponModel>? _cachedGlobalCouponList;
  DateTime? _lastCacheTime;
  DateTime? _lastGlobalCouponCacheTime;
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration globalCouponCacheExpiry = Duration(minutes: 5);

  // 🔑 PRODUCT CACHE
  final Map<String, ProductModel?> _productCache = {};
  bool _isLoadingProducts = false;
  bool _productsLoaded = false;

  // 🔑 CALCULATION CACHE
  final Map<String, Map<String, dynamic>> _promotionalCalculationCache = {};
  final Map<String, double> _cachedFreeDeliveryKm = {};
  final Map<String, double> _cachedExtraKmCharge = {};
  List<TaxModel>? _cachedTaxList;
  bool _calculationCacheLoaded = false;

  // 🔑 COUPON LOADING
  bool _isLoadingCoupons = false;
  String _currentContext = "restaurant";

  // 🔑 RAZORPAY
  final RazorpayCrashPrevention _razorpayCrashPrevention =
      RazorpayCrashPrevention();

  // 🔑 DEBOUNCING
  Timer? _calculatePriceDebounceTimer;
  Timer? _syncPricesDebounceTimer;

  // ============ PUBLIC PROPERTIES ============
  late OrderPlacingProvider orderPlacingProvider;
  final CartProvider cartProvider = CartProvider();
  TextEditingController reMarkController = TextEditingController();
  Map<String, dynamic>? _martDeliverySettings;
  TextEditingController couponCodeController = TextEditingController();
  TextEditingController tipsController = TextEditingController();

  bool isProcessingOrder = false;
  DateTime? lastOrderAttempt;
  static const Duration orderDebounceTime = Duration(seconds: 3);

  ShippingAddress? selectedAddress = ShippingAddress();
  VendorModel vendorModel = VendorModel();
  DeliveryCharge deliveryChargeModel = DeliveryCharge();
  UserModel userModel = UserModel();
  List<CouponModel> couponList = <CouponModel>[];
  List<CouponModel> allCouponList = <CouponModel>[];
  String selectedFoodType = "Delivery";
  String selectedPaymentMethod = '';
  String deliveryType = "instant";
  DateTime scheduleDateTime = DateTime.now();
  double totalDistance = 0.0;
  double deliveryCharges = 0.0;
  double subTotal = 0.0;
  double couponAmount = 0.0;
  double specialDiscountAmount = 0.0;
  double specialDiscount = 0.0;
  String specialType = "";
  double deliveryTips = 0.0;
  double taxAmount = 0.0;
  double totalAmount = 0.0;
  double surgePercent = 0.0;

  bool isCartReady = false;
  bool isPaymentReady = false;
  bool isAddressValid = false;
  CouponModel selectedCouponModel = CouponModel();
  double originalDeliveryFee = 0.0;

  int _priceSyncVersion = 0;

  int get priceSyncVersion => _priceSyncVersion;

  bool get isLoadingProducts => _isLoadingProducts;

  bool get productsLoaded => _productsLoaded;

  bool get isLoadingCoupons => _isLoadingCoupons;

  CodSettingModel cashOnDeliverySettingModel = CodSettingModel();
  RazorPayModel razorPayModel = RazorPayModel();

  // ============ INITIALIZATION ============

  void initFunction(BuildContext context) {
    _startOperation('initFunction');

    // 🔑 CRITICAL: Reset all flags on init
    resetAllProcessingFlags();

    orderPlacingProvider = Provider.of<OrderPlacingProvider>(
      context,
      listen: false,
    );

    // 🔑 START OPTIMIZATION TIMERS
    _startCleanupScheduler();
    _startBatchUpdateScheduler();
    _startPriceSyncScheduler();

    Future.delayed(const Duration(seconds: 3), () {
      _restorePaymentState().then((_) {
        if (isPaymentInProgress && _lastPaymentId != null) {
          _checkPendingPaymentAndRecover();
        }
      });
      _initializeAddressWithPriority(context);
      getCartData();
      getPaymentSettings();
      validateUserProfile();

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (subTotal > cashOnDeliverySettingModel.getMaxAmount() &&
            selectedPaymentMethod == PaymentGateway.cod.name) {
          selectedPaymentMethod = PaymentGateway.razorpay.name;
        }
      });
    });

    _endOperation('initFunction');
    notifyListeners();
  }

  // ============ PERFORMANCE OPTIMIZATION METHODS ============

  void _startOperation(String operationId) {
    _performanceMetrics[operationId] = PerformanceMetric(
      startTime: DateTime.now(),
      operationId: operationId,
    );
    _operationCounts[operationId] = (_operationCounts[operationId] ?? 0) + 1;
  }

  void _endOperation(String operationId) {
    final metric = _performanceMetrics[operationId];
    if (metric != null) {
      metric.endTime = DateTime.now();
      metric.duration = metric.endTime!.difference(metric.startTime);

      if (metric.duration!.inMilliseconds > 200) {
        print(
          '[PERFORMANCE] ⚠️ $operationId took ${metric.duration!.inMilliseconds}ms',
        );
      }
    }
  }

  void logPerformance() {
    if (_performanceMetrics.isEmpty) return;

    print('[PERFORMANCE] ==== METRICS REPORT ====');
    _performanceMetrics.forEach((key, metric) {
      if (metric.duration != null) {
        final count = _operationCounts[key] ?? 1;
        final avgTime = metric.duration!.inMilliseconds / count;
        print(
          '[PERFORMANCE] $key: ${metric.duration!.inMilliseconds}ms (avg: ${avgTime.toStringAsFixed(1)}ms, count: $count)',
        );
      }
    });
    print('[PERFORMANCE] ========================');
  }

  void _startCleanupScheduler() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupResources();
    });
  }

  void _cleanupResources() {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));

    // Clean old operation timestamps
    _operationTimestamps.removeWhere(
      (key, value) => value.isBefore(cutoffTime),
    );

    // Clean recently synced items
    _recentlySyncedItems.removeWhere((id) {
      final lastSync = _operationTimestamps['sync_$id'];
      return lastSync == null || lastSync.isBefore(cutoffTime);
    });

    // Clean product cache (keep only items in cart)
    final productIdsInCart = HomeProvider.cartItem
        .map((item) => item.id)
        .where((id) => id != null)
        .toSet();
    _productCache.removeWhere((key, value) => !productIdsInCart.contains(key));

    // 🔑 NEW: Clean promotional calculation cache
    _promotionalCalculationCache.removeWhere(
      (key, value) => !productIdsInCart.any((id) => key.contains(id!)),
    );

    // 🔑 NEW: Clean cached delivery km
    _cachedFreeDeliveryKm.removeWhere(
      (key, value) => !productIdsInCart.any((id) => key.contains(id!)),
    );

    // 🔑 NEW: Clean cached extra km charge
    _cachedExtraKmCharge.removeWhere(
      (key, value) => !productIdsInCart.any((id) => key.contains(id!)),
    );

    // Clean performance metrics (keep last 50)
    if (_performanceMetrics.length > 50) {
      final keys = _performanceMetrics.keys.toList();
      for (int i = 0; i < keys.length - 50; i++) {
        _performanceMetrics.remove(keys[i]);
      }
    }

    // Clean operation counts (keep last 100)
    if (_operationCounts.length > 100) {
      final keys = _operationCounts.keys.toList();
      for (int i = 0; i < keys.length - 100; i++) {
        _operationCounts.remove(keys[i]);
      }
    }

    // 🔑 NEW: Clean processed payment IDs if too many
    if (_processedPaymentIds.length > _maxProcessedPaymentIds) {
      final idsToRemove = _processedPaymentIds
          .take(_processedPaymentIds.length - _maxProcessedPaymentIds)
          .toList();
      for (final id in idsToRemove) {
        _processedPaymentIds.remove(id);
      }
    }

    print('[CLEANUP] ✅ Freed up resources');
  }

  void _startBatchUpdateScheduler() {
    _batchUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_pendingUpdates.isNotEmpty && !_isBatchUpdateScheduled) {
        _isBatchUpdateScheduled = true;

        Future.delayed(const Duration(milliseconds: 500), () {
          _processPendingUpdates();
          _isBatchUpdateScheduled = false;
        });
      }
    });
  }

  void _startPriceSyncScheduler() {
    _priceSyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isPriceSyncScheduled) {
        _isPriceSyncScheduled = true;

        Future.delayed(const Duration(seconds: 1), () {
          unawaited(syncCartPricesInBackground());
          _isPriceSyncScheduled = false;
        });
      }
    });
  }

  void _processPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;

    final updates = List<Function()>.from(_pendingUpdates);
    _pendingUpdates.clear();

    // Execute all pending updates
    for (final update in updates) {
      try {
        update();
      } catch (e) {
        print('[PENDING_UPDATES] ❌ Error: $e');
      }
    }

    // Notify once after all updates
    _priceSyncVersion++;
    notifyListeners();
  }

  // ============ ADDRESS MANAGEMENT ============

  Future<void> initializeAddress(BuildContext context) async {
    await _initializeAddressWithPriority(context);
  }

  Future<void> _initializeAddressWithPriority(BuildContext context) async {
    _startOperation('initializeAddress');

    try {
      if (_addressInitialized &&
          selectedAddress != null &&
          selectedAddress!.location?.latitude != null &&
          selectedAddress!.location?.longitude != null) {
        print('[ADDRESS] ✅ Already initialized');
        return;
      }

      // PRIORITY 1: Saved addresses
      if (Constant.userModel != null &&
          Constant.userModel!.shippingAddress != null &&
          Constant.userModel!.shippingAddress!.isNotEmpty) {
        final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => Constant.userModel!.shippingAddress!.first,
        );
        selectedAddress = defaultAddress;
        _addressInitialized = true;

        await initialLiseSurgeValue(
          defaultAddress.location?.latitude ?? 0.0,
          defaultAddress.location?.longitude ?? 0.0,
        );

        if (HomeProvider.cartItem.isNotEmpty) {
          await _loadFreshVendorForCart();
          if (vendorModel.id != null) {
            await calculatePrice();
          }
        }

        notifyListeners();
        print('[ADDRESS] ✅ Using saved address');
        return;
      }

      // PRIORITY 2: Current location
      final homeScreenAddress = await _getCurrentLocationAddress(context);
      if (homeScreenAddress != null) {
        selectedAddress = homeScreenAddress;
        _addressInitialized = true;

        await initialLiseSurgeValue(
          homeScreenAddress.location?.latitude ?? 0.0,
          homeScreenAddress.location?.longitude ?? 0.0,
        );

        if (HomeProvider.cartItem.isNotEmpty) {
          await _loadFreshVendorForCart();
          if (vendorModel.id != null) {
            await calculatePrice();
          }
        }

        notifyListeners();
        print('[ADDRESS] ✅ Using current location');
        return;
      }

      selectedAddress = null;
      _addressInitialized = false;
      notifyListeners();
    } catch (e) {
      print('[ADDRESS] ❌ Error: $e');
      selectedAddress = null;
      _addressInitialized = false;
      notifyListeners();
    } finally {
      _endOperation('initializeAddress');
    }
  }

  Future<ShippingAddress?> _getCurrentLocationAddress(
    BuildContext context,
  ) async {
    try {
      if (Constant.selectedLocation.location?.latitude != null &&
          Constant.selectedLocation.location?.longitude != null) {
        final lat = Constant.selectedLocation.location!.latitude!;
        final lng = Constant.selectedLocation.location!.longitude!;

        if (lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0) {
          String address = Constant.selectedLocation.address ?? '';
          String locality = Constant.selectedLocation.locality ?? '';

          if (address.isEmpty ||
              locality.isEmpty ||
              address == 'Current Location' ||
              locality == 'Current Location') {
            return null;
          }

          String? detectedZoneId;

          if (Constant.selectedLocation.zoneId != null &&
              Constant.selectedLocation.zoneId!.isNotEmpty) {
            detectedZoneId = Constant.selectedLocation.zoneId;
          } else if (Constant.selectedZone?.id != null &&
              Constant.selectedZone!.id!.isNotEmpty) {
            detectedZoneId = Constant.selectedZone!.id;
          } else {
            detectedZoneId = await _detectZoneIdForCoordinates(
              lat,
              lng,
              context,
            );
          }

          return ShippingAddress(
            id: 'home_screen_address_${DateTime.now().millisecondsSinceEpoch}',
            addressAs:
                Constant.selectedLocation.addressAs ?? 'Current Location',
            address: address,
            locality: locality,
            location: UserLocation(latitude: lat, longitude: lng),
            isDefault: false,
            zoneId: detectedZoneId,
          );
        }
      }
      return null;
    } catch (e) {
      print('[CURRENT_ADDRESS] ❌ Error: $e');
      return null;
    }
  }

  Future<String?> _detectZoneIdForCoordinates(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    try {
      final zoneModel = await HomeProvider.getCurrentZone(latitude, longitude);
      if (zoneModel == null || zoneModel.zone == null) {
        return null;
      }

      final zone = zoneModel.zone!;
      if (zone.area != null && zone.area!.isNotEmpty) {
        if (Constant.isPointInPolygon(
          LatLng(latitude, longitude),
          zone.area!.cast<GeoPoint>(),
        )) {
          return zone.id;
        }
      }
      return null;
    } catch (e) {
      print('[ZONE_DETECTION] ❌ Error: $e');
      return null;
    }
  }

  // ============ PRICE CALCULATION ============

  Future<void> calculatePrice() async {
    // 🔑 DEBOUNCE: Cancel any pending calculation
    _calculatePriceDebounceTimer?.cancel();

    // 🔑 RATE LIMITING
    final now = DateTime.now();
    final lastCall = _operationTimestamps['calculatePrice'];

    if (lastCall != null && now.difference(lastCall) < _rateLimitDuration) {
      // Schedule for later
      _calculatePriceDebounceTimer = Timer(
        _rateLimitDuration - now.difference(lastCall),
        () {
          if (!_isCalculatingPrice) {
            _calculatePriceInternal();
          }
        },
      );
      return;
    }

    _operationTimestamps['calculatePrice'] = now;
    await _calculatePriceInternal();
  }

  Future<void> _calculatePriceInternal() async {
    if (_isCalculatingPrice) return;

    _isCalculatingPrice = true;
    _startOperation('calculatePrice');

    try {
      await ANRPrevention.executeWithANRPrevention(
        'CartController_calculatePrice',
        () async {
          // Cache tax list
          if (_cachedTaxList != null) {
            Constant.taxList = _cachedTaxList;
          } else if (Constant.taxList == null) {
            Constant.taxList = await FireStoreUtils.getTaxList();
            _cachedTaxList = Constant.taxList;
          }

          // Store previous values
          final previousSubTotal = subTotal;
          final previousTotalAmount = totalAmount;
          final previousDeliveryCharges = deliveryCharges;
          final previousTaxAmount = taxAmount;

          if (HomeProvider.cartItem.isEmpty) {
            deliveryCharges = 0.0;
            subTotal = 0.0;
            couponAmount = 0.0;
            specialDiscountAmount = 0.0;
            taxAmount = 0.0;
            totalAmount = 0.0;
            notifyListeners();
            return;
          }

          // Don't reset for non-empty cart - each _calculate* overwrites in sequence.
          // Avoids UI flicker to 0 during async calculation.

          // Load vendor if needed
          if (vendorModel.id == null) {
            await _loadVendorForPriceCalculation();
          }

          // Calculate subtotal
          await _calculateSubTotal();

          // Calculate delivery charges
          if (HomeProvider.cartItem.isNotEmpty &&
              selectedFoodType == "Delivery") {
            await _calculateDeliveryCharges();
          }

          // Calculate coupons
          await _calculateCoupons();

          // Calculate tax
          await _calculateTax(previousDeliveryCharges);

          // Calculate total
          await _calculateTotal();

          // Validate calculations
          _validateCalculations(
            previousSubTotal,
            previousTotalAmount,
            previousDeliveryCharges,
            previousTaxAmount,
          );

          checkAndUpdatePaymentMethod();
          updateCartReadiness();

          notifyListeners();
        },
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      print('[CART_PRICE] ❌ Calculation failed: $e');
      notifyListeners();
      rethrow;
    } finally {
      _isCalculatingPrice = false;
      _endOperation('calculatePrice');
    }
  }

  Future<void> _loadVendorForPriceCalculation() async {
    try {
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();

      if (martItems.isNotEmpty) {
        await _loadFreshMartVendor(martItems);
      } else if (HomeProvider.cartItem.isNotEmpty) {
        await _loadFreshRestaurantVendor(HomeProvider.cartItem.first.vendorID);
      }
    } catch (e) {
      print('[CART_VENDOR] ⚠️ Error loading vendor for price: $e');
    }
  }

  Future<void> _calculateSubTotal() async {
    subTotal = 0.0;

    for (var element in HomeProvider.cartItem) {
      final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;

      double itemPrice;
      if (hasPromo) {
        itemPrice = double.parse(element.price.toString());
      } else if (double.parse(element.discountPrice.toString()) <= 0) {
        itemPrice = double.parse(element.price.toString());
      } else {
        itemPrice = double.parse(element.discountPrice.toString());
      }

      final quantity = double.parse(element.quantity.toString());
      final extrasPrice = double.parse(element.extrasPrice.toString());

      subTotal += (itemPrice * quantity) + (extrasPrice * quantity);
    }
  }

  Future<void> _calculateDeliveryCharges() async {
    if (selectedAddress?.location?.latitude != null &&
        selectedAddress?.location?.longitude != null &&
        vendorModel.latitude != null &&
        vendorModel.longitude != null) {
      final customerLat = selectedAddress?.location!.latitude;
      final customerLng = selectedAddress?.location!.longitude;
      final vendorLat = vendorModel.latitude!;
      final vendorLng = vendorModel.longitude!;

      final distanceString = Constant.getDistance(
        lat1: customerLat.toString(),
        lng1: customerLng.toString(),
        lat2: vendorLat.toString(),
        lng2: vendorLng.toString(),
      );

      totalDistance = double.parse(distanceString);
    } else {
      totalDistance = 0.0;
    }

    final hasPromotionalItems = HomeProvider.cartItem.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );

    final hasMartItems = hasMartItemsInCart();

    if (hasPromotionalItems) {
      calculatePromotionalDeliveryChargeFast();
    } else if (hasMartItems) {
      calculateMartDeliveryCharge();
    } else {
      calculateRegularDeliveryCharge();
    }
  }

  Future<void> _calculateCoupons() async {
    CouponModel? activeCoupon;

    if (selectedCouponModel.id != null && selectedCouponModel.id!.isNotEmpty) {
      activeCoupon = selectedCouponModel;
    } else if (couponCodeController.text.isNotEmpty) {
      activeCoupon = couponList
          .where((element) => element.code == couponCodeController.text)
          .firstOrNull;
    }

    final hasPromotionalItems = HomeProvider.cartItem.any((item) {
      final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
      final discountPriceValue =
          double.tryParse(item.discountPrice.toString()) ?? 0.0;
      final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
      final isPricePromotional =
          priceValue > 0 &&
          discountPriceValue > 0 &&
          priceValue < discountPriceValue;
      return hasPromo || isPricePromotional;
    });

    if (hasPromotionalItems && activeCoupon != null) {
      ShowToastDialog.showToast(
        "Coupons cannot be applied to promotional items".tr,
      );
      couponCodeController.text = "";
      selectedCouponModel = CouponModel();
      couponAmount = 0.0;
    } else if (activeCoupon != null) {
      final minimumValue =
          double.tryParse(activeCoupon.itemValue ?? '0') ?? 0.0;
      if (subTotal < minimumValue) {
        ShowToastDialog.showToast(
          "Minimum order value for this coupon is ${Constant.amountShow(amount: activeCoupon.itemValue ?? '0')}"
              .tr,
        );
        couponCodeController.text = "";
        selectedCouponModel = CouponModel();
        couponAmount = 0.0;
      } else {
        if (activeCoupon.discountType == "percentage") {
          couponAmount =
              (subTotal * double.parse(activeCoupon.discount.toString())) / 100;
        } else {
          couponAmount = double.parse(activeCoupon.discount.toString());
        }
      }
    } else {
      couponAmount = 0.0;
    }

    if (specialDiscountAmount > 0) {
      specialDiscountAmount = (subTotal * specialDiscountAmount) / 100;
    }
  }

  Future<void> _calculateTax(double previousDeliveryCharges) async {
    double sgst = 0.0;
    double gst = 0.0;

    final hasPromotionalItemsForTax = HomeProvider.cartItem.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );

    final hasMartItems = hasMartItemsInCart();

    final double taxableDeliveryFee = originalDeliveryFee > 0
        ? originalDeliveryFee
        : (deliveryCharges > 0 ? deliveryCharges : 0.0);

    if (Constant.taxList != null) {
      for (var element in Constant.taxList!) {
        if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
          sgst = Constant.calculateTax(
            amount: subTotal.toString(),
            taxModel: element,
          );
        } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
          gst = Constant.calculateTax(
            amount: taxableDeliveryFee.toString(),
            taxModel: element,
          );
        }
      }
    }

    sgst = sgst.isNaN ? 0.0 : sgst;
    gst = gst.isNaN ? 0.0 : gst;
    taxAmount = sgst + gst;

    if (taxAmount == 0.0) {
      double sgstFallback = subTotal * 0.05;
      double gstFallback = taxableDeliveryFee > 0
          ? taxableDeliveryFee * 0.18
          : 0.0;
      taxAmount = sgstFallback + gstFallback;
    }

    if (taxAmount.isNaN) taxAmount = 0.0;
  }

  Future<void> _calculateTotal() async {
    bool isFreeDelivery = false;

    if (HomeProvider.cartItem.isNotEmpty && selectedFoodType == "Delivery") {
      final hasPromotionalItems = HomeProvider.cartItem.any(
        (item) => item.promoId != null && item.promoId!.isNotEmpty,
      );

      final hasMartItems = hasMartItemsInCart();

      if (hasPromotionalItems) {
        final promotionalItems = HomeProvider.cartItem
            .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
            .toList();

        final firstPromoItem = promotionalItems.first;
        final freeDeliveryKm = _getCachedFreeDeliveryKm(
          firstPromoItem.id ?? '',
          firstPromoItem.vendorID ?? '',
        );

        if (totalDistance <= freeDeliveryKm) {
          isFreeDelivery = true;
        }
      } else if (hasMartItems) {
        final dc = deliveryChargeModel;
        final threshold = dc.itemTotalThreshold ?? 299;
        final freeKm = dc.freeDeliveryDistanceKm ?? 7;

        if (subTotal >= threshold && totalDistance <= freeKm) {
          isFreeDelivery = true;
        }
      } else {
        final dc = deliveryChargeModel;
        final threshold = dc.itemTotalThreshold ?? 299;
        final freeKm = dc.freeDeliveryDistanceKm ?? 7;

        if (subTotal >= threshold && totalDistance <= freeKm) {
          isFreeDelivery = true;
        }
      }
    }

    totalAmount =
        (subTotal - couponAmount - specialDiscountAmount) +
        taxAmount +
        (isFreeDelivery ? 0.0 : deliveryCharges) +
        deliveryTips +
        surgePercent;
  }

  void _validateCalculations(
    double previousSubTotal,
    double previousTotalAmount,
    double previousDeliveryCharges,
    double previousTaxAmount,
  ) {
    final bool isCartEmpty = HomeProvider.cartItem.isEmpty;
    final bool hasInvalidValues =
        subTotal < 0 ||
        totalAmount < 0 ||
        subTotal.isNaN ||
        totalAmount.isNaN ||
        subTotal.isInfinite ||
        totalAmount.isInfinite ||
        (!isCartEmpty && (subTotal == 0.0 || totalAmount == 0.0));

    if (hasInvalidValues) {
      print('[CALC_VALIDATION] ⚠️ Invalid values, restoring previous values');
      subTotal = previousSubTotal;
      totalAmount = previousTotalAmount;
      deliveryCharges = previousDeliveryCharges;
      taxAmount = previousTaxAmount;
    }
  }

  // ============ PRICE SYNC OPTIMIZATIONS ============

  Future<void> syncCartPricesInBackground() async {
    if (HomeProvider.cartItem.isEmpty) {
      print('[PRICE_SYNC] Cart is empty, skipping sync');
      return;
    }

    _startOperation('syncCartPrices');

    try {
      print('[PRICE_SYNC] 🔄 Starting optimized price sync...');

      // 🔑 OPTIMIZATION: Skip if recently synced
      final lastSyncKey = 'last_full_sync';
      final lastSyncTime = _operationTimestamps[lastSyncKey];
      if (lastSyncTime != null &&
          DateTime.now().difference(lastSyncTime) < Duration(minutes: 1)) {
        print('[PRICE_SYNC] ⏱️ Skipping - synced recently');
        _endOperation('syncCartPrices');
        return;
      }

      // 🔑 OPTIMIZATION: Process in smaller batches
      final List<CartProductModel> itemsToSync = [];
      for (var item in HomeProvider.cartItem) {
        // Skip recently synced items
        final itemLastSync = _operationTimestamps['sync_${item.id}'];
        if (itemLastSync == null ||
            DateTime.now().difference(itemLastSync) > Duration(minutes: 5)) {
          itemsToSync.add(item);
        }
      }

      if (itemsToSync.isEmpty) {
        print('[PRICE_SYNC] ℹ️ No items need syncing');
        _endOperation('syncCartPrices');
        return;
      }

      print('[PRICE_SYNC] 🔍 Syncing ${itemsToSync.length} items');

      // 🔑 OPTIMIZATION: Process in parallel batches
      final batchSize = 5;
      final List<List<CartProductModel>> batches = [];
      for (int i = 0; i < itemsToSync.length; i += batchSize) {
        batches.add(
          itemsToSync.sublist(
            i,
            i + batchSize > itemsToSync.length
                ? itemsToSync.length
                : i + batchSize,
          ),
        );
      }

      bool hasUpdates = false;
      List<PriceUpdateResult> allUpdates = [];

      // Process batches in parallel but with rate limiting
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        print('[PRICE_SYNC] 📦 Processing batch ${i + 1}/${batches.length}');

        try {
          final batchUpdates = await validateAndUpdateCartPricesForBatch(batch);

          for (var entry in batchUpdates.entries) {
            final result = entry.value;

            if (result.hasPriceChange &&
                result.oldPrice != null &&
                result.newPrice != null) {
              hasUpdates = true;
              allUpdates.add(result);

              // Update immediately
              await _updateCartItemPrice(result);

              // Update sync timestamp
              _operationTimestamps['sync_${result.productId}'] = DateTime.now();
              _recentlySyncedItems.add(result.productId);

              print(
                '[PRICE_SYNC] ✅ Updated ${result.productName}: ₹${result.oldPrice} → ₹${result.newPrice}',
              );
            }
          }

          // Small delay between batches to avoid rate limiting
          if (i < batches.length - 1) {
            await Future.delayed(Duration(milliseconds: 100));
          }
        } catch (e) {
          print('[PRICE_SYNC] ❌ Error in batch ${i + 1}: $e');
        }
      }

      // Update timestamp
      _operationTimestamps[lastSyncKey] = DateTime.now();

      if (hasUpdates) {
        print('[PRICE_SYNC] ✅ Sync complete with ${allUpdates.length} updates');

        // Force UI update
        _priceSyncVersion++;
        notifyListeners();

        // Show notification if app is in foreground
        if (allUpdates.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEnhancedPriceUpdateDialog(allUpdates);
          });
        }
      } else {
        print('[PRICE_SYNC] ℹ️ No price changes detected');
      }
    } catch (e, stackTrace) {
      print('[PRICE_SYNC] ❌ Error: $e');
      print('[PRICE_SYNC] Stack trace: $stackTrace');
    } finally {
      _endOperation('syncCartPrices');
    }
  }

  void _showEnhancedPriceUpdateDialog(List<PriceUpdateResult> updates) {
    try {
      // Don't show if app is not in foreground
      if (!Get.isSnackbarOpen) {
        // For single update, show compact snackbar
        if (updates.length == 1) {
          final update = updates.first;
          Get.snackbar(
            '💰 Price Updated'.tr,
            '${update.productName ?? "Item"}: ₹${update.oldPrice} → ₹${update.newPrice}',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: Icon(Icons.currency_rupee, color: Colors.white),
            shouldIconPulse: true,
            margin: EdgeInsets.all(10),
            borderRadius: 8,
            animationDuration: Duration(milliseconds: 300),
            mainButton: TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                _showDetailedPriceUpdateDialog(updates);
              },
              child: Text('Details', style: TextStyle(color: Colors.white)),
            ),
          );
        } else {
          // For multiple updates, show expanded view
          _showDetailedPriceUpdateDialog(updates);
        }
      }
    } catch (e) {
      print('[PRICE_UPDATE_UI] ❌ Error showing notification: $e');
    }
  }

  void _showDetailedPriceUpdateDialog(List<PriceUpdateResult> updates) {
    // Calculate total savings
    double totalSavings = 0;
    double totalIncrease = 0;

    for (final update in updates) {
      final oldPrice = double.tryParse(update.oldPrice ?? '0') ?? 0;
      final newPrice = double.tryParse(update.newPrice ?? '0') ?? 0;
      final difference = newPrice - oldPrice;

      if (difference < 0) {
        totalSavings += difference.abs();
      } else if (difference > 0) {
        totalIncrease += difference;
      }
    }

    // Determine message based on price changes
    String message = '';
    Color primaryColor = Colors.blue;

    if (totalSavings > 0 && totalIncrease == 0) {
      message = 'You saved ₹${totalSavings.toStringAsFixed(2)}';
      primaryColor = Colors.green;
    } else if (totalIncrease > 0 && totalSavings == 0) {
      message = 'Price increased by ₹${totalIncrease.toStringAsFixed(2)}';
      primaryColor = Colors.orange;
    } else if (totalSavings > 0 && totalIncrease > 0) {
      message = 'Mixed price changes';
      primaryColor = Colors.blue;
    } else {
      message = '${updates.length} items updated';
    }

    // Show as bottom sheet for better UX
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Price Updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Summary
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        totalSavings > totalIncrease
                            ? Icons.savings
                            : Icons.trending_up,
                        color: totalSavings > totalIncrease
                            ? Colors.green
                            : Colors.orange,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${updates.length} item${updates.length > 1 ? 's' : ''} updated',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),

            // Item List
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(Get.context!).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: updates.length,
                itemBuilder: (context, index) {
                  final update = updates[index];
                  final oldPrice = double.tryParse(update.oldPrice ?? '0') ?? 0;
                  final newPrice = double.tryParse(update.newPrice ?? '0') ?? 0;
                  final difference = newPrice - oldPrice;
                  final isPriceDrop = difference < 0;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPriceDrop
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPriceDrop
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isPriceDrop ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        update.productName ?? 'Item ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        isPriceDrop ? 'Price decreased' : 'Price increased',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${newPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPriceDrop ? Colors.green : Colors.orange,
                            ),
                          ),
                          Text(
                            '₹${oldPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            isPriceDrop
                                ? 'Save ₹${difference.abs().toStringAsFixed(2)}'
                                : '+₹${difference.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPriceDrop ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Continue Shopping',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close the dialog first
                        calculatePrice(); // Recalculate cart total

                        // Navigate to cart screen after a small delay
                        Future.delayed(Duration(milliseconds: 300), () {
                          Get.to(() => CartScreen()); // Navigate to cart screen
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Update Cart',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Safe area for bottom navigation
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Future<Map<String, PriceUpdateResult>> validateAndUpdateCartPricesForBatch(
    List<CartProductModel> batch,
  ) async {
    final Map<String, PriceUpdateResult> results = {};

    // 🔑 PARALLEL FETCHING
    final fetchFutures = batch.map((cartItem) async {
      try {
        return await _validateSingleItemPrice(cartItem);
      } catch (e) {
        print('[BATCH_VALIDATE] ❌ Error validating ${cartItem.id}: $e');
        return null;
      }
    }).toList();

    try {
      final batchResults = await Future.wait(fetchFutures, eagerError: false);

      for (var result in batchResults) {
        if (result != null) {
          results[result.productId] = result;
        }
      }
    } catch (e) {
      print('[BATCH_VALIDATE] ❌ Batch validation failed: $e');
    }

    return results;
  }

  Future<PriceUpdateResult> _validateSingleItemPrice(
    CartProductModel cartItem,
  ) async {
    if (cartItem.id == null || cartItem.id!.isEmpty) {
      return PriceUpdateResult(
        productId: cartItem.id ?? 'unknown',
        status: PriceStatus.error,
        error: 'Invalid product ID',
      );
    }

    final isPromotionalItem =
        cartItem.promoId != null && cartItem.promoId!.isNotEmpty;

    if (isPromotionalItem) {
      return PriceUpdateResult(
        productId: cartItem.id!,
        status: PriceStatus.noChange,
        oldPrice: cartItem.price,
        newPrice: cartItem.price,
        productName: cartItem.name,
      );
    }

    try {
      dynamic currentProduct;
      final isMart = _isMartItem(cartItem);

      if (isMart) {
        final martService = Get.find<MartFirestoreService>();
        currentProduct = await martService.getItemById(cartItem.id!);
      } else {
        currentProduct = await FireStoreUtils.getProductById(cartItem.id!);
      }

      if (currentProduct == null) {
        return PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.productNotFound,
          oldPrice: cartItem.price,
          productName: cartItem.name,
        );
      }

      final currentPrice = _getCurrentProductPrice(currentProduct, cartItem);

      final storedDiscountPrice =
          double.tryParse(cartItem.discountPrice ?? "0") ?? 0.0;
      final storedRegularPrice = double.tryParse(cartItem.price ?? "0") ?? 0.0;
      final storedDisplayPrice =
          storedDiscountPrice > 0 && storedDiscountPrice < storedRegularPrice
          ? storedDiscountPrice
          : storedRegularPrice;

      if ((currentPrice - storedDisplayPrice).abs() > 0.01) {
        return PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.priceChanged,
          oldPrice: storedDisplayPrice.toStringAsFixed(2),
          newPrice: currentPrice.toStringAsFixed(2),
          productName: cartItem.name,
        );
      } else {
        return PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.noChange,
          oldPrice: storedDisplayPrice.toStringAsFixed(2),
          newPrice: currentPrice.toStringAsFixed(2),
        );
      }
    } catch (e) {
      return PriceUpdateResult(
        productId: cartItem.id!,
        status: PriceStatus.error,
        oldPrice: cartItem.price,
        error: e.toString(),
      );
    }
  }

  // ============ PROFILE VALIDATION METHODS ============

  Future<void> validateUserProfile() async {
    await validateUserProfileBulletproof();
  }

  Future<void> validateUserProfileBulletproof() async {
    isProfileValidating = true;
    notifyListeners();

    try {
      UserModel? user;
      int attempts = 0;
      const maxAttempts = 3;

      while (user == null && attempts < maxAttempts) {
        attempts++;

        try {
          final userId = await SqlStorageConst.getFirebaseId();
          user = await AddressListProvider.getUserProfile(
            userId.toString(),
          ).timeout(const Duration(seconds: 10));

          if (user != null) {
            break;
          }
        } catch (e) {
          if (attempts == 2 && Constant.userModel != null) {
            user = Constant.userModel;
            break;
          }

          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 2));
            print('[PROFILE] 🔄 Wait completed, proceeding to next attempt');
          }
        }
      }

      if (user == null) {
        isProfileValid = false;
        ShowToastDialog.showToast(
          "Unable to verify profile. Please check your internet connection and try again."
              .tr,
        );
        return;
      }

      final hasFirstName =
          user.firstName != null &&
          user.firstName!.trim().isNotEmpty &&
          user.firstName!.trim().length >= 2;

      final hasPhoneNumber =
          user.phoneNumber != null &&
          user.phoneNumber!.trim().isNotEmpty &&
          user.phoneNumber!.trim().length >= 10;

      final hasEmail =
          user.email != null &&
          user.email!.trim().isNotEmpty &&
          user.email!.contains('@') &&
          user.email!.contains('.');

      isProfileValid = hasFirstName && hasPhoneNumber && hasEmail;

      userModel = user;
      Constant.userModel = user;

      if (!isProfileValid) {
        final missingFields = <String>[];
        if (!hasFirstName) missingFields.add('First Name (min 2 chars)');
        if (!hasPhoneNumber) missingFields.add('Phone Number (min 10 digits)');
        if (!hasEmail) missingFields.add('Valid Email Address');

        print('[PROFILE] ⚠️ Missing fields: ${missingFields.join(', ')}');
      }

      notifyListeners();
    } catch (e) {
      isProfileValid = false;
      ShowToastDialog.showToast(
        "Error validating profile. Please try again.".tr,
      );
      notifyListeners();
    } finally {
      isProfileValidating = false;
      notifyListeners();
    }
  }

  // ============ PAYMENT HANDLER METHODS ============

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    try {
      final paymentId = response.paymentId;
      print("handlePaymentSuccess  ${paymentId}");

      if (paymentId == null || paymentId.isEmpty) {
        print('❌ [PAYMENT_SUCCESS] Invalid payment ID, ignoring callback');
        return;
      }

      if (_processedPaymentIds.contains(paymentId)) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Payment ID $paymentId already processed, ignoring duplicate callback',
        );
        return;
      }

      if (_isOrderBeingCreated) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Order is already being created, ignoring duplicate callback',
        );
        return;
      }

      if (isPaymentCompleted && _lastPaymentId == paymentId) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Payment already completed for ID $paymentId, ignoring duplicate callback',
        );
        return;
      }

      print('✅ [PAYMENT_SUCCESS] Processing payment ID: $paymentId');

      _processedPaymentIds.add(paymentId);

      if (_processedPaymentIds.length > _maxProcessedPaymentIds) {
        final idsToRemove = _processedPaymentIds
            .take(_processedPaymentIds.length - _maxProcessedPaymentIds)
            .toList();
        for (final id in idsToRemove) {
          _processedPaymentIds.remove(id);
        }
      }

      // Use the setter method instead of direct assignment
      _lockGlobal();

      _lastPaymentId = paymentId;
      _lastPaymentTime = DateTime.now();
      isPaymentCompleted = true;

      ShowToastDialog.showLoader("Processing payment and placing order...".tr);

      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          print(
            '[PAYMENT_SUCCESS] Starting order placement after delay for payment ID: $paymentId',
          );
          await placeOrderAfterPayment();
        } catch (e, stackTrace) {
          print('❌ [PAYMENT_SUCCESS] Error in placeOrderAfterPayment: $e');
          print('❌ [PAYMENT_SUCCESS] Stack trace: $stackTrace');

          _processedPaymentIds.remove(paymentId);
          _isOrderBeingCreated = false;
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;

          ShowToastDialog.showToast(
            "Order placement failed. Your payment is safe. Please try again."
                .tr,
          );
        } finally {
          // Use the unlock method instead of direct assignment
          _unlockGlobal();
        }
      });

      notifyListeners();
    } catch (e) {
      print('❌ [PAYMENT_SUCCESS] Exception in handlePaymentSuccess: $e');
      // Use the unlock method instead of direct assignment
      _unlockGlobal();

      isPaymentInProgress = false;
      _isOrderBeingCreated = false;

      if (response.paymentId != null) {
        _processedPaymentIds.remove(response.paymentId);
      }

      ShowToastDialog.showToast(
        "Payment processing failed. Please try again.".tr,
      );
      notifyListeners();
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    try {
      isPaymentInProgress = false;
      endOrderProcessing();

      ShowToastDialog.showToast("Payment failed: ${response.message}".tr);
      notifyListeners();
    } catch (e) {
      isPaymentInProgress = false;
      endOrderProcessing();
      ShowToastDialog.showToast("Payment failed. Please try again.".tr);
      notifyListeners();
    }
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    try {
      ShowToastDialog.showToast(
        "External wallet selected: ${response.walletName}".tr,
      );
      notifyListeners();
    } catch (e) {
      isPaymentInProgress = false;
      ShowToastDialog.showToast("External wallet error. Please try again.".tr);
      notifyListeners();
    }
  }

  void handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Processing!! via".tr);
  }

  List<CartProductModel> tempProduc = [];

  /// Check if order is already in progress (idempotency)
  // bool _isOrderInProgress() {
  //   return _orderInProgress || isProcessingOrder;
  // }

  /// Start order processing with idempotency
  void _startOrderProcessing() {
    _orderInProgress = true;
    isProcessingOrder = true;
    notifyListeners();
  }

  // ============ ORDER PROCESSING METHODS ============

  placeOrder(BuildContext context) async {
    _startOperation('placeOrder');

    try {
      // 🔑 CRITICAL FIX: Check if order is already being processed
      if (isProcessingOrder) {
        ShowToastDialog.showToast(
          "Order is already being processed. Please wait...".tr,
        );
        return;
      }

      if (lastOrderAttempt != null &&
          DateTime.now().difference(lastOrderAttempt!) < orderDebounceTime) {
        ShowToastDialog.showToast("Please wait before trying again...".tr);
        return;
      }

      // 🔑 IMPORTANT: Set processing flag EARLY
      startOrderProcessing();
      lastOrderAttempt = DateTime.now();

      // Validate before proceeding
      if (!await validateOrderBeforePayment(context)) {
        // 🔑 CRITICAL: Clear processing flag on validation failure
        endOrderProcessing();
        return;
      }

      if (HomeProvider.cartItem.isEmpty) {
        ShowToastDialog.showToast(
          "Cart is empty. Please add items to cart.".tr,
        );
        endOrderProcessing();
        return;
      }

      // Recalculate prices
      await calculatePrice();

      // Validate calculations
      if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
        print('❌ [ORDER_VALIDATION] Invalid subTotal: $subTotal');
        ShowToastDialog.showToast(
          "Order calculation error. Please refresh and try again.".tr,
        );
        endOrderProcessing();
        return;
      }

      if (totalAmount <= 0 || totalAmount.isNaN || totalAmount.isInfinite) {
        print('❌ [ORDER_VALIDATION] Invalid totalAmount: $totalAmount');
        ShowToastDialog.showToast(
          "Order total is invalid. Please refresh and try again.".tr,
        );
        endOrderProcessing();
        return;
      }

      // Validate payment method
      if (selectedPaymentMethod.isEmpty) {
        ShowToastDialog.showToast("Please select payment method".tr);
        endOrderProcessing();
        return;
      }

      // 🔑 CRITICAL FIX: Handle different payment methods
      if (selectedPaymentMethod == PaymentGateway.cod.name) {
        await _processCODOrder();
      } else if (selectedPaymentMethod == PaymentGateway.razorpay.name) {
        await _processRazorpayOrder();
      } else if (selectedPaymentMethod == PaymentGateway.wallet.name) {
        await _processWalletOrder();
      } else {
        ShowToastDialog.showToast("Invalid payment method selected".tr);
        endOrderProcessing();
      }
    } catch (e) {
      print('❌ [PLACE_ORDER] Error: $e');

      // 🔑 CRITICAL: Always clear processing flag on error
      endOrderProcessing();

      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
        // Specific error already shown
      } else {
        ShowToastDialog.showToast(
          "An error occurred while placing your order. Please try again.".tr,
        );
      }
    } finally {
      _endOperation('placeOrder');
    }
  }

  Future<void> _processCODOrder() async {
    try {
      // Validate COD availability
      if (cashOnDeliverySettingModel.isEnabled != true) {
        ShowToastDialog.showToast(
          "Cash on Delivery is currently disabled. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      if (subTotal > cashOnDeliverySettingModel.getMaxAmount()) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      if (hasPromotionalItems()) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for promotional items. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      // 🔑 CRITICAL: Clear any leftover payment state for COD
      isPaymentInProgress = false;
      isPaymentCompleted = false;
      _lastPaymentId = null;

      // Show loader and place order
      ShowToastDialog.showLoader("Placing your order...".tr);
      await setOrder();
    } catch (e) {
      print('❌ [COD_ORDER] Error: $e');
      ShowToastDialog.closeLoader();
      endOrderProcessing();
      ShowToastDialog.showToast("Failed to place order. Please try again.".tr);
    }
  }

  void endOrderProcessing() {
    // 🔑 CRITICAL: Reset ALL processing flags
    isProcessingOrder = false;
    _orderInProgress = false;
    _isOrderBeingCreated = false;
    _isGlobalLocked = false;

    print('✅ [ORDER_PROCESSING] All flags reset');

    notifyListeners();
  }

  Future<void> _processRazorpayOrder() async {
    try {
      if (!isPaymentCompleted || _lastPaymentId == null) {
        ShowToastDialog.showToast(
          "Payment not completed. Please complete payment before placing order."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      ShowToastDialog.showLoader("Processing your order...".tr);
      await placeOrderAfterPayment();
    } catch (e) {
      print('❌ [RAZORPAY_ORDER] Error: $e');
      ShowToastDialog.closeLoader();
      endOrderProcessing();
      ShowToastDialog.showToast(
        "Failed to process order. Please try again.".tr,
      );
    }
  }

  Future<void> _processWalletOrder() async {
    try {
      if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
        ShowToastDialog.showLoader("Placing your order...".tr);
        await setOrder();
      } else {
        ShowToastDialog.showToast(
          "You don't have sufficient wallet balance to place order".tr,
        );
        endOrderProcessing();
      }
    } catch (e) {
      print('❌ [WALLET_ORDER] Error: $e');
      ShowToastDialog.closeLoader();
      endOrderProcessing();
      ShowToastDialog.showToast("Failed to place order. Please try again.".tr);
    }
  }

  // Add this method if it's missing:
  // Add this method to CartControllerProvider class

  // ============ HEADERS METHOD (MISSING) ============

  Future<void> placeOrderAfterPayment() async {
    try {
      // Add global lock at the beginning
      _lockGlobal();

      if (!isPaymentCompleted || _lastPaymentId == null) {
        print(
          '❌ [ORDER_PLACEMENT] Payment validation failed - no valid payment found',
        );
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Payment validation failed. Please try again.".tr,
        );
        _unlockGlobal(); // Unlock before throwing
        return;
      }

      // Check if order is already being created
      if (_isOrderBeingCreated || _isOrderCreationInProgress) {
        print('⚠️ [ORDER_PLACEMENT] Order creation already in progress');
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Order is already being processed. Please wait...".tr,
        );
        _unlockGlobal();
        return;
      }

      _isOrderBeingCreated = true;
      print(
        '✅ [ORDER_PLACEMENT] Starting order placement for payment: $_lastPaymentId',
      );

      // Validate cart items
      if (HomeProvider.cartItem.isEmpty) {
        print('❌ [ORDER_PLACEMENT] Cart is empty');
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Your cart is empty. Please add items before placing order.".tr,
        );
        _isOrderBeingCreated = false;
        _unlockGlobal();
        return;
      }

      // Call the actual order creation
      await setOrder();
    } catch (e, stackTrace) {
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      if (_lastPaymentId != null) {
        _processedPaymentIds.remove(_lastPaymentId);
      }

      ShowToastDialog.closeLoader();
      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
        // Specific error already shown by validation
      } else {
        ShowToastDialog.showToast(
          "An error occurred while placing your order. Your payment is safe. Please try again."
              .tr,
        );
      }
      endOrderProcessing();
      _unlockGlobal(); // Unlock on error
      print('❌ [ORDER_PLACEMENT] Error in placeOrderAfterPayment: $e');
      print('❌ [ORDER_PLACEMENT] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to create order billing via API
  Future<void> _createOrderBilling(
    String orderId,
    String totalAmount,
    int surgePercent,
    String adminFee,
  ) async {
    try {
      final billingPayload = {
        'order_id': orderId,
        'to_pay': totalAmount,
        'created_at': DateTime.now().toIso8601String(),
        'surge_fee': surgePercent,
        'admin_surge_fee': adminFee,
      };
      print("billingPayload ${billingPayload} ");
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}order-billing'),
        headers: await getHeaders(),
        body: json.encode(billingPayload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Order billing created successfully');
      } else {
        print('⚠️ Failed to create order billing: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating order billing: $e');
    }
  }

  getPaymentSettings() async {
    try {
      await FireStoreUtils.getPaymentSettingsData()
          .then((value) {
            try {
              final razorpaySettingsStr = Preferences.getString(
                Preferences.razorpaySettings,
              );
              final codSettingsStr = Preferences.getString(
                Preferences.codSettings,
              );
              if (razorpaySettingsStr.isNotEmpty) {
                razorPayModel = RazorPayModel.fromJson(
                  jsonDecode(razorpaySettingsStr),
                );
              }

              if (codSettingsStr.isNotEmpty) {
                cashOnDeliverySettingModel = CodSettingModel.fromJson(
                  jsonDecode(codSettingsStr),
                );
              }

              // 🔑 CRITICAL: If COD is disabled and currently selected, switch to another payment method
              if (selectedPaymentMethod == PaymentGateway.cod.name &&
                  cashOnDeliverySettingModel.isEnabled != true) {
                selectedPaymentMethod = '';
                print(
                  '[PAYMENT_SETTINGS] COD is disabled, clearing COD selection',
                );
              }

              if (cashOnDeliverySettingModel.isEnabled == true &&
                  subTotal <= cashOnDeliverySettingModel.getMaxAmount() &&
                  !hasMartItemsInCart()) {
                selectedPaymentMethod = PaymentGateway.cod.name;
              } else if (razorPayModel.isEnabled == true) {
                selectedPaymentMethod = PaymentGateway.razorpay.name;
              }

              // 🔑 OPTIMIZATION: Pre-initialize Razorpay when settings are loaded
              // This eliminates initialization delay when user clicks "Confirm Payment"
              if (razorPayModel.isEnabled == true &&
                  razorPayModel.razorpayKey != null &&
                  razorPayModel.razorpayKey!.isNotEmpty) {
                _preInitializeRazorpay();
              }

              // 🔑 CRITICAL FIX: DO NOT register event listeners here
              // Event listeners are already registered in RazorpayCrashPrevention.safeInitialize()
              // Registering them again causes duplicate callbacks and multiple orders
              // The crash prevention utility handles all event listener registration
              print(
                '✅ [PAYMENT_SETTINGS] Event listeners are managed by RazorpayCrashPrevention, skipping duplicate registration',
              );

              checkAndUpdatePaymentMethod();
            } catch (e) {
              print('[CART_PROVIDER] Error parsing payment settings: $e');
              // Continue with default payment method selection
              if (razorPayModel.isEnabled == true) {
                selectedPaymentMethod = PaymentGateway.razorpay.name;
                // Try to pre-initialize even on error
                _preInitializeRazorpay();
              }
            }
          })
          .catchError((e) {
            print('[CART_PROVIDER] Error fetching payment settings: $e');
            // Set default payment method on error
            if (razorPayModel.isEnabled == true) {
              selectedPaymentMethod = PaymentGateway.razorpay.name;
              // Try to pre-initialize even on error
              _preInitializeRazorpay();
            }
          });
    } catch (e) {
      print('[CART_PROVIDER] Error in getPaymentSettings: $e');
    }
    notifyListeners();
  }

  // Add this field if it's missing:

  // ============ OTHER MISSING METHODS ============

  // Add this method if it's missing (called in handlePaymentSuccess):
  bool get isGlobalLocked {
    return _isOrderCreationInProgress ||
        _isOrderBeingCreated ||
        isProcessingOrder;
  }

  // Add this method if it's missing:
  void startOrderProcessing() {
    _orderInProgress = true;
    isProcessingOrder = true;
    notifyListeners();
  }

  // Add this method if it's missing:
  Future<bool> validateMinimumOrderValue() async {
    try {
      bool hasMartItems = HomeProvider.cartItem.any(
        (item) => item.vendorID?.startsWith('mart_') == true,
      );

      if (!hasMartItems) {
        return true;
      }

      double minOrderValue = 99.0;
      String minOrderMessage = 'Min Item value is ₹99';
      bool isSettingsActive = true;

      if (_martDeliverySettings != null) {
        isSettingsActive = _martDeliverySettings!['is_active'] ?? true;
        minOrderValue =
            (_martDeliverySettings!['min_order_value'] as num?)?.toDouble() ??
            99.0;
        minOrderMessage =
            _martDeliverySettings!['min_order_message'] ??
            'Min Item value is ₹${minOrderValue.toInt()}';
      } else {
        final settings = await _fetchMartDeliveryChargeSettings();
        if (settings != null) {
          _martDeliverySettings = settings;
          isSettingsActive = settings['is_active'] ?? true;
          minOrderValue =
              (settings['min_order_value'] as num?)?.toDouble() ?? 99.0;
          minOrderMessage =
              settings['min_order_message'] ??
              'Min Item value is ₹${minOrderValue.toInt()}';
        }
      }

      if (!isSettingsActive) {
        return true;
      }

      final currentSubTotal = subTotal;

      if (currentSubTotal < minOrderValue) {
        ShowToastDialog.showToast(minOrderMessage);
        throw Exception('Minimum order value not met');
      }

      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Add this method if it's missing:
  Future<Map<String, dynamic>?> _fetchMartDeliveryChargeSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mobile/settings/mart-delivery-charge'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return data;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Add this method if it's missing (from CartControllerProvider):
  Future<String> getAdminSurgeFee() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mobile/surge-rules/admin-fee'),
        headers: await getHeaders(),
      );

      print("getAdminSurgeFee ${response.body} ");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final adminSurgeFee = responseData['data']['admin_surge_fee']
              .toString();
          print("Admin Surge Fee: $adminSurgeFee");
          return adminSurgeFee;
        } else {
          throw Exception("API returned unsuccessful response");
        }
      } else {
        throw Exception(
          "Failed to fetch admin surge fee: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching admin surge fee: $e");
    }
  }

  double _getCurrentProductPrice(dynamic product, CartProductModel cartItem) {
    try {
      if (cartItem.variantInfo != null &&
          product is ProductModel &&
          product.itemAttribute != null) {
        final variantSku = cartItem.variantInfo!.variantSku;
        Variants? variant;

        try {
          variant = product.itemAttribute!.variants?.firstWhere(
            (v) => v.variantSku == variantSku,
          );
        } catch (e) {
          variant = null;
        }

        if (variant != null && variant.variantPrice != null) {
          if (vendorModel.id != null) {
            return double.parse(
              Constant.productCommissionPrice(
                vendorModel,
                variant.variantPrice ?? product.price ?? "0",
              ),
            );
          }
          return double.tryParse(variant.variantPrice ?? "0") ?? 0.0;
        }
      }

      if (product is MartItemModel) {
        return product.finalPrice;
      }

      if (product is ProductModel) {
        if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) {
          if (vendorModel.id != null) {
            return double.parse(
              Constant.productCommissionPrice(
                vendorModel,
                product.price ?? "0",
              ),
            );
          }
          return double.tryParse(product.price ?? "0") ?? 0.0;
        }

        if (product.disPrice != null &&
            double.tryParse(product.disPrice!) != null &&
            double.tryParse(product.price ?? "0") != null) {
          final disPrice = double.parse(product.disPrice!);
          final regPrice = double.parse(product.price ?? "0");
          if (disPrice > 0 && disPrice < regPrice) {
            if (vendorModel.id != null) {
              return double.parse(
                Constant.productCommissionPrice(
                  vendorModel,
                  product.disPrice ?? "0",
                ),
              );
            }
            return disPrice;
          }
        }

        if (vendorModel.id != null) {
          return double.parse(
            Constant.productCommissionPrice(vendorModel, product.price ?? "0"),
          );
        }
        return double.tryParse(product.price ?? "0") ?? 0.0;
      }
    } catch (e) {
      print('Error getting current product price: $e');
    }

    return 0.0;
  }

  Future<void> _updateCartItemPrice(PriceUpdateResult result) async {
    try {
      final cartItemIndex = HomeProvider.cartItem.indexWhere(
        (item) => item.id == result.productId,
      );

      if (cartItemIndex < 0) return;

      final cartItem = HomeProvider.cartItem[cartItemIndex];
      final isMart = _isMartItem(cartItem);

      dynamic currentProduct;

      if (isMart) {
        final martService = Get.find<MartFirestoreService>();
        currentProduct = await martService.getItemById(cartItem.id!);
      } else {
        currentProduct = await FireStoreUtils.getProductById(cartItem.id!);
      }

      if (currentProduct != null) {
        if (currentProduct is MartItemModel) {
          cartItem.price = currentProduct.price.toStringAsFixed(2);
          if (currentProduct.disPrice != null &&
              currentProduct.disPrice! < currentProduct.price &&
              currentProduct.disPrice! > 0) {
            cartItem.discountPrice = currentProduct.disPrice!.toStringAsFixed(
              2,
            );
          } else {
            cartItem.discountPrice = "0";
          }
        } else if (currentProduct is ProductModel) {
          cartItem.price = result.newPrice;
          if (currentProduct.disPrice != null &&
              double.tryParse(currentProduct.disPrice!) != null &&
              double.tryParse(currentProduct.price ?? "0") != null) {
            final disPrice = double.parse(currentProduct.disPrice!);
            final regPrice = double.parse(currentProduct.price ?? "0");
            if (disPrice > 0 && disPrice < regPrice) {
              if (vendorModel.id != null) {
                cartItem.discountPrice = Constant.productCommissionPrice(
                  vendorModel,
                  currentProduct.disPrice ?? "0",
                );
              } else {
                cartItem.discountPrice = currentProduct.disPrice;
              }
            } else {
              cartItem.discountPrice = "0";
            }
          } else {
            cartItem.discountPrice = "0";
          }
        }
      } else {
        cartItem.price = result.newPrice;
      }

      await DatabaseHelper.instance.updateCartProduct(cartItem);
      HomeProvider.cartItem[cartItemIndex] = cartItem;

      print(
        '[PRICE_UPDATE] ✅ Updated ${result.productName ?? cartItem.name}: ₹${result.oldPrice ?? "N/A"} → ₹${result.newPrice ?? "N/A"}',
      );
    } catch (e) {
      print('[PRICE_UPDATE] ❌ Error: $e');
    }
  }

  Future<void> _applyBatchUpdates() async {
    try {
      await cartProvider.refreshCart();

      final updatedItems = await DatabaseHelper.instance.fetchCartProducts();

      if (updatedItems.length == HomeProvider.cartItem.length) {
        for (int i = 0; i < updatedItems.length; i++) {
          HomeProvider.cartItem[i] = updatedItems[i];
        }
      } else {
        HomeProvider.cartItem
          ..clear()
          ..addAll(updatedItems);
      }

      cartProvider.forceStreamUpdate();
      await _calculatePriceInternal();

      _priceSyncVersion++;
      notifyListeners();

      print('[BATCH_UPDATE] ✅ Applied batch updates');
    } catch (e) {
      print('[BATCH_UPDATE] ❌ Error: $e');
    }
  }

  // ============ CART OPERATIONS ============

  Future<void> forceRefreshCart() async {
    _startOperation('forceRefreshCart');

    _invalidateCartRelatedCaches();
    await cartProvider.refreshCart();
    await _loadFreshVendorForCart();
    await preloadCartProducts(forceRefresh: true);

    deliveryTips = 0.0;
    await calculatePrice();
    checkAndUpdatePaymentMethod();
    updateCartReadiness();

    _endOperation('forceRefreshCart');
    notifyListeners();
  }

  Future<void> getCartData() async {
    _startOperation('getCartData');

    cartProvider.cartStream.listen((event) async {
      // Smart cache: cart DB changed → invalidate so next load reflects changes
      _invalidateCartRelatedCaches();

      HomeProvider.cartItem.clear();
      HomeProvider.cartItem.addAll(event);

      if (HomeProvider.cartItem.isNotEmpty) {
        final firstItemVendor = HomeProvider.cartItem.first.vendorID;
        if (_cachedVendorModel?.id != firstItemVendor) {
          _clearVendorCache();
        }

        await _loadFreshVendorForCart();
      }

      await _loadCalculationCache();

      unawaited(
        _loadNewProductsIncrementally().catchError((e) {
          print('[CART_DATA] Error loading products: $e');
        }),
      );

      await calculatePrice();
      checkAndUpdatePaymentMethod();
      updateCartReadiness();
      notifyListeners();
    });

    selectedFoodType = Preferences.getString(
      Preferences.foodDeliveryType,
      defaultValue: "Delivery".tr,
    );

    // Run independent operations in parallel to reduce total time
    await Future.wait([
      if (userModel.id == null) _loadUserProfileForCart(),
      if (_cachedDeliveryCharge == null || !_isCacheValid())
        _loadDeliveryChargeForCart(),
    ]);

    _detectCurrentContext();

    if (vendorModel.id != null &&
        (!_isCacheValid() || _cachedCouponList == null)) {
      await _loadCoupons(restaurantId: vendorModel.id.toString());
    } else {
      if (vendorModel.id != null && _cachedCouponList == null) {
        await _loadCoupons(restaurantId: vendorModel.id.toString());
      } else if (vendorModel.id == null && HomeProvider.cartItem.isNotEmpty) {
        final martItems = HomeProvider.cartItem
            .where((item) => _isMartItem(item))
            .toList();
        if (martItems.isNotEmpty) {
          final vendorId = martItems.first.vendorID;
          if (vendorId != null && vendorId.isNotEmpty) {
            await _loadCoupons(restaurantId: vendorId);
          } else {
            await _loadGlobalCouponsOnly();
          }
        } else {
          final vendorId = HomeProvider.cartItem.first.vendorID;
          if (vendorId != null && vendorId.isNotEmpty) {
            await _loadCoupons(restaurantId: vendorId);
          } else {
            await _loadGlobalCouponsOnly();
          }
        }
      } else if (vendorModel.id == null) {
        await _loadGlobalCouponsOnly();
      }
    }

    _endOperation('getCartData');
    notifyListeners();
  }

  Future<void> _loadUserProfileForCart() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final value = await AddressListProvider.getUserProfile(userId.toString());
      if (value != null) userModel = value;
    } catch (_) {}
  }

  Future<void> _loadDeliveryChargeForCart() async {
    try {
      final value = await FireStoreUtils.getDeliveryCharge();
      if (value != null) {
        deliveryChargeModel = value;
        _cachedDeliveryCharge = value;
        _updateCacheTime();
        calculatePrice();
      }
    } catch (_) {}
  }

  Future<void> preloadCartProducts({bool forceRefresh = false}) async {
    if (_isLoadingProducts && !forceRefresh) return;

    if (forceRefresh) {
      _productCache.clear();
      _productsLoaded = false;
    }

    _isLoadingProducts = true;
    _startOperation('preloadCartProducts');

    try {
      final Set<String> productIds = {};

      for (final cartItem in HomeProvider.cartItem) {
        if (cartItem.id != null &&
            cartItem.id!.isNotEmpty &&
            cartItem.id!.toLowerCase() != 'null') {
          final parts = cartItem.id!.split('~');
          if (parts.isNotEmpty &&
              parts.first.isNotEmpty &&
              parts.first.toLowerCase() != 'null') {
            productIds.add(parts.first);
          }
        }
      }

      final Set<String> productsToLoad = forceRefresh
          ? productIds
          : productIds.where((id) => !_productCache.containsKey(id)).toSet();

      if (productsToLoad.isEmpty) {
        _productsLoaded = true;
        notifyListeners();
        return;
      }

      final List<Future<void>> loadFutures = productsToLoad.map((
        productId,
      ) async {
        try {
          final cartItem = HomeProvider.cartItem.firstWhere((item) {
            if (item.id == null || item.id!.isEmpty) return false;
            final parts = item.id!.split('~');
            return parts.isNotEmpty && parts.first == productId;
          }, orElse: () => CartProductModel());

          final isMartItem = _isMartItem(cartItem);

          if (isMartItem) {
            _productCache[productId] = null;
          } else {
            final product = await FireStoreUtils.getProductById(productId);
            _productCache[productId] = product;
          }
        } catch (e) {
          print('[CART_PRODUCT] Error loading product $productId: $e');
          _productCache[productId] = null;
        }
      }).toList();

      await Future.wait(loadFutures);
      _productsLoaded = true;
      notifyListeners();
    } catch (e) {
      print('[CART_PRODUCT] Error preloading products: $e');
    } finally {
      _isLoadingProducts = false;
      _endOperation('preloadCartProducts');
    }
  }

  // ============ HELPER METHODS ============

  bool _isCacheValid() {
    return _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < cacheExpiry;
  }

  void _updateCacheTime() {
    _lastCacheTime = DateTime.now();
  }

  void _clearVendorCache() {
    _cachedVendorModel = null;
    _lastCacheTime = null;
    vendorModel = VendorModel();
    _invalidateCartRelatedCaches();
    notifyListeners();
  }

  /// Smart cache: invalidate when cart/vendor changes so UI reflects DB changes
  void _invalidateCartRelatedCaches() {
    _cachedGlobalCouponList = null;
    _lastGlobalCouponCacheTime = null;
    _cachedCouponList = null;
  }

  // Add these methods to the CartControllerProvider class:

  // ============ CART CLEAR METHOD ============
  Future<void> clearCart() async {
    _startOperation('clearCart');

    try {
      // Clear cart items from memory
      HomeProvider.cartItem.clear();
      await DatabaseHelper.instance.deleteAllCartProducts();

      // Reset all values
      subTotal = 0.0;
      totalAmount = 0.0;
      deliveryCharges = 0.0;
      couponAmount = 0.0;
      specialDiscountAmount = 0.0;
      taxAmount = 0.0;
      deliveryTips = 0.0;
      selectedPaymentMethod = '';

      // 🔑 CRITICAL: Reset payment state when clearing cart
      _resetPaymentState();
      _processedPaymentIds.clear();
      _isOrderBeingCreated = false;

      // 🔑 CRITICAL: Reset address initialization flag when clearing cart
      _addressInitialized = false;

      // Verify cart is actually empty
      final remainingItems = await DatabaseHelper.instance.fetchCartProducts();
      if (remainingItems.isNotEmpty) {
        print('[CLEAR_CART] ⚠️ Some items still remain in database');
      }

      notifyListeners();
    } catch (e) {
      print('[CLEAR_CART] ❌ Error: $e');
    } finally {
      _endOperation('clearCart');
    }
  }

  // ============ ADDRESS SYNC METHOD ============
  Future<void> syncAddressWithHomeLocation(BuildContext context) async {
    _startOperation('syncAddressWithHomeLocation');

    try {
      // 🔑 CRITICAL: Don't auto-sync if address is already initialized with a saved/default address
      if (_addressInitialized &&
          selectedAddress != null &&
          selectedAddress!.id != null &&
          !selectedAddress!.id!.startsWith('home_screen_address_')) {
        print('[CART_SYNC] ⚠️ Address is a saved address, skipping auto-sync');

        // Only sync zoneId if missing
        if ((selectedAddress?.zoneId == null ||
                selectedAddress!.zoneId!.isEmpty) &&
            Constant.selectedLocation.zoneId != null &&
            Constant.selectedLocation.zoneId!.isNotEmpty) {
          selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
          print(
            '[CART_SYNC] ✅ Synced zoneId only (address unchanged): ${selectedAddress!.zoneId}',
          );
          notifyListeners();
        }
        return;
      }

      // Check if Constant.selectedLocation has valid coordinates
      if (Constant.selectedLocation.location?.latitude != null &&
          Constant.selectedLocation.location?.longitude != null) {
        final homeLat = Constant.selectedLocation.location!.latitude!;
        final homeLng = Constant.selectedLocation.location!.longitude!;

        // Check if current selectedAddress matches Constant.selectedLocation
        final currentLat = selectedAddress?.location?.latitude;
        final currentLng = selectedAddress?.location?.longitude;

        // If coordinates don't match AND address is not initialized, sync the address
        if (currentLat == null ||
            currentLng == null ||
            currentLat != homeLat ||
            currentLng != homeLng) {
          // Only sync if address is not initialized (first time) or is a temporary address
          if (!_addressInitialized ||
              selectedAddress == null ||
              selectedAddress!.id == null ||
              selectedAddress!.id!.startsWith('home_screen_address_')) {
            final homeScreenAddress = await _getCurrentLocationAddress(context);
            if (homeScreenAddress != null) {
              selectedAddress = homeScreenAddress;
              _addressInitialized = true; // Mark as initialized after sync

              // Ensure zoneId is set
              if ((selectedAddress!.zoneId == null ||
                      selectedAddress!.zoneId!.isEmpty) &&
                  Constant.selectedLocation.zoneId != null &&
                  Constant.selectedLocation.zoneId!.isNotEmpty) {
                selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
                print(
                  '[CART_SYNC] ✅ Set zoneId from Constant.selectedLocation: ${selectedAddress!.zoneId}',
                );
              }

              // Update surge value for new location
              await initialLiseSurgeValue(homeLat, homeLng);

              // Recalculate prices with new address
              await calculatePrice();

              print(
                '[CART_SYNC] ✅ Synced selectedAddress with Constant.selectedLocation (zoneId: ${selectedAddress!.zoneId})',
              );
              notifyListeners();
            }
          }
        } else {
          // Coordinates match, but check if zoneId needs syncing
          if ((selectedAddress?.zoneId == null ||
                  selectedAddress!.zoneId!.isEmpty) &&
              Constant.selectedLocation.zoneId != null &&
              Constant.selectedLocation.zoneId!.isNotEmpty) {
            selectedAddress!.zoneId = Constant.selectedLocation.zoneId;
            print(
              '[CART_SYNC] ✅ Synced zoneId while coordinates match: ${selectedAddress!.zoneId}',
            );
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('[CART_SYNC] ❌ Error syncing address with home location: $e');
    } finally {
      _endOperation('syncAddressWithHomeLocation');
    }
  }

  // ============ PAYMENT RECOVERY METHOD ============
  Future<void> _checkPendingPaymentAndRecover() async {
    _startOperation('checkPendingPayment');

    try {
      if (_lastPaymentTime != null) {
        final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
        if (timeSincePayment > paymentTimeout) {
          print('🔑 Payment session expired, clearing state');
          await _clearPersistentPaymentState();
          _resetPaymentState();
          ShowToastDialog.showToast(
            "Payment session expired. Please try again.".tr,
          );
          return;
        }
      }

      // Show recovery dialog to user
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.payment, color: Colors.orange, size: 24),
              SizedBox(width: 10),
              Text(
                "Payment Recovery",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We detected a successful payment from before the app was closed.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Payment ID: $_lastPaymentId",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Please complete your order to continue.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _completePendingOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Complete Order",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print('[PAYMENT_RECOVERY] ❌ Error: $e');
      await _clearPersistentPaymentState();
      _resetPaymentState();
    } finally {
      _endOperation('checkPendingPayment');
    }
  }

  // ============ LOAD COUPONS METHOD ============
  Future<void> _loadCoupons({required String restaurantId}) async {
    if (_isLoadingCoupons) {
      print('[COUPON_LOAD] ⚠️ Coupon load already in progress, skipping...');
      return;
    }

    if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
      print('[COUPON_LOAD] ⚠️ Skipping coupon load: empty restaurant ID');
      await _loadGlobalCouponsOnly();
      return;
    }

    _isLoadingCoupons = true;
    _startOperation('loadCoupons');

    try {
      _detectCurrentContext();
      print(
        '[COUPON_LOAD] 🔍 Loading coupons for vendor: $restaurantId, Context: $_currentContext',
      );

      final allCoupons = _currentContext == "mart"
          ? await RestaurantApiHelper.getMartCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('[COUPON_LOAD] ⏱️ Mart coupon API call timed out');
                return <CouponModel>[];
              },
            )
          : await RestaurantApiHelper.getRestaurantCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('[COUPON_LOAD] ⏱️ Restaurant coupon API call timed out');
                return <CouponModel>[];
              },
            );

      print(
        '[COUPON_LOAD] ✅ Received ${allCoupons.length} coupons from ${_currentContext} API',
      );

      final filteredGlobalCoupons = allCoupons
          .where(
            (c) =>
                c.resturantId == null ||
                c.resturantId == '' ||
                c.resturantId?.toUpperCase() == 'ALL',
          )
          .toList();

      final vendorCoupons = allCoupons
          .where(
            (c) =>
                c.resturantId != null &&
                c.resturantId!.isNotEmpty &&
                c.resturantId!.toUpperCase() != 'ALL' &&
                c.resturantId == restaurantId,
          )
          .toList();

      final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
      final combinedAllCoupons = [...allCoupons];

      final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
        coupons: combinedCoupons.cast<CouponModel>(),
        contextType: _currentContext,
        fallbackEnabled: true,
      );

      final contextFilteredAllCoupons =
          CouponFilterService.filterCouponsByContext(
            coupons: combinedAllCoupons.cast<CouponModel>(),
            contextType: _currentContext,
            fallbackEnabled: true,
          );

      print(
        '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} coupons for context: $_currentContext',
      );

      _cachedCouponList = contextFilteredCoupons;
      _updateCacheTime();

      couponList = contextFilteredCoupons;
      allCouponList = contextFilteredAllCoupons;

      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Connection error: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print('[COUPON_LOAD] ❌ ClientException: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_LOAD] ❌ Error loading coupons: $e');
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('Status code: 429')) {
        print('[COUPON_LOAD] ⚠️ Rate limit (429) - using cached coupons');
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        await _loadCouponsWithoutFiltering(restaurantId: restaurantId);
        notifyListeners();
      }
    } finally {
      _isLoadingCoupons = false;
      _endOperation('loadCoupons');
    }
  }

  // ============ ADDITIONAL HELPER METHODS ============

  // Add these methods also if they're missing:

  bool _isGlobalCouponCacheValid() {
    return _lastGlobalCouponCacheTime != null &&
        DateTime.now().difference(_lastGlobalCouponCacheTime!) <
            globalCouponCacheExpiry;
  }

  Future<void> _loadGlobalCouponsOnly() async {
    if (_isLoadingCoupons) {
      print(
        '[COUPON_LOAD] ⚠️ Global coupon load already in progress, skipping...',
      );
      return;
    }

    // Cache-first: use cached global coupons if valid (5 min TTL)
    if (_cachedGlobalCouponList != null &&
        _cachedGlobalCouponList!.isNotEmpty &&
        _isGlobalCouponCacheValid()) {
      couponList = _cachedGlobalCouponList!;
      allCouponList = _cachedGlobalCouponList!;
      await _markUsedCoupons();
      notifyListeners();
      return;
    }

    _isLoadingCoupons = true;
    _startOperation('loadGlobalCoupons');

    try {
      _detectCurrentContext();
      print('[COUPON_LOAD] 🔍 Global coupon load - Context: $_currentContext');

      final globalCoupons = _currentContext == "mart"
          ? await RestaurantApiHelper.getMartCoupons(restaurantId: '').timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('[COUPON_LOAD] ⏱️ Global mart coupon API call timed out');
                return <CouponModel>[];
              },
            )
          : await RestaurantApiHelper.getRestaurantCoupons(
              restaurantId: '',
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '[COUPON_LOAD] ⏱️ Global restaurant coupon API call timed out',
                );
                return <CouponModel>[];
              },
            );

      print(
        '[COUPON_LOAD] ✅ Received ${globalCoupons.length} global coupons from ${_currentContext} API',
      );

      final filteredGlobalCoupons = globalCoupons
          .where(
            (c) =>
                c.resturantId == null ||
                c.resturantId == '' ||
                c.resturantId?.toUpperCase() == 'ALL',
          )
          .toList();

      final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
        coupons: filteredGlobalCoupons.cast<CouponModel>(),
        contextType: _currentContext,
        fallbackEnabled: true,
      );

      print(
        '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} global coupons for context: $_currentContext',
      );

      _cachedCouponList = contextFilteredCoupons;
      _cachedGlobalCouponList = contextFilteredCoupons;
      _lastGlobalCouponCacheTime = DateTime.now();
      _updateCacheTime();

      couponList = contextFilteredCoupons;
      allCouponList = filteredGlobalCoupons.cast<CouponModel>();

      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Global: Connection error: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print('[COUPON_LOAD] ❌ Global: ClientException: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_LOAD] ❌ Error loading global coupons: $e');
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('400') ||
          errorString.contains('Status code: 429') ||
          errorString.contains('Status code: 400')) {
        print(
          '[COUPON_LOAD] ⚠️ Global: Rate limit or bad request - using cached coupons',
        );
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        }
      }
    } finally {
      _isLoadingCoupons = false;
      _endOperation('loadGlobalCoupons');
    }
  }

  Future<void> _loadCouponsWithoutFiltering({
    required String restaurantId,
  }) async {
    if (_isLoadingCoupons) {
      print(
        '[COUPON_LOAD] ⚠️ Fallback coupon load already in progress, skipping...',
      );
      return;
    }

    if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
      print('[COUPON_LOAD] ⚠️ Fallback: Skipping - empty restaurant ID');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
      return;
    }

    _isLoadingCoupons = true;
    _startOperation('loadCouponsWithoutFiltering');

    try {
      _detectCurrentContext();
      print(
        '[COUPON_LOAD] 🔍 Fallback: Loading coupons for vendor: $restaurantId, Context: $_currentContext',
      );

      final allCoupons = _currentContext == "mart"
          ? await RestaurantApiHelper.getMartCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '[COUPON_LOAD] ⏱️ Fallback: Mart coupon API call timed out',
                );
                return <CouponModel>[];
              },
            )
          : await RestaurantApiHelper.getRestaurantCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '[COUPON_LOAD] ⏱️ Fallback: Restaurant coupon API call timed out',
                );
                return <CouponModel>[];
              },
            );

      print(
        '[COUPON_LOAD] ✅ Fallback: Received ${allCoupons.length} coupons from ${_currentContext} API',
      );

      final filteredGlobalCoupons = allCoupons
          .where(
            (c) =>
                c.resturantId == null ||
                c.resturantId == '' ||
                c.resturantId?.toUpperCase() == 'ALL',
          )
          .toList();

      final vendorCoupons = allCoupons
          .where(
            (c) =>
                c.resturantId != null &&
                c.resturantId!.isNotEmpty &&
                c.resturantId!.toUpperCase() != 'ALL' &&
                c.resturantId == restaurantId,
          )
          .toList();

      final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
      final combinedAllCoupons = [...allCoupons];

      _cachedCouponList = combinedCoupons.cast<CouponModel>();
      _updateCacheTime();

      couponList = combinedCoupons.cast<CouponModel>();
      allCouponList = combinedAllCoupons.cast<CouponModel>();

      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Fallback: Connection error: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print('[COUPON_LOAD] ❌ Fallback: ClientException: $e');
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_LOAD] ❌ Fallback coupon loading also failed: $e');
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('Status code: 429')) {
        print(
          '[COUPON_LOAD] ⚠️ Fallback: Rate limit (429) - using cached coupons',
        );
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      }
    } finally {
      _isLoadingCoupons = false;
      _endOperation('loadCouponsWithoutFiltering');
    }
  }

  Future<void> _markUsedCoupons() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mobile/coupons/used?userId=$userId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> usedCoupons = responseData['data']['coupons'];
          final usedCouponIds = usedCoupons
              .map((coupon) => coupon['couponId'] as String)
              .toSet();

          for (var coupon in couponList) {
            coupon.isEnabled = !usedCouponIds.contains(coupon.id);
          }

          for (var coupon in allCouponList) {
            coupon.isEnabled = !usedCouponIds.contains(coupon.id);
          }

          notifyListeners();
        }
      }
    } catch (e) {
      print('[MARK_USED_COUPONS] ❌ Error: $e');
    }
  }

  // ============ PAYMENT HELPER METHODS ============

  void _resetPaymentState() {
    isPaymentInProgress = false;
    isPaymentCompleted = false;
    _lastPaymentId = null;
    _lastPaymentTime = null;
    _isOrderBeingCreated = false;
    _isOrderCreationInProgress = false;
    _currentOrderPaymentId = null;
    _processedPaymentIds.clear();
    notifyListeners();
  }

  Future<void> _completePendingOrder() async {
    try {
      ShowToastDialog.showLoader("Completing your order...".tr);
      isPaymentCompleted = true;

      await _processOrderWithRetry();
      notifyListeners();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        "Failed to complete order. Please try again.".tr,
      );
      await _clearPersistentPaymentState();
      _resetPaymentState();
      notifyListeners();
    }
  }

  Future<void> _processOrderWithRetry() async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        if (retryCount > 0) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }

        await placeOrderAfterPayment();
        notifyListeners();
        return;
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          await _handleOrderPlacementFailure();
          return;
        }

        await placeOrderAfterPayment();
        ShowToastDialog.showLoader(
          "Retrying order placement... ($retryCount/$maxRetries)".tr,
        );
      }
    }
  }

  Future<void> _handleOrderPlacementFailure() async {
    ShowToastDialog.closeLoader();

    Get.dialog(
      AlertDialog(
        title: Text("Order Placement Failed"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your payment was successful, but we couldn't place your order.",
            ),
            SizedBox(height: 10),
            Text(
              "Don't worry - your money is safe and will be refunded within 24 hours.",
            ),
            SizedBox(height: 10),
            Text("Please contact support with Payment ID: $_lastPaymentId"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _resetPaymentState();
            },
            child: Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _retryOrderPlacement();
            },
            child: Text("Retry Order"),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    notifyListeners();
  }

  Future<void> _retryOrderPlacement() async {
    if (_lastPaymentId != null && _lastPaymentTime != null) {
      final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
      if (timeSincePayment < paymentTimeout) {
        ShowToastDialog.showLoader("Retrying order placement...".tr);
        await _processOrderWithRetry();
      } else {
        ShowToastDialog.showToast(
          "Payment session expired. Please try again.".tr,
        );
        _resetPaymentState();
      }
    } else {
      ShowToastDialog.showToast("No valid payment found. Please try again.".tr);
      _resetPaymentState();
    }
    notifyListeners();
  }

  // ============ PERSISTENT STATE METHODS ============

  static const String _paymentStateKey = 'razorpay_payment_state';
  static const String _paymentIdKey = 'razorpay_payment_id';
  static const String _paymentSignatureKey = 'razorpay_payment_signature';
  static const String _paymentTimeKey = 'razorpay_payment_time';
  static const String _paymentMethodKey = 'razorpay_payment_method';
  static const String _paymentAmountKey = 'razorpay_payment_amount';
  static const String _paymentOrderIdKey = 'razorpay_order_id';

  Future<void> _restorePaymentState() async {
    final paymentState = Preferences.getString(_paymentStateKey);
    if (paymentState == 'true') {
      isPaymentInProgress = true;
      _lastPaymentId = Preferences.getString(_paymentIdKey);
      final paymentTimeStr = Preferences.getString(_paymentTimeKey);
      final paymentMethodStr = Preferences.getString(_paymentMethodKey);

      if (paymentTimeStr.isNotEmpty && paymentTimeStr != '') {
        _lastPaymentTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(paymentTimeStr),
        );
      }

      if (paymentMethodStr.isNotEmpty && paymentMethodStr != '') {
        selectedPaymentMethod = paymentMethodStr;
      } else if (_lastPaymentId != null && _lastPaymentId!.isNotEmpty) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }

      notifyListeners();
    }
  }

  Future<void> _clearPersistentPaymentState() async {
    try {
      await Preferences.setString(_paymentStateKey, '');
      await Preferences.setString(_paymentIdKey, '');
      await Preferences.setString(_paymentSignatureKey, '');
      await Preferences.setString(_paymentTimeKey, '');
      await Preferences.setString(_paymentMethodKey, '');
      await Preferences.setString(_paymentAmountKey, '');
      await Preferences.setString(_paymentOrderIdKey, '');
    } catch (e) {
      print('[CLEAR_PERSISTENT] ❌ Error: $e');
    }
  }

  // ============ OTHER MISSING METHODS ============

  // Add this if it's missing
  int? getPromotionalItemLimit(String productId, String restaurantId) {
    try {
      final limit = PromotionalCacheService.getPromotionalItemLimit(
        productId,
        restaurantId,
      );
      return limit;
    } catch (e) {
      return null;
    }
  }

  // Add this if it's missing
  bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) {
      return true;
    }

    final isAllowed = PromotionalCacheService.isPromotionalItemQuantityAllowed(
      productId,
      restaurantId,
      currentQuantity,
    );

    return isAllowed;
  }

  // Add this if it's missing
  Future<void> initialLiseSurgeValue(double lat, double lon) async {
    try {
      Map<String, dynamic> weather = await getWeather(lat, lon);
      Map<String, dynamic> rules = await getSurgeRules();
      surgePercent = calculateSurgeFee(weather, rules);
      notifyListeners();
    } catch (e) {
      print('[SURGE_VALUE] ❌ Error: $e');
      surgePercent = 0;
      notifyListeners();
    }
  }

  // Add this if it's missing
  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    const apiKey = "7885eed00855633516f769cf3646aace";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load weather");
    }
  }

  // Add this if it's missing
  Future<Map<String, dynamic>> getSurgeRules() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}mobile/surge-rules'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] ?? {};
        } else {
          return {};
        }
      } else if (response.statusCode == 429) {
        return {};
      } else {
        return {};
      }
    } on TimeoutException {
      return {};
    } catch (e) {
      return {};
    }
  }

  // Add this if it's missing
  double calculateSurgeFee(
    Map<String, dynamic> weather,
    Map<String, dynamic> rules,
  ) {
    double surge = 0;
    String condition = weather['weather'][0]['main'].toLowerCase();
    if (condition.contains("rain")) surge += rules["rain"];
    double temp = weather['main']['temp'];
    if (temp > 45) surge += rules["summer"];
    if (temp < 10) surge += rules["bad_weather"];
    return surge;
  }

  Future<void> _loadFreshVendorForCart() async {
    try {
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();
      final restaurantItems = HomeProvider.cartItem
          .where((item) => !_isMartItem(item))
          .toList();

      if (martItems.isNotEmpty) {
        await _loadFreshMartVendor(martItems);
      } else if (restaurantItems.isNotEmpty) {
        await _loadFreshRestaurantVendor(restaurantItems.first.vendorID);
      }
    } catch (e) {
      print('[VENDOR_LOAD] ❌ Error: $e');
    }
  }

  Future<void> _loadFreshMartVendor(List<CartProductModel> martItems) async {
    try {
      final firstMartItem = martItems.first;
      var vendorId = firstMartItem.vendorID;
      // Cart stores "mart_123"; API expects raw ID "123"
      if (vendorId != null && vendorId.startsWith('mart_')) {
        vendorId = vendorId.substring(5);
      }
      MartVendorModel? martVendor;

      if (vendorId != null && vendorId.isNotEmpty && vendorId != 'unknown') {
        martVendor = await MartVendorService.getMartVendorById(vendorId);
        martVendor ??= await MartVendorService.getDefaultMartVendor();
      } else {
        martVendor = await MartVendorService.getDefaultMartVendor();
      }

      if (martVendor != null) {
        String? finalZoneId = martVendor.zoneId;
        if ((finalZoneId == null || finalZoneId.isEmpty) &&
            selectedAddress?.zoneId != null &&
            selectedAddress!.zoneId!.isNotEmpty) {
          finalZoneId = selectedAddress!.zoneId;
        } else if ((finalZoneId == null || finalZoneId.isEmpty) &&
            Constant.selectedLocation.zoneId != null &&
            Constant.selectedLocation.zoneId!.isNotEmpty) {
          finalZoneId = Constant.selectedLocation.zoneId;
        }

        vendorModel = VendorModel(
          id: martVendor.id,
          author: martVendor.author,
          title: martVendor.title,
          latitude: martVendor.latitude,
          longitude: martVendor.longitude,
          isSelfDelivery: false,
          vType: martVendor.vType,
          zoneId: finalZoneId,
          isOpen: martVendor.isOpen,
        );
      }
      if (!_isCalculatingPrice) notifyListeners();
    } catch (e) {
      print('[MART_VENDOR] ❌ Error: $e');
    }
  }

  Future<void> _loadFreshRestaurantVendor(String? vendorId) async {
    try {
      if (vendorId == null) return;

      final freshVendor = await FireStoreUtils.getVendorById(vendorId);
      if (freshVendor != null) {
        vendorModel = freshVendor;
      }
      if (!_isCalculatingPrice) notifyListeners();
    } catch (e) {
      print('[RESTAURANT_VENDOR] ❌ Error: $e');
    }
  }

  bool _isMartItem(CartProductModel item) {
    try {
      if (item.vendorID != null && item.vendorID!.startsWith("mart_")) {
        return true;
      }

      if (item.vendorID != null) {
        final vendorId = item.vendorID!.toLowerCase();
        if (vendorId.startsWith("demo_") ||
            vendorId.contains("mart") ||
            vendorId.contains("vendor")) {
          return true;
        }
      }

      if (item.vendorName != null) {
        final vendorName = item.vendorName!.toLowerCase();
        if (vendorName.contains("jippy mart") || vendorName.contains("mart")) {
          return true;
        }
      }

      if (item.categoryId != null) {
        final categoryId = item.categoryId!.toLowerCase();
        if (categoryId.contains("grocery") ||
            categoryId.contains("mart") ||
            categoryId.contains("retail")) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  bool hasMartItemsInCart() {
    try {
      return HomeProvider.cartItem.any((item) => _isMartItem(item));
    } catch (e) {
      return false;
    }
  }

  /// Returns vendor_id for order API. For mart: vendorModel.id or first cart item's vendorID.
  /// Strips "mart_" prefix when sending to backend (backend expects raw ID in mart_vendor table).
  String _getVendorIdForOrder() {
    String? rawId;
    if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
      rawId = vendorModel.id!;
    } else if (hasMartItemsInCart()) {
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();
      if (martItems.isNotEmpty) {
        rawId = martItems.first.vendorID;
      }
    }
    if (rawId == null || rawId.isEmpty) {
      if (HomeProvider.cartItem.isNotEmpty) {
        rawId = HomeProvider.cartItem.first.vendorID;
      }
    }
    if (rawId == null || rawId.isEmpty) return 'mart_default';
    // Backend mart_vendor table uses raw ID; cart stores "mart_123" format
    final id = rawId.startsWith('mart_') ? rawId.substring(5) : rawId;
    return (id.isEmpty || id == 'unknown') ? 'mart_default' : id;
  }

  void _detectCurrentContext() {
    try {
      bool hasMartItems = false;
      bool hasRestaurantItems = false;

      for (final item in HomeProvider.cartItem) {
        if (_isMartItem(item)) {
          hasMartItems = true;
        } else {
          hasRestaurantItems = true;
        }
      }

      if (hasMartItems && !hasRestaurantItems) {
        _currentContext = "mart";
      } else if (hasRestaurantItems && !hasMartItems) {
        _currentContext = "restaurant";
      } else {
        if (hasMartItems) {
          _currentContext = "mart";
        } else {
          _currentContext = "restaurant";
        }
      }
    } catch (e) {
      _currentContext = "restaurant";
    }
  }

  // ============ COUPON METHODS ============

  void ensureCouponsLoaded() {
    if (_isLoadingCoupons) return;

    _detectCurrentContext();

    if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
      if (couponList.isEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        notifyListeners();
      }

      if (_isCacheValid()) {
        final reFilteredCoupons = CouponFilterService.filterCouponsByContext(
          coupons: _cachedCouponList!,
          contextType: _currentContext,
          fallbackEnabled: true,
        );

        if (reFilteredCoupons.length != couponList.length) {
          print('[COUPONS] 🔄 Context changed, reloading coupons...');
        } else {
          return;
        }
      }
    }

    String? vendorId;
    if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
      vendorId = vendorModel.id.toString();
    } else if (HomeProvider.cartItem.isNotEmpty) {
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();
      if (martItems.isNotEmpty) {
        vendorId = martItems.first.vendorID;
      } else {
        vendorId = HomeProvider.cartItem.first.vendorID;
      }
    }

    if (vendorId != null && vendorId.isNotEmpty) {
      _loadCoupons(restaurantId: vendorId);
    } else {
      _loadGlobalCouponsOnly();
    }
  }

  // ============ DELIVERY CHARGE METHODS ============

  void calculatePromotionalDeliveryChargeFast() {
    final promotionalItems = HomeProvider.cartItem
        .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
        .toList();

    if (promotionalItems.isEmpty) {
      calculateRegularDeliveryCharge();
      return;
    }

    final firstPromoItem = promotionalItems.first;
    final freeDeliveryKm = _getCachedFreeDeliveryKm(
      firstPromoItem.id ?? '',
      firstPromoItem.vendorID ?? '',
    );
    final extraKmCharge = _getCachedExtraKmCharge(
      firstPromoItem.id ?? '',
      firstPromoItem.vendorID ?? '',
    );
    final baseCharge = 21.0;

    _calculateDeliveryCharge(
      orderType: 'promotional',
      freeDeliveryKm: freeDeliveryKm,
      perKmCharge: extraKmCharge,
      baseCharge: baseCharge,
      logPrefix: '[PROMOTIONAL_DELIVERY]',
    );
  }

  void _calculateDeliveryCharge({
    required String orderType,
    required double freeDeliveryKm,
    required double perKmCharge,
    required double baseCharge,
    required String logPrefix,
  }) {
    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (totalDistance <= freeDeliveryKm) {
      deliveryCharges = 0.0;
      originalDeliveryFee = baseCharge;
    } else {
      double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
      deliveryCharges = extraKm * perKmCharge;
      originalDeliveryFee = baseCharge + deliveryCharges;
    }
  }

  void calculateMartDeliveryCharge() {
    final martItems = HomeProvider.cartItem
        .where((item) => _isMartItem(item))
        .toList();

    if (martItems.isEmpty) {
      calculateRegularDeliveryCharge();
      return;
    }

    _calculateMartDeliveryWithBackendSettings();
  }

  void _calculateMartDeliveryWithBackendSettings() {
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? 299;
    final baseCharge = dc.baseDeliveryCharge ?? 21;
    final freeKm = dc.freeDeliveryDistanceKm ?? 7;
    final perKm = dc.perKmChargeAboveFreeDistance ?? 8;
    final distance = totalDistance;

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal < threshold) {
      if (distance <= freeKm) {
        deliveryCharges = baseCharge.toDouble();
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
        originalDeliveryFee = deliveryCharges;
      }
    } else {
      if (distance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
        deliveryCharges = (extraKm * perKm).toDouble();
      }
    }
  }

  void calculateRegularDeliveryCharge() {
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? 299;
    final baseCharge = dc.baseDeliveryCharge ?? 21;
    final freeKm = dc.freeDeliveryDistanceKm ?? 7;
    final perKm = dc.perKmChargeAboveFreeDistance ?? 8;

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal < threshold) {
      if (totalDistance <= freeKm) {
        deliveryCharges = baseCharge.toDouble();
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
        originalDeliveryFee = deliveryCharges;
      }
    } else {
      if (totalDistance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
        deliveryCharges = (extraKm * perKm).toDouble();
      }
    }
  }

  double _getCachedFreeDeliveryKm(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _cachedFreeDeliveryKm[cacheKey] ?? 3.0;
  }

  double _getCachedExtraKmCharge(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _cachedExtraKmCharge[cacheKey] ?? 7.0;
  }

  Future<void> _loadCalculationCache() async {
    if (_calculationCacheLoaded) return;

    try {
      _cachedTaxList ??= await FireStoreUtils.getTaxList();
      final futures = <Future>[];

      for (var item in HomeProvider.cartItem) {
        if (item.promoId != null && item.promoId!.isNotEmpty) {
          final cacheKey = '${item.id}-${item.vendorID}';
          if (!_promotionalCalculationCache.containsKey(cacheKey)) {
            futures.add(
              _cachePromotionalData(
                item.id ?? '',
                item.vendorID ?? '',
                cacheKey,
              ),
            );
          }
        }
      }

      await Future.wait(futures);
      _calculationCacheLoaded = true;
    } catch (e) {
      print('[CALC_CACHE] ❌ Error: $e');
    }
  }

  set isGlobalLocked(bool value) {
    _isGlobalLocked = value;
    notifyListeners();
  }

  void _lockGlobal() {
    _isGlobalLocked = true;
    notifyListeners();
  }

  void _unlockGlobal() {
    _isGlobalLocked = false;
    notifyListeners();
  }

  Future<void> _cachePromotionalData(
    String productId,
    String restaurantId,
    String cacheKey,
  ) async {
    try {
      final promoDetails = await FireStoreUtils.getActivePromotionForProduct(
        productId: productId,
        restaurantId: restaurantId,
      );

      if (promoDetails != null) {
        _promotionalCalculationCache[cacheKey] = promoDetails;
        final freeDeliveryKm =
            (promoDetails['free_delivery_km'] as num?)?.toDouble() ?? 3.0;
        final extraKmCharge =
            (promoDetails['extra_km_charge'] as num?)?.toDouble() ?? 7.0;
        _cachedFreeDeliveryKm[cacheKey] = freeDeliveryKm;
        _cachedExtraKmCharge[cacheKey] = extraKmCharge;
      }
    } catch (e) {
      print('[PROMO_CACHE] ❌ Error: $e');
    }
  }

  // ============ CART ITEM OPERATIONS ============

  Future<bool> addToCart({
    required CartProductModel cartProductModel,
    required bool isIncrement,
    required int quantity,
  }) async {
    if (isIncrement) {
      final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
      if (!isLoggedIn) {
        _showLoginRequiredDialog(Get.context!);
        return false;
      }

      if (cartProductModel.promoId != null &&
          cartProductModel.promoId!.isNotEmpty) {
        final isAllowed = isPromotionalItemQuantityAllowed(
          cartProductModel.id ?? '',
          cartProductModel.vendorID ?? '',
          quantity,
        );
        if (!isAllowed) {
          final limit = getPromotionalItemLimit(
            cartProductModel.id ?? '',
            cartProductModel.vendorID ?? '',
          );
          ShowToastDialog.showToast(
            "Maximum $limit items allowed for this promotional offer".tr,
          );
          return false;
        }
      }

      final success = await cartProvider.addToCart(
        Get.context!,
        cartProductModel,
        quantity,
      );

      if (!success) {
        return false;
      }
    } else {
      cartProvider.removeFromCart(cartProductModel, quantity);
    }

    await _incrementalCartUpdate();
    notifyListeners();
    return true;
  }

  Future<void> _incrementalCartUpdate() async {
    try {
      await _loadNewProductsIncrementally();
      await calculatePrice();
      checkAndUpdatePaymentMethod();
      updateCartReadiness();
      notifyListeners();
    } catch (e) {
      print('[CART_UPDATE] ❌ Error: $e');
      await forceRefreshCart();
    }
  }

  Future<void> _loadNewProductsIncrementally() async {
    try {
      final Set<String> productIds = {};

      for (final cartItem in HomeProvider.cartItem) {
        if (cartItem.id != null &&
            cartItem.id!.isNotEmpty &&
            cartItem.id!.toLowerCase() != 'null') {
          final parts = cartItem.id!.split('~');
          if (parts.isNotEmpty &&
              parts.first.isNotEmpty &&
              parts.first.toLowerCase() != 'null') {
            productIds.add(parts.first);
          }
        }
      }

      final Set<String> productsToLoad = productIds
          .where((id) => !_productCache.containsKey(id))
          .toSet();

      if (productsToLoad.isEmpty) return;

      final List<Future<void>> loadFutures = productsToLoad.map((
        productId,
      ) async {
        try {
          final isMartItem = _isMartItem(
            HomeProvider.cartItem.firstWhere(
              (item) => item.id?.split('~').first == productId,
              orElse: () => CartProductModel(),
            ),
          );

          if (isMartItem) {
            _productCache[productId] = null;
          } else {
            final product = await FireStoreUtils.getProductById(productId);
            _productCache[productId] = product;
          }
          notifyListeners();
        } catch (e) {
          print('[INCREMENTAL_LOAD] ❌ Error: $e');
          _productCache[productId] = null;
        }
      }).toList();

      await Future.wait(loadFutures);
      _productsLoaded = true;
      notifyListeners();
    } catch (e) {
      print('[INCREMENTAL_LOAD] ❌ Error: $e');
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Login Required".tr,
          descriptions:
              "Please login to add items to your cart and continue shopping."
                  .tr,
          positiveString: "Login".tr,
          negativeString: "Cancel".tr,
          positiveClick: () {
            Get.back();
            Get.to(() => PhoneNumberScreen());
          },
          negativeClick: () {
            Get.back();
          },
          img: Image.asset(
            'assets/images/ic_launcher.png',
            height: 50,
            width: 50,
          ),
        );
      },
    );
  }

  // ============ VALIDATION METHODS ============

  Future<bool> validateAndPlaceOrderBulletproof(BuildContext context) async {
    await validateUserProfileBulletproof();

    if (!isProfileValid) {
      final user = userModel;
      List<String> missingFields = [];

      if (user.firstName == null ||
          user.firstName!.trim().isEmpty ||
          user.firstName!.trim().length < 2) {
        missingFields.add("First Name (minimum 2 characters)");
      }

      if (user.phoneNumber == null ||
          user.phoneNumber!.trim().isEmpty ||
          user.phoneNumber!.trim().length < 10) {
        missingFields.add("Phone Number (minimum 10 digits)");
      }

      if (user.email == null ||
          user.email!.trim().isEmpty ||
          !user.email!.contains('@')) {
        missingFields.add("Valid Email Address");
      }

      String message = "Please complete your profile before placing an order.";
      if (missingFields.isNotEmpty) {
        message =
            "Missing required fields: ${missingFields.join(', ')}. Please complete your profile.";
      }

      ShowToastDialog.showToast(message);
      return false;
    }

    final addressValid = await _validateAddressBulletproof(context);
    if (!addressValid) {
      return false;
    }

    try {
      await validateMinimumOrderValue();
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<bool> _validateAddressBulletproof(
    BuildContext context, {
    bool isRetry = false,
  }) async {
    try {
      if (!isRetry &&
          (selectedAddress == null ||
              selectedAddress!.location?.latitude == null ||
              selectedAddress!.location?.longitude == null ||
              selectedAddress!.location!.latitude == 0.0 ||
              selectedAddress!.location!.longitude == 0.0 ||
              selectedAddress!.address == null ||
              selectedAddress!.address!.isEmpty ||
              selectedAddress!.address == 'Current Location')) {
        final homeScreenAddress = await _getCurrentLocationAddress(context);
        if (homeScreenAddress != null) {
          selectedAddress = homeScreenAddress;
        }
      }

      if (selectedAddress == null) {
        ShowToastDialog.showToast(
          "Delivery address is required. Please add an address to continue.".tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      final address = selectedAddress!;

      if (address.id == null || address.id!.trim().isEmpty) {
        ShowToastDialog.showToast(
          "Invalid address detected. Please select a valid delivery address."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      if (address.address == null ||
          address.address!.trim().isEmpty ||
          address.address!.trim() == 'null') {
        ShowToastDialog.showToast(
          "Please select a valid delivery address with complete address details."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      if (address.locality == null ||
          address.locality!.trim().isEmpty ||
          address.locality!.trim() == 'null') {
        ShowToastDialog.showToast(
          "Please select a valid delivery address with complete location details."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      if (address.location == null ||
          address.location!.latitude == null ||
          address.location!.longitude == null ||
          address.location!.latitude == 0.0 ||
          address.location!.longitude == 0.0) {
        if (!isRetry) {
          final homeScreenAddress = await _getCurrentLocationAddress(context);
          if (homeScreenAddress != null &&
              homeScreenAddress.location?.latitude != null &&
              homeScreenAddress.location?.longitude != null) {
            selectedAddress = homeScreenAddress;
            return await _validateAddressBulletproof(context, isRetry: true);
          }
        }

        ShowToastDialog.showToast(
          "Please select a delivery address with valid location coordinates."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      if (address.id!.startsWith('fallback_zone_') ||
          address.address == 'Ongole' ||
          address.address == 'Service Area' ||
          address.locality == 'Ongole' ||
          address.locality == 'Service Area' ||
          address.id!.contains('ongole_fallback_zone')) {
        ShowToastDialog.showToast(
          "Please add a valid delivery address. Fallback zones are not allowed."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      final lat = address.location!.latitude!;
      final lng = address.location!.longitude!;

      if (lat < 6.0 || lat > 37.0 || lng < 68.0 || lng > 97.0) {
        ShowToastDialog.showToast(
          "Please select a delivery address within our service area.".tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }

      if (address.zoneId == null || address.zoneId!.isEmpty) {
        String? detectedZoneId;

        if (Constant.selectedLocation.zoneId != null &&
            Constant.selectedLocation.zoneId!.isNotEmpty) {
          detectedZoneId = Constant.selectedLocation.zoneId;
        } else if (Constant.selectedZone?.id != null &&
            Constant.selectedZone!.id!.isNotEmpty) {
          detectedZoneId = Constant.selectedZone!.id;
        } else {
          detectedZoneId = await _detectZoneIdForCoordinates(
            address.location!.latitude!,
            address.location!.longitude!,
            context,
          );
        }

        if (detectedZoneId != null && detectedZoneId.isNotEmpty) {
          address.zoneId = detectedZoneId;
          Constant.selectedLocation.zoneId = detectedZoneId;
        } else {
          ShowToastDialog.showToast(
            "Address zone not detected. Please update your address or contact support."
                .tr,
          );
          Get.to(() => const AddressListScreen());
          return false;
        }
      }

      if (vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) {
        if (vendorModel.id != null) {
          final hasMartItems = HomeProvider.cartItem.any(
            (item) => item.vendorID?.startsWith('mart_') == true,
          );

          if (hasMartItems) {
            try {
              final vendorId = vendorModel.id;
              MartVendorModel? martVendor;

              if (vendorId != null && vendorId.isNotEmpty) {
                martVendor = await MartVendorService.getMartVendorById(
                  vendorId,
                );
              }
              martVendor ??= await MartVendorService.getDefaultMartVendor();

              if (martVendor != null &&
                  martVendor.zoneId != null &&
                  martVendor.zoneId!.isNotEmpty) {
                vendorModel.zoneId = martVendor.zoneId;
              } else if (address.zoneId != null && address.zoneId!.isNotEmpty) {
                vendorModel.zoneId = address.zoneId;
              }
            } catch (e) {
              print('[VENDOR_ZONE] ❌ Error: $e');
            }
          }
        }

        if ((vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) &&
            address.zoneId != null &&
            address.zoneId!.isNotEmpty) {
          vendorModel.zoneId = address.zoneId;
        } else if ((vendorModel.zoneId == null ||
                vendorModel.zoneId!.isEmpty) &&
            Constant.selectedLocation.zoneId != null &&
            Constant.selectedLocation.zoneId!.isNotEmpty) {
          vendorModel.zoneId = Constant.selectedLocation.zoneId;
        } else if ((vendorModel.zoneId == null ||
                vendorModel.zoneId!.isEmpty) &&
            Constant.selectedZone?.id != null &&
            Constant.selectedZone!.id!.isNotEmpty) {
          vendorModel.zoneId = Constant.selectedZone!.id;
        }

        if (vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) {
          ShowToastDialog.showToast(
            "Vendor zone not configured. Please contact support.".tr,
          );
          return false;
        }
      }

      if (address.zoneId != vendorModel.zoneId) {
        DeliveryZoneAlertDialog.showZoneMismatchError();
        return false;
      }

      if (vendorModel.latitude != null && vendorModel.longitude != null) {
        final distance = Constant.calculateDistance(
          address.location!.latitude!,
          address.location!.longitude!,
          vendorModel.latitude!,
          vendorModel.longitude!,
        );

        const maxDeliveryDistance = 16.0;

        if (distance > maxDeliveryDistance) {
          DeliveryZoneAlertDialog.showDistanceTooFarError();
          return false;
        }
      }

      return true;
    } catch (e) {
      ShowToastDialog.showToast(
        "Error validating address. Please select a valid delivery address.".tr,
      );

      Get.to(() => const AddressListScreen());
      return false;
    }
  }

  //   Future<void> rollbackFailedOrder(
  //     String orderId,
  //     List<CartProductModel> products,
  //   ) async {
  //     try {
  //       // Prepare the request body
  //       final Map<String, dynamic> requestBody = {
  //         "order_id": orderId,
  //         "products": products
  //             .map((product) => {"id": product.id, "quantity": product.quantity})
  //             .toList(),
  //       };
  //       final response = await http.post(
  //         Uri.parse('${AppConst.baseUrl}/mobile/orders/rollback-failed'),
  //         headers: await getHeaders(),
  //         body: jsonEncode(requestBody),
  //       );
  //       if (response.statusCode == 200) {
  //         print('Order rollback successful for order: $orderId');
  //         notifyListeners();
  //       } else {
  //         // Handle API error
  //         print('Failed to rollback order: ${response.statusCode}');
  //         throw Exception('Failed to rollback order: ${response.statusCode}');
  //       }
  //     } catch (e) {
  //       print('Error rolling back order: $e');
  //       // Re-throw the exception or handle it as needed
  //       rethrow;
  //     }
  //   }
  // ============ PAYMENT METHODS ============

  // Future<void> getPaymentSettings() async {
  //   try {
  //     await FireStoreUtils.getPaymentSettingsData()
  //         .then((value) {
  //           try {
  //             final razorpaySettingsStr = Preferences.getString(
  //               Preferences.razorpaySettings,
  //             );
  //             final codSettingsStr = Preferences.getString(
  //               Preferences.codSettings,
  //             );
  //
  //             if (razorpaySettingsStr.isNotEmpty) {
  //               razorPayModel = RazorPayModel.fromJson(
  //                 jsonDecode(razorpaySettingsStr),
  //               );
  //             }
  //
  //             if (codSettingsStr.isNotEmpty) {
  //               cashOnDeliverySettingModel = CodSettingModel.fromJson(
  //                 jsonDecode(codSettingsStr),
  //               );
  //             }
  //
  //             if (selectedPaymentMethod == PaymentGateway.cod.name &&
  //                 cashOnDeliverySettingModel.isEnabled != true) {
  //               selectedPaymentMethod = '';
  //             }
  //
  //             if (cashOnDeliverySettingModel.isEnabled == true &&
  //                 subTotal <= cashOnDeliverySettingModel.getMaxAmount() &&
  //                 !hasMartItemsInCart()) {
  //               selectedPaymentMethod = PaymentGateway.cod.name;
  //             } else if (razorPayModel.isEnabled == true) {
  //               selectedPaymentMethod = PaymentGateway.razorpay.name;
  //             }
  //
  //             if (razorPayModel.isEnabled == true &&
  //                 razorPayModel.razorpayKey != null &&
  //                 razorPayModel.razorpayKey!.isNotEmpty) {
  //               _preInitializeRazorpay();
  //             }
  //
  //             checkAndUpdatePaymentMethod();
  //           } catch (e) {
  //             print('[PAYMENT_SETTINGS] ❌ Error parsing: $e');
  //             if (razorPayModel.isEnabled == true) {
  //               selectedPaymentMethod = PaymentGateway.razorpay.name;
  //               _preInitializeRazorpay();
  //             }
  //           }
  //         })
  //         .catchError((e) {
  //           print('[PAYMENT_SETTINGS] ❌ Error fetching: $e');
  //           if (razorPayModel.isEnabled == true) {
  //             selectedPaymentMethod = PaymentGateway.razorpay.name;
  //             _preInitializeRazorpay();
  //           }
  //         });
  //   } catch (e) {
  //     print('[PAYMENT_SETTINGS] ❌ Error: $e');
  //   }
  //   notifyListeners();
  // }

  Future<void> _preInitializeRazorpay() async {
    try {
      if (!_razorpayCrashPrevention.isInitialized) {
        print('[RAZORPAY] 🔄 Pre-initializing...');
        await _razorpayCrashPrevention.safeInitialize(
          onSuccess: handlePaymentSuccess,
          onFailure: handlePaymentError,
          onExternalWallet: handleExternalWallet,
        );
      }
    } catch (e) {
      print('[RAZORPAY_PREINIT] ⚠️ Failed: $e');
    }
  }

  Razorpay? get razorPay => _razorpayCrashPrevention.razorpayInstance;

  // ============ CART READINESS ============

  void updateCartReadiness() {
    isCartReady = HomeProvider.cartItem.isNotEmpty && subTotal > 0;
    isPaymentReady = isCartReadyForPayment();
    isAddressValid = selectedAddress?.id != null;
    if (!_isCalculatingPrice) notifyListeners();
  }

  bool isCartReadyForPayment() {
    final cartNotEmpty = HomeProvider.cartItem.isNotEmpty;
    final subTotalValid = subTotal > 0;
    final totalValid = totalAmount > 0;
    final paymentMethodSelected = selectedPaymentMethod.isNotEmpty;
    final profileValid = isProfileValid;
    final notProcessing = !isProcessingOrder;
    final notPaymentInProgress = !isPaymentInProgress;
    final notPaymentCompleted = !isPaymentCompleted;

    final isReady =
        cartNotEmpty &&
        subTotalValid &&
        totalValid &&
        paymentMethodSelected &&
        profileValid &&
        notProcessing &&
        notPaymentInProgress &&
        notPaymentCompleted;

    return isReady;
  }

  void checkAndUpdatePaymentMethod() {
    final hasPromoItems = hasPromotionalItems();

    if (hasPromoItems) {
      if (selectedPaymentMethod == PaymentGateway.cod.name ||
          selectedPaymentMethod.isEmpty) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }
    } else if (subTotal > 599) {
      if (selectedPaymentMethod == PaymentGateway.cod.name ||
          selectedPaymentMethod.isEmpty) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }
    }
    if (!_isCalculatingPrice) notifyListeners();
  }

  Future<void> rollbackFailedOrder(
    String orderId,
    List<CartProductModel> products,
  ) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "order_id": orderId,
        "products": products
            .map((product) => {"id": product.id, "quantity": product.quantity})
            .toList(),
      };
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}/mobile/orders/rollback-failed'),
        headers: await getHeaders(),
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        print('Order rollback successful for order: $orderId');
        notifyListeners();
      } else {
        // Handle API error
        print('Failed to rollback order: ${response.statusCode}');
        throw Exception('Failed to rollback order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error rolling back order: $e');
      // Re-throw the exception or handle it as needed
      rethrow;
    }
  }

  // ============ PAYMENT DIALOG METHOD ============

  Future<bool> showPaymentMethodDialog(BuildContext context) async {
    _startOperation('showPaymentMethodDialog');

    // Validate before showing dialog
    final canProceed = await validateAndPlaceOrderBulletproof(context);
    if (!canProceed) {
      endOrderProcessing();
      return false;
    }

    final String initialSelection = selectedPaymentMethod;

    final result = await Get.dialog<bool>(
      WillPopScope(
        onWillPop: () async {
          selectedPaymentMethod = initialSelection;
          notifyListeners();
          Get.back(result: false);
          return false;
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.payment, color: Colors.orange, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Select Payment Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose how you want to pay for your order:",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),

                  // COD Option
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.all(4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            "assets/images/ic_cash.png",
                            width: 30,
                            height: 30,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cash on Delivery",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Pay when you receive your order",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      value: PaymentGateway.cod.name,
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPaymentMethod = value;
                          });
                          notifyListeners();
                        }
                      },
                      activeColor: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Razorpay Option
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.all(4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            "assets/images/razorpay.png",
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Online Payment",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Pay securely with Razorpay",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: PaymentGateway.razorpay.name,
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPaymentMethod = value;
                          });
                          notifyListeners();
                        }
                      },
                      activeColor: Colors.orange,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Validation messages
                  if (subTotal > cashOnDeliverySettingModel.getMaxAmount() &&
                      selectedPaymentMethod == PaymentGateway.cod.name)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "COD not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (hasPromotionalItems() &&
                      selectedPaymentMethod == PaymentGateway.cod.name)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "COD not available for promotional items",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    selectedPaymentMethod = "";
                    notifyListeners();
                    Get.back(result: false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedPaymentMethod.isEmpty) {
                      ShowToastDialog.showToast(
                        "Please select a payment method".tr,
                      );
                      return;
                    }

                    if (selectedPaymentMethod == PaymentGateway.cod.name) {
                      if (subTotal >
                          cashOnDeliverySettingModel.getMaxAmount()) {
                        ShowToastDialog.showToast(
                          "COD not available for orders above ₹${cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}. Please select online payment."
                              .tr,
                        );
                        return;
                      }

                      if (hasPromotionalItems()) {
                        ShowToastDialog.showToast(
                          "COD not available for promotional items. Please select online payment."
                              .tr,
                        );
                        return;
                      }
                    }

                    Get.back(result: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Confirm Payment"),
                ),
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    );

    notifyListeners();
    _endOperation('showPaymentMethodDialog');

    return result == true && selectedPaymentMethod.isNotEmpty;
  }

  // ============ PROVIDER INITIALIZER METHOD ============

  void providerInitializer({required BuildContext context}) {
    _startOperation('providerInitializer');

    orderPlacingProvider = Provider.of<OrderPlacingProvider>(
      context,
      listen: false,
    );

    _endOperation('providerInitializer');
    notifyListeners();
  }

  // ============ PROCESS PAYMENT METHOD ============

  // ============ OPEN CHECKOUT METHOD ============
  // Add this method if it's missing:

  void resetAllProcessingFlags() {
    print('🔄 [SAFETY_RESET] Resetting all processing flags');

    isProcessingOrder = false;
    isPaymentInProgress = false;
    isPaymentCompleted = false;
    _isOrderBeingCreated = false;
    _isOrderCreationInProgress = false;
    _orderInProgress = false;
    _isGlobalLocked = false;
    _currentOrderPaymentId = null;

    // Clear any pending timers
    _calculatePriceDebounceTimer?.cancel();
    _syncPricesDebounceTimer?.cancel();

    notifyListeners();
  }

  Future<bool> openCheckout({required amount, required orderId}) async {
    print(
      '🔑 [RAZORPAY_CHECKOUT] Starting openCheckout - amount: $amount, orderId: $orderId',
    );

    if (isPaymentInProgress) {
      print('⚠️ [RAZORPAY_CHECKOUT] Payment already in progress');
      ShowToastDialog.showToast(
        "Payment is already in progress. Please wait...".tr,
      );
      return false;
    }

    if (isPaymentCompleted) {
      print('⚠️ [RAZORPAY_CHECKOUT] Payment already completed');
      ShowToastDialog.showToast(
        "Payment already completed. Please refresh the page.".tr,
      );
      return false;
    }

    if (!_razorpayCrashPrevention.isInitialized) {
      print(
        '⚠️ [RAZORPAY_CHECKOUT] Razorpay not initialized (unexpected), initializing now...',
      );
      final initialized = await _razorpayCrashPrevention.safeInitialize(
        onSuccess: handlePaymentSuccess,
        onFailure: handlePaymentError,
        onExternalWallet: handleExternalWallet,
      );

      if (!initialized) {
        print('❌ [RAZORPAY_CHECKOUT] Razorpay initialization failed');
        ShowToastDialog.showToast(
          "Payment system is temporarily unavailable. Please try again later."
              .tr,
        );
        return false;
      }
      print('✅ [RAZORPAY_CHECKOUT] Razorpay initialized (fallback)');
    } else {
      print(
        '✅ [RAZORPAY_CHECKOUT] Razorpay already initialized (pre-initialized)',
      );
    }

    isPaymentInProgress = true;
    print('🔑 [RAZORPAY_CHECKOUT] Payment in progress flag set');

    if (razorPayModel.razorpayKey == null ||
        razorPayModel.razorpayKey!.isEmpty) {
      print('❌ [RAZORPAY_CHECKOUT] Razorpay key is null or empty');
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Payment configuration error. Please contact support.".tr,
      );
      return false;
    }

    if (!razorPayModel.razorpayKey!.startsWith('rzp_')) {
      print(
        '❌ [RAZORPAY_CHECKOUT] Invalid Razorpay key format: ${razorPayModel.razorpayKey}',
      );
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Payment configuration error. Please contact support.".tr,
      );
      return false;
    }

    int amountInPaise;
    if (amount is int) {
      amountInPaise = amount;
    } else if (amount is double) {
      amountInPaise = (amount * 100).round();
    } else {
      amountInPaise = (double.parse(amount.toString()) * 100).round();
    }

    print('🔑 [RAZORPAY_CHECKOUT] Amount in paise: $amountInPaise');

    var options = {
      'key': razorPayModel.razorpayKey,
      'amount': amountInPaise,
      'name': 'JIPPY MART',
      'order_id': orderId,
      "currency": "INR",
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': userModel.phoneNumber, 'email': userModel.email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    print('🔑 [RAZORPAY_CHECKOUT] Payment options prepared');
    notifyListeners();

    try {
      print('🔑 [RAZORPAY_CHECKOUT] Calling safeOpenPayment...');
      final success = await _razorpayCrashPrevention.safeOpenPayment(options);

      if (success) {
        print('✅ [RAZORPAY_CHECKOUT] Payment gateway opened successfully');
        return true;
      } else {
        print('❌ [RAZORPAY_CHECKOUT] safeOpenPayment returned false');
        isPaymentInProgress = false;
        ShowToastDialog.showToast(
          "Failed to open payment gateway. Please try again.".tr,
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [RAZORPAY_CHECKOUT] Exception in openCheckout: $e');
      print('❌ [RAZORPAY_CHECKOUT] Stack trace: $stackTrace');
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Failed to open payment gateway. Please try again.".tr,
      );
      return false;
    }
  }

  // ============ PLACE ORDER METHOD ============
  // Add this method if it's missing:

  // Add this method if validateOrderBeforePayment is missing:
  Future<bool> validateOrderBeforePayment(BuildContext context) async {
    try {
      if (HomeProvider.cartItem.isEmpty) {
        ShowToastDialog.showToast(
          "Your cart is empty. Please add items before placing order.".tr,
        );
        return false;
      }

      try {
        await validateMinimumOrderValue();
      } catch (e) {
        return false;
      }

      final addressValid = await _validateAddressBulletproof(context);
      if (!addressValid) {
        return false;
      }

      if (vendorModel.id != null) {
        final latestVendor = await FireStoreUtils.getVendorById(
          vendorModel.id!,
        );
        if (latestVendor != null) {
          if (latestVendor.vType == 'mart') {
            if (latestVendor.isOpen == false) {
              ShowToastDialog.showToast(
                "Jippy Mart is temporarily closed. Please try again later.",
              );
              return false;
            }
          } else {
            if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
              ShowToastDialog.showToast("Restaurant Closed");
              return false;
            }
          }
        }
      }

      // Validate all items in cart for availability
      for (var item in HomeProvider.cartItem) {
        bool isMartItem = item.vendorID?.startsWith('mart_') == true;

        if (isMartItem) {
          try {
            final martItems = await MartFirestoreService().getMartItems();
            final martItem = martItems.firstWhere(
              (mart) => mart.id == item.id!,
              orElse: () => MartItemModel(
                id: '',
                name: '',
                description: '',
                price: 0,
                photo: '',
                isAvailable: false,
                publish: false,
                veg: false,
                nonveg: false,
                quantity: 0,
              ),
            );

            final availableQuantity = martItem.quantity;
            final orderedQuantity = item.quantity ?? 0;
            if (availableQuantity != -1 &&
                availableQuantity < orderedQuantity) {
              final itemName = martItem.displayName;
              ShowToastDialog.showToast(
                "$itemName is out of stock. Available: $availableQuantity, Ordered: $orderedQuantity",
              );
              return false;
            }
          } catch (e) {
            print('[ORDER VALIDATION] ❌ Error validating mart items: $e');
            ShowToastDialog.showToast(
              "Error validating mart items. Please try again.",
            );
            return false;
          }
        } else {
          final productId = item.id;
          if (productId == null ||
              productId.isEmpty ||
              productId == 'null' ||
              productId.trim().isEmpty) {
            print('[CART_VALIDATION] Invalid product ID: $productId');
            ShowToastDialog.showToast(
              "Some items in your cart have invalid product information.".tr,
            );
            return false;
          }

          final baseProductId = productId.contains('~')
              ? productId.split('~').first
              : productId;

          final product = await FireStoreUtils.getProductById(baseProductId);
          if (product == null) {
            ShowToastDialog.showToast(
              "Some items in your cart are no longer available.".tr,
            );
            return false;
          }

          if (product.quantity != -1) {
            int availableQuantity = product.quantity ?? 0;
            int orderedQuantity = item.quantity ?? 0;

            if (availableQuantity < orderedQuantity) {
              ShowToastDialog.showToast(
                "${product.name} is out of stock. Available: $availableQuantity, Ordered: $orderedQuantity"
                    .tr,
              );
              return false;
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('[ORDER_VALIDATION] ❌ Error: $e');
      ShowToastDialog.showToast("Error validating order. Please try again.".tr);
      return false;
    }
  }

  // ============ SET ORDER METHOD ============
  // Add this method if it's missing:

  setOrder() async {
    _startOperation('setOrder');

    try {
      // Validate vendor
      if (vendorModel.id != null) {
        final latestVendor = await FireStoreUtils.getVendorById(
          vendorModel.id.toString(),
        );
        if (latestVendor != null) {
          if (latestVendor.vType == 'mart') {
            if (latestVendor.isOpen == false) {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showToast(
                "Jippy Mart is temporarily closed. Please try again later.",
              );
              endOrderProcessing();
              return;
            }
          } else {
            if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showToast("Restaurant Closed");
              endOrderProcessing();
              return;
            }
          }
        }
      }

      notifyListeners();
      return await _setOrderInternal();
    } catch (e) {
      print('❌ [SET_ORDER] Error: $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to place order. Please try again.".tr);
      endOrderProcessing();
      rethrow;
    } finally {
      _endOperation('setOrder');
    }
  }

  Future<void> processPayment(
    CartControllerProvider controller,
    BuildContext context,
  ) async {
    _startOperation('processPayment');

    try {
      // 🔑 FIX: Clear any stale processing flags at the start
      if (controller.isProcessingOrder) {
        // Force reset if stuck
        controller.endOrderProcessing();
        await Future.delayed(Duration(milliseconds: 100));
      }

      final canProceed = await controller.validateAndPlaceOrderBulletproof(
        context,
      );
      if (!canProceed) {
        controller.endOrderProcessing();
        return;
      }

      // Validate coupon amount
      if ((controller.couponAmount >= 1) &&
          (controller.couponAmount > controller.totalAmount)) {
        ShowToastDialog.showToast(
          "The total price must be greater than or equal to the coupon discount value for the code to apply. Please review your cart total."
              .tr,
        );
        controller.endOrderProcessing();
        return;
      }

      // Validate special discount
      if ((controller.specialDiscountAmount >= 1) &&
          (controller.specialDiscountAmount > controller.totalAmount)) {
        ShowToastDialog.showToast(
          "The total price must be greater than or equal to the special discount value for the code to apply. Please review your cart total."
              .tr,
        );
        controller.endOrderProcessing();
        return;
      }

      if (controller.selectedPaymentMethod.isEmpty) {
        ShowToastDialog.showToast("Please select payment method".tr);
        controller.endOrderProcessing();
        return;
      }

      if (controller.selectedPaymentMethod == PaymentGateway.cod.name) {
        // Directly call placeOrder for COD
        controller.placeOrder(context);
      } else if (controller.selectedPaymentMethod ==
          PaymentGateway.razorpay.name) {
        // Handle Razorpay payment flow
        await _processRazorpayPayment(controller);
      }
    } catch (e, stackTrace) {
      print('❌ [PROCESS_PAYMENT] Error: $e');
      print('❌ [PROCESS_PAYMENT] Stack trace: $stackTrace');
      ShowToastDialog.showToast(
        "Payment processing failed. Please try again.".tr,
      );
      controller.endOrderProcessing();
    } finally {
      _endOperation('processPayment');
    }
  }

  Future<void> _processRazorpayPayment(
    CartControllerProvider controller,
  ) async {
    if (controller.razorPayModel.razorpayKey == null ||
        controller.razorPayModel.razorpayKey!.isEmpty) {
      print('❌ [RAZORPAY] Razorpay key is missing or empty');
      ShowToastDialog.showToast(
        "Payment configuration error. Please contact support.".tr,
      );
      controller.endOrderProcessing();
      return;
    }

    print(
      '✅ [RAZORPAY] Razorpay key found: ${controller.razorPayModel.razorpayKey!.substring(0, 10)}...',
    );

    // Clear any stale payment state
    controller.isPaymentInProgress = false;
    controller.isPaymentCompleted = false;
    controller._lastPaymentId = null;

    print(
      '🔑 [RAZORPAY] Starting payment flow for amount: ${controller.totalAmount}',
    );

    ShowToastDialog.showLoader("Opening payment gateway...".tr);

    // Initialize Razorpay if needed
    if (!controller._razorpayCrashPrevention.isInitialized) {
      print('🔑 [RAZORPAY] Razorpay not initialized, initializing now...');
      final initialized = await controller._razorpayCrashPrevention
          .safeInitialize(
            onSuccess: controller.handlePaymentSuccess,
            onFailure: controller.handlePaymentError,
            onExternalWallet: controller.handleExternalWallet,
          );

      if (!initialized) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Payment system is temporarily unavailable. Please try again later."
              .tr,
        );
        controller.endOrderProcessing();
        return;
      }
    }

    // Create Razorpay order
    final orderResult = await RazorPayController().createOrderRazorPay(
      amount: double.parse(controller.totalAmount.toString()),
      razorpayModel: controller.razorPayModel,
    );

    if (orderResult == null) {
      print('❌ [RAZORPAY] Order creation returned null');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        "Something went wrong, please contact admin.".tr,
      );
      controller.endOrderProcessing();
      return;
    }

    print('✅ [RAZORPAY] Order created successfully: ${orderResult.id}');
    ShowToastDialog.closeLoader();

    // Open checkout
    final checkoutOpened = await controller.openCheckout(
      amount: orderResult.amount / 100.0,
      orderId: orderResult.id,
    );

    if (!checkoutOpened) {
      print('❌ [RAZORPAY] Checkout failed to open');
      ShowToastDialog.showToast(
        "Failed to open payment gateway. Please try again.".tr,
      );
      controller.endOrderProcessing();
    }
  }

  Future<void> _setOrderInternal() async {
    try {
      // 🔑 CRITICAL FIX: Only check for Razorpay orders, NOT for COD
      // COD orders should not be blocked by duplicate prevention
      if (selectedPaymentMethod == PaymentGateway.razorpay.name) {
        if (_isOrderCreationInProgress &&
            _currentOrderPaymentId == _lastPaymentId) {
          print(
            '⚠️ [ORDER_CREATION] Order creation already in progress for payment ID $_lastPaymentId, preventing duplicate',
          );
          return;
        }

        if (_lastOrderCreationTime != null &&
            _currentOrderPaymentId == _lastPaymentId) {
          final timeSinceLastOrder = DateTime.now().difference(
            _lastOrderCreationTime!,
          );
          if (timeSinceLastOrder < _orderCreationCooldown) {
            print(
              '⚠️ [ORDER_CREATION] Order creation cooldown active, preventing duplicate for payment ID: $_lastPaymentId',
            );
            return;
          }
        }
      }

      // Set static lock immediately
      _isOrderCreationInProgress = true;
      _currentOrderPaymentId = _lastPaymentId;
      _lastOrderCreationTime = DateTime.now();

      print(
        '✅ [ORDER_CREATION] Starting order creation for payment ID: $_lastPaymentId, Payment method: $selectedPaymentMethod',
      );

      // 🔑 CRITICAL: For COD, clear payment flags since there's no actual payment
      if (selectedPaymentMethod == PaymentGateway.cod.name) {
        _lastPaymentId = null;
        isPaymentCompleted = false;
        isPaymentInProgress = false;
      }

      // Validation checks...
      if (HomeProvider.cartItem.isEmpty) {
        print('❌ [ORDER_CREATION] Cart is empty, cannot create order');
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Cart is empty. Please add items to cart.".tr,
        );
        _isOrderCreationInProgress = false;
        _currentOrderPaymentId = null;
        endOrderProcessing();
        _unlockGlobal();
        return;
      }

      await calculatePrice();

      if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
        print(
          '❌ [ORDER_CREATION] Invalid subTotal: $subTotal, cannot create order',
        );
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Order calculation error. Please refresh and try again.".tr,
        );
        _isOrderCreationInProgress = false;
        _currentOrderPaymentId = null;
        endOrderProcessing();
        _unlockGlobal();
        return;
      }

      if (totalAmount <= 0 || totalAmount.isNaN || totalAmount.isInfinite) {
        print(
          '❌ [ORDER_CREATION] Invalid totalAmount: $totalAmount, cannot create order',
        );
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Order total is invalid. Please refresh and try again.".tr,
        );
        _isOrderCreationInProgress = false;
        _currentOrderPaymentId = null;
        endOrderProcessing();
        _unlockGlobal();
        return;
      }

      print(
        '✅ [ORDER_CREATION] Final validation passed - SubTotal: ₹$subTotal, Total: ₹$totalAmount',
      );

      // 🔑 MART FIX: Ensure vendor is loaded before order (backend needs valid vendor_id)
      if (hasMartItemsInCart()) {
        final martItems = HomeProvider.cartItem
            .where((item) => _isMartItem(item))
            .toList();
        if (martItems.isNotEmpty &&
            (vendorModel.id == null ||
                vendorModel.id!.isEmpty ||
                vendorModel.id == 'mart_default')) {
          await _loadFreshMartVendor(martItems);
          print(
            '[ORDER_CREATION] Loaded mart vendor for order: ${vendorModel.id}',
          );
        }
        // Validate we have a real vendor ID (not mart_default) before proceeding
        final vendorId = _getVendorIdForOrder();
        if (vendorId == 'mart_default') {
          print('❌ [ORDER_CREATION] No valid mart vendor found in cart items');
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Unable to process order. Please remove items and add them again from Mart."
                .tr,
          );
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
          endOrderProcessing();
          _unlockGlobal();
          return;
        }
      }

      // 🔑 FIX 2: Build order model and API payload
      String? orderId;
      List<CartProductModel> orderedProducts = [];
      OrderModel? orderModel;

      tempProduc.clear();

      // Check vendor subscription (skip for mart - uses different table)
      if (!hasMartItemsInCart() &&
          (Constant.isSubscriptionModelApplied == true ||
              Constant.adminCommission?.isEnabled == true) &&
          vendorModel.subscriptionPlan != null &&
          vendorModel.id != null) {
        final vender = await FireStoreUtils.getVendorById(
          vendorModel.id.toString(),
        );
        if (vender?.subscriptionTotalOrders == '0' ||
            vender?.subscriptionTotalOrders == null) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "This vendor has reached their maximum order capacity. Please select a different vendor or try again later."
                .tr,
          );
          endOrderProcessing();
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
          _unlockGlobal();
          return;
        }
      }

      // Prepare cart products
      for (CartProductModel cartProduct in HomeProvider.cartItem) {
        CartProductModel tempCart = cartProduct;
        if (cartProduct.extrasPrice == '0') {
          tempCart.extras = [];
        }
        tempProduc.add(tempCart);
        orderedProducts.add(tempCart);
      }

      Map<String, dynamic> specialDiscountMap = {
        'special_discount': specialDiscountAmount,
        'special_discount_label': specialDiscount,
        'specialType': specialType,
      };

      orderModel = OrderModel();

      // Get latest order number
      int maxNumber = 5;
      try {
        final response = await http.get(
          Uri.parse('${AppConst.baseUrl}firestore/getLatestOrderInRange'),
          headers: await getHeaders(),
        );
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true &&
              responseData['order'] != null) {
            final orderData = responseData['order'];
            final String orderIdFromApi = orderData['id'].toString();
            final match = RegExp(r'Jippy3(\d+)').firstMatch(orderIdFromApi);
            if (match != null) {
              final num = int.tryParse(match.group(1)!);
              if (num != null && num > maxNumber) {
                maxNumber = num;
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Error fetching latest order: $e');
      }

      // Build order model
      orderModel.address = selectedAddress;
      orderModel.authorID = await SqlStorageConst.getFirebaseId();
      orderModel.author = userModel;
      orderModel.vendorID = _getVendorIdForOrder();
      orderModel.vendor = vendorModel;
      orderModel.products = tempProduc;
      orderModel.specialDiscount = specialDiscountMap;
      orderModel.paymentMethod = selectedPaymentMethod;
      orderModel.status = Constant.orderPlaced;
      orderModel.createdAt = Timestamp.now();
      orderModel.couponId = selectedCouponModel.id ?? '';
      orderModel.couponCode = selectedCouponModel.code ?? '';
      orderModel.discount = couponAmount;
      orderModel.deliveryCharge = deliveryCharges.toString();
      orderModel.tipAmount = deliveryTips.toString();
      orderModel.toPayAmount = totalAmount;
      orderModel.scheduleTime = Timestamp.fromDate(scheduleDateTime);

      // Build API payload
      Map<String, dynamic> orderPayload = {
        "author_id": await SqlStorageConst.getFirebaseId(),
        "cart_items": tempProduc.map((item) => item.toJson()).toList(),
        "selected_address": {
          "isDefault": selectedAddress?.isDefault,
          "address": selectedAddress?.address,
          "addressAs": selectedAddress?.addressAs,
          "locality": selectedAddress?.locality,
          "location": {
            "latitude": selectedAddress?.location?.latitude,
            "longitude": selectedAddress?.location?.longitude,
          },
          "id": selectedAddress?.id,
          "landmark": selectedAddress?.landmark,
        },
        "payment_method": selectedPaymentMethod,
        "payment_id": _lastPaymentId ?? '',
        "razorpay_payment_id": _lastPaymentId ?? '',
        "total_amount": totalAmount,
        "delivery_charges": deliveryCharges.toString(),
        "tip_amount": deliveryTips.toString(),
        "coupon_id": selectedCouponModel.id ?? '',
        "coupon_code": selectedCouponModel.code ?? '',
        "discount": couponAmount,
        "schedule_time": scheduleDateTime.toIso8601String(),
        "surge_percent": surgePercent,
        "admin_surge_fee": await getAdminSurgeFee(),
        "special_discount": specialDiscountMap,
        "vendor_id": _getVendorIdForOrder(),
        "v_type":
            vendorModel.vType ?? (hasMartItemsInCart() ? 'mart' : 'restaurant'),
        "status": Constant.orderPlaced,
        "created_at": DateTime.now().toIso8601String(),
      };

      print('🌐 [ORDER_CREATION] Creating order via API...');
      print(
        '🌐 [ORDER_CREATION] vendor_id: ${orderPayload["vendor_id"]}, v_type: ${orderPayload["v_type"]}',
      );
      print('🌐 [ORDER_CREATION] Payment method: $selectedPaymentMethod');
      print('🌐 [ORDER_CREATION] Total amount: ₹$totalAmount');

      // 🔑 FIX 3: Show loader for user feedback
      ShowToastDialog.showLoader("Creating your order...".tr);

      // Make API call
      final response = await http
          .post(
            Uri.parse('${AppConst.baseUrl}mobile/orders'),
            headers: await getHeaders(),
            body: json.encode(orderPayload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Order creation API call timed out after 30 seconds',
              );
            },
          );

      print('🌐 [ORDER_CREATION] API response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '❌ [ORDER_CREATION] API returned error status: ${response.statusCode}',
        );
        print('❌ [ORDER_CREATION] Response body: ${response.body}');
        throw Exception(
          'API returned status code: ${response.statusCode}. Response: ${response.body}',
        );
      }

      final responseData = json.decode(response.body);

      if (responseData['success'] != true) {
        print(
          '❌ [ORDER_CREATION] API returned error: ${responseData['message']}',
        );
        throw Exception('API returned error: ${responseData['message']}');
      }

      if (responseData['data'] == null ||
          responseData['data']['order_id'] == null) {
        print('❌ [ORDER_CREATION] API response missing order_id');
        throw Exception('API response missing order_id');
      }

      orderModel.id = responseData['data']['order_id'];
      print(
        '✅ [ORDER_CREATION] Order created successfully with ID: ${orderModel.id}',
      );

      // Post-order tasks
      final additionalTasks = <Future>[];

      if (selectedCouponModel.id != null &&
          selectedCouponModel.id!.isNotEmpty) {
        additionalTasks.add(markCouponAsUsed(selectedCouponModel.id!));
      }

      String adminFee = "0";
      if (surgePercent > 0) {
        adminFee = await getAdminSurgeFee();
      }

      additionalTasks.add(
        _createOrderBilling(
          responseData['data']['order_id'],
          totalAmount.toString(),
          surgePercent.toInt(),
          adminFee,
        ),
      );

      if (vendorModel.id != null && vendorModel.author != null) {
        additionalTasks.add(
          AddressListProvider.getUserProfile(
            vendorModel.author.toString(),
          ).then((value) {
            if (value != null) {
              if (scheduleDateTime.isAfter(DateTime.now())) {
                SendNotification.sendFcmMessage(
                  Constant.scheduleOrder,
                  value.fcmToken ?? '',
                  {},
                );
              } else {
                SendNotification.sendFcmMessage(
                  Constant.newOrderPlaced,
                  value.fcmToken ?? '',
                  {},
                );
              }
            }
          }),
        );
      }

      additionalTasks.add(Constant.sendOrderEmail(orderModel: orderModel));

      await Future.wait(additionalTasks);

      // Clear order creation flags
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      // Clear payment state
      isPaymentInProgress = false;
      isPaymentCompleted = false;
      _lastPaymentId = null;
      _lastPaymentTime = null;
      selectedCouponModel = CouponModel();
      couponCodeController.text = '';
      couponAmount = 0.0;

      await calculatePrice();
      await _clearPersistentPaymentState();

      ShowToastDialog.closeLoader();
      endOrderProcessing();

      // Navigate to order success screen
      orderPlacingProvider.initFunction(orderModels: orderModel);
      Get.off(() => OrderPlacingScreen());

      print('✅ [ORDER_CREATION] Order placement complete!');
    } catch (e, stackTrace) {
      print("❌ [ORDER_CREATION] Error: $e");
      print("❌ [ORDER_CREATION] Stack trace: $stackTrace");

      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      ShowToastDialog.closeLoader();
      endOrderProcessing();

      if (isPaymentCompleted && _lastPaymentId != null) {
        _processedPaymentIds.remove(_lastPaymentId!);
        ShowToastDialog.showToast(
          "Order placement failed. Your payment is safe. Please try again.".tr,
        );
      } else {
        _resetPaymentState();
        ShowToastDialog.showToast(
          "Failed to place order. Please try again.".tr,
        );
      }
    } finally {
      // 🔑 CRITICAL: Always unlock global at the end
      _unlockGlobal();
    }
  }

  bool hasPromotionalItems() {
    return HomeProvider.cartItem.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );
  }

  // ============ OTHER METHODS ============

  void changeLocationFunctionInCart({required BuildContext context}) {
    Get.to(const AddressListScreen())!.then((value) async {
      if (value != null) {
        ShippingAddress addressModel = value;

        try {
          if (addressModel.zoneId != null && addressModel.zoneId!.isNotEmpty) {
            print('[ADDRESS_CHANGE] ✅ Using existing zoneId');
          } else if (Constant.selectedLocation.zoneId != null &&
              Constant.selectedLocation.zoneId!.isNotEmpty) {
            addressModel.zoneId = Constant.selectedLocation.zoneId;
          } else if (Constant.selectedZone != null) {
            addressModel.zoneId = Constant.selectedZone!.id;
          } else {
            final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
              addressModel.location!.latitude!,
              addressModel.location!.longitude!,
              context,
            );
            if (zoneId.isNotEmpty) {
              addressModel.zoneId = zoneId;
            }
          }
        } catch (e) {
          print('[ADDRESS_CHANGE] ❌ Error detecting zone: $e');
        }

        selectedAddress = addressModel;
        _addressInitialized = true;
        await _loadFreshVendorForCart();
        notifyListeners();
        await calculatePrice();
      }
    });
  }

  //   /// Get cached product by ID - returns null if not cached
  ProductModel? getCachedProduct(String? productId) {
    if (productId == null ||
        productId.isEmpty ||
        productId.toLowerCase() == 'null') {
      return null;
    }
    return _productCache[productId];
  }

  // Add this method to CartControllerProvider class
  // Replace the validateAndUpdateCartPrices() method with this improved version:
  Future<Map<String, PriceUpdateResult>> validateAndUpdateCartPrices() async {
    final Map<String, PriceUpdateResult> results = {};

    print(
      '[PRICE_SYNC] 🔍 Starting IMMEDIATE price validation for ${HomeProvider.cartItem.length} items',
    );

    for (var cartItem in HomeProvider.cartItem) {
      try {
        if (cartItem.id == null || cartItem.id!.isEmpty) {
          continue;
        }

        final isPromotionalItem =
            cartItem.promoId != null && cartItem.promoId!.isNotEmpty;

        // 🔑 CRITICAL: Skip promotional items - their prices are fixed
        if (isPromotionalItem) {
          print('[PRICE_SYNC] 🎯 Skipping promotional item: ${cartItem.name}');
          continue;
        }

        final isMart = _isMartItem(cartItem);
        final itemType = isMart ? 'MART' : 'FOOD';

        // Get current stored price from cart item
        double storedPrice;
        try {
          // Try to parse the price - handle both string and double
          if (cartItem.price is String) {
            storedPrice = double.parse(cartItem.price.toString());
          } else if (cartItem.price is double) {
            storedPrice = cartItem.price as double;
          } else if (cartItem.price is int) {
            storedPrice = (cartItem.price as int).toDouble();
          } else {
            storedPrice = 0.0;
          }
        } catch (e) {
          storedPrice = 0.0;
        }

        print(
          '[PRICE_SYNC] [$itemType] Checking ${cartItem.name}: Stored price in cart = ₹$storedPrice',
        );

        // Fetch current price from database
        dynamic currentProduct;
        double currentPrice = 0.0;

        try {
          if (isMart) {
            // For mart items
            final martService = Get.find<MartFirestoreService>();
            currentProduct = await martService.getItemById(cartItem.id!);
            if (currentProduct != null && currentProduct is MartItemModel) {
              currentPrice = currentProduct.finalPrice;
            }
          } else {
            // For restaurant items
            currentProduct = await FireStoreUtils.getProductById(cartItem.id!);
            if (currentProduct != null && currentProduct is ProductModel) {
              // Calculate price with commission
              if (vendorModel.id != null) {
                currentPrice = double.parse(
                  Constant.productCommissionPrice(
                    vendorModel,
                    currentProduct.price ?? "0",
                  ),
                );
              } else {
                currentPrice =
                    double.tryParse(currentProduct.price ?? "0") ?? 0.0;
              }
            }
          }

          print(
            '[PRICE_SYNC] [$itemType] Current price from DB = ₹$currentPrice',
          );

          // 🔑 CRITICAL: Compare prices with better tolerance
          final priceDifference = (currentPrice - storedPrice).abs();
          final tolerance = 0.01; // 1 paisa tolerance

          if (priceDifference > tolerance) {
            // Price has changed significantly
            print(
              '[PRICE_SYNC] ✅✅✅ PRICE CHANGE DETECTED for ${cartItem.name}: ₹$storedPrice → ₹$currentPrice (difference: ₹$priceDifference)',
            );

            results[cartItem.id!] = PriceUpdateResult(
              productId: cartItem.id!,
              status: PriceStatus.priceChanged,
              oldPrice: storedPrice.toStringAsFixed(2),
              newPrice: currentPrice.toStringAsFixed(2),
              productName: cartItem.name,
            );

            // 🔑 Update the cart item immediately
            cartItem.price = currentPrice.toStringAsFixed(2);
            // Clear any discount price since the base price changed
            cartItem.discountPrice = "0";

            // Save to database immediately
            await DatabaseHelper.instance.updateCartProduct(cartItem);

            // Force UI update
            notifyListeners();
          } else {
            print(
              '[PRICE_SYNC] ℹ️ No significant price change for ${cartItem.name} (difference: ₹$priceDifference)',
            );

            results[cartItem.id!] = PriceUpdateResult(
              productId: cartItem.id!,
              status: PriceStatus.noChange,
              oldPrice: storedPrice.toStringAsFixed(2),
              newPrice: currentPrice.toStringAsFixed(2),
            );
          }
        } catch (e) {
          print(
            '[PRICE_SYNC] ❌ Error fetching current price for ${cartItem.id}: $e',
          );
          results[cartItem.id!] = PriceUpdateResult(
            productId: cartItem.id!,
            status: PriceStatus.error,
            oldPrice: storedPrice.toStringAsFixed(2),
            error: e.toString(),
          );
        }
      } catch (e) {
        print('[PRICE_SYNC] ❌ General error for item ${cartItem.id}: $e');
      }
    }

    return results;
  }

  Future<void> markCouponAsUsed(String couponId) async {
    try {
      await SqlStorageConst.getFirebaseId(); // Get user ID for authentication context
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/coupons/$couponId/used'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Coupon marked as used: $couponId');

        // Update local state to mark coupon as used
        for (var coupon in couponList) {
          if (coupon.id == couponId) {
            coupon.isEnabled = false;
          }
        }
        for (var coupon in allCouponList) {
          if (coupon.id == couponId) {
            coupon.isEnabled = false;
          }
        }
        notifyListeners();
      } else {
        print('❌ Failed to mark coupon as used: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking coupon as used: $e');
    }
  }

  double _getStoredDisplayPrice(CartProductModel cartItem) {
    try {
      final storedDiscountPrice =
          double.tryParse(cartItem.discountPrice ?? "0") ?? 0.0;
      final storedRegularPrice = double.tryParse(cartItem.price ?? "0") ?? 0.0;

      // Use discount price if available and lower than regular price
      if (storedDiscountPrice > 0 && storedDiscountPrice < storedRegularPrice) {
        return storedDiscountPrice;
      }
      return storedRegularPrice;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _batchUpdateTimer?.cancel();
    _priceSyncTimer?.cancel();
    _calculatePriceDebounceTimer?.cancel();
    _syncPricesDebounceTimer?.cancel();
    _cleanupResources();
    super.dispose();
  }
}

enum PaymentGateway { razorpay, cod, wallet }

// Helper for unawaited futures
void unawaited(Future<void> future) {
  future.then((_) {}).catchError((e) {});
}
