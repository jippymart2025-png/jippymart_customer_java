import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/oder_placing_screens.dart';
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/provider/order_placing_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
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
import 'package:jippymart_customer/payment/createRazorPayOrderModel.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../models/mart_item_model.dart';
import '../../../services/mart_firestore_service.dart';

class CartControllerProvider extends ChangeNotifier {
  late OrderPlacingProvider orderPlacingProvider;

  Future<void> processPayment(
    CartControllerProvider controller,
    BuildContext context,
  ) async {
    final canProceed = await controller.validateAndPlaceOrderBulletproof(
      context,
    );
    if (!canProceed) {
      controller.endOrderProcessing();
      return;
    }
    if ((controller.couponAmount >= 1) &&
        (controller.couponAmount > controller.totalAmount)) {
      ShowToastDialog.showToast(
        "The total price must be greater than or equal to the coupon discount value for the code to apply. Please review your cart total."
            .tr,
      );
      controller.endOrderProcessing();
      return;
    }
    if ((controller.specialDiscountAmount >= 1) &&
        (controller.specialDiscountAmount > controller.totalAmount)) {
      ShowToastDialog.showToast(
        "The total price must be greater than or equal to the special discount value for the code to apply. Please review your cart total."
            .tr,
      );
      controller.endOrderProcessing();
      return;
    }

    // 🔑 CRITICAL: Validate payment method is selected
    if (controller.selectedPaymentMethod.isEmpty) {
      ShowToastDialog.showToast("Please select payment method".tr);
      controller.endOrderProcessing();
      return;
    }

    if (controller.selectedPaymentMethod == PaymentGateway.cod.name) {
      // 🔑 CRITICAL: For COD, verify it's allowed
      if (controller.subTotal > 599) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for orders above ₹599. Please select online payment."
              .tr,
        );
        controller.endOrderProcessing();
        return;
      }
      if (controller.hasPromotionalItems()) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for promotional items. Please select online payment."
              .tr,
        );
        controller.endOrderProcessing();
        return;
      }
      controller.placeOrder(context);
      print(" controller.placeOrder(context); ");
    } else if (controller.selectedPaymentMethod ==
        PaymentGateway.razorpay.name) {
      // 🔑 CRITICAL: Ensure Razorpay is properly configured
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

      // 🔑 CRITICAL: Reset payment state before starting new payment
      controller.isPaymentInProgress = false;
      controller.isPaymentCompleted = false;
      controller._lastPaymentId = null;

      print(
        '🔑 [RAZORPAY] Starting payment flow for amount: ${controller.totalAmount}',
      );

      // 🔑 OPTIMIZATION: Show loading immediately and ensure Razorpay is initialized
      ShowToastDialog.showLoader("Opening payment gateway...".tr);

      // 🔑 OPTIMIZATION: Ensure Razorpay is initialized (should already be from pre-init, but double-check)
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

      try {
        // 🔑 OPTIMIZATION: Create order and open checkout in parallel where possible
        // Show payment page as soon as order is created
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
        print(
          '🔑 [RAZORPAY] Order amount (paise): ${orderResult.amount}, Order ID: ${orderResult.id}',
        );

        // 🔑 CRITICAL: Convert amount from paise to rupees for openCheckout
        // orderResult.amount is in paise, but openCheckout expects rupees and converts to paise internally
        final amountInRupees = orderResult.amount / 100.0;
        print('🔑 [RAZORPAY] Amount in rupees: $amountInRupees');

        // 🔑 OPTIMIZATION: Close loader before opening checkout for instant UI
        ShowToastDialog.closeLoader();

        // 🔑 CRITICAL: Check if checkout opens successfully
        print('🔑 [RAZORPAY] Attempting to open checkout...');
        final checkoutOpened = await controller.openCheckout(
          amount: amountInRupees,
          orderId: orderResult.id,
        );

        if (!checkoutOpened) {
          print('❌ [RAZORPAY] Checkout failed to open');
          // 🔑 CRITICAL: If checkout failed to open, prevent order placement
          ShowToastDialog.showToast(
            "Failed to open payment gateway. Please try again.".tr,
          );
          controller.endOrderProcessing();
          return;
        }

        print('✅ [RAZORPAY] Checkout opened successfully');
      } catch (error, stackTrace) {
        // 🔑 CRITICAL: Handle any errors during RazorPay order creation
        print('❌ [RAZORPAY] Exception in payment flow: $error');
        print('❌ [RAZORPAY] Stack trace: $stackTrace');
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Failed to create payment order. Please try again.".tr,
        );
        controller.endOrderProcessing();
      }
    } else {
      ShowToastDialog.showToast("Please select payment method".tr);
      // 🔑 CRITICAL: Reset processing flag when no payment method is selected
      controller.endOrderProcessing();
    }
    notifyListeners();
  }

  void changeLocationFunctionInCart({required BuildContext context}) {
    Get.to(const AddressListScreen())!.then((value) async {
      if (value != null) {
        ShippingAddress addressModel = value;
        print(" changeLocationFunctionInCart  13 ${addressModel.locality}");
        print(
          " changeLocationFunctionInCart  12 ${addressModel.location?.latitude}   ${addressModel.location?.latitude}",
        );
        print(" changeLocationFunctionInCart  1 ${addressModel.latitude}");
        if (addressModel.location?.latitude != null &&
            addressModel.location?.longitude != null) {
          try {
            if (addressModel.zoneId != null &&
                addressModel.zoneId!.isNotEmpty) {
              print(
                '✅ [CART_ADDRESS_CHANGE] Using zoneId from addressModel: ${addressModel.zoneId}',
              );
            } else if (Constant.selectedLocation.zoneId != null &&
                Constant.selectedLocation.zoneId!.isNotEmpty) {
              addressModel.zoneId = Constant.selectedLocation.zoneId;
              notifyListeners();
              print(
                '✅ [CART_ADDRESS_CHANGE] Using zoneId from Constant.selectedLocation: ${addressModel.zoneId}',
              );
            } else if (Constant.selectedZone != null) {
              addressModel.zoneId = Constant.selectedZone!.id;
              print(
                '✅ [CART_ADDRESS_CHANGE] Using zoneId from Constant.selectedZone: ${addressModel.zoneId}',
              );
              notifyListeners();
            } else {
              final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
                addressModel.location!.latitude!,
                addressModel.location!.longitude!,
                context,
              );
              if (zoneId.isNotEmpty) {
                addressModel.zoneId = zoneId;
                print(
                  '✅ [CART_ADDRESS_CHANGE] Detected zone from coordinates: $zoneId',
                );
              } else {
                print(
                  '⚠️ [CART_ADDRESS_CHANGE] No zone detected for coordinates - leaving zoneId as null',
                );
              }
            }
          } catch (e) {
            print('❌ [CART_ADDRESS_CHANGE] Error detecting zone: $e');
            // Continue without zone ID if detection fails
          }
        } else {
          print(
            '⚠️ [CART_ADDRESS_CHANGE] No coordinates available for zone detection',
          );
        }
        selectedAddress = addressModel;
        _addressInitialized =
            true; // 🔑 Mark as initialized when user explicitly changes address
        await _loadFreshVendorForCart();
        notifyListeners();
        await calculatePrice();
      }
    });
  }

  // ProductModel? productModelImageDetails;
  //
  // void cartProductDetailsImageProductListFunction() {
  //   CartProductModel cartProductModel = cartItem[index];
  //   ProductModel? productModel;
  //   FireStoreUtils.getProductById(cartProductModel.id!.split('~').first).then((
  //     value,
  //   ) {
  //     productModelImageDetails = value;
  //     notifyListeners();
  //   });
  // }
  Future<bool> showPaymentMethodDialog(BuildContext context) async {
    // Validate before showing dialog - if validation fails, don't show dialog
    final canProceed = await validateAndPlaceOrderBulletproof(context);
    if (!canProceed) {
      // Validation failed - ensure processing flag is reset (in case it was stuck from previous attempt)
      endOrderProcessing();
      return false;
    }
    final String initialSelection = selectedPaymentMethod;
    final result = await Get.dialog<bool>(
      WillPopScope(
        onWillPop: () async {
          // User cancelled via back button - restore initial selection
          selectedPaymentMethod = initialSelection;
          notifyListeners();
          Get.back(result: false); // Return false to indicate cancellation
          return false; // Prevent default back behavior since we handled it
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
                          SizedBox(
                            width: 150,
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
                        ],
                      ),
                      value: PaymentGateway.cod.name,
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPaymentMethod = value;
                          });
                          notifyListeners(); // 🔑 CRITICAL: Update provider state
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
                          notifyListeners(); // 🔑 CRITICAL: Update provider state
                        }
                      },
                      activeColor: Colors.orange,
                    ),
                  ),

                  SizedBox(height: 10),
                  // Validation messages
                  if (subTotal > 599 &&
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
                              "COD not available for orders above ₹599",
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
                    // User cancelled - clear payment method
                    selectedPaymentMethod = "";
                    notifyListeners();
                    Get.back(
                      result: false,
                    ); // Return false to indicate cancellation
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
                    // Validate selection
                    if (selectedPaymentMethod == PaymentGateway.cod.name) {
                      if (subTotal > 599) {
                        ShowToastDialog.showToast(
                          "COD not available for orders above ₹599. Please select online payment."
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

                    Get.back(
                      result: true,
                    ); // Return true to indicate confirmation
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

    // After dialog closes, ensure UI reflects the current selection
    notifyListeners();

    // Return true if payment was confirmed, false if cancelled
    return result == true && selectedPaymentMethod.isNotEmpty;
  }

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    print(" getWeather ");
    const apiKey = "7885eed00855633516f769cf3646aace"; // 🔑 Add your key
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load weather");
    }
  }

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
          print("API response data: ${responseData['data']}");
          return responseData['data'] ?? {};
        } else {
          print(
            '[CART_PROVIDER] Surge rules API returned unsuccessful response',
          );
          return {}; // Return empty map instead of throwing
        }
      } else if (response.statusCode == 429) {
        print('[CART_PROVIDER] Rate limited when fetching surge rules');
        return {}; // Return empty map on rate limit
      } else {
        print(
          '[CART_PROVIDER] Failed to fetch surge rules: ${response.statusCode}',
        );
        return {}; // Return empty map instead of throwing
      }
    } on TimeoutException {
      print('[CART_PROVIDER] Timeout fetching surge rules');
      return {}; // Return empty map on timeout
    } catch (e) {
      print('[CART_PROVIDER] Error fetching surge rules: $e');
      return {}; // Return empty map instead of throwing
    }
  }

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

  double calculateSurgeFee(
    Map<String, dynamic> weather,
    Map<String, dynamic> rules,
  ) {
    double surge = 0;
    String condition = weather['weather'][0]['main'].toLowerCase();
    if (condition.contains("rain")) surge += rules["rain"];
    double temp = weather['main']['temp'];
    if (temp > 45) surge += rules["summer"]; // hot weather
    if (temp < 10) surge += rules["bad_weather"]; // cold/winter
    return surge; // percentage
  }

  final CartProvider cartProvider = CartProvider();
  TextEditingController reMarkController = TextEditingController();
  Map<String, dynamic>? _martDeliverySettings;
  TextEditingController couponCodeController = TextEditingController();
  TextEditingController tipsController = TextEditingController();

  // Add debouncing mechanism to prevent duplicate orders
  bool isProcessingOrder = false;
  DateTime? lastOrderAttempt;
  static const Duration orderDebounceTime = Duration(seconds: 3);

  // Add order idempotency tracking
  bool _orderInProgress = false;

  // 🔑 CRITICAL: Debouncing for price calculation to prevent continuous updates
  bool _isCalculatingPrice = false;
  DateTime? _lastPriceCalculationTime;
  static const Duration _priceCalculationDebounce = Duration(milliseconds: 300);

  // 🔑 RAZORPAY PAYMENT STATE MANAGEMENT
  bool isPaymentInProgress = false;
  bool isPaymentCompleted = false;
  String? _lastPaymentId;
  DateTime? _lastPaymentTime;
  static const Duration paymentTimeout = Duration(minutes: 5);

  // 🔑 CRITICAL: Prevent duplicate order creation
  bool _isOrderBeingCreated = false;
  Set<String> _processedPaymentIds = {}; // Track processed payment IDs
  static const int _maxProcessedPaymentIds =
      100; // Limit to prevent memory issues

  // 🔑 CRITICAL: Static lock to prevent concurrent order creation across all instances
  static bool _isOrderCreationInProgress = false;
  static String?
  _currentOrderPaymentId; // Track payment ID for current order creation
  static DateTime? _lastOrderCreationTime;
  static const Duration _orderCreationCooldown = Duration(
    seconds: 10,
  ); // Cooldown period

  // 🔑 PERSISTENT PAYMENT STATE STORAGE (SURVIVES APP KILLS)
  static const String _paymentStateKey = 'razorpay_payment_state';
  static const String _paymentIdKey = 'razorpay_payment_id';
  static const String _paymentSignatureKey = 'razorpay_payment_signature';
  static const String _paymentTimeKey = 'razorpay_payment_time';
  static const String _paymentMethodKey = 'razorpay_payment_method';
  static const String _paymentAmountKey = 'razorpay_payment_amount';
  static const String _paymentOrderIdKey = 'razorpay_order_id';

  // Add profile validation state
  bool isProfileValid = false;
  bool isProfileValidating = false;

  // 🔑 CRITICAL: Track if address has been initialized to prevent repeated changes
  bool _addressInitialized = false;

  // Add caching for better performance
  VendorModel? _cachedVendorModel;
  DeliveryCharge? _cachedDeliveryCharge;
  List<CouponModel>? _cachedCouponList;
  DateTime? _lastCacheTime;
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Flag to prevent multiple simultaneous coupon loads
  bool _isLoadingCoupons = false;

  // Context detection for coupon filtering
  String _currentContext = "restaurant"; // Default to restaurant

  // **ULTRA-FAST CALCULATION CACHE FOR INSTANT CART UPDATES**
  final Map<String, Map<String, dynamic>> _promotionalCalculationCache = {};
  final Map<String, double> _cachedFreeDeliveryKm = {};
  final Map<String, double> _cachedExtraKmCharge = {};
  List<TaxModel>? _cachedTaxList;
  bool _calculationCacheLoaded = false;

  // **PRODUCT CACHE FOR CART - LOAD ONCE, USE MANY TIMES**
  final Map<String, ProductModel?> _productCache = {};
  bool _isLoadingProducts = false;
  bool _productsLoaded = false;

  // Getters for product cache state
  bool get isLoadingProducts => _isLoadingProducts;

  bool get productsLoaded => _productsLoaded;

  // Getter for coupon loading state
  bool get isLoadingCoupons => _isLoadingCoupons;

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

  // Add UI state management
  bool isCartReady = false;
  bool isPaymentReady = false;
  bool isAddressValid = false;
  CouponModel selectedCouponModel = CouponModel();

  double originalDeliveryFee = 0.0;

  /// Public method to initialize address (for external calls)
  Future<void> initializeAddress(BuildContext context) async {
    await _initializeAddressWithPriority(context);
  }

  Future<void> initialLiseSurgeValue(double lat, double lon) async {
    try {
      Map<String, dynamic> weather = await getWeather(lat, lon);
      Map<String, dynamic> rules = await getSurgeRules();
      surgePercent = calculateSurgeFee(weather, rules);
      notifyListeners();
    } catch (e) {
      print('[CART_PROVIDER] Error initializing surge value: $e');
      // Set default surge percent on error
      surgePercent = 0;
      notifyListeners();
    }
  }

  Future<void> _initializeAddressWithPriority(BuildContext context) async {
    try {
      // 🔑 CRITICAL: If address is already initialized and valid, don't change it
      if (_addressInitialized &&
          selectedAddress != null &&
          selectedAddress!.location?.latitude != null &&
          selectedAddress!.location?.longitude != null) {
        print(
          '🏠 [ADDRESS_PRIORITY] ✅ Address already initialized, skipping auto-change',
        );
        return;
      }

      // PRIORITY 1: Check for saved addresses in user profile (DEFAULT LOCATION)
      if (Constant.userModel != null &&
          Constant.userModel!.shippingAddress != null &&
          Constant.userModel!.shippingAddress!.isNotEmpty) {
        final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => Constant.userModel!.shippingAddress!.first,
        );
        selectedAddress = defaultAddress;
        _addressInitialized = true; // Mark as initialized
        await initialLiseSurgeValue(
          defaultAddress.location?.latitude ?? 0.0,
          defaultAddress.location?.longitude ?? 0.0,
        );
        // 🔑 CRITICAL: Load vendor and calculate price after address is set
        // Only load vendor if cart has items
        if (HomeProvider.cartItem.isNotEmpty) {
          await _loadFreshVendorForCart();
          // Ensure vendor is loaded before calculating price
          if (vendorModel.id != null) {
            await calculatePrice();
          }
        }
        notifyListeners();
        print('🏠 [ADDRESS_PRIORITY] ✅ Using default saved address');
        return;
      }

      // PRIORITY 2: Only use current location if no default address exists
      final homeScreenAddress = await _getCurrentLocationAddress(context);
      if (homeScreenAddress != null) {
        selectedAddress = homeScreenAddress;
        _addressInitialized = true; // Mark as initialized
        await initialLiseSurgeValue(
          homeScreenAddress.location?.latitude ?? 0.0,
          homeScreenAddress.location?.longitude ?? 0.0,
        );
        // 🔑 CRITICAL: Load vendor and calculate price after address is set
        // Only load vendor if cart has items
        if (HomeProvider.cartItem.isNotEmpty) {
          await _loadFreshVendorForCart();
          // Ensure vendor is loaded before calculating price
          if (vendorModel.id != null) {
            await calculatePrice();
          }
        }
        notifyListeners();
        print(
          '🏠 [ADDRESS_PRIORITY] ✅ Using current location (no default address)',
        );
        return;
      }
      selectedAddress = null;
      _addressInitialized = false;
      notifyListeners();
      _showAddressRequiredAlert();
    } catch (e) {
      print('🏠 [ADDRESS_PRIORITY] ❌ ERROR in address initialization: $e');
      selectedAddress = null;
      _addressInitialized = false;
      _showAddressRequiredAlert();
    }
    notifyListeners();
  }

  /// Get home screen address (Constant.selectedLocation) as address
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
              locality == 'Current Location' ||
              address.contains('Current Location') ||
              locality.contains('Current Location')) {
            return null;
          }
          // Try multiple sources for zone ID
          String? detectedZoneId;

          // PRIORITY 1: Use zoneId from Constant.selectedLocation if available
          if (Constant.selectedLocation.zoneId != null &&
              Constant.selectedLocation.zoneId!.isNotEmpty) {
            detectedZoneId = Constant.selectedLocation.zoneId;
            print(
              '[HOME_SCREEN_ADDRESS] ✅ Using zoneId from Constant.selectedLocation: $detectedZoneId',
            );
          }
          // PRIORITY 2: Use zoneId from Constant.selectedZone if available
          else if (Constant.selectedZone?.id != null &&
              Constant.selectedZone!.id!.isNotEmpty) {
            detectedZoneId = Constant.selectedZone!.id;
            print(
              '[HOME_SCREEN_ADDRESS] ✅ Using zoneId from Constant.selectedZone: $detectedZoneId',
            );
          }
          // PRIORITY 3: Try to detect zone ID from coordinates
          else {
            detectedZoneId = await _detectZoneIdForCoordinates(
              lat,
              lng,
              context,
            );
            if (detectedZoneId != null) {
              print(
                '[HOME_SCREEN_ADDRESS] ✅ Detected zoneId from coordinates: $detectedZoneId',
              );
            } else {
              print(
                '[HOME_SCREEN_ADDRESS] ⚠️ Could not detect zoneId from coordinates',
              );
            }
          }

          notifyListeners();
          return ShippingAddress(
            id: 'home_screen_address_${DateTime.now().millisecondsSinceEpoch}',
            addressAs:
                Constant.selectedLocation.addressAs ?? 'Home Screen Address',
            address: address,
            locality: locality,
            location: UserLocation(latitude: lat, longitude: lng),
            isDefault: false,
            zoneId: detectedZoneId, // 🔑 Add detected zone ID
          );
        }
      }

      return null;
    } catch (e) {
      print('📍 [HOME_SCREEN_ADDRESS] ❌ Error getting home screen address: $e');
      return null;
    }
  }

  /// Sync selectedAddress with Constant.selectedLocation if needed
  /// This ensures cart address stays in sync when location changes on home screen
  /// 🔑 CRITICAL: Only syncs if address is not initialized or user explicitly changes location
  Future<void> syncAddressWithHomeLocation(BuildContext context) async {
    try {
      // 🔑 CRITICAL: Don't auto-sync if address is already initialized with a saved/default address
      // Only sync if address is null or invalid, or if user explicitly changed location
      if (_addressInitialized &&
          selectedAddress != null &&
          selectedAddress!.id != null &&
          !selectedAddress!.id!.startsWith('home_screen_address_')) {
        // Address is a saved address (not temporary), don't auto-change it
        print(
          '[CART_SYNC] ⚠️ Address is a saved address, skipping auto-sync to prevent repeated changes',
        );
        // Only sync zoneId if missing, don't change the address itself
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
              // Ensure zoneId is set (it should be set by _getCurrentLocationAddress, but verify)
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
              // Recalculate prices with new address - await to ensure calculation completes
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
    }
  }

  /// Show alert when address is required
  void _showAddressRequiredAlert() {
    Get.dialog(
      AlertDialog(
        title: Text('Address Required'.tr),
        content: Text(
          'Please add a delivery address to continue with your order.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const AddressListScreen());
            },
            child: Text('Add Address'.tr),
          ),
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        ],
      ),
    );
  }

  ///
  Future<String?> _detectZoneIdForCoordinates(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    try {
      final zoneModel = await HomeProvider.getCurrentZone(latitude, longitude);
      notifyListeners();
      if (zoneModel == null || zoneModel.zone == null) {
        print('[DEBUG] No zone available');
        return null;
      }
      final zone = zoneModel.zone!;
      print('[DEBUG] Checking zone: ${zone.name} (${zone.id})');
      if (zone.area != null && zone.area!.isNotEmpty) {
        if (Constant.isPointInPolygon(
          LatLng(latitude, longitude),
          zone.area!.cast<GeoPoint>(),
        )) {
          print('[DEBUG] Zone detected: ${zone.name} (${zone.id})');
          return zone.id;
        }
      }
      notifyListeners();
      print('[DEBUG] Coordinates not within the service zone');
      return null;
    } catch (e) {
      print('[DEBUG] Error detecting zone: $e');
      return null;
    }
  }

  void initFunction(BuildContext context) {
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
        if (subTotal > 599 &&
            selectedPaymentMethod == PaymentGateway.cod.name) {
          selectedPaymentMethod = PaymentGateway.razorpay.name;
        }
      });
    });
    orderPlacingProvider = Provider.of<OrderPlacingProvider>(
      context,
      listen: false,
    );
    notifyListeners();
  }

  /// 🔑 BULLETPROOF PROFILE VALIDATION - NEVER FAILS
  Future<void> validateUserProfileBulletproof() async {
    isProfileValidating = true;
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
          } else {}
        } catch (e) {
          if (attempts == 2 && Constant.userModel != null) {
            user = Constant.userModel;

            break;
          }

          // Strategy 3: Wait and retry for network issues
          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 2));
            print(
              '🔒 [BULLETPROOF_PROFILE] Wait completed, proceeding to next attempt',
            );
          }
        }
      }
      notifyListeners();

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
      Constant.userModel = user; // Update global cache
      notifyListeners();
      if (!isProfileValid) {
        final missingFields = <String>[];
        if (!hasFirstName) missingFields.add('First Name (min 2 chars)');
        if (!hasPhoneNumber) missingFields.add('Phone Number (min 10 digits)');
        if (!hasEmail) missingFields.add('Valid Email Address');
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

  Future<void> validateUserProfile() async {
    await validateUserProfileBulletproof();
  }

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
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  // Method to check if cache is valid
  bool _isCacheValid() {
    return _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < cacheExpiry;
  }

  // Method to update cache timestamp
  void _updateCacheTime() {
    _lastCacheTime = DateTime.now();
  }

  // **ULTRA-FAST METHOD TO PRELOAD ALL CALCULATION DATA FOR INSTANT CART UPDATES**
  Future<void> _loadCalculationCache() async {
    if (_calculationCacheLoaded) return;
    try {
      // Load tax list once and cache it
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
    } catch (e) {}
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
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error caching promotional data for $cacheKey: $e');
    }
    notifyListeners();
  }

  double _getCachedFreeDeliveryKm(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _cachedFreeDeliveryKm[cacheKey] ?? 3.0;
  }

  // **INSTANT METHOD TO GET CACHED EXTRA KM CHARGE (ZERO ASYNC)**
  double _getCachedExtraKmCharge(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';
    return _cachedExtraKmCharge[cacheKey] ?? 7.0;
  }

  // **REMOVED: getMartDeliveryFreeDistance() - NO FREE DELIVERY for mart items**

  // Method to check if cart has promotional items
  bool hasPromotionalItems() {
    return HomeProvider.cartItem.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );
  }

  // Method to get promotional item limit
  // Future<int?> getPromotionalItemLimit(String productId, String restaurantId) async {
  /// **ULTRA-FAST PROMOTIONAL ITEM LIMIT (INSTANT - ZERO ASYNC)**
  int? getPromotionalItemLimit(String productId, String restaurantId) {
    try {
      final limit = PromotionalCacheService.getPromotionalItemLimit(
        productId,
        restaurantId,
      );
      if (limit != null) {
      } else {}
      notifyListeners();
      return limit;
    } catch (e) {
      return null;
    }
  }

  /// **ULTRA-FAST PROMOTIONAL ITEM QUANTITY CHECK (INSTANT - ZERO ASYNC)**
  bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) {
      return true; // Allow decrement
    }
    final isAllowed = PromotionalCacheService.isPromotionalItemQuantityAllowed(
      productId,
      restaurantId,
      currentQuantity,
    );
    notifyListeners();
    return isAllowed;
  }

  bool canProcessOrder() {
    if (isProcessingOrder) {
      return false;
    }

    if (lastOrderAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastOrderAttempt!);
      if (timeSinceLastAttempt < orderDebounceTime) {
        return false;
      }
    }
    notifyListeners();
    return true;
  }

  // Method to end order processing
  void endOrderProcessing() {
    _endOrderProcessing();
  }

  // Method to check and update payment method based on order total, promotional items, and mart items
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
    notifyListeners();
  }

  /// Check if cart is ready for payment
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
    notifyListeners();
    return isReady;
  }

  /// Update cart readiness state
  void updateCartReadiness() {
    isCartReady = HomeProvider.cartItem.isNotEmpty && subTotal > 0;
    isPaymentReady = isCartReadyForPayment();
    isAddressValid = selectedAddress?.id != null;
    notifyListeners();
  }

  /// Force refresh cart data and recalculate prices
  Future<void> forceRefreshCart() async {
    await cartProvider.refreshCart();
    // Refresh vendor details so delivery distance can be recalculated
    await _loadFreshVendorForCart();
    // Preload all products for cart display (load once, use many times)
    await preloadCartProducts(forceRefresh: true);
    // Reset delivery tips when cart refreshes (for new orders)
    deliveryTips = 0.0;
    await calculatePrice();
    checkAndUpdatePaymentMethod();
    updateCartReadiness();
    notifyListeners();
  }

  /// Preload all products in cart - called once when cart screen opens
  /// If forceRefresh is true, clears cache and reloads all products
  Future<void> preloadCartProducts({bool forceRefresh = false}) async {
    if (_isLoadingProducts && !forceRefresh) {
      return; // Already loading
    }

    if (forceRefresh) {
      _productCache.clear();
      _productsLoaded = false;
    }

    _isLoadingProducts = true;

    try {
      // Get all unique product IDs from cart
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

      // Only load products that aren't already cached (unless force refresh)
      final Set<String> productsToLoad = forceRefresh
          ? productIds
          : productIds.where((id) => !_productCache.containsKey(id)).toSet();

      if (productsToLoad.isEmpty) {
        _productsLoaded = true;
        notifyListeners();
        return;
      }

      // Load all products in parallel
      final List<Future<void>> loadFutures = productsToLoad.map((
        productId,
      ) async {
        try {
          // Check if it's a mart item by finding the cart item
          final cartItem = HomeProvider.cartItem.firstWhere((item) {
            if (item.id == null || item.id!.isEmpty) return false;
            final parts = item.id!.split('~');
            return parts.isNotEmpty && parts.first == productId;
          }, orElse: () => CartProductModel());

          final isMartItem = _isMartItem(cartItem);

          if (isMartItem) {
            // For mart items, we don't have ProductModel - use cart data
            // Mart items are displayed using cartProductModel data
            _productCache[productId] =
                null; // Mark as loaded (null = use cart data)
          } else {
            // For restaurant items, fetch ProductModel
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
      print(
        '[CART_PRODUCT] Preloaded ${_productCache.length} products (${productsToLoad.length} new)',
      );
    } catch (e) {
      print('[CART_PRODUCT] Error preloading products: $e');
    } finally {
      _isLoadingProducts = false;
    }
  }

  /// Get cached product by ID - returns null if not cached
  ProductModel? getCachedProduct(String? productId) {
    if (productId == null ||
        productId.isEmpty ||
        productId.toLowerCase() == 'null') {
      return null;
    }
    return _productCache[productId];
  }

  /// Clear product cache (call when cart changes significantly)
  void clearProductCache() {
    _productCache.clear();
    _productsLoaded = false;
    notifyListeners();
  }

  // Method to clear cart data on logout
  Future<void> clearCart() async {
    try {
      // Clear cart items from memory
      HomeProvider.cartItem.clear();
      await DatabaseHelper.instance.deleteAllCartProducts();
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
      if (remainingItems.isNotEmpty) {}
      notifyListeners();
    } catch (e) {}
    notifyListeners();
  }

  /// 🔑 CLEAR VENDOR CACHE WHEN CART CHANGES
  void _clearVendorCache() {
    _cachedVendorModel = null;
    _lastCacheTime = null;
    vendorModel = VendorModel();
    notifyListeners();
  }

  /// 🔑 LOAD FRESH VENDOR DATA - NO CACHING
  Future<void> _loadFreshVendorForCart() async {
    try {
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();
      final restaurantItems = HomeProvider.cartItem
          .where((item) => !_isMartItem(item))
          .toList();
      // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
      if (martItems.isNotEmpty) {
        await _loadFreshMartVendor(martItems);
      } else if (restaurantItems.isNotEmpty) {
        await _loadFreshRestaurantVendor(restaurantItems.first.vendorID);
      } else {}
      // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
    } catch (e) {}
    // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice()
  }

  /// 🔑 LOAD FRESH MART VENDOR
  Future<void> _loadFreshMartVendor(List<CartProductModel> martItems) async {
    try {
      final firstMartItem = martItems.first;
      final vendorId = firstMartItem.vendorID;
      MartVendorModel? martVendor;
      if (vendorId != null && vendorId.isNotEmpty) {
        martVendor = await MartVendorService.getMartVendorById(vendorId);
        martVendor ??= await MartVendorService.getDefaultMartVendor();
      } else {
        martVendor = await MartVendorService.getDefaultMartVendor();
      }
      if (martVendor != null) {
        vendorModel = VendorModel(
          id: martVendor.id,
          author: martVendor.author,
          title: martVendor.title,
          latitude: martVendor.latitude,
          longitude: martVendor.longitude,
          isSelfDelivery: false,
          vType: martVendor.vType,
          zoneId: martVendor.zoneId,
          isOpen: martVendor.isOpen,
        );
      }
      notifyListeners();
    } catch (e) {}
  }

  /// 🔑 LOAD FRESH RESTAURANT VENDOR
  Future<void> _loadFreshRestaurantVendor(String? vendorId) async {
    try {
      if (vendorId == null) {
        return;
      }
      final freshVendor = await FireStoreUtils.getVendorById(vendorId);
      if (freshVendor != null) {
        vendorModel = freshVendor;
      } else {}
      notifyListeners();
    } catch (e) {}
  }

  getCartData() async {
    cartProvider.cartStream.listen((event) async {
      HomeProvider.cartItem.clear();
      HomeProvider.cartItem.addAll(event);
      if (HomeProvider.cartItem.isNotEmpty) {
        final firstItemVendor = HomeProvider.cartItem.first.vendorID;
        if (_cachedVendorModel?.id != firstItemVendor) {
          _clearVendorCache();
        }
      }
      if (HomeProvider.cartItem.isNotEmpty) {
        await _loadFreshVendorForCart();
      }
      if (HomeProvider.cartItem.isNotEmpty) {
        final martItems = HomeProvider.cartItem
            .where((item) => _isMartItem(item))
            .toList();
        if (martItems.isNotEmpty) {
          try {
            final firstMartItem = martItems.first;
            final vendorId = firstMartItem.vendorID;
            MartVendorModel? martVendor;
            if (vendorId != null && vendorId.isNotEmpty) {
              martVendor = await MartVendorService.getMartVendorById(vendorId);
              if (martVendor != null) {
              } else {
                // Fallback to default mart vendor
                martVendor = await MartVendorService.getDefaultMartVendor();
              }
            } else {
              martVendor = await MartVendorService.getDefaultMartVendor();
            }
            if (martVendor != null) {
              vendorModel = VendorModel(
                id: martVendor.id,
                author: martVendor.author,
                title: martVendor.title,
                latitude: martVendor.latitude,
                longitude: martVendor.longitude,
                isSelfDelivery: false,
                vType: martVendor.vType,
                zoneId: martVendor.zoneId,
                isOpen: martVendor.isOpen,
                // Add other necessary fields as needed
              );
              _cachedVendorModel = vendorModel;
              _updateCacheTime();
              // 🔑 Reload coupons after mart vendor is loaded
              _detectCurrentContext();
              if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
                await _loadCoupons(restaurantId: vendorModel.id.toString());
              }
            } else {
              // Don't set hardcoded values - let the system handle this gracefully
              vendorModel = VendorModel();
            }
            notifyListeners();
          } catch (e) {
            vendorModel = VendorModel();
          }
          notifyListeners();
        } else {
          if (_cachedVendorModel != null && _isCacheValid()) {
            vendorModel = _cachedVendorModel!;
          } else {
            await FireStoreUtils.getVendorById(
              HomeProvider.cartItem.first.vendorID.toString(),
            ).then((value) async {
              if (value != null) {
                vendorModel = value;
                _cachedVendorModel = value;
                _updateCacheTime();
                // 🔑 Reload coupons after restaurant vendor is loaded
                _detectCurrentContext();
                if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
                  await _loadCoupons(restaurantId: vendorModel.id.toString());
                }
                notifyListeners();
              }
            });
            notifyListeners();
          }
        }
      }
      notifyListeners();
      await _loadCalculationCache();
      // 🔑 OPTIMIZED: Preload products when cart data changes (incremental loading)
      // This ensures products are ready when UI renders
      // Load in background without blocking price calculation
      _loadNewProductsIncrementally().catchError((e) {
        print('[CART_DATA] Error loading products: $e');
      });
      await calculatePrice();
      checkAndUpdatePaymentMethod();
      updateCartReadiness();
    });
    selectedFoodType = Preferences.getString(
      Preferences.foodDeliveryType,
      defaultValue: "Delivery".tr,
    );

    if (userModel.id == null) {
      final userId = await SqlStorageConst.getFirebaseId();
      await AddressListProvider.getUserProfile(userId.toString()).then((value) {
        if (value != null) {
          userModel = value;
        }
      });
    }
    if (_cachedDeliveryCharge != null && _isCacheValid()) {
      deliveryChargeModel = _cachedDeliveryCharge!;
    } else {
      await FireStoreUtils.getDeliveryCharge().then((value) {
        if (value != null) {
          deliveryChargeModel = value;
          _cachedDeliveryCharge = value;
          _updateCacheTime();
          calculatePrice();
        }
      });
    }
    // 🔑 Load coupons with proper context detection
    // Detect context first based on cart items
    _detectCurrentContext();

    if (vendorModel.id != null &&
        (!_isCacheValid() || _cachedCouponList == null)) {
      await _loadCoupons(restaurantId: vendorModel.id.toString());
    } else {
      if (vendorModel.id != null && _cachedCouponList == null) {
        await _loadCoupons(restaurantId: vendorModel.id.toString());
      } else if (vendorModel.id == null && HomeProvider.cartItem.isNotEmpty) {
        // 🔑 Vendor not loaded yet, but we have cart items - try to get vendor ID from items
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
        // No vendor and no cart items - load global coupons
        await _loadGlobalCouponsOnly();
      }
    }
    notifyListeners();
  }

  Future<void> _loadCoupons({required String restaurantId}) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingCoupons) {
      print('[COUPON_LOAD] ⚠️ Coupon load already in progress, skipping...');
      return;
    }

    // Validate restaurant ID before making API call
    if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
      print('[COUPON_LOAD] ⚠️ Skipping coupon load: empty restaurant ID');
      await _loadGlobalCouponsOnly();
      return;
    }
    _isLoadingCoupons = true;
    try {
      // 🔑 CRITICAL: Detect context BEFORE loading coupons
      // This ensures we call the correct API (mart vs restaurant)
      _detectCurrentContext();
      print(
        '[COUPON_LOAD] 🔍 Loading coupons for vendor: $restaurantId, Context: $_currentContext',
      );

      // 🔑 CRITICAL: Call the correct API based on context
      // If mart items in cart → call getMartCoupons API
      // If restaurant items in cart → call getRestaurantCoupons API
      final allCoupons = _currentContext == "mart"
          ? await RestaurantDetailsProvider.getMartCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('[COUPON_LOAD] ⏱️ Mart coupon API call timed out');
                return <CouponModel>[];
              },
            )
          : await RestaurantDetailsProvider.getRestaurantCoupons(
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

      // Filter vendor-specific coupons
      final vendorCoupons = allCoupons
          .where(
            (c) =>
                c.resturantId != null &&
                c.resturantId!.isNotEmpty &&
                c.resturantId!.toUpperCase() != 'ALL' &&
                c.resturantId == restaurantId,
          )
          .toList();

      // Combine vendor and global coupons
      final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
      final combinedAllCoupons = [...allCoupons];

      // 🔑 CRITICAL: Filter coupons by context (mart vs restaurant)
      final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
        coupons: combinedCoupons.cast<CouponModel>(),
        contextType: _currentContext,
        fallbackEnabled: true, // Enable fallback for backward compatibility
      );

      final contextFilteredAllCoupons =
          CouponFilterService.filterCouponsByContext(
            coupons: combinedAllCoupons.cast<CouponModel>(),
            contextType: _currentContext,
            fallbackEnabled: true,
          );

      print(
        '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} coupons for context: $_currentContext (from ${combinedCoupons.length} total)',
      );

      _cachedCouponList = contextFilteredCoupons;
      _updateCacheTime();

      couponList = contextFilteredCoupons;
      allCouponList = contextFilteredAllCoupons;
      // Mark used coupons BEFORE notifying listeners
      // This ensures coupons are validated before UI shows them
      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Connection error: $e');
      // Use cached coupons if available, otherwise empty list
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print(
        '[COUPON_LOAD] ❌ ClientException (connection refused or network error): $e',
      );
      // Use cached coupons if available, otherwise empty list
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_LOAD] ❌ Error loading coupons: $e');
      // Check for rate limit (429) or other errors
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('Status code: 429')) {
        print(
          '[COUPON_LOAD] ⚠️ Rate limit (429) - using cached coupons if available',
        );
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          // Mark used coupons before showing cached coupons
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        // Try fallback method only for non-rate-limit errors
        await _loadCouponsWithoutFiltering(restaurantId: restaurantId);
        notifyListeners();
      }
    } finally {
      _isLoadingCoupons = false;
      notifyListeners();
    }
  }

  // Fallback method to load coupons without context filtering
  Future<void> _loadCouponsWithoutFiltering({
    required String restaurantId,
  }) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingCoupons) {
      print(
        '[COUPON_LOAD] ⚠️ Fallback coupon load already in progress, skipping...',
      );
      return;
    }

    // Validate restaurant ID
    if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
      print('[COUPON_LOAD] ⚠️ Fallback: Skipping - empty restaurant ID');
      // Use cached coupons if available
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

    try {
      // 🔑 CRITICAL: Detect context BEFORE loading coupons
      _detectCurrentContext();
      print(
        '[COUPON_LOAD] 🔍 Fallback: Loading coupons for vendor: $restaurantId, Context: $_currentContext',
      );

      // 🔑 CRITICAL: Call the correct API based on context
      // If mart items in cart → call getMartCoupons API
      // If restaurant items in cart → call getRestaurantCoupons API
      final allCoupons = _currentContext == "mart"
          ? await RestaurantDetailsProvider.getMartCoupons(
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
          : await RestaurantDetailsProvider.getRestaurantCoupons(
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

      // Update observable lists
      couponList = combinedCoupons.cast<CouponModel>();
      allCouponList = combinedAllCoupons.cast<CouponModel>();
      // Mark used coupons BEFORE notifying listeners
      // This ensures coupons are validated before UI shows them
      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Fallback: Connection error: $e');
      // Use cached coupons if available
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print(
        '[COUPON_LOAD] ❌ Fallback: ClientException (connection refused or network error): $e',
      );
      // Use cached coupons if available
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_LOAD] ❌ Fallback coupon loading also failed: $e');
      // Check for rate limit (429) or other errors
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('Status code: 429')) {
        print(
          '[COUPON_LOAD] ⚠️ Fallback: Rate limit (429) - using cached coupons if available',
        );
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          // Mark used coupons before showing cached coupons
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        // Use cached coupons if available, otherwise empty list
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          // Mark used coupons before showing cached coupons
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
    }
  }

  // Detect current context based on cart items
  // NOTE: This method should NOT call notifyListeners() as it may be called during build
  void _detectCurrentContext() {
    try {
      bool hasMartItems = false;
      bool hasRestaurantItems = false;

      for (final item in HomeProvider.cartItem) {
        // Check if item is from mart (you may need to adjust this logic based on your item structure)
        if (_isMartItem(item)) {
          hasMartItems = true;
        } else {
          hasRestaurantItems = true;
        }
      }

      // Determine context based on cart contents
      if (hasMartItems && !hasRestaurantItems) {
        _currentContext = "mart";
      } else if (hasRestaurantItems && !hasMartItems) {
        _currentContext = "restaurant";
      } else {
        // Mixed cart or empty cart - prioritize mart if it has items
        if (hasMartItems) {
          _currentContext = "mart";
        } else {
          _currentContext = "restaurant";
        }
      }
      // Removed notifyListeners() to prevent setState during build errors
      // The caller should call notifyListeners() if needed after this method
    } catch (e) {
      _currentContext = "restaurant";
      // Removed notifyListeners() to prevent setState during build errors
    }
  }

  // Helper method to determine if an item is from mart
  // NOTE: This is a pure function and should NEVER call notifyListeners()
  // It may be called during widget build, so it must not trigger state changes
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

      // Method 4: Check category patterns that indicate mart items
      if (item.categoryId != null) {
        final categoryId = item.categoryId!.toLowerCase();
        if (categoryId.contains("grocery") ||
            categoryId.contains("mart") ||
            categoryId.contains("retail")) {
          return true;
        }
      }
      return false; // Default to restaurant if no mart indicators found
    } catch (e) {
      return false;
    }
  }

  // Check if cart has mart items
  // NOTE: This is a pure function and should NEVER call notifyListeners()
  // It may be called during widget build, so it must not trigger state changes
  bool hasMartItemsInCart() {
    try {
      return HomeProvider.cartItem.any((item) => _isMartItem(item));
    } catch (e) {
      return false;
    }
  }

  bool isMartDeliveryFree() {
    try {
      if (!hasMartItemsInCart()) {
        return false;
      }

      // 🔑 Use same deliveryChargeModel as restaurant (₹299 threshold from backend)
      final dc = deliveryChargeModel;
      final itemThreshold = dc.itemTotalThreshold ?? 299; // Same as restaurant
      final freeDeliveryKm =
          dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant

      final isEligible =
          subTotal >= itemThreshold && totalDistance <= freeDeliveryKm;

      notifyListeners();
      return isEligible;
    } catch (e) {
      return false;
    }
  }

  // Temporary method to force restaurant context for testing

  // Ensure coupons are loaded when cart screen opens
  void ensureCouponsLoaded() {
    if (_isLoadingCoupons) {
      print('[COUPON_LOAD] ⚠️ Coupon load already in progress, skipping...');
      return;
    }

    // 🔑 CRITICAL: Detect context FIRST based on cart items (not vendor model)
    // This ensures correct context even if vendor is not loaded yet
    _detectCurrentContext();
    print('[COUPON_LOAD] 🔍 Detected context: $_currentContext');

    if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
      if (couponList.isEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        notifyListeners();
      }
      // 🔑 Check if cache is valid AND context matches
      if (_isCacheValid()) {
        // Re-filter cached coupons with current context to ensure correct filtering
        final reFilteredCoupons = CouponFilterService.filterCouponsByContext(
          coupons: _cachedCouponList!,
          contextType: _currentContext,
          fallbackEnabled: true,
        );
        if (reFilteredCoupons.length != couponList.length) {
          // Context changed, need to reload
          print('[COUPON_LOAD] 🔄 Context changed, reloading coupons...');
        } else {
          return; // Cache is still valid and context matches
        }
      }
    }

    // 🔑 Try to get vendor ID - for mart items, vendor might not be loaded yet
    String? vendorId;
    if (vendorModel.id != null && vendorModel.id!.isNotEmpty) {
      vendorId = vendorModel.id.toString();
    } else if (HomeProvider.cartItem.isNotEmpty) {
      // 🔑 For mart items, try to get vendor ID from cart items
      final martItems = HomeProvider.cartItem
          .where((item) => _isMartItem(item))
          .toList();
      if (martItems.isNotEmpty) {
        final firstMartItem = martItems.first;
        vendorId = firstMartItem.vendorID;
        print('[COUPON_LOAD] 🔍 Using vendor ID from mart item: $vendorId');
      } else {
        // For restaurant items, try to get vendor ID from first item
        final firstItem = HomeProvider.cartItem.first;
        vendorId = firstItem.vendorID;
        print(
          '[COUPON_LOAD] 🔍 Using vendor ID from restaurant item: $vendorId',
        );
      }
    }

    if (vendorId != null && vendorId.isNotEmpty) {
      _loadCoupons(restaurantId: vendorId);
    } else {
      // No vendor ID available, load global coupons with context filtering
      _loadGlobalCouponsOnly();
    }
  }

  // Load only global coupons when no vendor ID is available
  Future<void> _loadGlobalCouponsOnly() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingCoupons) {
      print(
        '[COUPON_LOAD] ⚠️ Global coupon load already in progress, skipping...',
      );
      return;
    }

    _isLoadingCoupons = true;

    try {
      // 🔑 CRITICAL: Detect context BEFORE loading coupons
      // This ensures we call the correct API (mart vs restaurant)
      _detectCurrentContext();
      print('[COUPON_LOAD] 🔍 Global coupon load - Context: $_currentContext');

      // 🔑 CRITICAL: Call the correct API based on context
      // If mart items in cart → call getMartCoupons API
      // If restaurant items in cart → call getRestaurantCoupons API
      final globalCoupons = _currentContext == "mart"
          ? await RestaurantDetailsProvider.getMartCoupons(
              restaurantId: '',
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('[COUPON_LOAD] ⏱️ Global mart coupon API call timed out');
                return <CouponModel>[];
              },
            )
          : await RestaurantDetailsProvider.getRestaurantCoupons(
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

      // 🔑 CRITICAL: Filter global coupons by context (mart vs restaurant)
      final contextFilteredCoupons = CouponFilterService.filterCouponsByContext(
        coupons: filteredGlobalCoupons.cast<CouponModel>(),
        contextType: _currentContext,
        fallbackEnabled: true,
      );

      print(
        '[COUPON_LOAD] ✅ Filtered ${contextFilteredCoupons.length} global coupons for context: $_currentContext (from ${filteredGlobalCoupons.length} total)',
      );

      _cachedCouponList = contextFilteredCoupons;
      _updateCacheTime();

      // Update observable lists
      couponList = contextFilteredCoupons;
      allCouponList = filteredGlobalCoupons.cast<CouponModel>();
      // Mark used coupons BEFORE notifying listeners
      // This ensures coupons are validated before UI shows them
      await _markUsedCoupons();
      notifyListeners();
    } on SocketException catch (e) {
      print('[COUPON_LOAD] ❌ Global: Connection error: $e');
      // Use cached coupons if available
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } on http.ClientException catch (e) {
      print('[COUPON_LOAD] ❌ Global: ClientException: $e');
      // Use cached coupons if available
      if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
        allCouponList = _cachedCouponList!;
        // Mark used coupons before showing cached coupons
        await _markUsedCoupons();
        notifyListeners();
      } else {
        couponList = [];
        allCouponList = [];
        notifyListeners();
      }
    } catch (e) {
      print('[COUPON_DEBUG] ❌ Error loading global coupons: $e');
      // Check for rate limit (429) or bad request (400)
      final errorString = e.toString();
      if (errorString.contains('429') ||
          errorString.contains('400') ||
          errorString.contains('Status code: 429') ||
          errorString.contains('Status code: 400')) {
        print(
          '[COUPON_LOAD] ⚠️ Global: Rate limit or bad request - using cached coupons if available',
        );
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          // Mark used coupons before showing cached coupons
          await _markUsedCoupons();
          notifyListeners();
        } else {
          couponList = [];
          allCouponList = [];
          notifyListeners();
        }
      } else {
        // For other errors, try to use cached data
        if (_cachedCouponList != null && _cachedCouponList!.isNotEmpty) {
          couponList = _cachedCouponList!;
          allCouponList = _cachedCouponList!;
          await _markUsedCoupons();
          notifyListeners();
        }
      }
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _isLoadingCoupons = false;
    }
  }

  // Separate method to mark used coupons
  // Separate method to mark used coupons
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
        } else {
          print('DEBUG: API returned unsuccessful response');
        }
      } else {
        print('DEBUG: Failed to fetch used coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error marking used coupons: $e');
    }
  }

  Future<void> calculatePrice() async {
    // 🔑 CRITICAL: Debounce price calculation to prevent continuous updates
    if (_isCalculatingPrice) {
      print(
        '[PRICE_CALC] ⚠️ Price calculation already in progress, skipping duplicate call',
      );
      return;
    }

    // Check debounce time
    if (_lastPriceCalculationTime != null) {
      final timeSinceLastCalc = DateTime.now().difference(
        _lastPriceCalculationTime!,
      );
      if (timeSinceLastCalc < _priceCalculationDebounce) {
        print(
          '[PRICE_CALC] ⚠️ Price calculation debounced (${timeSinceLastCalc.inMilliseconds}ms < ${_priceCalculationDebounce.inMilliseconds}ms)',
        );
        return;
      }
    }

    _isCalculatingPrice = true;
    _lastPriceCalculationTime = DateTime.now();

    try {
      await ANRPrevention.executeWithANRPrevention('CartController_calculatePrice', () async {
        if (_cachedTaxList != null) {
          Constant.taxList = _cachedTaxList;
          // 🔑 REMOVED: notifyListeners() - will call at end
        } else if (Constant.taxList == null) {
          Constant.taxList = await FireStoreUtils.getTaxList();
          _cachedTaxList = Constant.taxList;
          // 🔑 REMOVED: notifyListeners() - will call at end
        }
        print(
          'DEBUG: Using cached tax list with ${Constant.taxList?.length ?? 0} items',
        );
        // Reset all values
        deliveryCharges = 0.0;
        subTotal = 0.0;
        couponAmount = 0.0;
        specialDiscountAmount = 0.0;
        taxAmount = 0.0;
        totalAmount = 0.0;
        // 🔑 REMOVED: notifyListeners() - will call at end
        if (HomeProvider.cartItem.isEmpty) {
          _isCalculatingPrice = false;
          notifyListeners(); // Only notify once when cart is empty
          return;
        }
        if (vendorModel.id == null) {
          final martItems = HomeProvider.cartItem
              .where((item) => _isMartItem(item))
              .toList();
          if (martItems.isNotEmpty) {
            print(
              '[VENDOR_LOAD] 🔧 Fallback: Loading mart vendor in calculatePrice...',
            );
            try {
              final firstMartItem = martItems.first;
              final vendorId = firstMartItem.vendorID;
              print(
                '[VENDOR_LOAD] 🔧 Fallback: Loading mart vendor for vendorID: $vendorId',
              );

              MartVendorModel? martVendor;

              if (vendorId != null && vendorId.isNotEmpty) {
                // Try to get the specific mart vendor by ID first
                martVendor = await MartVendorService.getMartVendorById(
                  vendorId,
                );
                if (martVendor != null) {
                  print(
                    '[VENDOR_LOAD] ✅ Fallback: Found specific mart vendor: ${martVendor.title} (${martVendor.id})',
                  );
                } else {
                  print(
                    '[VENDOR_LOAD] ⚠️ Fallback: Specific mart vendor not found, trying default mart vendor...',
                  );
                  // Fallback to default mart vendor
                  martVendor = await MartVendorService.getDefaultMartVendor();
                }
              } else {
                print(
                  '[VENDOR_LOAD] ⚠️ Fallback: No vendorID in mart item, trying default mart vendor...',
                );
                martVendor = await MartVendorService.getDefaultMartVendor();
              }
              if (martVendor != null) {
                vendorModel = VendorModel(
                  id: martVendor.id,
                  title: martVendor.title,
                  latitude: martVendor.latitude,
                  longitude: martVendor.longitude,
                  isSelfDelivery: false,
                  // Mart vendors don't have self delivery, use false
                  vType: martVendor.vType,
                  zoneId: martVendor.zoneId,
                  isOpen: martVendor.isOpen,
                );
                print(
                  '[VENDOR_LOAD] ✅ Fallback: Mart vendor loaded: ${martVendor.title} (${martVendor.id})',
                );
              }
            } catch (e) {
              print('[VENDOR_LOAD] ❌ Fallback: Error loading mart vendor: $e');
            }
          }
        }

        // 1. Calculate subtotal first - Use promotional price if available
        subTotal = 0.0;
        // 🔑 REMOVED: notifyListeners() - will call at end
        for (var element in HomeProvider.cartItem) {
          // Check if this item has a promotional price
          final hasPromo =
              element.promoId != null && element.promoId!.isNotEmpty;

          double itemPrice;
          if (hasPromo) {
            // Use promotional price for calculations
            itemPrice = double.parse(element.price.toString());
          } else if (double.parse(element.discountPrice.toString()) <= 0) {
            // No promotion, no discount - use regular price
            itemPrice = double.parse(element.price.toString());
          } else {
            // Regular discount (non-promo) - use discount price
            itemPrice = double.parse(element.discountPrice.toString());
          }

          final quantity = double.parse(element.quantity.toString());
          final extrasPrice = double.parse(element.extrasPrice.toString());

          subTotal += (itemPrice * quantity) + (extrasPrice * quantity);
          // 🔑 CRITICAL: REMOVED notifyListeners() from inside loop - causes continuous updates!
        }

        if (HomeProvider.cartItem.isNotEmpty) {
          if (selectedFoodType == "Delivery") {
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
          // 🔑 REMOVED: notifyListeners() - will call at end
        }
        // 🔑 REMOVED: notifyListeners() - will call at end
        CouponModel? activeCoupon;
        if (selectedCouponModel.id != null &&
            selectedCouponModel.id!.isNotEmpty) {
          activeCoupon = selectedCouponModel;
        } else if (couponCodeController.text.isNotEmpty) {
          activeCoupon = couponList
              .where((element) => element.code == couponCodeController.text)
              .firstOrNull;
          // 🔑 REMOVED: notifyListeners() - will call at end
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
          // 🔑 REMOVED: notifyListeners() - will call at end
          print('DEBUG: Coupon removed - cart contains promotional items');
        } else if (activeCoupon != null) {
          // Check minimum order value first
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
            // Calculate coupon discount
            if (activeCoupon.discountType == "percentage") {
              couponAmount =
                  (subTotal * double.parse(activeCoupon.discount.toString())) /
                  100;
            } else {
              couponAmount = double.parse(activeCoupon.discount.toString());
            }
            print('DEBUG: Coupon applied successfully - ${activeCoupon.code}');
          }
        } else {
          couponAmount = 0.0;
        }
        // 🔑 REMOVED: notifyListeners() - will call at end
        if (specialDiscountAmount > 0) {
          specialDiscountAmount = (subTotal * specialDiscountAmount) / 100;
        }
        double sgst = 0.0;
        double gst = 0.0;
        final hasPromotionalItemsForTax = HomeProvider.cartItem.any(
          (item) => item.promoId != null && item.promoId!.isNotEmpty,
        );
        final hasMartItems = hasMartItemsInCart();
        // 🔑 FIXED: Calculate tax ONLY on deliveryCharges (what customer actually pays)
        // When delivery is free (above ₹299), customer only pays extra km charge
        // Tax should be calculated on the actual amount charged, not on waived base charge
        // Example: If customer pays ₹7 (extra km), tax should be on ₹7, not on ₹30 (base + extra)
        final double taxableDeliveryFee = deliveryCharges > 0
            ? deliveryCharges
            : 0.0;

        print(
          '[TAX_CALC] Delivery charges (customer pays): ₹$deliveryCharges, Original fee (waived): ₹$originalDeliveryFee, Taxable fee: ₹$taxableDeliveryFee',
        );

        if (Constant.taxList != null) {
          for (var element in Constant.taxList!) {
            if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
              sgst = Constant.calculateTax(
                amount: subTotal.toString(),
                taxModel: element,
              );
              if (hasPromotionalItemsForTax) {
              } else if (hasMartItems) {
              } else {}
            } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
              gst = Constant.calculateTax(
                amount: taxableDeliveryFee.toString(),
                taxModel: element,
              );
              if (hasPromotionalItemsForTax) {
              } else if (hasMartItems) {
              } else {}
            }
          }
        }
        sgst = sgst.isNaN ? 0.0 : sgst;
        gst = gst.isNaN ? 0.0 : gst;
        taxAmount = sgst + gst;
        print(
          '[TAX_CALC] Tax from tax list: SGST: ₹$sgst, GST: ₹$gst, Total: ₹$taxAmount',
        );
        if (taxAmount == 0.0) {
          double sgstFallback = subTotal * 0.05; // 5% on subtotal
          double gstFallback = taxableDeliveryFee > 0
              ? taxableDeliveryFee *
                    0.18 // 18% on delivery charges (what customer pays)
              : 0.0;
          taxAmount = sgstFallback + gstFallback;
          print(
            '[TAX_CALC] Fallback tax applied → SGST (5% of ₹$subTotal): ₹$sgstFallback, GST (18% of ₹$taxableDeliveryFee): ₹$gstFallback, Total: ₹$taxAmount',
          );
        }
        if (taxAmount.isNaN) taxAmount = 0.0;
        print("Fallback tax applied → SGST:: $taxAmount");
        // sgst = (sgst.isNaN) ? 0.0 : sgst;
        // gst = (gst.isNaN) ? 0.0 : gst;
        // taxAmount = sgst + gst;
        // print("taxAmount = $taxAmount (SGST: $sgst, GST: $gst)");
        //
        // if (taxAmount.isNaN) taxAmount = 0.0;

        // if (taxAmount == 0.0) {
        //   double sgsts = subTotal * 0.05;
        //   double gsts = originalDeliveryFee * 0.18;
        //   taxAmount = sgsts + gsts;
        // }
        print("taxAmounttaxAmount  $taxAmount");
        // 🔑 REMOVED: notifyListeners() - will call at end
        if (hasPromotionalItemsForTax) {
        } else if (hasMartItems) {
        } else {}
        bool isFreeDelivery = false;
        if (HomeProvider.cartItem.isNotEmpty &&
            selectedFoodType == "Delivery") {
          // Check if cart has promotional items or mart items
          final hasPromotionalItems = HomeProvider.cartItem.any(
            (item) => item.promoId != null && item.promoId!.isNotEmpty,
          );
          final hasMartItems = hasMartItemsInCart();
          if (hasPromotionalItems) {
            final promotionalItems = HomeProvider.cartItem
                .where(
                  (item) => item.promoId != null && item.promoId!.isNotEmpty,
                )
                .toList();
            final firstPromoItem = promotionalItems.first;

            // Use cached data instead of Firebase query - INSTANT RESPONSE
            final freeDeliveryKm = _getCachedFreeDeliveryKm(
              firstPromoItem.id ?? '',
              firstPromoItem.vendorID ?? '',
            );

            if (totalDistance <= freeDeliveryKm) {
              isFreeDelivery = true;
            }

            // 🔑 REMOVED: notifyListeners() - will call at end
          } else if (hasMartItems) {
            // 🔑 Use same deliveryChargeModel as restaurant (₹299 threshold from backend)
            final dc = deliveryChargeModel;
            final threshold =
                dc.itemTotalThreshold ?? 299; // Same as restaurant
            final freeKm = dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant
            if (subTotal >= threshold && totalDistance <= freeKm) {
              isFreeDelivery = true;
            } else {
              isFreeDelivery = false;
            }
            // 🔑 REMOVED: notifyListeners() - will call at end
          } else {
            // For regular items, use regular delivery settings
            final dc = deliveryChargeModel;
            final subtotal = subTotal;
            final threshold = dc.itemTotalThreshold ?? 299;
            final freeKm = dc.freeDeliveryDistanceKm ?? 7;
            if (subtotal >= threshold && totalDistance <= freeKm) {
              isFreeDelivery = true;
              // 🔑 REMOVED: notifyListeners() - will call at end
            }
            // 🔑 REMOVED: notifyListeners() - will call at end
          }
          // 🔑 REMOVED: notifyListeners() - will call at end
        }
        totalAmount =
            (subTotal - couponAmount - specialDiscountAmount) +
            taxAmount +
            (isFreeDelivery ? 0.0 : deliveryCharges) +
            deliveryTips +
            surgePercent;
        checkAndUpdatePaymentMethod();
        // 🔑 CRITICAL: Only ONE notifyListeners() call at the very end
        notifyListeners();
      }, timeout: const Duration(seconds: 5));
    } finally {
      _isCalculatingPrice = false;
    }
  }

  void calculatePromotionalDeliveryChargeFast() {
    final promotionalItems = HomeProvider.cartItem
        .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
        .toList();

    if (promotionalItems.isEmpty) {
      print('DEBUG: No promotional items found, using regular delivery charge');
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
    final baseCharge = 23.0; // Base delivery charge for promotional items
    //finded
    _calculateDeliveryCharge(
      orderType: 'promotional',
      freeDeliveryKm: freeDeliveryKm,
      perKmCharge: extraKmCharge,
      baseCharge: baseCharge,
      logPrefix: '[PROMOTIONAL_DELIVERY]',
    );
    // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
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
      // Always calculate tax on base charge (₹23) + extra charges for all order types
      originalDeliveryFee = baseCharge + deliveryCharges;
    }
    // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
  }

  /// Calculate delivery charge for mart items - Use same backend settings as restaurant
  void calculateMartDeliveryCharge() {
    // Get mart items from cart
    final martItems = HomeProvider.cartItem
        .where((item) => _isMartItem(item))
        .toList();
    notifyListeners();

    if (martItems.isEmpty) {
      calculateRegularDeliveryCharge();
      return;
    }
    // 🔑 Use same deliveryChargeModel as restaurant (₹299 threshold from backend)
    _calculateMartDeliveryWithBackendSettings();
  }

  /// 🔑 Calculate mart delivery using same backend settings as restaurant
  void _calculateMartDeliveryWithBackendSettings() {
    // Use same deliveryChargeModel as restaurant items
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? 299; // Same as restaurant (₹299)
    final baseCharge = dc.baseDeliveryCharge ?? 23;
    final freeKm = dc.freeDeliveryDistanceKm ?? 7; // Same as restaurant
    final perKm = dc.perKmChargeAboveFreeDistance ?? 8; // Same as restaurant
    final distance = totalDistance;

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal < threshold) {
      // Below threshold - regular paid delivery
      if (distance <= freeKm) {
        deliveryCharges = baseCharge.toDouble();
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        deliveryCharges = (baseCharge + (extraKm * perKm)).toDouble();
        originalDeliveryFee = deliveryCharges;
      }
    } else {
      // Above threshold - free delivery within distance
      if (distance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
        deliveryCharges = (extraKm * perKm).toDouble();
      }
    }
    print(
      "calculateMartDeliveryCharge ${deliveryCharges} (threshold: ₹$threshold, subtotal: ₹$subtotal)",
    );
    // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
  }

  /// Fetch mart delivery charge settings from Firestore
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

  /// Calculate delivery charge for regular (non-promotional) items
  ///
  //finded here
  void calculateRegularDeliveryCharge() {
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? 299;
    final baseCharge = dc.baseDeliveryCharge ?? 23;
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
      // Above threshold - free delivery within distance
      if (totalDistance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge.toDouble();
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        originalDeliveryFee = (baseCharge + (extraKm * perKm)).toDouble();
        deliveryCharges = (extraKm * perKm).toDouble();
      }
    }
    print("calculateRegularDeliveryCharge ${deliveryCharges} ");
    // 🔑 REMOVED: notifyListeners() - will be called by calculatePrice() at end
  }

  Future<bool> addToCart({
    required CartProductModel cartProductModel,
    required bool isIncrement,
    required int quantity,
  }) async {
    if (isIncrement) {
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
      notifyListeners();
      if (!success) {
        return false;
      }
    } else {
      print("addToCart removeFromCart");
      cartProvider.removeFromCart(cartProductModel, quantity);
      notifyListeners();
    }
    // 🔑 OPTIMIZED: Only refresh prices and load new products incrementally
    // Don't clear cache or reload everything
    await _incrementalCartUpdate();
    notifyListeners();
    return true;
  }

  /// 🔑 OPTIMIZED: Incremental cart update - only loads new products and recalculates prices
  /// This is much faster than forceRefreshCart() which clears cache
  Future<void> _incrementalCartUpdate() async {
    try {
      // Load any new products that aren't cached yet (incremental loading)
      await _loadNewProductsIncrementally();

      // Recalculate prices (this is fast, no network calls)
      await calculatePrice();

      // Update payment method if needed
      checkAndUpdatePaymentMethod();

      // Update cart readiness
      updateCartReadiness();

      notifyListeners();
    } catch (e) {
      print('[CART_UPDATE] Error in incremental update: $e');
      // Fallback to full refresh only on error
      await forceRefreshCart();
    }
  }

  /// 🔑 Load only new products that aren't in cache (incremental loading)
  Future<void> _loadNewProductsIncrementally() async {
    try {
      // Get all product IDs from current cart
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

      // Find products that need to be loaded (not in cache)
      final Set<String> productsToLoad = productIds
          .where((id) => !_productCache.containsKey(id))
          .toSet();

      if (productsToLoad.isEmpty) {
        // All products already cached - no loading needed
        return;
      }

      // Load new products in parallel (non-blocking)
      // Don't set _isLoadingProducts to true here to avoid blocking UI
      final List<Future<void>> loadFutures = productsToLoad.map((
        productId,
      ) async {
        try {
          // Check if it's a mart item
          final isMartItem = _isMartItem(
            HomeProvider.cartItem.firstWhere(
              (item) => item.id?.split('~').first == productId,
              orElse: () => CartProductModel(),
            ),
          );

          ProductModel? product;
          if (isMartItem) {
            // For mart items, we don't have ProductModel - use cart data
            // Mart items are displayed using cartProductModel data
            _productCache[productId] =
                null; // Mark as loaded (null = use cart data)
          } else {
            // For restaurant items, fetch ProductModel
            product = await FireStoreUtils.getProductById(productId);
            _productCache[productId] = product;
          }

          // Notify listeners after each product loads (for progressive rendering)
          notifyListeners();
        } catch (e) {
          print('[CART_PRODUCT] Error loading product $productId: $e');
          _productCache[productId] = null; // Mark as loaded even on error
        }
      }).toList();

      // Wait for all new products to load
      await Future.wait(loadFutures);

      _productsLoaded = true;
      notifyListeners();
      print(
        '[CART_PRODUCT] Incrementally loaded ${productsToLoad.length} new products',
      );
    } catch (e) {
      print('[CART_PRODUCT] Error in incremental product loading: $e');
    }
  }

  List<CartProductModel> tempProduc = [];

  /// Check if order is already in progress (idempotency)
  bool _isOrderInProgress() {
    return _orderInProgress || isProcessingOrder;
  }

  /// Start order processing with idempotency
  void _startOrderProcessing() {
    _orderInProgress = true;
    isProcessingOrder = true;
    notifyListeners();
  }

  /// End order processing
  void _endOrderProcessing() {
    _orderInProgress = false;
    isProcessingOrder = false;
    notifyListeners();
  }

  /// Public method to start order processing (for use in widgets)
  void startOrderProcessing() {
    _startOrderProcessing();
  }

  ///finded

  placeOrder(BuildContext context) async {
    // if (_isOrderInProgress()) {
    //   ShowToastDialog.showToast(
    //     "Order is already being processed. Please wait...".tr,
    //   );
    //   return;
    // }
    if (lastOrderAttempt != null &&
        DateTime.now().difference(lastOrderAttempt!) < orderDebounceTime) {
      ShowToastDialog.showToast("Please wait before trying again...".tr);
      return;
    }
    _startOrderProcessing();
    lastOrderAttempt = DateTime.now();
    // 🔑 FIXED: Don't reset deliveryTips here - user has already selected the tip amount
    // Tips should only be reset when cart screen initializes (for new order sessions)
    try {
      if (!await validateOrderBeforePayment(context)) {
        _endOrderProcessing();
        return;
      }

      // 🔑 CRITICAL: Validate payment method is selected
      if (selectedPaymentMethod.isEmpty) {
        ShowToastDialog.showToast("Please select payment method".tr);
        endOrderProcessing();
        return;
      }

      // 🔑 CRITICAL: For Razorpay, ensure payment was completed
      if (selectedPaymentMethod == PaymentGateway.razorpay.name) {
        if (!isPaymentCompleted || _lastPaymentId == null) {
          ShowToastDialog.showToast(
            "Payment not completed. Please complete payment before placing order."
                .tr,
          );
          endOrderProcessing();
          return;
        }
      }

      if (selectedPaymentMethod == PaymentGateway.cod.name && subTotal > 599) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for orders above ₹599. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }
      if (selectedPaymentMethod == PaymentGateway.cod.name &&
          hasPromotionalItems()) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for promotional items. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }
      if (isPaymentCompleted &&
          _lastPaymentId != null &&
          (selectedPaymentMethod.isEmpty ||
              selectedPaymentMethod == PaymentGateway.cod.name)) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }
      if (selectedPaymentMethod == PaymentGateway.wallet.name) {
        if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
          await setOrder();
        } else {
          ShowToastDialog.showToast(
            "You don't have sufficient wallet balance to place order".tr,
          );
          endOrderProcessing();
        }
      } else {
        await setOrder();
      }
    } catch (e) {
      print('DEBUG: Error in placeOrder: $e');
      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
      } else {
        ShowToastDialog.showToast(
          "An error occurred while placing your order. Please try again.".tr,
        );
      }
      endOrderProcessing();
    }
    notifyListeners();
  }

  // Validate order before payment to prevent payment without order
  // Validate order before payment to prevent payment without order
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
            // For restaurant vendors, use restaurant status system
            if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
              // final status = RestaurantStatusUtils.getRestaurantStatus(
              //   latestVendor,
              // );
              ShowToastDialog.showToast("Restaurant Closed");
              return false;
            }
          }
        }
      } else {
        // Handle case where vendor model is not set (e.g., mart items)
      }

      // First, validate all items in cart for availability
      for (var item in HomeProvider.cartItem) {
        bool isMartItem = item.vendorID?.startsWith('mart_') == true;

        if (isMartItem) {
          // For mart items, fetch from API instead of Firebase
          try {
            // final martItems = await getMartItems();
            // final martItem = martItems.firstWhere(
            //       (mart) => mart.id == item.id!,
            //   orElse: () => MartItemModel(),
            // );
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
          // For restaurant ites, use existing Firebase logic
          // Validate product ID before making API call
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

          // Extract base product ID if it contains variant separator
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

          // Check stock availability (skip unlimited stock items)
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

      // After validation, update quantities (this part might need adjustment based on your API)
      for (int i = 0; i < tempProduc.length; i++) {
        // Check if this is a mart item (has 'mart_' prefix in vendorID)
        bool isMartItem = tempProduc[i].vendorID?.startsWith('mart_') == true;

        if (isMartItem) {
          // TODO: You'll need to implement an API endpoint to update mart item quantities
          // For now, we'll skip the quantity update for mart items via API
          // since getMartItems() is a GET request and doesn't update quantities
          print(
            '[ORDER VALIDATION] ⚠️ Mart item quantity update skipped - API update needed',
          );

          // If you have an API endpoint to update quantities, you would call it here:
          // await updateMartItemQuantity(tempProduc[i].id!.split('~').first, tempProduc[i].quantity!);
        } else {
          await FireStoreUtils.getProductById(
            tempProduc[i].id!.split('~').first,
          ).then((value) async {
            ProductModel? productModel = value;
            if (tempProduc[i].variantInfo != null) {
              if (productModel!.itemAttribute != null) {
                for (
                  int j = 0;
                  j < productModel.itemAttribute!.variants!.length;
                  j++
                ) {
                  if (productModel.itemAttribute!.variants![j].variantId ==
                      tempProduc[i].id!.split('~').last) {
                    if (productModel
                            .itemAttribute!
                            .variants![j]
                            .variantQuantity !=
                        "-1") {
                      int newVariantQuantity =
                          int.parse(
                            productModel
                                .itemAttribute!
                                .variants![j]
                                .variantQuantity
                                .toString(),
                          ) -
                          tempProduc[i].quantity!;
                      if (newVariantQuantity < 0) newVariantQuantity = 0;
                      productModel.itemAttribute!.variants![j].variantQuantity =
                          newVariantQuantity.toString();
                    }
                  }
                }
              } else {
                if (productModel.quantity != -1) {
                  int newQuantity =
                      productModel.quantity! - tempProduc[i].quantity!;
                  if (newQuantity < 0) newQuantity = 0;
                  productModel.quantity = newQuantity;
                }
              }
            } else {
              if (productModel!.quantity != -1) {
                int newQuantity =
                    productModel.quantity! - tempProduc[i].quantity!;
                if (newQuantity < 0) newQuantity = 0;
                productModel.quantity = newQuantity;
              }
            }

            await FireStoreUtils.setProduct(productModel);
          });
        }
        notifyListeners();
      }

      notifyListeners();
      return true;
    } catch (e) {
      // Check if this is a zone validation error and show specific message
      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
        // Handle zone validation errors if needed
      } else {
        // Generic validation error
        ShowToastDialog.showToast(
          "Error validating order. Please try again.".tr,
        );
      }
      notifyListeners();
      return false;
    }
  }

  // Rollback mechanism for failed orders
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

  /// finderone
  setOrder() async {
    await FireStoreUtils.getVendorById(vendorModel.id!);
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
    } else {}
    notifyListeners();
    return await _setOrderInternal();
  }

  void providerInitializer({required BuildContext context}) {
    orderPlacingProvider = Provider.of<OrderPlacingProvider>(
      context,
      listen: false,
    );
  }

  ///issue finded
  Future<void> _setOrderInternal() async {
    // 🔑 CRITICAL: Prevent concurrent order creation at the API level
    // Only block if it's the SAME payment ID - allow different payment IDs to proceed
    if (_isOrderCreationInProgress &&
        _currentOrderPaymentId == _lastPaymentId) {
      print(
        '⚠️ [ORDER_CREATION] Order creation already in progress for payment ID $_lastPaymentId, preventing duplicate',
      );
      return; // Prevent concurrent order creation for same payment
    }

    // 🔑 CRITICAL: Check cooldown period to prevent rapid duplicate calls
    // Only apply cooldown if it's the SAME payment ID
    if (_lastOrderCreationTime != null &&
        _currentOrderPaymentId == _lastPaymentId) {
      final timeSinceLastOrder = DateTime.now().difference(
        _lastOrderCreationTime!,
      );
      if (timeSinceLastOrder < _orderCreationCooldown) {
        print(
          '⚠️ [ORDER_CREATION] Order creation cooldown active, preventing duplicate for payment ID: $_lastPaymentId',
        );
        return; // Prevent duplicate orders within cooldown period
      }
    }

    // Set static lock immediately - this prevents other instances from creating orders
    _isOrderCreationInProgress = true;
    _currentOrderPaymentId = _lastPaymentId;
    _lastOrderCreationTime = DateTime.now();

    print(
      '✅ [ORDER_CREATION] Starting order creation for payment ID: $_lastPaymentId',
    );

    String? orderId;
    List<CartProductModel> orderedProducts = [];
    try {
      tempProduc.clear();
      if ((Constant.isSubscriptionModelApplied == true ||
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
          return;
        }
      }
      for (CartProductModel cartProduct in HomeProvider.cartItem) {
        CartProductModel tempCart = cartProduct;
        if (cartProduct.extrasPrice == '0') {
          tempCart.extras = [];
        }
        tempProduc.add(tempCart);
        orderedProducts.add(tempCart);
        notifyListeners();
      }
      Map<String, dynamic> specialDiscountMap = {
        'special_discount': specialDiscountAmount,
        'special_discount_label': specialDiscount,
        'specialType': specialType,
      };
      OrderModel orderModel = OrderModel();
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
              notifyListeners();
            }
          }
        } else {
          print('⚠️ API call failed with status: ${response.statusCode}');
          // Continue with default maxNumber
        }
      } catch (e) {
        print('⚠️ Error fetching latest order: $e');
        // Continue with default maxNumber
      }

      orderModel.address = selectedAddress;
      orderModel.authorID = await SqlStorageConst.getFirebaseId();
      orderModel.author = userModel;
      orderModel.vendorID = vendorModel.id;
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
      notifyListeners();
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
        // "selected_address": {
        //   "address_id": selectedAddress?.id,
        //   "label": selectedAddress?.address,
        //   "address_line": selectedAddress?.address,
        //   "city": selectedAddress?.addressAs,
        //   "lat": selectedAddress?.location?.latitude,
        //   "lng": selectedAddress?.location?.longitude,
        // },
        "payment_method": selectedPaymentMethod,
        "payment_id": _lastPaymentId ?? '',
        // 🔑 CRITICAL: Include payment ID for reconciliation
        "razorpay_payment_id": _lastPaymentId ?? '',
        // 🔑 CRITICAL: Include Razorpay payment ID
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
        "vendor_id": vendorModel.id ?? 'mart_default',
        "status": Constant.orderPlaced,
        "created_at": DateTime.now().toIso8601String(),
      };
      notifyListeners();
      log(
        const JsonEncoder.withIndent('  ').convert(orderPayload),
        name: "ORDER_PAYLOAD",
      );
      // **API CALL: Store the order**
      print(
        '🌐 [ORDER_CREATION] Creating order via API for payment ID: $_lastPaymentId',
      );
      print('🌐 [ORDER_CREATION] API URL: ${AppConst.baseUrl}mobile/orders');

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
      print('🌐 [ORDER_CREATION] API response body: ${response.body}');

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
        '✅ [ORDER_CREATION] Order created successfully with ID: ${orderModel.id} for payment ID: $_lastPaymentId',
      );

      ///finded new
      print('✅ Order created successfully via API');
      final additionalTasks = <Future>[];
      if (selectedCouponModel.id != null &&
          selectedCouponModel.id!.isNotEmpty) {
        additionalTasks.add(markCouponAsUsed(selectedCouponModel.id!));
        notifyListeners();
      }
      String adminFee = "0";
      if (surgePercent > 0) {
        adminFee = await getAdminSurgeFee();
        notifyListeners();
      }
      additionalTasks.add(
        _createOrderBilling(
          responseData['data']['order_id'],
          totalAmount.toString(),
          surgePercent.toInt(),
          adminFee,
        ),
      );
      print(
        " additionalTasks author  ${vendorModel.id}   ${vendorModel.author}",
      );
      if (vendorModel.id != null && vendorModel.author != null) {
        print(" additionalTasks author ");
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
      print(
        " additionalTasks author1  ${vendorModel.id}   ${vendorModel.author}",
      );
      additionalTasks.add(Constant.sendOrderEmail(orderModel: orderModel));
      await Future.wait(additionalTasks);

      // 🔑 CRITICAL: Clear all order creation flags after successful order creation
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      // 🔑 CRITICAL: Keep payment ID in processed set to prevent duplicate orders
      // Don't clear _processedPaymentIds here - keep it to prevent duplicates

      isPaymentInProgress = false;
      isPaymentCompleted = false;
      _lastPaymentId = null;
      _lastPaymentTime = null;
      selectedCouponModel = CouponModel();
      couponCodeController.text = '';
      couponAmount = 0.0;
      calculatePrice();
      await _clearPersistentPaymentState();
      ShowToastDialog.closeLoader();
      endOrderProcessing();
      notifyListeners();
      // Navigate to order success screen
      orderPlacingProvider.initFunction(orderModels: orderModel);
      Get.off(const OrderPlacingScreen());
      notifyListeners();
    } catch (e) {
      print("OrderPlacingScreen  $e");

      // 🔑 CRITICAL: Reset all order creation flags on error
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      ShowToastDialog.closeLoader();
      endOrderProcessing();
      if (isPaymentCompleted && _lastPaymentId != null) {
        // Remove from processed set to allow retry
        _processedPaymentIds.remove(_lastPaymentId!);
        // Don't reset payment state here - let user retry
        ShowToastDialog.showToast(
          "Order placement failed. Your payment is safe. Please try again.".tr,
        );
      } else {
        // Reset payment state for non-payment related errors
        _resetPaymentState();
        ShowToastDialog.showToast(
          "Failed to place order. Please try again.".tr,
        );
      }
      if (orderId != null) {
        await rollbackFailedOrder(orderId, orderedProducts);
      }
      notifyListeners();
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

  CodSettingModel cashOnDeliverySettingModel = CodSettingModel();
  RazorPayModel razorPayModel = RazorPayModel();

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

              if (cashOnDeliverySettingModel.isEnabled == true &&
                  subTotal <= 599 &&
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

  /// 🔑 OPTIMIZATION: Pre-initialize Razorpay in background
  /// This eliminates the initialization delay when user clicks "Confirm Payment"
  Future<void> _preInitializeRazorpay() async {
    try {
      // Only pre-initialize if not already initialized
      if (!_razorpayCrashPrevention.isInitialized) {
        print('🔑 [RAZORPAY_PREINIT] Pre-initializing Razorpay...');
        await _razorpayCrashPrevention.safeInitialize(
          onSuccess: handlePaymentSuccess,
          onFailure: handlePaymentError,
          onExternalWallet: handleExternalWallet,
        );
        print('✅ [RAZORPAY_PREINIT] Razorpay pre-initialized successfully');
      } else {
        print('✅ [RAZORPAY_PREINIT] Razorpay already initialized');
      }
    } catch (e) {
      print(
        '⚠️ [RAZORPAY_PREINIT] Pre-initialization failed (will initialize on demand): $e',
      );
      // Don't throw - initialization will happen on demand in openCheckout
    }
  }

  final RazorpayCrashPrevention _razorpayCrashPrevention =
      RazorpayCrashPrevention();

  Razorpay? get razorPay => _razorpayCrashPrevention.razorpayInstance;

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

    // 🔑 OPTIMIZATION: Razorpay should already be initialized from pre-init
    // Only initialize if absolutely necessary (shouldn't happen in normal flow)
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

    // 🔑 SET PAYMENT IN PROGRESS STATE
    isPaymentInProgress = true;
    print('🔑 [RAZORPAY_CHECKOUT] Payment in progress flag set');

    // 🔑 CRITICAL FIX: Validate Razorpay configuration before creating options
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

    // 🔑 CRITICAL FIX: Convert amount to int to pass validation
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
      'amount': amountInPaise, // ✅ FIXED: Now using int instead of double
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

    print(
      '🔑 [RAZORPAY_CHECKOUT] Payment options prepared: ${options.toString().replaceAll(razorPayModel.razorpayKey!, 'rzp_***')}',
    );
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
      // 🔑 RESET PAYMENT STATE ON ERROR
      print('❌ [RAZORPAY_CHECKOUT] Exception in openCheckout: $e');
      print('❌ [RAZORPAY_CHECKOUT] Stack trace: $stackTrace');
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Failed to open payment gateway. Please try again.".tr,
      );
      return false;
    }
  }

  bool isGlobalLocked = false;

  /// ✅ NEW: Safe payment success handler with crash prevention
  /// 🔑 CRITICAL FIX: Added idempotency check to prevent duplicate orders
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    try {
      final paymentId = response.paymentId;
      print("handlePaymentSuccess  ${paymentId}");
      // 🔑 CRITICAL: Validate payment ID is not null
      if (paymentId == null || paymentId.isEmpty) {
        print('❌ [PAYMENT_SUCCESS] Invalid payment ID, ignoring callback');
        return;
      }

      // 🔑 CRITICAL: Check if this payment ID has already been processed
      if (_processedPaymentIds.contains(paymentId)) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Payment ID $paymentId already processed, ignoring duplicate callback',
        );
        return; // Ignore duplicate payment success callbacks
      }

      // 🔑 CRITICAL: Check if order is already being created
      if (_isOrderBeingCreated) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Order is already being created, ignoring duplicate callback',
        );
        return; // Prevent concurrent order creation
      }

      // 🔑 CRITICAL: Check if payment is already completed
      if (isPaymentCompleted && _lastPaymentId == paymentId) {
        print(
          '⚠️ [DUPLICATE_PREVENTION] Payment already completed for ID $paymentId, ignoring duplicate callback',
        );
        return; // Prevent duplicate processing
      }

      print('✅ [PAYMENT_SUCCESS] Processing payment ID: $paymentId');

      // Mark payment ID as being processed immediately
      _processedPaymentIds.add(paymentId);

      // 🔑 CRITICAL: Clean up old payment IDs to prevent memory issues
      if (_processedPaymentIds.length > _maxProcessedPaymentIds) {
        // Remove oldest entries (keep most recent)
        final idsToRemove = _processedPaymentIds
            .take(_processedPaymentIds.length - _maxProcessedPaymentIds)
            .toList();
        for (final id in idsToRemove) {
          _processedPaymentIds.remove(id);
        }
      }

      isGlobalLocked = true;
      _lastPaymentId = paymentId;
      _lastPaymentTime = DateTime.now();
      isPaymentCompleted = true;
      // 🔑 CRITICAL: DON'T set _isOrderBeingCreated here - set it in placeOrderAfterPayment
      // Setting it here causes placeOrderAfterPayment to return early and never create order!

      ShowToastDialog.showLoader("Processing payment and placing order...".tr);

      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          print(
            '🔑 [PAYMENT_SUCCESS] Starting order placement after delay for payment ID: $paymentId',
          );
          await placeOrderAfterPayment();
        } catch (e, stackTrace) {
          print('❌ [PAYMENT_SUCCESS] Error in placeOrderAfterPayment: $e');
          print('❌ [PAYMENT_SUCCESS] Stack trace: $stackTrace');
          // On error, allow retry by removing from processed set (but keep payment completed flag)
          _processedPaymentIds.remove(paymentId);
          _isOrderBeingCreated = false;
          // 🔑 CRITICAL: Reset static lock on error
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
          ShowToastDialog.showToast(
            "Order placement failed. Your payment is safe. Please try again."
                .tr,
          );
        } finally {
          isGlobalLocked = false;
        }
      });
      notifyListeners();
    } catch (e) {
      print('❌ [PAYMENT_SUCCESS] Exception in handlePaymentSuccess: $e');
      isGlobalLocked = false;
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

  /// ✅ NEW: Safe payment error handler with crash prevention
  void handlePaymentError(PaymentFailureResponse response) {
    try {
      // Reset payment state
      isPaymentInProgress = false;
      // 🔑 CRITICAL: Reset order processing flag when payment fails
      endOrderProcessing();

      // Show error message
      ShowToastDialog.showToast("Payment failed: ${response.message}".tr);
      notifyListeners();
    } catch (e) {
      isPaymentInProgress = false;
      // 🔑 CRITICAL: Reset order processing flag on error
      endOrderProcessing();
      ShowToastDialog.showToast("Payment failed. Please try again.".tr);
      notifyListeners();
    }
  }

  /// ✅ NEW: Safe external wallet handler with crash prevention
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
    // Show critical error dialog
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

  void _resetPaymentState() {
    isPaymentInProgress = false;
    isPaymentCompleted = false;
    _lastPaymentId = null;
    _lastPaymentTime = null;
    _isOrderBeingCreated = false;
    // 🔑 CRITICAL: Clear static order creation flags
    _isOrderCreationInProgress = false;
    _currentOrderPaymentId = null;
    // 🔑 CRITICAL: Clear processed payment IDs when resetting payment state
    // This allows retry after a full reset
    _processedPaymentIds.clear();
    notifyListeners();
  }

  // 🔑 RESTORE PAYMENT STATE FROM PERSISTENT STORAGE
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
      // 🔑 RESTORE PAYMENT METHOD FROM PERSISTENT STORAGE
      if (paymentMethodStr.isNotEmpty && paymentMethodStr != '') {
        selectedPaymentMethod = paymentMethodStr;
      } else if (_lastPaymentId != null && _lastPaymentId!.isNotEmpty) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }
      notifyListeners();
    }
  }

  // 🔑 CLEAR PERSISTENT PAYMENT STATE
  Future<void> _clearPersistentPaymentState() async {
    try {
      await Preferences.setString(_paymentStateKey, '');
      await Preferences.setString(_paymentIdKey, '');
      await Preferences.setString(_paymentSignatureKey, '');
      await Preferences.setString(_paymentTimeKey, '');
      await Preferences.setString(_paymentMethodKey, '');
      await Preferences.setString(_paymentAmountKey, '');
      await Preferences.setString(_paymentOrderIdKey, '');
    } catch (e) {}
  }

  // 🔑 CHECK PENDING PAYMENT AND RECOVER (HANDLES APP KILLS)
  Future<void> _checkPendingPaymentAndRecover() async {
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

      // Show recovery dialog to user (matching app's address alert style)
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
      notifyListeners();
    } catch (e) {
      await _clearPersistentPaymentState();
      _resetPaymentState();
      notifyListeners();
    }
  }

  // 🔑 COMPLETE PENDING ORDER
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

  // 🔑 RETRY ORDER PLACEMENT
  Future<void> _retryOrderPlacement() async {
    if (_lastPaymentId != null && _lastPaymentTime != null) {
      // Check if payment is still valid (within timeout)
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

  // 🔑 ENHANCED PLACE ORDER AFTER PAYMENT - NEW IMPLEMENTATION
  placeOrderAfterPayment() async {
    try {
      // 🔑 VALIDATE PAYMENT STATE BEFORE PROCEEDING
      if (!isPaymentCompleted || _lastPaymentId == null) {
        print(
          '❌ [ORDER_PLACEMENT] Payment validation failed - no valid payment found',
        );
        throw Exception('Payment validation failed - no valid payment found');
      }

      // 🔑 CRITICAL: Check if order is already being created for THIS payment ID
      // Only prevent if it's the same payment ID AND order is being created
      if (_isOrderBeingCreated && _currentOrderPaymentId == _lastPaymentId) {
        print(
          '⚠️ [ORDER_PLACEMENT] Order is already being created for payment ID $_lastPaymentId, preventing duplicate',
        );
        return; // Prevent concurrent order creation for same payment
      }

      // 🔑 CRITICAL: Check static lock to prevent concurrent order creation across instances
      if (_isOrderCreationInProgress &&
          _currentOrderPaymentId == _lastPaymentId) {
        print(
          '⚠️ [ORDER_PLACEMENT] Order creation already in progress for payment ID $_lastPaymentId',
        );
        return; // Prevent duplicate order creation
      }

      // Set flags to prevent concurrent calls
      _isOrderBeingCreated = true;
      print(
        '✅ [ORDER_PLACEMENT] Starting order creation for payment ID: $_lastPaymentId',
      );

      // 🔑 CHECK PAYMENT TIMEOUT
      if (_lastPaymentTime != null) {
        final timeSincePayment = DateTime.now().difference(_lastPaymentTime!);
        if (timeSincePayment > paymentTimeout) {
          throw Exception('Payment session expired');
        }
      }

      // 🔑 ENSURE PAYMENT METHOD IS SET CORRECTLY FOR PREPAID ORDERS
      if (selectedPaymentMethod.isEmpty ||
          selectedPaymentMethod == PaymentGateway.cod.name) {
        // If payment method is empty or COD, but we have a successful payment, set it to razorpay
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }

      // Prevent order if fallback location is used - apply to ALL payment methods
      if (selectedAddress?.locality == 'Ongole, Andhra Pradesh, India' ||
          selectedAddress?.addressAs == 'Ongole Center') {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Please select your actual address or use current location to place order."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      if (selectedPaymentMethod == PaymentGateway.cod.name && subTotal > 599) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for orders above ₹599. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      if (selectedPaymentMethod == PaymentGateway.cod.name &&
          hasPromotionalItems()) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for promotional items. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      // 🔑 CRITICAL: Ensure we have valid payment before creating order
      if (_lastPaymentId == null || _lastPaymentId!.isEmpty) {
        throw Exception('Payment ID is missing - cannot create order');
      }

      print(
        '🔑 [ORDER_PLACEMENT] Payment validated, proceeding to create order for payment ID: $_lastPaymentId',
      );
      print('🔑 [ORDER_PLACEMENT] Payment method: $selectedPaymentMethod');
      print('🔑 [ORDER_PLACEMENT] Total amount: $totalAmount');

      if (selectedPaymentMethod == PaymentGateway.wallet.name) {
        if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
          print(
            '🔑 [ORDER_PLACEMENT] Using wallet payment, calling _setOrderInternal',
          );
          await _setOrderInternal();
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "You don't have sufficient wallet balance to place order".tr,
          );
          endOrderProcessing();
          _isOrderBeingCreated = false;
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
          return;
        }
      } else {
        print(
          '🔑 [ORDER_PLACEMENT] Using Razorpay payment, calling _setOrderInternal',
        );
        await _setOrderInternal();
      }

      // 🔑 CRITICAL: Clear order creation flag only after successful order creation
      _isOrderBeingCreated = false;
      print(
        '✅ [ORDER_PLACEMENT] Order creation completed successfully for payment ID: $_lastPaymentId',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      // 🔑 CRITICAL: Reset all order creation flags on error to allow retry
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      if (_lastPaymentId != null) {
        // Remove from processed set to allow retry on error
        _processedPaymentIds.remove(_lastPaymentId);
      }

      ShowToastDialog.closeLoader();
      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
        // Zone validation errors are handled separately
      } else {
        ShowToastDialog.showToast(
          "An error occurred while placing your order. Your payment is safe. Please try again."
              .tr,
        );
      }
      endOrderProcessing();
      print('❌ [ORDER_PLACEMENT] Error in placeOrderAfterPayment: $e');
      print('❌ [ORDER_PLACEMENT] Stack trace: $stackTrace');

      // 🔑 CRITICAL: Re-throw error so handlePaymentSuccess can catch it and show proper message
      rethrow;
    }
    notifyListeners();
  }

  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  // In CartControllerProvider class
  Future<void> markCouponAsUsed(String couponId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
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

  // Add this method to mark a coupon as used for the current user
  // Future<void> markCouponAsUsed(String couponId) async {
  //   try {
  //     final headers = await getHeaders();
  //     final response = await http.post(
  //       Uri.parse('${AppConst.baseUrl}mobile/coupons/$couponId/used'),
  //       headers: headers,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       print('Coupon marked as used successfully');
  //       await getCartData();
  //     } else {
  //       throw Exception(
  //         'Failed to mark coupon as used: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     print('Error marking coupon as used: $e');
  //     throw Exception('Failed to mark coupon as used: $e');
  //   }
  // }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  //Paypal - Commented out to reduce APK size
  void paypalPaymentSheet(String amount, BuildContext context) {
    ShowToastDialog.showToast(
      "PayPal payment is disabled for APK size optimization".tr,
    );
  }

  /// Validate minimum order value for mart items
  Future<void> validateMinimumOrderValue() async {
    try {
      // Check if cart contains any mart items
      bool hasMartItems = HomeProvider.cartItem.any(
        (item) => item.vendorID?.startsWith('mart_') == true,
      );
      if (!hasMartItems) {
        return;
      }
      double minOrderValue = 99.0; // Default value
      String minOrderMessage = 'Min Item value is ₹99';
      bool isSettingsActive = true; // Default to active

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
        return; // Skip validation if settings are inactive
      }

      final currentSubTotal = subTotal;

      // Check if current subtotal meets minimum order requirement
      if (currentSubTotal < minOrderValue) {
        ShowToastDialog.showToast(minOrderMessage);
        throw Exception('Minimum order value not met');
      }

      notifyListeners();
    } catch (e) {
      // Re-throw the exception to stop the order process
      rethrow;
    }
    notifyListeners();
  }

  /// 🔑 BULLETPROOF ADDRESS VALIDATION - NEVER FAILS
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
          print(
            '[CART_VALIDATION] ✅ Synced selectedAddress with Constant.selectedLocation',
          );
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
      // CRITICAL CHECK 2: Address must have valid ID
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
      if (address.address!.trim() == 'Current Location' &&
          (address.location?.latitude == null ||
              address.location?.longitude == null)) {
        ShowToastDialog.showToast(
          "Current location address must have valid coordinates. Please add a proper address."
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
      if (address.locality!.trim() == 'Current Location' &&
          (address.location?.latitude == null ||
              address.location?.longitude == null)) {
        ShowToastDialog.showToast(
          "Current location must have valid coordinates. Please add a proper address."
              .tr,
        );
        Get.to(() => const AddressListScreen());
        return false;
      }
      print(
        '🏠 [BULLETPROOF_ADDRESS] ✅ CHECK 4 PASSED - Valid locality: "${address.locality}"',
      );
      if (address.location == null ||
          address.location!.latitude == null ||
          address.location!.longitude == null ||
          address.location!.latitude == 0.0 ||
          address.location!.longitude == 0.0) {
        print('[CART_VALIDATION] ❌ CHECK 5 FAILED - Invalid coordinates');
        print('[CART_VALIDATION] Location: ${address.location?.toJson()}');
        print('[CART_VALIDATION] Address: ${address.address}');
        print('[CART_VALIDATION] Locality: ${address.locality}');
        if (!isRetry) {
          final homeScreenAddress = await _getCurrentLocationAddress(context);
          if (homeScreenAddress != null &&
              homeScreenAddress.location?.latitude != null &&
              homeScreenAddress.location?.longitude != null) {
            selectedAddress = homeScreenAddress;
            print(
              '[CART_VALIDATION] ✅ Retry sync successful - using home screen address',
            );
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

        // PRIORITY 1: Try to use zoneId from Constant.selectedLocation
        if (Constant.selectedLocation.zoneId != null &&
            Constant.selectedLocation.zoneId!.isNotEmpty) {
          detectedZoneId = Constant.selectedLocation.zoneId;
          print(
            '[CART_VALIDATION] ✅ Using zoneId from Constant.selectedLocation: $detectedZoneId',
          );
        }
        // PRIORITY 2: Try to use zoneId from Constant.selectedZone
        else if (Constant.selectedZone?.id != null &&
            Constant.selectedZone!.id!.isNotEmpty) {
          detectedZoneId = Constant.selectedZone!.id;
          print(
            '[CART_VALIDATION] ✅ Using zoneId from Constant.selectedZone: $detectedZoneId',
          );
        }
        // PRIORITY 3: Try to detect zone ID from coordinates
        else {
          detectedZoneId = await _detectZoneIdForCoordinates(
            address.location!.latitude!,
            address.location!.longitude!,
            context,
          );
          if (detectedZoneId != null) {
            print(
              '[CART_VALIDATION] ✅ Detected zoneId from coordinates: $detectedZoneId',
            );
          }
        }
        if (detectedZoneId != null && detectedZoneId.isNotEmpty) {
          address.zoneId = detectedZoneId;
          Constant.selectedLocation.zoneId = detectedZoneId;
          print(
            '[CART_VALIDATION] ✅ Zone ID set successfully: $detectedZoneId',
          );
        } else {
          print('[CART_VALIDATION] ❌ All zone detection methods failed');
          print(
            '[CART_VALIDATION] Constant.selectedLocation.zoneId: ${Constant.selectedLocation.zoneId}',
          );
          print(
            '[CART_VALIDATION] Constant.selectedZone?.id: ${Constant.selectedZone?.id}',
          );
          ShowToastDialog.showToast(
            "Address zone not detected. Please update your address or contact support."
                .tr,
          );
          Get.to(() => const AddressListScreen());
          return false;
        }
      }
      if (vendorModel.zoneId == null || vendorModel.zoneId!.isEmpty) {
        ShowToastDialog.showToast(
          "Vendor zone not configured. Please contact support.".tr,
        );
        return false;
      }
      if (address.zoneId != vendorModel.zoneId) {
        // Show zone mismatch alert dialog
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

        // Set maximum delivery distance (20km - adjust as needed)
        const maxDeliveryDistance = 16.0;

        if (distance > maxDeliveryDistance) {
          // Show distance too far alert dialog
          DeliveryZoneAlertDialog.showDistanceTooFarError();
          return false;
        }
        notifyListeners();
      }
      notifyListeners();
      return true;
    } catch (e) {
      ShowToastDialog.showToast(
        "Error validating address. Please select a valid delivery address.".tr,
      );

      Get.to(() => const AddressListScreen());
      return false;
    }
  }
}

enum PaymentGateway { razorpay, cod, wallet }
