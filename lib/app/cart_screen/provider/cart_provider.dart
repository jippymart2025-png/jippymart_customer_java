import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/oder_placing_screens.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/send_notification.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
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

import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/coupon_filter_service.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/services/mart_vendor_service.dart';
import 'package:jippymart_customer/services/promotional_cache_service.dart';
import 'package:jippymart_customer/utils/anr_prevention.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/razorpay_crash_prevention.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widgets/delivery_zone_alert_dialog.dart'
    show DeliveryZoneAlertDialog;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartControllerProvider extends ChangeNotifier {
  Future<void> showPaymentMethodDialog(BuildContext context) async {
    final canProceed = await validateAndPlaceOrderBulletproof(context);
    if (!canProceed) {
      return;
    }
    await Get.dialog(
      WillPopScope(
        onWillPop: () async {
          selectedPaymentMethod = '';
          return true;
        },
        child: AlertDialog(
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
                    selectedPaymentMethod = value!;
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
                    selectedPaymentMethod = value!;
                  },
                  activeColor: Colors.orange,
                ),
              ),

              SizedBox(height: 10),
              // Validation messages
              if (subTotal > 599)
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
              if (hasPromotionalItems())
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
            // Cancel Button
            TextButton(
              onPressed: () {
                selectedPaymentMethod = '';
                Get.back();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: Text("Cancel"),
            ),
            // OK/Proceed Button
            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Proceed to Pay"),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
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
    final doc = await FirebaseFirestore.instance
        .collection("surge_rules")
        .doc("surge_settings")
        .get();
    if (doc.exists) {
      print(" doc data ${doc.data()}");
      return doc.data()!;
    } else {
      throw Exception("Surge rules not found");
    }
  }

  Future<String> getAdminSurgeFee() async {
    final doc = await FirebaseFirestore.instance
        .collection("surge_rules")
        .doc("surge_settings")
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('admin_surge_fee')) {
        print("Admin Surge Fee: ${data['admin_surge_fee']}");
        return data['admin_surge_fee'].toString(); // return as String
      } else {
        throw Exception("Field 'admin_surge_fee' not found in surge_settings");
      }
    } else {
      throw Exception("Document surge_settings not found");
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

  // 🔑 RAZORPAY PAYMENT STATE MANAGEMENT
  bool isPaymentInProgress = false;
  bool isPaymentCompleted = false;
  String? _lastPaymentId;
  DateTime? _lastPaymentTime;
  static const Duration paymentTimeout = Duration(minutes: 5);

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

  // Add caching for better performance
  VendorModel? _cachedVendorModel;
  DeliveryCharge? _cachedDeliveryCharge;
  List<CouponModel>? _cachedCouponList;
  DateTime? _lastCacheTime;
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Context detection for coupon filtering
  String _currentContext = "restaurant"; // Default to restaurant

  // **ULTRA-FAST CALCULATION CACHE FOR INSTANT CART UPDATES**
  final Map<String, Map<String, dynamic>> _promotionalCalculationCache = {};
  final Map<String, double> _cachedFreeDeliveryKm = {};
  final Map<String, double> _cachedExtraKmCharge = {};
  List<TaxModel>? _cachedTaxList;
  bool _calculationCacheLoaded = false;

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
    Map<String, dynamic> weather = await getWeather(lat, lon);
    Map<String, dynamic> rules = await getSurgeRules();
    surgePercent = calculateSurgeFee(weather, rules);
    notifyListeners();
  }

  Future<void> _initializeAddressWithPriority(BuildContext context) async {
    try {
      // PRIORITY 1: Check for saved addresses in user profile
      if (Constant.userModel != null &&
          Constant.userModel!.shippingAddress != null &&
          Constant.userModel!.shippingAddress!.isNotEmpty) {
        final defaultAddress = Constant.userModel!.shippingAddress!.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => Constant.userModel!.shippingAddress!.first,
        );
        selectedAddress = defaultAddress;
        initialLiseSurgeValue(
          defaultAddress.location?.latitude ?? 0.0,
          defaultAddress.location?.longitude ?? 0.0,
        );
        return;
      }
      final homeScreenAddress = await _getCurrentLocationAddress(context);
      if (homeScreenAddress != null) {
        selectedAddress = homeScreenAddress;
        initialLiseSurgeValue(
          homeScreenAddress.location?.latitude ?? 0.0,
          homeScreenAddress.location?.longitude ?? 0.0,
        );

        return;
      }
      selectedAddress = null;
      notifyListeners();
      _showAddressRequiredAlert();
    } catch (e) {
      print('🏠 [ADDRESS_PRIORITY] ❌ ERROR in address initialization: $e');
      selectedAddress = null;
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
          String? detectedZoneId = await _detectZoneIdForCoordinates(
            lat,
            lng,
            context,
          );
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

  /// 🔑 DETECT ZONE ID FOR COORDINATES
  ///
  /// This method detects the zone ID for given coordinates by checking
  /// if the coordinates fall within any zone polygon
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

      // Check if coordinates fall within the zone polygon
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
      if (_cachedTaxList == null) {
        _cachedTaxList = await FireStoreUtils.getTaxList();
      }
      final futures = <Future>[];
      for (var item in cartItem) {
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
    return cartItem.any(
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
    final cartNotEmpty = cartItem.isNotEmpty;
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
    isCartReady = cartItem.isNotEmpty && subTotal > 0;
    isPaymentReady = isCartReadyForPayment();
    isAddressValid = selectedAddress?.id != null;
    notifyListeners();
  }

  /// Force refresh cart data and recalculate prices
  Future<void> forceRefreshCart() async {
    await cartProvider.refreshCart();
    await calculatePrice();
    checkAndUpdatePaymentMethod();
    updateCartReadiness();
    notifyListeners();
  }

  // Method to clear cart data on logout
  Future<void> clearCart() async {
    try {
      // Clear cart items from memory
      cartItem.clear();
      // Clear cart from database
      await DatabaseHelper.instance.deleteAllCartProducts();

      subTotal = 0.0;
      totalAmount = 0.0;
      deliveryCharges = 0.0;
      couponAmount = 0.0;
      specialDiscountAmount = 0.0;
      taxAmount = 0.0;
      deliveryTips = 0.0;
      selectedPaymentMethod = '';

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
      final martItems = cartItem.where((item) => _isMartItem(item)).toList();
      final restaurantItems = cartItem
          .where((item) => !_isMartItem(item))
          .toList();
      if (martItems.isNotEmpty) {
        await _loadFreshMartVendor(martItems);
      } else if (restaurantItems.isNotEmpty) {
        await _loadFreshRestaurantVendor(restaurantItems.first.vendorID);
      } else {}
      notifyListeners();
    } catch (e) {}
    notifyListeners();
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
      cartItem.clear();
      cartItem.addAll(event);
      if (cartItem.isNotEmpty) {
        final firstItemVendor = cartItem.first.vendorID;
        if (_cachedVendorModel?.id != firstItemVendor) {
          _clearVendorCache();
        }
      }
      if (cartItem.isNotEmpty) {
        await _loadFreshVendorForCart();
      }
      if (cartItem.isNotEmpty) {
        final martItems = cartItem.where((item) => _isMartItem(item)).toList();
        if (martItems.isNotEmpty) {
          try {
            final firstMartItem = martItems.first;
            final vendorId = firstMartItem.vendorID;
            MartVendorModel? martVendor;

            if (vendorId != null && vendorId.isNotEmpty) {
              // Try to get the specific mart vendor by ID first
              martVendor = await MartVendorService.getMartVendorById(vendorId);
              if (martVendor != null) {
              } else {
                // Fallback to default mart vendor
                martVendor = await MartVendorService.getDefaultMartVendor();
              }
            } else {
              // Fallback to default mart vendor
              martVendor = await MartVendorService.getDefaultMartVendor();
            }

            if (martVendor != null) {
              // Convert MartVendorModel to VendorModel for compatibility
              vendorModel = VendorModel(
                id: martVendor.id,
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
              cartItem.first.vendorID.toString(),
            ).then((value) async {
              if (value != null) {
                vendorModel = value;
                _cachedVendorModel = value;
                _updateCacheTime();
              }
            });
            notifyListeners();
          }
        }
      }

      // Load ultra-fast calculation cache before calculating price
      await _loadCalculationCache();

      // Force price calculation
      await calculatePrice();

      // Check payment method after cart data is loaded
      checkAndUpdatePaymentMethod();
      // Update cart readiness state
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

    if (vendorModel.id != null &&
        (!_isCacheValid() || _cachedCouponList == null)) {
      await _loadCoupons();
    } else {
      if (vendorModel.id != null && _cachedCouponList == null) {
        await _loadCoupons();
      }
    }
    notifyListeners();
  }

  Future<void> _loadCoupons() async {
    try {
      _detectCurrentContext();
      final vendorCoupons = await FireStoreUtils.getAllVendorPublicCoupons();
      final allVendorCoupons = await FireStoreUtils.getAllVendorPublicCoupons();

      final globalCoupons =
          await RestaurantDetailsProvider.getRestaurantCoupons();
      final filteredGlobalCoupons = globalCoupons
          .where(
            (c) =>
                c.resturantId == null ||
                c.resturantId == '' ||
                c.resturantId?.toUpperCase() == 'ALL',
          )
          .toList();

      final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
      final combinedAllCoupons = [
        ...allVendorCoupons,
        ...filteredGlobalCoupons,
      ];

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

      _cachedCouponList = contextFilteredCoupons;
      _updateCacheTime();

      couponList = contextFilteredCoupons;
      allCouponList = contextFilteredAllCoupons;
      notifyListeners();
      // Mark used coupons
      await _markUsedCoupons();
    } catch (e) {
      await _loadCouponsWithoutFiltering();
    }
  }

  // Fallback method to load coupons without context filtering
  Future<void> _loadCouponsWithoutFiltering() async {
    try {
      final vendorCoupons = await FireStoreUtils.getAllVendorPublicCoupons();
      final allVendorCoupons = await FireStoreUtils.getAllVendorPublicCoupons();

      final globalCoupons =
          await RestaurantDetailsProvider.getRestaurantCoupons();
      final filteredGlobalCoupons = globalCoupons
          .where(
            (c) =>
                c.resturantId == null ||
                c.resturantId == '' ||
                c.resturantId?.toUpperCase() == 'ALL',
          )
          .toList();

      final combinedCoupons = [...vendorCoupons, ...filteredGlobalCoupons];
      final combinedAllCoupons = [
        ...allVendorCoupons,
        ...filteredGlobalCoupons,
      ];

      _cachedCouponList = combinedCoupons.cast<CouponModel>();
      _updateCacheTime();

      // Update observable lists
      couponList = combinedCoupons.cast<CouponModel>();
      allCouponList = combinedAllCoupons.cast<CouponModel>();
      notifyListeners();
      // Mark used coupons
      await _markUsedCoupons();
    } catch (e) {
      print('[COUPON_LOAD] ❌ Fallback coupon loading also failed: $e');
    }
  }

  // Detect current context based on cart items
  void _detectCurrentContext() {
    try {
      bool hasMartItems = false;
      bool hasRestaurantItems = false;

      for (final item in cartItem) {
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
      notifyListeners();
    } catch (e) {
      _currentContext = "restaurant";
      notifyListeners();
    }
  }

  // Helper method to determine if an item is from mart
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
      notifyListeners();
      return false; // Default to restaurant if no mart indicators found
    } catch (e) {
      return false;
    }
  }

  bool hasMartItemsInCart() {
    try {
      return cartItem.any((item) => _isMartItem(item));
    } catch (e) {
      return false;
    }
  }

  bool isMartDeliveryFree() {
    try {
      if (!hasMartItemsInCart()) {
        return false;
      }

      double itemThreshold = 199.0; // Default
      double freeDeliveryKm = 5.0; // Default

      if (_martDeliverySettings != null) {
        itemThreshold =
            (_martDeliverySettings!['item_total_threshold'] as num?)
                ?.toDouble() ??
            199.0;
        freeDeliveryKm =
            (_martDeliverySettings!['free_delivery_distance_km'] as num?)
                ?.toDouble() ??
            5.0;
      }
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
    if (_cachedCouponList == null || _cachedCouponList!.isEmpty) {
      if (vendorModel.id != null) {
        _loadCoupons();
      } else {
        _loadGlobalCouponsOnly();
      }
    } else {
      // Update the observable list with cached coupons
      if (couponList.isEmpty && _cachedCouponList!.isNotEmpty) {
        couponList = _cachedCouponList!;
      }
    }
    notifyListeners();
  }

  // Load only global coupons when no vendor ID is available
  Future<void> _loadGlobalCouponsOnly() async {
    try {
      _detectCurrentContext();

      // Load global coupons
      final globalCoupons =
          await RestaurantDetailsProvider.getRestaurantCoupons();
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
      _cachedCouponList = contextFilteredCoupons;
      _updateCacheTime();
      // Update observable lists
      couponList = contextFilteredCoupons;
      allCouponList = filteredGlobalCoupons.cast<CouponModel>();
      notifyListeners();
    } catch (e) {
      print('[COUPON_DEBUG] ❌ Error loading global coupons: $e');
    }
  }

  // Separate method to mark used coupons
  Future<void> _markUsedCoupons() async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final usedCouponsSnapshot = await FirebaseFirestore.instance
          .collection('used_coupons')
          .where('userId', isEqualTo: userId)
          .get();
      final usedCouponIds = usedCouponsSnapshot.docs
          .map((doc) => doc['couponId'] as String)
          .toSet();

      // Mark used coupons in both lists
      for (var coupon in couponList) {
        coupon.isEnabled = !usedCouponIds.contains(coupon.id);
      }
      for (var coupon in allCouponList) {
        coupon.isEnabled = !usedCouponIds.contains(coupon.id);
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error marking used coupons: $e');
    }
  }

  Future<void> calculatePrice() async {
    await ANRPrevention.executeWithANRPrevention('CartController_calculatePrice', () async {
      if (_cachedTaxList != null) {
        Constant.taxList = _cachedTaxList;
      } else if (Constant.taxList == null || Constant.taxList!.isEmpty) {
        Constant.taxList = await FireStoreUtils.getTaxList();
        _cachedTaxList = Constant.taxList;
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
      if (cartItem.isEmpty) {
        return;
      }
      if (vendorModel.id == null) {
        final martItems = cartItem.where((item) => _isMartItem(item)).toList();
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
              martVendor = await MartVendorService.getMartVendorById(vendorId);
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
              // Fallback to default mart vendor
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
      for (var element in cartItem) {
        // Check if this item has a promotional price
        final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;

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
      }

      // 2. Now calculate delivery fee using the correct subtotal
      if (cartItem.isNotEmpty) {
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

          final hasPromotionalItems = cartItem.any(
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
        notifyListeners();
      }
      notifyListeners();
      CouponModel? activeCoupon;
      if (selectedCouponModel.id != null &&
          selectedCouponModel.id!.isNotEmpty) {
        activeCoupon = selectedCouponModel;
      } else if (couponCodeController.text.isNotEmpty) {
        activeCoupon = couponList
            .where((element) => element.code == couponCodeController.text)
            .firstOrNull;
      }
      final hasPromotionalItems = cartItem.any((item) {
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
      notifyListeners();

      if (specialDiscountAmount > 0) {
        specialDiscountAmount = (subTotal * specialDiscountAmount) / 100;
      }

      double sgst = 0.0;
      double gst = 0.0;

      // Check if cart has promotional items or mart items
      final hasPromotionalItemsForTax = cartItem.any(
        (item) => item.promoId != null && item.promoId!.isNotEmpty,
      );
      final hasMartItems = hasMartItemsInCart();

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
              amount: originalDeliveryFee.toString(),
              taxModel: element,
            );
            if (hasPromotionalItemsForTax) {
            } else if (hasMartItems) {
            } else {}
          }
        }
      }
      taxAmount = sgst + gst;
      if (hasPromotionalItemsForTax) {
      } else if (hasMartItems) {
      } else {}
      bool isFreeDelivery = false;
      if (cartItem.isNotEmpty && selectedFoodType == "Delivery") {
        // Check if cart has promotional items or mart items
        final hasPromotionalItems = cartItem.any(
          (item) => item.promoId != null && item.promoId!.isNotEmpty,
        );
        final hasMartItems = hasMartItemsInCart();
        if (hasPromotionalItems) {
          final promotionalItems = cartItem
              .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
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
        } else if (hasMartItems) {
          double itemThreshold = 199.0; // Default
          double freeDeliveryKm = 5.0; // Default

          if (_martDeliverySettings != null) {
            itemThreshold =
                (_martDeliverySettings!['item_total_threshold'] as num?)
                    ?.toDouble() ??
                199.0;
            freeDeliveryKm =
                (_martDeliverySettings!['free_delivery_distance_km'] as num?)
                    ?.toDouble() ??
                5.0;
          }

          if (subTotal >= itemThreshold && totalDistance <= freeDeliveryKm) {
            isFreeDelivery = true;
          } else {
            isFreeDelivery = false;
          }
        } else {
          // For regular items, use regular delivery settings
          final dc = deliveryChargeModel;
          final subtotal = subTotal;
          final threshold = dc.itemTotalThreshold ?? 299;
          final freeKm = dc.freeDeliveryDistanceKm ?? 7;
          if (subtotal >= threshold && totalDistance <= freeKm) {
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
      checkAndUpdatePaymentMethod();
      notifyListeners();
    }, timeout: const Duration(seconds: 5));
    notifyListeners();
  }

  void calculatePromotionalDeliveryChargeFast() {
    final promotionalItems = cartItem
        .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
        .toList();

    if (promotionalItems.isEmpty) {
      print('DEBUG: No promotional items found, using regular delivery charge');
      calculateRegularDeliveryCharge();
      return;
    }

    // Get the first promotional item's delivery settings from cache - INSTANT
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

    _calculateDeliveryCharge(
      orderType: 'promotional',
      freeDeliveryKm: freeDeliveryKm,
      perKmCharge: extraKmCharge,
      baseCharge: baseCharge,
      logPrefix: '[PROMOTIONAL_DELIVERY]',
    );
    notifyListeners();
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
      // Free delivery within distance - show original fee with strikethrough
      deliveryCharges = 0.0;
      originalDeliveryFee = baseCharge;
    } else {
      double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
      deliveryCharges = extraKm * perKmCharge;
      // Always calculate tax on base charge (₹23) + extra charges for all order types
      originalDeliveryFee = baseCharge + deliveryCharges;
    }
    notifyListeners();
  }

  /// Calculate delivery charge for mart items using static values (like restaurant)
  void calculateMartDeliveryCharge() {
    // Get mart items from cart
    final martItems = cartItem.where((item) => _isMartItem(item)).toList();
    notifyListeners();

    if (martItems.isEmpty) {
      calculateRegularDeliveryCharge();
      return;
    }
    // Use static values like restaurant delivery (don't fetch from database)
    _calculateMartDeliveryWithStaticValues();
  }

  void _calculateMartDeliveryWithStaticValues() {
    final baseCharge = 23.0; // Base delivery charge
    final freeKm = 5.0; // Free delivery distance for mart
    final perKm = 7.0; // Per km charge above free distance
    final threshold = 199.0; // Free delivery threshold for mart

    final subtotal = subTotal;
    final distance = totalDistance;

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal >= threshold) {
      if (distance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        deliveryCharges = extraKm * perKm;
        originalDeliveryFee = baseCharge + deliveryCharges;
      }
      notifyListeners();
    } else {
      if (distance <= freeKm) {
        deliveryCharges = baseCharge;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (distance - freeKm).ceilToDouble();
        deliveryCharges = baseCharge + (extraKm * perKm);
        originalDeliveryFee = deliveryCharges;
      }
    }
    notifyListeners();
  }

  /// Fetch mart delivery charge settings from Firestore
  Future<Map<String, dynamic>?> _fetchMartDeliveryChargeSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('martDeliveryCharge')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Calculate delivery charge for regular (non-promotional) items
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

    notifyListeners();
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
          // final limit = await getPromotionalItemLimit(
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
        // Don't update the UI if adding to cart failed
        return false;
      }
    } else {
      cartProvider.removeFromCart(cartProductModel, quantity);
      notifyListeners();
    }
    notifyListeners();
    return true;
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

  ///finded

  placeOrder(BuildContext context) async {
    // Check idempotency - prevent duplicate orders
    if (_isOrderInProgress()) {
      ShowToastDialog.showToast(
        "Order is already being processed. Please wait...".tr,
      );
      return;
    }
    // Check debouncing
    if (lastOrderAttempt != null &&
        DateTime.now().difference(lastOrderAttempt!) < orderDebounceTime) {
      ShowToastDialog.showToast("Please wait before trying again...".tr);
      return;
    }
    _startOrderProcessing();
    lastOrderAttempt = DateTime.now();
    try {
      if (!await validateOrderBeforePayment(context)) {
        _endOrderProcessing();
        return;
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
        // Generic order error
        ShowToastDialog.showToast(
          "An error occurred while placing your order. Please try again.".tr,
        );
      }

      endOrderProcessing();
    }
    notifyListeners();
  }

  // Validate order before payment to prevent payment without order
  Future<bool> validateOrderBeforePayment(BuildContext context) async {
    try {
      if (cartItem.isEmpty) {
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

      // 🔑 BULLETPROOF ADDRESS VALIDATION - NEVER SKIPS
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
            if (!RestaurantStatusUtils.isRestaurantOpen(latestVendor)) {
              final status = RestaurantStatusUtils.getRestaurantStatus(
                latestVendor,
              );
              ShowToastDialog.showToast(status['reason']);
              return false;
            }
          }
        }
      } else {
        // Handle case where vendor model is not set (e.g., mart items)
      }

      for (int i = 0; i < tempProduc.length; i++) {
        // Check if this is a mart item (has 'mart_' prefix in vendorID)
        bool isMartItem = tempProduc[i].vendorID?.startsWith('mart_') == true;

        if (isMartItem) {
          // For mart items, update quantity in mart_items collection
          try {
            final martItemDoc = await FirebaseFirestore.instance
                .collection('mart_items')
                .doc(tempProduc[i].id!.split('~').first)
                .get();

            if (martItemDoc.exists) {
              final martItemData = martItemDoc.data()!;
              final currentQuantity = martItemData['quantity'] ?? -1;

              if (currentQuantity != -1) {
                int newQuantity = currentQuantity - tempProduc[i].quantity!;
                if (newQuantity < 0) newQuantity = 0;

                await FirebaseFirestore.instance
                    .collection('mart_items')
                    .doc(tempProduc[i].id!.split('~').first)
                    .update({'quantity': newQuantity});
              }
            }
          } catch (e) {}
          notifyListeners();
        } else {
          // For restaurant items, use existing logic
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
          notifyListeners();
        }
      }

      // Check if items are still available and have sufficient stock
      for (var item in cartItem) {
        // Check if this is a mart item (has 'mart_' prefix in vendorID)
        bool isMartItem = item.vendorID?.startsWith('mart_') == true;

        if (isMartItem) {
          // For mart items, fetch from mart_items collection
          try {
            final martItemDoc = await FirebaseFirestore.instance
                .collection('mart_items')
                .doc(item.id!)
                .get();

            if (!martItemDoc.exists) {
              ShowToastDialog.showToast(
                "Some mart items in your cart are no longer available.",
              );
              return false;
            }

            final martItemData = martItemDoc.data()!;
            final availableQuantity = martItemData['quantity'] ?? -1;
            final orderedQuantity = item.quantity ?? 0;

            // Check stock availability (skip unlimited stock items)
            if (availableQuantity != -1 &&
                availableQuantity < orderedQuantity) {
              final itemName = martItemData['title'] ?? 'Mart Item';
              ShowToastDialog.showToast(
                "$itemName is out of stock. Available: $availableQuantity, Ordered: $orderedQuantity",
              );
              return false;
            }
          } catch (e) {
            ShowToastDialog.showToast(
              "Error validating mart items. Please try again.",
            );
            return false;
          }
        } else {
          // For restaurant items, use existing logic
          final product = await FireStoreUtils.getProductById(item.id!);
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
      notifyListeners();
      return true;
    } catch (e) {
      // Check if this is a zone validation error and show specific message
      if (e.toString().contains('Delivery zone validation failed') ||
          e.toString().contains('Delivery distance validation failed')) {
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
      await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .doc(orderId)
          .delete();
      for (var product in products) {
        bool isMartItem = product.vendorID?.startsWith('mart_') == true;
        if (isMartItem) {
          try {
            final martItemDoc = await FirebaseFirestore.instance
                .collection('mart_items')
                .doc(product.id!)
                .get();
            if (martItemDoc.exists) {
              final martItemData = martItemDoc.data()!;
              final currentQuantity = martItemData['quantity'] ?? 0;
              final orderedQuantity = product.quantity ?? 0;
              final newQuantity = currentQuantity + orderedQuantity;

              await FirebaseFirestore.instance
                  .collection('mart_items')
                  .doc(product.id!)
                  .update({'quantity': newQuantity});
            }
          } catch (e) {}
          notifyListeners();
        } else {
          // For restaurant items, use existing logic
          final productModel = await FireStoreUtils.getProductById(product.id!);
          if (productModel != null) {
            int currentQuantity = productModel.quantity ?? 0;
            int orderedQuantity = product.quantity ?? 0;
            int newQuantity = currentQuantity + orderedQuantity;
            productModel.quantity = newQuantity;
            await FireStoreUtils.setProduct(productModel);
          }

          notifyListeners();
        }
      }

      // Delete billing record if exists
      await FirebaseFirestore.instance
          .collection('order_Billing')
          .doc(orderId)
          .delete();

      notifyListeners();
    } catch (e) {}
  }

  /// finderone
  setOrder() async {
    await FireStoreUtils.getVendorById(vendorModel.id!);
    if (vendorModel.id != null) {
      final latestVendor = await FireStoreUtils.getVendorById(vendorModel.id!);
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
          if (!RestaurantStatusUtils.isRestaurantOpen(latestVendor)) {
            ShowToastDialog.closeLoader();
            final status = RestaurantStatusUtils.getRestaurantStatus(
              latestVendor,
            );
            ShowToastDialog.showToast(status['reason']);
            endOrderProcessing();
            return;
          }
        }
      }
    } else {}
    notifyListeners();
    return await _setOrderInternal();
  }

  ///issue finded
  Future<void> _setOrderInternal() async {
    String? orderId;
    List<CartProductModel> orderedProducts = [];
    try {
      if ((Constant.isSubscriptionModelApplied == true ||
              Constant.adminCommission?.isEnabled == true) &&
          vendorModel.subscriptionPlan != null &&
          vendorModel.id != null) {
        final vender = await FireStoreUtils.getVendorById(vendorModel.id!);
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
      // Prepare cart products
      for (CartProductModel cartProduct in cartItem) {
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
      OrderModel orderModel = OrderModel();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'Jippy3000000')
          .where(FieldPath.documentId, isLessThan: 'Jippy4')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      int maxNumber = 5;
      if (querySnapshot.docs.isNotEmpty) {
        final id = querySnapshot.docs.first.id;
        final match = RegExp(r'Jippy3(\d{7})').firstMatch(id);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null && num > maxNumber) {
            maxNumber = num;
          }
        }
      }
      final nextNumber = maxNumber + 1;
      orderModel.id = 'Jippy3${nextNumber.toString().padLeft(7, '0')}';
      orderId = orderModel.id;
      print('DEBUG: Generated Order ID: ${orderModel.id}');

      orderModel.address = selectedAddress;
      orderModel.authorID = await SqlStorageConst.getFirebaseId();
      orderModel.author = userModel;

      // Handle vendor details - check if vendor model is set
      if (vendorModel.id != null) {
        // Restaurant order - use existing vendor model
        orderModel.vendorID = vendorModel.id;
        orderModel.vendor = vendorModel;
        orderModel.adminCommission = vendorModel.adminCommission != null
            ? vendorModel.adminCommission!.amount
            : Constant.adminCommission!.amount;
        orderModel.adminCommissionType = vendorModel.adminCommission != null
            ? vendorModel.adminCommission!.commissionType
            : Constant.adminCommission!.commissionType;
      } else {
        // Mart order - fetch the actual mart vendor from Firebase
        try {
          print('DEBUG: Fetching mart vendor for order...');
          final martVendor = await MartVendorService.getDefaultMartVendor();
          if (martVendor != null) {
            orderModel.vendorID = martVendor.id;
            // Convert MartVendorModel to VendorModel for compatibility
            orderModel.vendor = VendorModel(
              id: martVendor.id,
              title: martVendor.title,
              location: martVendor.location,
              phonenumber: martVendor.phonenumber,
              latitude: martVendor.latitude,
              longitude: martVendor.longitude,
              isOpen: martVendor.isOpen,
              vType: martVendor.vType,
              author: martVendor.author,
              authorName: martVendor.authorName,
              authorProfilePic: martVendor.authorProfilePic,
              adminCommission: martVendor.adminCommission,
              // deliveryCharge will be set to default below
              workingHours: martVendor.workingHours
                  ?.map(
                    (wh) => WorkingHours(
                      day: wh.day,
                      timeslot: wh.timeslot
                          ?.map((ts) => Timeslot(from: ts.from, to: ts.to))
                          .toList(),
                    ),
                  )
                  .toList(),
            );
            orderModel.adminCommission =
                martVendor.adminCommission?.amount ??
                Constant.adminCommission!.amount;
            orderModel.adminCommissionType =
                martVendor.adminCommission?.commissionType ??
                Constant.adminCommission!.commissionType;
          } else {
            // Fallback to default values if no mart vendor found
            orderModel.vendorID = 'mart_default';
            // Create a default vendor object instead of setting to null
            orderModel.vendor = VendorModel(
              id: 'mart_default',
              title: 'Jippy Mart',
              location: 'Default Location',
              phonenumber: '0000000000',
              latitude: 15.48649,
              // Default Ongole coordinates for mart
              longitude: 80.04967,
              isOpen: true,
              vType: 'mart',
              author: 'default',
              authorName: 'Jippy Mart',
              authorProfilePic: null,
              adminCommission: AdminCommission(
                amount: Constant.adminCommission!.amount,
                commissionType: Constant.adminCommission!.commissionType,
                isEnabled: true,
              ),
            );
            orderModel.adminCommission = Constant.adminCommission!.amount;
            orderModel.adminCommissionType =
                Constant.adminCommission!.commissionType;
          }
        } catch (e) {
          orderModel.vendorID = 'mart_default';
          orderModel.vendor = VendorModel(
            id: 'mart_default',
            title: 'Jippy Mart',
            location: 'Default Location',
            phonenumber: '0000000000',
            latitude: 15.48649,
            // Default Ongole coordinates for mart
            longitude: 80.04967,
            isOpen: true,
            vType: 'mart',
            author: 'default',
            authorName: 'Jippy Mart',
            authorProfilePic: null,
            adminCommission: AdminCommission(
              amount: Constant.adminCommission!.amount,
              commissionType: Constant.adminCommission!.commissionType,
              isEnabled: true,
            ),
          );
          orderModel.adminCommission = Constant.adminCommission!.amount;
          orderModel.adminCommissionType =
              Constant.adminCommission!.commissionType;
        }
      }
      String admin_fee = "0";
      if (surgePercent > 0) {
        admin_fee = await getAdminSurgeFee();
      }
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
      orderModel.surgeFee = "${surgePercent + int.parse(admin_fee)}";
      if (vendorModel.id != null &&
          vendorModel.latitude != null &&
          vendorModel.longitude != null) {
        Constant.calculateDistance(
          vendorModel.latitude!,
          vendorModel.longitude!,
          selectedAddress?.location?.latitude ?? 0.0,
          selectedAddress?.location?.longitude ?? 0.0,
        );
        notifyListeners();
      }

      // Store the order
      await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .doc(orderModel.id)
          .set(orderModel.toJson());
      notifyListeners();
      final additionalTasks = <Future>[];
      if (orderModel.couponId != null && orderModel.couponId!.isNotEmpty) {
        additionalTasks.add(markCouponAsUsed(orderModel.couponId!));
      }

      additionalTasks.add(
        FirebaseFirestore.instance
            .collection('order_Billing')
            .doc(orderModel.id)
            .set({
              'orderId': orderModel.id,
              'ToPay': orderModel.toPayAmount,
              'createdAt': Timestamp.now(),
              'surge_fee': surgePercent,
              'admin_surge_fee': admin_fee,
              'total_surge_fee': "${surgePercent + int.parse(admin_fee)}",
            }),
      );
      if (orderModel.vendor != null && orderModel.vendor!.author != null) {
        additionalTasks.add(
          AddressListProvider.getUserProfile(
            orderModel.vendor!.author.toString(),
          ).then((value) {
            if (value != null) {
              if (orderModel.scheduleTime != null) {
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

      isPaymentInProgress = false;
      isPaymentCompleted = false;
      _lastPaymentId = null;
      _lastPaymentTime = null;

      await _clearPersistentPaymentState();

      ShowToastDialog.closeLoader();
      endOrderProcessing();
      notifyListeners();
      // Navigate to order success screen
      Get.off(
        const OrderPlacingScreen(),
        arguments: {"orderModel": orderModel},
      );
      notifyListeners();
    } catch (e) {
      ShowToastDialog.closeLoader();
      endOrderProcessing();

      if (isPaymentCompleted && _lastPaymentId != null) {
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

  CodSettingModel cashOnDeliverySettingModel = CodSettingModel();

  RazorPayModel razorPayModel = RazorPayModel();

  getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      razorPayModel = RazorPayModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.razorpaySettings)),
      );
      cashOnDeliverySettingModel = CodSettingModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.codSettings)),
      );
      if (cashOnDeliverySettingModel.isEnabled == true &&
          subTotal <= 599 &&
          !hasMartItemsInCart()) {
        selectedPaymentMethod = PaymentGateway.cod.name;
      } else if (razorPayModel.isEnabled == true) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
      }
      razorPay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
      razorPay?.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
      razorPay?.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
      checkAndUpdatePaymentMethod();
    });
    notifyListeners();
  }

  final RazorpayCrashPrevention _razorpayCrashPrevention =
      RazorpayCrashPrevention();

  Razorpay? get razorPay => _razorpayCrashPrevention.razorpayInstance;

  void openCheckout({required amount, required orderId}) async {
    if (isPaymentInProgress) {
      ShowToastDialog.showToast(
        "Payment is already in progress. Please wait...".tr,
      );
      return;
    }

    if (isPaymentCompleted) {
      ShowToastDialog.showToast(
        "Payment already completed. Please refresh the page.".tr,
      );
      return;
    }

    if (!_razorpayCrashPrevention.isInitialized) {
      print('🔑 Initializing Razorpay with crash prevention...');
      final initialized = await _razorpayCrashPrevention.safeInitialize(
        onSuccess: handlePaymentSuccess,
        onFailure: handlePaymentError,
        onExternalWallet: handleExternalWallet,
      );

      if (!initialized) {
        ShowToastDialog.showToast(
          "Payment system is temporarily unavailable. Please try again later."
              .tr,
        );
        return;
      }
    }

    // 🔑 SET PAYMENT IN PROGRESS STATE
    isPaymentInProgress = true;

    // 🔑 CRITICAL FIX: Validate Razorpay configuration before creating options
    if (razorPayModel.razorpayKey == null ||
        razorPayModel.razorpayKey!.isEmpty) {
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Payment configuration error. Please contact support.".tr,
      );
      return;
    }

    if (!razorPayModel.razorpayKey!.startsWith('rzp_')) {
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Payment configuration error. Please contact support.".tr,
      );
      return;
    }

    // 🔑 CRITICAL FIX: Convert amount to int to pass validation
    final int amountInPaise = (double.parse(amount.toString()) * 100).round();

    var options = {
      'key': razorPayModel.razorpayKey,
      'amount': amountInPaise, // ✅ FIXED: Now using int instead of double
      'name': 'GoRide',
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
    notifyListeners();
    try {
      final success = await _razorpayCrashPrevention.safeOpenPayment(options);
      if (success) {
      } else {
        isPaymentInProgress = false;
        ShowToastDialog.showToast(
          "Failed to open payment gateway. Please try again.".tr,
        );
      }
      notifyListeners();
    } catch (e) {
      // 🔑 RESET PAYMENT STATE ON ERROR
      isPaymentInProgress = false;
      ShowToastDialog.showToast(
        "Failed to open payment gateway. Please try again.".tr,
      );
      debugPrint('Error: $e');
    }
  }

  bool isGlobalLocked = false;

  /// ✅ NEW: Safe payment success handler with crash prevention
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    try {
      isGlobalLocked = true;
      _lastPaymentId = response.paymentId;
      _lastPaymentTime = DateTime.now();
      isPaymentCompleted = true;

      ShowToastDialog.showLoader("Processing payment and placing order...".tr);

      Future.delayed(const Duration(milliseconds: 500), () async {
        print('🔑 RAZORPAY SUCCESS - Starting order placement after delay');
        placeOrderAfterPayment();
        isGlobalLocked = false;
      });
      notifyListeners();
    } catch (e) {
      isGlobalLocked = false;
      isPaymentInProgress = false;
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

      // Show error message
      ShowToastDialog.showToast("Payment failed: ${response.message}".tr);
      notifyListeners();
    } catch (e) {
      isPaymentInProgress = false;
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
        throw Exception('Payment validation failed - no valid payment found');
      }

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

      if (selectedPaymentMethod == PaymentGateway.wallet.name) {
        if (double.parse(userModel.walletAmount.toString()) >= totalAmount) {
          await _setOrderInternal();
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "You don't have sufficient wallet balance to place order".tr,
          );
          endOrderProcessing();
        }
      } else {
        await _setOrderInternal();
      }
      notifyListeners();
    } catch (e) {
      ShowToastDialog.closeLoader();
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

  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  // Add this method to mark a coupon as used for the current user
  Future<void> markCouponAsUsed(String couponId) async {
    final userId = await SqlStorageConst.getFirebaseId();
    await FirebaseFirestore.instance.collection('used_coupons').add({
      'userId': userId,
      'couponId': couponId,
      'usedAt': FieldValue.serverTimestamp(),
    });
    // After marking as used, re-fetch coupon lists to update their status
    await getCartData();
  }

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
      bool hasMartItems = cartItem.any(
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
  Future<bool> _validateAddressBulletproof(BuildContext context) async {
    try {
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

      // CRITICAL CHECK 5: Address must have valid coordinates
      if (address.location == null ||
          address.location!.latitude == null ||
          address.location!.longitude == null ||
          address.location!.latitude == 0.0 ||
          address.location!.longitude == 0.0) {
        ShowToastDialog.showToast(
          "Please select a delivery address with valid location coordinates."
              .tr,
        );

        Get.to(() => const AddressListScreen());
        return false;
      }
      // CRITICAL CHECK 6: BLOCK ALL FALLBACK ZONES - NO EXCEPTIONS
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
        // 🔑 CRITICAL: Try to detect zone ID for addresses that don't have one
        String? detectedZoneId = await _detectZoneIdForCoordinates(
          address.location!.latitude!,
          address.location!.longitude!,
          context,
        );

        if (detectedZoneId != null) {
          address.zoneId = detectedZoneId;
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
