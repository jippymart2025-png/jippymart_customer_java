import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:jippymart_customer/utils/utils/common.dart'
    show unawaited, getHeaders;
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
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
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
import 'package:jippymart_customer/services/paytm_service.dart';
import 'package:jippymart_customer/services/smartlook_service.dart';
import 'package:jippymart_customer/services/coupon_filter_service.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/services/wallet_api_service.dart';
import 'package:jippymart_customer/services/mart_vendor_service.dart';
import 'package:jippymart_customer/services/promotional_cache_service.dart';
import 'package:jippymart_customer/utils/anr_prevention.dart';
import 'package:jippymart_customer/utils/delivery_charge_cache.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/razorpay_crash_prevention.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart'
    show unawaited, getHeaders;
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widgets/delivery_zone_alert_dialog.dart'
    show DeliveryZoneAlertDialog;
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../models/mart_item_model.dart';
import '../../../services/mart_firestore_service.dart';
import '../cart_screen.dart';

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

  // 🔑 RETRY MECHANISM: Timer for periodic retry of failed orders
  Timer? _pendingOrderRetryTimer;

  // 🔑 ORDER PROCESSING
  bool _isOrderBeingCreated = false;

  /// 🔑 CRITICAL: Start periodic retry for pending orders
  void _startPendingOrderRetryTimer() {
    // Cancel existing timer if any
    _pendingOrderRetryTimer?.cancel();

    // Check for pending orders every 30 seconds
    _pendingOrderRetryTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        final paymentState = Preferences.getString(_paymentStateKey);
        if (paymentState == 'true') {
          final savedPaymentId = Preferences.getString(_paymentIdKey);
          if (savedPaymentId.isNotEmpty && !_isOrderBeingCreated) {
            print(
              '🔄 [PERIODIC_RETRY] Found pending payment, attempting to place order...',
            );
            await checkPendingPaymentAndPlaceOrder();
          }
        } else {
          // No pending payment, cancel timer
          timer.cancel();
          _pendingOrderRetryTimer = null;
        }
      } catch (e) {
        print('❌ [PERIODIC_RETRY] Error in periodic retry: $e');
      }
    });
  }

  /// 🔑 CRITICAL: Stop periodic retry timer
  void _stopPendingOrderRetryTimer() {
    _pendingOrderRetryTimer?.cancel();
    _pendingOrderRetryTimer = null;
  }

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
  final Map<String, double> _cachedPromotionalBaseCharge =
      {}; // 🔑 NEW: Cache for promotional base charge
  List<TaxModel>? _cachedTaxList;
  bool _calculationCacheLoaded = false;

  // 🔑 PERFORMANCE: Cache cart item type checks to avoid repeated iterations
  bool? _cachedHasPromotionalItems;
  bool? _cachedHasMartItems;
  int _lastCartItemCount = 0;
  String? _lastCartItemHash; // Simple hash to detect cart changes
  String? _lastObservedProductSetHash;

  // 🔑 OPTIMIZATION: Cache distance calculation to avoid repeated calculations
  double? _cachedDistance;
  double? _cachedCustomerLat;
  double? _cachedCustomerLng;
  double? _cachedVendorLat;
  double? _cachedVendorLng;

  // 🔑 COUPON LOADING
  bool _isLoadingCoupons = false;
  String _currentContext = "restaurant";
  Future<void>? _couponLoadInFlight;
  Future<void>? _markUsedCouponsInFlight;
  DateTime? _lastUsedCouponsFetchAt;
  static const Duration _usedCouponsCacheExpiry = Duration(minutes: 2);
  Set<String> _cachedUsedCouponIds = <String>{};

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

  /// Call after changing [selectedPaymentMethod] from UI so listeners rebuild.
  void setSelectedPaymentMethod(String value) {
    if (selectedPaymentMethod == value) return;
    selectedPaymentMethod = value;
    notifyListeners();
  }

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
  Map<String, dynamic> _zonePaymentSettings = {};

  /// Use Wallet toggle: when true, apply wallet balance to order (split or full).
  bool useWalletBalance = false;

  /// Cached wallet balance (rupees) from GET /wallet (WalletApiService). Same source as wallet screen.
  double? _walletBalanceRupeesFromApi;

  /// Wallet balance in same unit as [totalAmount] (rupees). From GET /wallet (money_balance_paise) when available, else UserModel fallback.
  double get walletBalanceRupees {
    if (_walletBalanceRupeesFromApi != null) {
      return _walletBalanceRupeesFromApi!;
    }
    return (userModel.walletAmount != null)
        ? (userModel.walletAmount is int
              ? (userModel.walletAmount as int).toDouble()
              : (double.tryParse(userModel.walletAmount.toString()) ?? 0.0))
        : 0.0;
  }

  /// Fetches wallet balance from same API as wallet screen (GET /wallet).
  /// Uses money_balance_paise (paise -> rupees); fallback money_balance (rupees) if backend sends it.
  Future<void> refreshWalletBalance() async {
    try {
      final data = await WalletApiService.instance.getWallet();
      if (data == null) return;
      // Prefer money_balance_paise (API spec)
      final mb = data['money_balance_paise'];
      if (mb != null) {
        if (mb is int) {
          _walletBalanceRupeesFromApi = mb / 100.0;
        } else {
          final paise = int.tryParse(mb.toString());
          _walletBalanceRupeesFromApi = paise != null ? paise / 100.0 : null;
        }
      }
      // Fallback: backend may send money_balance in rupees
      if (_walletBalanceRupeesFromApi == null) {
        final rupeesRaw = data['money_balance'];
        if (rupeesRaw != null) {
          final r = rupeesRaw is num
              ? rupeesRaw.toDouble()
              : double.tryParse(rupeesRaw.toString());
          if (r != null) _walletBalanceRupeesFromApi = r;
        }
      }
    } catch (e) {
      // Keep previous cache or userModel fallback
    }
    notifyListeners();
  }

  /// Syncs balance from WalletProvider so cart shows same value as wallet screen (single source of truth).
  void syncWalletBalanceFromWallet(double rupees) {
    if (_walletBalanceRupeesFromApi != rupees) {
      _walletBalanceRupeesFromApi = rupees;
      notifyListeners();
    }
  }

  /// Amount to debit from wallet (single source of truth).
  /// Returns 0 when cart has promotional items (wallet not allowed for promos).
  double get walletToUse {
    if (isWalletDisabledByPromotions) return 0.0;
    return useWalletBalance
        ? (walletBalanceRupees <= 0
              ? 0.0
              : (totalAmount <= 0
                    ? 0.0
                    : (walletBalanceRupees >= totalAmount
                          ? totalAmount
                          : walletBalanceRupees)))
        : 0.0;
  }

  /// Amount to charge via payment gateway (COD or Razorpay). Single source of truth.
  double get paymentGatewayAmount =>
      totalAmount <= 0 ? 0.0 : (totalAmount - walletToUse);

  /// True when order is fully covered by wallet (no gateway needed).
  bool get isFullyPaidByWallet =>
      useWalletBalance && totalAmount > 0 && walletToUse >= totalAmount;

  /// Amount to charge via payment gateway (Razorpay/COD). When [useWalletBalance] is true, only the remainder after wallet.
  double get amountToChargeViaGateway =>
      useWalletBalance ? paymentGatewayAmount : totalAmount;

  /// True when coupons are disabled because "Use Wallet" is on.
  bool get isCouponDisabledByWallet => useWalletBalance;

  /// True when wallet cannot be used (e.g. cart contains promotional items).
  bool get isWalletDisabledByPromotions => hasPromotionalItems();

  Map<String, dynamic> _normalizeZonePaymentSettings(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final normalized = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key == null || value is! Map) return;
      normalized[key.toString()] = Map<String, dynamic>.from(value as Map);
    });
    return normalized;
  }

  bool? _parseFlexibleBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  double? _parseFlexibleDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String? get currentPaymentZoneId {
    final selectedLocationZoneId = Constant.selectedLocation.zoneId;
    if (selectedLocationZoneId != null && selectedLocationZoneId.isNotEmpty) {
      return selectedLocationZoneId;
    }
    return null;
  }

  bool? _readZonePaymentFlag(String key) {
    final zoneId = currentPaymentZoneId;
    if (zoneId == null || zoneId.isEmpty) return null;
    final zoneConfig = _zonePaymentSettings[zoneId];
    if (zoneConfig is! Map) return null;
    return _parseFlexibleBool(zoneConfig[key]);
  }

  bool get isCodEnabledForCurrentZone =>
      _readZonePaymentFlag('cod') ?? (cashOnDeliverySettingModel.isEnabled == true);

  bool get isRazorpayEnabledForCurrentZone =>
      _readZonePaymentFlag('razorpay') ?? (razorPayModel.isEnabled == true);

  double get codMaxAmountForCurrentZone {
    final zoneId = currentPaymentZoneId;
    if (zoneId != null && zoneId.isNotEmpty) {
      final zoneConfig = _zonePaymentSettings[zoneId];
      if (zoneConfig is Map) {
        final parsed = _parseFlexibleDouble(zoneConfig['maxAmount']);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return cashOnDeliverySettingModel.getMaxAmount();
  }

  /// Sets [useWalletBalance]. When turning on, clears coupon and recalculates (no change to other price logic).
  /// Does nothing if [value] is true and cart has promotional items (wallet not allowed for promos).
  Future<void> setUseWalletBalance(bool value) async {
    if (value && isWalletDisabledByPromotions) {
      ShowToastDialog.showToast(
        "Wallet cannot be used for orders with promotional items.".tr,
      );
      return;
    }
    if (value && !useWalletBalance) {
      selectedCouponModel = CouponModel();
      couponCodeController.text = '';
      couponAmount = 0.0;
      await calculatePrice();
    }
    useWalletBalance = value;
    checkAndUpdatePaymentMethod();
    notifyListeners();
  }

  bool _hasActiveCouponApplied() {
    return (selectedCouponModel.id != null &&
            selectedCouponModel.id!.isNotEmpty) ||
        couponCodeController.text.trim().isNotEmpty ||
        couponAmount > 0;
  }

  String _generateProductSetHashFromItems(List<CartProductModel> items) {
    if (items.isEmpty) return 'empty';
    final ids =
        items.map((item) => item.id ?? '').where((id) => id.isNotEmpty).toList()
          ..sort();
    return ids.join('|');
  }

  void _clearAppliedCouponState({bool showMessage = false}) {
    selectedCouponModel = CouponModel();
    couponCodeController.clear();
    couponAmount = 0.0;
    if (showMessage) {
      ShowToastDialog.showToast("Coupon removed because cart items changed".tr);
    }
  }

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
      // Wallet is refreshed from WalletProvider when opening cart from CartScreen; fallback only if needed (e.g. deep link to cart)

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (subTotal > codMaxAmountForCurrentZone &&
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

        // 🔑 OPTIMIZATION: Invalidate distance cache when address changes
        _cachedDistance = null;
        _cachedCustomerLat = null;
        _cachedCustomerLng = null;

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

        // 🔑 OPTIMIZATION: Invalidate distance cache when address changes
        _cachedDistance = null;
        _cachedCustomerLat = null;
        _cachedCustomerLng = null;

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

          // 🔑 OPTIMIZATION: Invalidate cart type cache at start of calculation
          _invalidateCartTypeCache();

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

          // 🔑 OPTIMIZATION: Single notifyListeners call at the end
          // This prevents multiple UI rebuilds during calculation
          notifyListeners();
        },
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      print('[CART_PRICE] ❌ Calculation failed: $e');
      // 🔑 OPTIMIZATION: Notify listeners even on error to update UI state
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

    // 🔑 OPTIMIZATION: Pre-parse values once and reuse
    for (var element in HomeProvider.cartItem) {
      final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;

      // 🔑 OPTIMIZATION: Parse once and reuse
      final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
      final discountPriceValue =
          double.tryParse(element.discountPrice.toString()) ?? 0.0;

      double itemPrice;
      if (hasPromo) {
        itemPrice = priceValue;
      } else if (discountPriceValue <= 0) {
        itemPrice = priceValue;
      } else {
        itemPrice = discountPriceValue;
      }

      final quantity = double.tryParse(element.quantity.toString()) ?? 0.0;
      final extrasPrice =
          double.tryParse(element.extrasPrice.toString()) ?? 0.0;

      subTotal += (itemPrice * quantity) + (extrasPrice * quantity);
    }

    // 🔑 OPTIMIZATION: Invalidate cart type cache when subtotal changes
    _invalidateCartTypeCache();
  }

  double _calculateCouponBaseAmount() {
    double baseAmount = 0.0;

    for (var element in HomeProvider.cartItem) {
      final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
      final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
      final discountPriceValue =
          double.tryParse(element.discountPrice.toString()) ?? 0.0;

      double itemPrice;
      if (hasPromo) {
        itemPrice = priceValue;
      } else if (discountPriceValue <= 0) {
        itemPrice = priceValue;
      } else {
        itemPrice = discountPriceValue;
      }

      final quantity = double.tryParse(element.quantity.toString()) ?? 0.0;
      baseAmount += itemPrice * quantity;
    }

    return baseAmount;
  }

  bool _isPercentageDiscountType(String? discountType) {
    final normalizedDiscountType = (discountType ?? '').trim().toLowerCase();
    return normalizedDiscountType == "percentage" ||
        normalizedDiscountType.contains("percent");
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

      // 🔑 OPTIMIZATION: Only recalculate distance if coordinates changed
      if (_cachedDistance == null ||
          _cachedCustomerLat != customerLat ||
          _cachedCustomerLng != customerLng ||
          _cachedVendorLat != vendorLat ||
          _cachedVendorLng != vendorLng) {
        final distanceString = Constant.getDistance(
          lat1: customerLat.toString(),
          lng1: customerLng.toString(),
          lat2: vendorLat.toString(),
          lng2: vendorLng.toString(),
        );

        _cachedDistance = double.parse(distanceString);
        _cachedCustomerLat = customerLat;
        _cachedCustomerLng = customerLng;
        _cachedVendorLat = vendorLat;
        _cachedVendorLng = vendorLng;
      }

      totalDistance = _cachedDistance!;
    } else {
      totalDistance = 0.0;
      _cachedDistance = null;
    }

    // 🔑 OPTIMIZATION: Use cached cart item type checks
    final hasPromotionalItems = _getCachedHasPromotionalItems();
    final hasMartItems = _getCachedHasMartItems();

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
    } else if (couponCodeController.text.trim().isNotEmpty) {
      // 🔑 OPTIMIZATION: Cache coupon lookup
      final enteredCode = couponCodeController.text.trim().toLowerCase();
      activeCoupon = couponList.firstWhere(
        (element) => (element.code ?? '').trim().toLowerCase() == enteredCode,
        orElse: CouponModel.new,
      );
      if ((activeCoupon.id ?? '').isEmpty &&
          (activeCoupon.code ?? '').isEmpty) {
        activeCoupon = null;
      }
    }

    // 🔑 OPTIMIZATION: Use cached promotional items check
    final hasPromotionalItems = _getCachedHasPromotionalItems();

    if (hasPromotionalItems && activeCoupon != null) {
      ShowToastDialog.showToast(
        "Coupons cannot be applied to promotional items".tr,
      );
      couponCodeController.text = "";
      selectedCouponModel = CouponModel();
      couponAmount = 0.0;
    } else if (activeCoupon != null) {
      final couponBaseAmount = _calculateCouponBaseAmount();
      final minimumValue =
          double.tryParse(activeCoupon.itemValue ?? '0') ?? 0.0;
      if (couponBaseAmount < minimumValue) {
        ShowToastDialog.showToast(
          "Minimum order value for this coupon is ${Constant.amountShow(amount: activeCoupon.itemValue ?? '0')}"
              .tr,
        );
        couponCodeController.text = "";
        selectedCouponModel = CouponModel();
        couponAmount = 0.0;
      } else {
        final discountValue =
            double.tryParse(activeCoupon.discount.toString()) ?? 0.0;
        final isPercentageDiscount = _isPercentageDiscountType(
          activeCoupon.discountType,
        );

        if (isPercentageDiscount) {
          couponAmount = (couponBaseAmount * discountValue) / 100;
        } else {
          couponAmount = discountValue;
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

    // 🔑 OPTIMIZATION: Use cached cart item type checks
    final hasPromotionalItemsForTax = _getCachedHasPromotionalItems();
    final hasMartItems = _getCachedHasMartItems();

    // 🔑 FIX: For promotional items, always use originalDeliveryFee (which includes base charge)
    // This ensures 18% GST is calculated on base charge even when delivery is free
    final double taxableDeliveryFee;
    if (hasPromotionalItemsForTax) {
      // For promotional items, originalDeliveryFee should always include base charge for GST
      taxableDeliveryFee = originalDeliveryFee > 0
          ? originalDeliveryFee
          : (deliveryCharges > 0 ? deliveryCharges : 0.0);
      print(
        '[TAX_CALC] Promotional items - Using originalDeliveryFee: ₹$originalDeliveryFee for GST calculation',
      );
    } else {
      // For non-promotional items, use existing logic
      taxableDeliveryFee = originalDeliveryFee > 0
          ? originalDeliveryFee
          : (deliveryCharges > 0 ? deliveryCharges : 0.0);
    }

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
      // 🔑 OPTIMIZATION: Use cached cart item type checks
      final hasPromotionalItems = _getCachedHasPromotionalItems();
      final hasMartItems = _getCachedHasMartItems();

      if (hasPromotionalItems) {
        final promotionalItems = HomeProvider.cartItem
            .where((item) => item.promoId != null && item.promoId!.isNotEmpty)
            .toList();

        final firstPromoItem = promotionalItems.first;
        final cacheKey = '${firstPromoItem.id}-${firstPromoItem.vendorID}';

        // 🔑 CRITICAL FIX: For promotional items, always use promotional free delivery km
        // Check promotion cache first, then cached map, then use promotional default
        double freeDeliveryKm;
        final promoDetails = _promotionalCalculationCache[cacheKey];
        if (promoDetails != null) {
          final promoFreeKm = (promoDetails['free_delivery_km'] as num?)
              ?.toDouble();
          if (promoFreeKm != null && promoFreeKm > 0) {
            freeDeliveryKm = promoFreeKm;
          } else if (_cachedFreeDeliveryKm.containsKey(cacheKey)) {
            freeDeliveryKm = _cachedFreeDeliveryKm[cacheKey]!;
          } else {
            freeDeliveryKm = 4.0; // Promotional default
          }
        } else if (_cachedFreeDeliveryKm.containsKey(cacheKey)) {
          freeDeliveryKm = _cachedFreeDeliveryKm[cacheKey]!;
        } else {
          freeDeliveryKm = 4.0; // Promotional default, NOT global
        }

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
      bool variantMetaChanged = false;
      List<PriceUpdateResult> allUpdates = [];

      // Process batches in parallel but with rate limiting
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        print('[PRICE_SYNC] 📦 Processing batch ${i + 1}/${batches.length}');

        try {
          final batchOutcome = await validateAndUpdateCartPricesForBatch(batch);
          final batchUpdates = batchOutcome.results;
          final foodByCatalogId = batchOutcome.foodByCatalogId;
          final martByLineId = batchOutcome.martByLineId;

          for (var entry in batchUpdates.entries) {
            final result = entry.value;

            if (result.status == PriceStatus.error ||
                result.status == PriceStatus.productNotFound) {
              continue;
            }

            final catalogId = _catalogProductIdForFetch(result.productId);
            final prefetchedFood =
                catalogId.isNotEmpty ? foodByCatalogId[catalogId] : null;
            final prefetchedMart = martByLineId[result.productId];

            if (result.hasPriceChange &&
                result.oldPrice != null &&
                result.newPrice != null) {
              hasUpdates = true;
              allUpdates.add(result);

              await _updateCartItemPrice(
                result,
                prefetchedFood: prefetchedFood,
                prefetchedMart: prefetchedMart,
              );

              print(
                '[PRICE_SYNC] ✅ Updated ${result.productName}: ₹${result.oldPrice} → ₹${result.newPrice}',
              );
            } else {
              final persisted = await _persistVariantInfoSyncForProductId(
                result.productId,
                prefetchedFood: prefetchedFood,
              );
              if (persisted) {
                variantMetaChanged = true;
                print(
                  '[PRICE_SYNC] ✅ Synced variant/option fields for ${result.productId}',
                );
              }
            }

            _operationTimestamps['sync_${result.productId}'] = DateTime.now();
            _recentlySyncedItems.add(result.productId);
          }

          if (i < batches.length - 1) {
            await Future.delayed(const Duration(milliseconds: 60));
          }
        } catch (e) {
          print('[PRICE_SYNC] ❌ Error in batch ${i + 1}: $e');
        }
      }

      // Update timestamp
      _operationTimestamps[lastSyncKey] = DateTime.now();

      if (hasUpdates || variantMetaChanged) {
        if (hasUpdates) {
          print(
            '[PRICE_SYNC] ✅ Sync complete with ${allUpdates.length} line updates',
          );
        }
        if (variantMetaChanged && !hasUpdates) {
          print('[PRICE_SYNC] ✅ Sync complete (variant/option metadata only)');
        }

        _priceSyncVersion++;
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(calculatePrice());
        });

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

  /// Compares [cartItem] with already-fetched catalog [currentProduct] (no I/O).
  PriceUpdateResult _priceUpdateResultFromFetchedProduct(
    CartProductModel cartItem,
    dynamic currentProduct,
  ) {
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
    }
    return PriceUpdateResult(
      productId: cartItem.id!,
      status: PriceStatus.noChange,
      oldPrice: storedDisplayPrice.toStringAsFixed(2),
      newPrice: currentPrice.toStringAsFixed(2),
    );
  }

  /// One HTTP round-trip per unique catalog id + parallel mart reads.
  /// Returns maps so callers can apply updates without re-fetching each product.
  Future<
      ({
        Map<String, PriceUpdateResult> results,
        Map<String, ProductModel?> foodByCatalogId,
        Map<String, MartItemModel?> martByLineId,
      })> validateAndUpdateCartPricesForBatch(
    List<CartProductModel> batch,
  ) async {
    final Map<String, PriceUpdateResult> results = {};

    final foodCatalogIds = <String>{};
    final martLineIds = <String>{};

    for (final cartItem in batch) {
      if (cartItem.id == null || cartItem.id!.isEmpty) continue;
      if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) continue;
      if (_isMartItem(cartItem)) {
        martLineIds.add(cartItem.id!);
      } else {
        final cid = _catalogProductIdForFetch(cartItem.id!);
        if (cid.isNotEmpty) foodCatalogIds.add(cid);
      }
    }

    var foodByCatalogId = <String, ProductModel?>{};
    var martByLineId = <String, MartItemModel?>{};

    try {
      await Future.wait([
        Future(() async {
          if (foodCatalogIds.isEmpty) return;
          final fetched = await FireStoreUtils.getProductsByIds(
            foodCatalogIds.toList(),
            forceRefresh: true,
          );
          foodByCatalogId.addAll(fetched);
        }),
        Future(() async {
          if (martLineIds.isEmpty) return;
          final martService = Get.find<MartFirestoreService>();
          await Future.wait(
            martLineIds.map((lineId) async {
              try {
                martByLineId[lineId] = await martService.getItemById(lineId);
              } catch (_) {
                martByLineId[lineId] = null;
              }
            }),
          );
        }),
      ]);
    } catch (e) {
      print('[BATCH_VALIDATE] ❌ Prefetch failed: $e');
      foodByCatalogId = {};
      martByLineId = {};
    }

    Future<PriceUpdateResult?> validateOne(CartProductModel cartItem) async {
      try {
        if (cartItem.id == null || cartItem.id!.isEmpty) {
          return PriceUpdateResult(
            productId: cartItem.id ?? 'unknown',
            status: PriceStatus.error,
            error: 'Invalid product ID',
          );
        }

        if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) {
          return PriceUpdateResult(
            productId: cartItem.id!,
            status: PriceStatus.noChange,
            oldPrice: cartItem.price,
            newPrice: cartItem.price,
            productName: cartItem.name,
          );
        }

        if (_isMartItem(cartItem)) {
          return _priceUpdateResultFromFetchedProduct(
            cartItem,
            martByLineId[cartItem.id!],
          );
        }

        final catalogId = _catalogProductIdForFetch(cartItem.id!);
        if (catalogId.isEmpty) {
          return PriceUpdateResult(
            productId: cartItem.id!,
            status: PriceStatus.error,
            oldPrice: cartItem.price,
            productName: cartItem.name,
            error: 'Invalid catalog product id',
          );
        }
        return _priceUpdateResultFromFetchedProduct(
          cartItem,
          foodByCatalogId[catalogId],
        );
      } catch (e) {
        print('[BATCH_VALIDATE] ❌ Error validating ${cartItem.id}: $e');
        return PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.error,
          oldPrice: cartItem.price,
          error: e.toString(),
        );
      }
    }

    try {
      final batchResults = await Future.wait(
        batch.map(validateOne),
        eagerError: false,
      );

      for (var result in batchResults) {
        if (result != null) {
          results[result.productId] = result;
        }
      }
    } catch (e) {
      print('[BATCH_VALIDATE] ❌ Batch validation failed: $e');
    }

    return (
      results: results,
      foodByCatalogId: foodByCatalogId,
      martByLineId: martByLineId,
    );
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

  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final paymentId = response.paymentId;
      final signature = response.signature;
      print("✅ [PAYMENT_SUCCESS] Payment received: $paymentId");

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

      // 🔑 CRITICAL: Lock immediately to prevent concurrent processing
      _lockGlobal();

      // 🔑 CRITICAL: Set payment state immediately (synchronous)
      _lastPaymentId = paymentId;
      _lastPaymentTime = DateTime.now();
      isPaymentCompleted = true;

      // 🔑 CRITICAL: Store payment state persistently FIRST (before any async operations)
      // This ensures recovery even if app closes immediately
      _savePaymentStatePersistently(paymentId, signature);

      // 🔑 OPTIMIZATION: Show loader in background, don't block
      try {
        ShowToastDialog.showLoader("Placing your order...".tr);
      } catch (e) {
        print(
          '⚠️ [PAYMENT_SUCCESS] Could not show loader (app may be closing): $e',
        );
      }

      // 🔑 CRITICAL: Try to place order once in foreground so success is reliable.
      // If first attempt fails (e.g. network), fall back to background retries.
      try {
        await placeOrderAfterPayment();
        // Success: setOrder() already closed loader and navigated to OrderPlacingScreen
        notifyListeners();
        return;
      } catch (firstError) {
        print(
          '⚠️ [PAYMENT_SUCCESS] First order placement failed, starting background retries: $firstError',
        );
        try {
          ShowToastDialog.closeLoader();
        } catch (_) {}
      }

      // First attempt failed: run retries in background (same as before)
      _placeOrderInBackgroundImmediately(paymentId, signature);

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [PAYMENT_SUCCESS] Exception in handlePaymentSuccess: $e');
      print('❌ [PAYMENT_SUCCESS] Stack trace: $stackTrace');

      // Use the unlock method instead of direct assignment
      _unlockGlobal();

      isPaymentInProgress = false;
      _isOrderBeingCreated = false;

      if (response.paymentId != null) {
        _processedPaymentIds.remove(response.paymentId);
      }

      try {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Payment processing failed. Please try again.".tr,
        );
      } catch (e) {
        print(
          '⚠️ [PAYMENT_SUCCESS] Could not show toast (app may be closing): $e',
        );
      }
      notifyListeners();
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    try {
      ShowToastDialog.closeLoader();
      isPaymentInProgress = false;
      endOrderProcessing();

      ShowToastDialog.showToast("Payment failed: ${response.message}".tr);
      notifyListeners();
    } catch (e) {
      ShowToastDialog.closeLoader();
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

      // Wallet: do not place order when total amount exceeds wallet balance
      if (selectedPaymentMethod == PaymentGateway.wallet.name) {
        if (totalAmount > walletBalanceRupees) {
          ShowToastDialog.showToast(
            "You don't have sufficient wallet balance to place order".tr,
          );
          endOrderProcessing();
          return;
        }
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
        DeliveryZoneAlertDialog.showZoneMismatchError();
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
      if (!isCodEnabledForCurrentZone) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available in your zone. Please select another payment method."
              .tr,
        );
        endOrderProcessing();
        return;
      }

      final codAmountCheck = useWalletBalance
          ? amountToChargeViaGateway
          : totalAmount;
      if (codAmountCheck > codMaxAmountForCurrentZone) {
        ShowToastDialog.showToast(
          "Cash on Delivery is not available for orders above ₹${codMaxAmountForCurrentZone.toStringAsFixed(0)}. Please select another payment method."
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

  Future<void> _processPaytmOrder() async {
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
      print('❌ [PAYTM_ORDER] Error: $e');
      ShowToastDialog.closeLoader();
      endOrderProcessing();
      ShowToastDialog.showToast(
        "Failed to process order. Please try again.".tr,
      );
    }
  }

  Future<void> _processWalletOrder() async {
    try {
      if (walletBalanceRupees >= totalAmount) {
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
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Payment validation failed. Please try again.".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_PLACEMENT] Could not show UI (app may be closing): $e',
          );
        }
        _unlockGlobal();
        return;
      }

      // Check if order is already being created
      if (_isOrderBeingCreated || _isOrderCreationInProgress) {
        print('⚠️ [ORDER_PLACEMENT] Order creation already in progress');
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Order is already being processed. Please wait...".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_PLACEMENT] Could not show UI (app may be closing): $e',
          );
        }
        _unlockGlobal();
        return;
      }

      _isOrderBeingCreated = true;
      print(
        '🚀 [ORDER_PLACEMENT] Starting IMMEDIATE order placement for payment: $_lastPaymentId',
      );

      // Validate cart items
      if (HomeProvider.cartItem.isEmpty) {
        print('❌ [ORDER_PLACEMENT] Cart is empty');
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Your cart is empty. Please add items before placing order.".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_PLACEMENT] Could not show UI (app may be closing): $e',
          );
        }
        _isOrderBeingCreated = false;
        _unlockGlobal();
        // 🔑 CRITICAL: Clear persistent state if cart is empty
        await _clearPersistentPaymentState();
        return;
      }

      // 🔑 CRITICAL: Show loader only if app is in foreground (non-blocking)
      // Don't block order placement if UI is not available (app backgrounded)
      try {
        ShowToastDialog.showLoader("Placing your order...".tr);
      } catch (e) {
        print(
          '⚠️ [ORDER_PLACEMENT] Could not show loader (app may be backgrounded): $e',
        );
        // Continue with order placement even if loader fails
      }

      // 🔑 CRITICAL: Call the actual order creation immediately
      // This API call will execute even if app is in background
      print(
        '🌐 [ORDER_CREATION_FLOW] placeOrderAfterPayment → setOrder (payment_id=$_lastPaymentId)',
      );
      try {
        // 🔑 CRITICAL: setOrder() makes API calls directly - works in background
        await setOrder();

        // 🔑 CRITICAL: Clear persistent payment state after successful order placement
        // This ensures we don't retry placing the same order
        await _clearPersistentPaymentState();
        print(
          '✅ [ORDER_PLACEMENT] Order placed successfully. Persistent state cleared.',
        );
      } catch (orderError, orderStackTrace) {
        print('❌ [ORDER_PLACEMENT] Error in setOrder: $orderError');
        print('❌ [ORDER_PLACEMENT] Stack trace: $orderStackTrace');

        // Re-throw to be caught by retry mechanism
        rethrow;
      }
    } catch (e, stackTrace) {
      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      if (_lastPaymentId != null) {
        _processedPaymentIds.remove(_lastPaymentId);
      }

      // 🔑 CRITICAL: Close loader and show error only if app is in foreground
      // Don't block or fail if app is backgrounded
      try {
        ShowToastDialog.closeLoader();
        if (e.toString().contains('Delivery zone validation failed') ||
            e.toString().contains('Delivery distance validation failed')) {
          DeliveryZoneAlertDialog.showZoneMismatchError();
        } else {
          ShowToastDialog.showToast(
            "An error occurred while placing your order. Your payment is safe. Please try again."
                .tr,
          );
        }
      } catch (uiError) {
        print(
          '⚠️ [ORDER_PLACEMENT] Could not show UI (app may be backgrounded): $uiError',
        );
        // Continue - order placement will retry automatically
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
      await FireStoreUtils.getPaymentSettingsData();

      try {
        final razorpaySettingsStr = Preferences.getString(
          Preferences.razorpaySettings,
        );
        final codSettingsStr = Preferences.getString(
          Preferences.codSettings,
        );
        final zonePaymentSettingsStr = Preferences.getString(
          Preferences.zonePaymentSettings,
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
        if (zonePaymentSettingsStr.isNotEmpty) {
          _zonePaymentSettings = _normalizeZonePaymentSettings(
            jsonDecode(zonePaymentSettingsStr),
          );
        } else {
          _zonePaymentSettings = {};
        }

        // If COD is disabled and currently selected, clear and recalculate.
        if (selectedPaymentMethod == PaymentGateway.cod.name &&
            !isCodEnabledForCurrentZone) {
          selectedPaymentMethod = '';
          print('[PAYMENT_SETTINGS] COD is disabled, clearing COD selection');
        }

        if (isCodEnabledForCurrentZone &&
            subTotal <= codMaxAmountForCurrentZone &&
            !hasMartItemsInCart()) {
          selectedPaymentMethod = PaymentGateway.cod.name;
        } else if (isRazorpayEnabledForCurrentZone) {
          selectedPaymentMethod = PaymentGateway.razorpay.name;
        }

        // Pre-initialize Razorpay to reduce checkout interaction latency.
        if (isRazorpayEnabledForCurrentZone &&
            razorPayModel.razorpayKey != null &&
            razorPayModel.razorpayKey!.isNotEmpty) {
          _preInitializeRazorpay();
        }

        checkAndUpdatePaymentMethod();
      } catch (e) {
        print('[CART_PROVIDER] Error parsing payment settings: $e');
        if (isRazorpayEnabledForCurrentZone) {
          selectedPaymentMethod = PaymentGateway.razorpay.name;
          _preInitializeRazorpay();
        }
        notifyListeners();
      }
    } catch (e) {
      print('[CART_PROVIDER] Error in getPaymentSettings: $e');
      if (isRazorpayEnabledForCurrentZone) {
        selectedPaymentMethod = PaymentGateway.razorpay.name;
        _preInitializeRazorpay();
      }
      notifyListeners();
    }
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

  /// Cart rows use `baseId~variantId`; product APIs only accept [baseId].
  String _catalogProductIdForFetch(String? cartRowId) {
    if (cartRowId == null || cartRowId.isEmpty) return '';
    final t = cartRowId.trim();
    if (t.toLowerCase() == 'null') return '';
    final tilde = t.indexOf('~');
    if (tilde <= 0) return t;
    return t.substring(0, tilde).trim();
  }

  double _storedCartUnitDisplayPrice(CartProductModel cartItem) {
    final d = double.tryParse(cartItem.discountPrice ?? '0') ?? 0.0;
    final p = double.tryParse(cartItem.price ?? '0') ?? 0.0;
    if (d > 0 && d < p) return d;
    return p;
  }

  bool _idsLooselyEqual(String? a, String? b) {
    if (a == null || b == null) return false;
    final as = a.trim();
    final bs = b.trim();
    if (as.isEmpty || bs.isEmpty) return false;
    if (as == bs) return true;
    final ai = int.tryParse(as);
    final bi = int.tryParse(bs);
    if (ai != null && bi != null && ai == bi) return true;
    return false;
  }

  ProductOption? _matchProductOption(
    ProductModel product,
    VariantInfo? vi,
  ) {
    if (vi == null || product.options == null || product.options!.isEmpty) {
      return null;
    }
    final vid = vi.variantId?.trim();
    if (vid != null && vid.isNotEmpty && vid != '0') {
      for (final o in product.options!) {
        if (_idsLooselyEqual(o.id, vid)) return o;
      }
    }
    final sku = vi.variantSku?.trim();
    if (sku != null && sku.isNotEmpty) {
      for (final o in product.options!) {
        if (o.subtitle == sku || o.title == sku) return o;
      }
    }
    return null;
  }

  Variants? _matchItemAttributeVariant(
    ProductModel product,
    VariantInfo? vi,
  ) {
    if (vi == null || product.itemAttribute?.variants == null) return null;
    final vars = product.itemAttribute!.variants!;
    final vid = vi.variantId?.trim();
    if (vid != null && vid.isNotEmpty && vid != '0') {
      for (final v in vars) {
        if (_idsLooselyEqual(v.variantId, vid)) return v;
      }
    }
    final sku = vi.variantSku?.trim();
    if (sku != null && sku.isNotEmpty) {
      try {
        return vars.firstWhere((v) => v.variantSku == sku);
      } catch (_) {}
    }
    return null;
  }

  /// Updates [vi] from live [product] (option / attribute variant prices and
  /// `variant_options` merchant_price when applicable). Returns true if any field changed.
  bool _syncVariantInfoFieldsFromProduct(VariantInfo vi, ProductModel product) {
    bool changed = false;
    final opt = _matchProductOption(product, vi);
    if (opt != null) {
      final newVp = opt.price ?? '0';
      if (vi.variantPrice != newVp) {
        vi.variantPrice = newVp;
        changed = true;
      }
      final merchantVal =
          (opt.originalPrice != null && opt.originalPrice!.trim().isNotEmpty)
          ? opt.originalPrice!
          : newVp;
      if (vi.variantOptions is Map) {
        final m = Map<String, dynamic>.from(vi.variantOptions as Map);
        final prevMerchant = m['merchant_price']?.toString();
        if (prevMerchant != merchantVal) {
          m['merchant_price'] = merchantVal;
          vi.variantOptions = m;
          changed = true;
        }
      } else if (merchantVal.isNotEmpty) {
        vi.variantOptions = <String, dynamic>{
          if (vi.variantOptions is Map)
            ...Map<String, dynamic>.from(vi.variantOptions as Map),
          'merchant_price': merchantVal,
        };
        changed = true;
      }
      return changed;
    }

    final variant = _matchItemAttributeVariant(product, vi);
    if (variant != null) {
      final newVp = variant.variantPrice ?? '0';
      if (vi.variantPrice != newVp) {
        vi.variantPrice = newVp;
        changed = true;
      }
      final img = variant.variantImage;
      if (img != null &&
          img.isNotEmpty &&
          vi.variantImage != img) {
        vi.variantImage = img;
        changed = true;
      }
    }
    return changed;
  }

  /// Persists `variant_info` (option price, merchant_price in variant_options map, etc.)
  /// for all cart rows with [productId], when line price was already correct.
  Future<bool> _persistVariantInfoSyncForProductId(
    String productId, {
    ProductModel? prefetchedFood,
  }) async {
    bool anyChanged = false;
    for (int i = 0; i < HomeProvider.cartItem.length; i++) {
      final cartItem = HomeProvider.cartItem[i];
      if (cartItem.id != productId) continue;
      if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) continue;
      if (cartItem.variantInfo == null) continue;
      if (_isMartItem(cartItem)) continue;
      if (cartItem.id == null || cartItem.id!.isEmpty) continue;

      try {
        final catalogId = _catalogProductIdForFetch(cartItem.id!);
        if (catalogId.isEmpty) continue;
        ProductModel? currentProduct = prefetchedFood;
        currentProduct ??= await FireStoreUtils.getProductById(
          catalogId,
          forceRefresh: true,
        );
        if (currentProduct is! ProductModel) continue;
        bool rowChanged = _syncVariantInfoFieldsFromProduct(
          cartItem.variantInfo!,
          currentProduct,
        );
        final live = _getCurrentProductPrice(currentProduct, cartItem);
        final storedDiscount =
            double.tryParse(cartItem.discountPrice ?? '0') ?? 0.0;
        final storedReg = double.tryParse(cartItem.price ?? '0') ?? 0.0;
        final storedDisplay =
            storedDiscount > 0 && storedDiscount < storedReg
            ? storedDiscount
            : storedReg;
        if ((live - storedDisplay).abs() > 0.01) {
          cartItem.price = live.toStringAsFixed(2);
          cartItem.discountPrice = '0';
          rowChanged = true;
        }
        if (rowChanged) {
          anyChanged = true;
          await DatabaseHelper.instance.updateCartProduct(cartItem);
          HomeProvider.cartItem[i] = cartItem;
        }
      } catch (e) {
        print('[PRICE_SYNC] variant metadata sync error: $e');
      }
    }
    return anyChanged;
  }

  double _getCurrentProductPrice(dynamic product, CartProductModel cartItem) {
    try {
      if (cartItem.variantInfo != null && product is ProductModel) {
        final opt = _matchProductOption(product, cartItem.variantInfo);
        if (opt != null && opt.price != null) {
          if (vendorModel.id != null) {
            return double.parse(
              Constant.productCommissionPrice(
                vendorModel,
                opt.price ?? '0',
              ),
            );
          }
          return double.tryParse(opt.price ?? '0') ?? 0.0;
        }

        final variant = _matchItemAttributeVariant(
          product,
          cartItem.variantInfo,
        );
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

        final rawVp = cartItem.variantInfo?.variantPrice?.trim();
        final rawParsed = rawVp != null ? double.tryParse(rawVp) : null;
        if (rawParsed != null && rawParsed > 0) {
          if (vendorModel.id != null) {
            return double.parse(
              Constant.productCommissionPrice(vendorModel, rawVp),
            );
          }
          return rawParsed;
        }

        return _storedCartUnitDisplayPrice(cartItem);
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

  Future<void> _updateCartItemPrice(
    PriceUpdateResult result, {
    ProductModel? prefetchedFood,
    MartItemModel? prefetchedMart,
  }) async {
    try {
      final cartItemIndex = HomeProvider.cartItem.indexWhere(
        (item) => item.id == result.productId,
      );

      if (cartItemIndex < 0) return;

      final cartItem = HomeProvider.cartItem[cartItemIndex];
      final isMart = _isMartItem(cartItem);

      dynamic currentProduct;

      if (isMart) {
        currentProduct = prefetchedMart;
        if (currentProduct == null) {
          final martService = Get.find<MartFirestoreService>();
          currentProduct = await martService.getItemById(cartItem.id!);
        }
      } else {
        final catalogId = _catalogProductIdForFetch(cartItem.id!);
        currentProduct = prefetchedFood;
        if (currentProduct == null && catalogId.isNotEmpty) {
          currentProduct = await FireStoreUtils.getProductById(
            catalogId,
            forceRefresh: true,
          );
        }
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
          if (cartItem.variantInfo != null) {
            cartItem.discountPrice = "0";
          } else if (currentProduct.disPrice != null &&
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

      if (cartItem.variantInfo != null && currentProduct is ProductModel) {
        _syncVariantInfoFieldsFromProduct(
          cartItem.variantInfo!,
          currentProduct,
        );
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
      final newProductSetHash = _generateProductSetHashFromItems(event);
      final productSetChanged =
          _lastObservedProductSetHash != null &&
          _lastObservedProductSetHash != newProductSetHash;
      _lastObservedProductSetHash = newProductSetHash;

      if (productSetChanged && _hasActiveCouponApplied()) {
        _clearAppliedCouponState(showMessage: true);
      }

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
      // Use delivery charge cache utility for dynamic delivery charges
      final value = await DeliveryChargeCache.instance.getDeliveryCharge();
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
      final Map<String, CartProductModel> cartItemsByProductId = {
        for (final item in HomeProvider.cartItem)
          if (item.id != null && item.id!.isNotEmpty)
            item.id!.split('~').first: item,
      };

      if (productsToLoad.isEmpty) {
        _productsLoaded = true;
        notifyListeners();
        return;
      }

      final List<Future<void>> loadFutures = productsToLoad.map((
        productId,
      ) async {
        try {
          final cartItem =
              cartItemsByProductId[productId] ?? CartProductModel();

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
    // 🔑 OPTIMIZATION: Invalidate cart type cache
    _cachedHasPromotionalItems = null;
    _cachedHasMartItems = null;
    _lastCartItemCount = 0;
    _lastCartItemHash = null;
    // 🔑 OPTIMIZATION: Invalidate distance cache when vendor/address changes
    _cachedDistance = null;
    _cachedCustomerLat = null;
    _cachedCustomerLng = null;
    _cachedVendorLat = null;
    _cachedVendorLng = null;
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
      _clearAppliedCouponState();

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
      if (_couponLoadInFlight != null) {
        await _couponLoadInFlight;
      }
      return;
    }

    if (restaurantId.isEmpty || restaurantId.trim().isEmpty) {
      print('[COUPON_LOAD] ⚠️ Skipping coupon load: empty restaurant ID');
      await _loadGlobalCouponsOnly();
      return;
    }

    _isLoadingCoupons = true;
    _startOperation('loadCoupons');
    final couponLoadCompleter = Completer<void>();
    _couponLoadInFlight = couponLoadCompleter.future;

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
              zoneId: Constant.selectedZone!.id.toString(),
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
      if (!couponLoadCompleter.isCompleted) {
        couponLoadCompleter.complete();
      }
      _couponLoadInFlight = null;
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
      if (_couponLoadInFlight != null) {
        await _couponLoadInFlight;
      }
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
    final globalCouponLoadCompleter = Completer<void>();
    _couponLoadInFlight = globalCouponLoadCompleter.future;

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
              zoneId: Constant.selectedZone!.id.toString(),
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
      if (!globalCouponLoadCompleter.isCompleted) {
        globalCouponLoadCompleter.complete();
      }
      _couponLoadInFlight = null;
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

      final List<CouponModel> allCoupons;
      if (_currentContext == "mart") {
        allCoupons =
            await RestaurantApiHelper.getMartCoupons(
              restaurantId: restaurantId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '[COUPON_LOAD] ⏱️ Fallback: Mart coupon API call timed out',
                );
                return <CouponModel>[];
              },
            );
      } else {
        allCoupons =
            await RestaurantApiHelper.getRestaurantCoupons(
              restaurantId: restaurantId,
              zoneId: Constant.selectedZone!.id.toString(),
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '[COUPON_LOAD] ⏱️ Fallback: Restaurant coupon API call timed out',
                );
                return <CouponModel>[];
              },
            );
      }

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

  Future<void> _markUsedCoupons({bool notify = true}) async {
    if (_markUsedCouponsInFlight != null) {
      await _markUsedCouponsInFlight!;
      if (notify) notifyListeners();
      return;
    }

    final canUseCache =
        _lastUsedCouponsFetchAt != null &&
        DateTime.now().difference(_lastUsedCouponsFetchAt!) <
            _usedCouponsCacheExpiry;
    if (canUseCache) {
      _applyUsedCouponIds(_cachedUsedCouponIds);
      if (notify) notifyListeners();
      return;
    }

    _markUsedCouponsInFlight = () async {
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
            _cachedUsedCouponIds = usedCoupons
                .map((coupon) => coupon['couponId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            _lastUsedCouponsFetchAt = DateTime.now();
          }
        }
      } catch (e) {
        print('[MARK_USED_COUPONS] ❌ Error: $e');
      } finally {
        _markUsedCouponsInFlight = null;
      }
    }();

    await _markUsedCouponsInFlight!;
    _applyUsedCouponIds(_cachedUsedCouponIds);
    if (notify) notifyListeners();
  }

  void _applyUsedCouponIds(Set<String> usedCouponIds) {
    for (final coupon in couponList) {
      coupon.isEnabled = !usedCouponIds.contains(coupon.id);
    }
    for (final coupon in allCouponList) {
      coupon.isEnabled = !usedCouponIds.contains(coupon.id);
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

  /// 🔑 CRITICAL: Save payment state persistently for app lifecycle recovery
  /// 🔑 OPTIMIZATION: Save synchronously without await to prevent blocking
  void _savePaymentStatePersistently(String paymentId, String? signature) {
    // Use unawaited future to save in background without blocking
    Future.microtask(() async {
      try {
        final now = DateTime.now().millisecondsSinceEpoch.toString();
        // Save all state in parallel for faster execution
        await Future.wait([
          Preferences.setString(_paymentStateKey, 'true'),
          Preferences.setString(_paymentIdKey, paymentId),
          Preferences.setString(_paymentTimeKey, now),
          Preferences.setString(
            _paymentMethodKey,
            PaymentGateway.razorpay.name,
          ),
          Preferences.setString(_paymentAmountKey, totalAmount.toString()),
          if (signature != null && signature.isNotEmpty)
            Preferences.setString(_paymentSignatureKey, signature)
          else
            Future.value(),
        ]);
        print(
          '✅ [PAYMENT_STATE] Payment state saved persistently for recovery',
        );
      } catch (e) {
        print('❌ [PAYMENT_STATE] Error saving payment state: $e');
        // Try to save at least the critical payment ID
        try {
          await Preferences.setString(_paymentIdKey, paymentId);
          await Preferences.setString(_paymentStateKey, 'true');
        } catch (e2) {
          print('❌ [PAYMENT_STATE] Critical save also failed: $e2');
        }
      }
    });
  }

  /// 🔑 CRITICAL: Place order immediately in background without UI dependencies
  ///
  /// This method ensures order placement happens immediately, even if app is backgrounded.
  /// It doesn't wait for UI and makes API calls directly.
  void _placeOrderInBackgroundImmediately(String paymentId, String? signature) {
    // Start order placement immediately without any UI dependencies
    // Use unawaited to prevent blocking - allows app to continue/background
    unawaited(_placeOrderWithRetry(paymentId, signature));

    // Also start a background check to ensure order completes
    // This handles edge cases where the first attempt might fail
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        // Check if order was already placed (payment state cleared = order placed)
        final paymentState = Preferences.getString(_paymentStateKey);
        if (paymentState != 'true') {
          // Order was placed successfully
          print('✅ [BACKGROUND_CHECK] Order already placed, no retry needed');
          return;
        }

        // If payment state still exists, order wasn't placed - retry in background
        print(
          '🔄 [BACKGROUND_CHECK] Order not placed yet, retrying in background...',
        );
        unawaited(_placeOrderWithRetry(paymentId, signature, maxRetries: 2));
      } catch (e) {
        print('⚠️ [BACKGROUND_CHECK] Error in background check: $e');
      }
    });
  }

  /// 🔑 CRITICAL: Place order with automatic retry mechanism (up to 3 attempts)
  Future<void> _placeOrderWithRetry(
    String paymentId,
    String? signature, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    bool orderPlaced = false;

    while (attempt < maxRetries && !orderPlaced) {
      attempt++;
      try {
        print(
          '🚀 [PAYMENT_SUCCESS] Attempt $attempt/$maxRetries: Starting order placement for payment ID: $paymentId',
        );

        // Place order immediately
        await placeOrderAfterPayment();

        // 🔑 CRITICAL: Clear persistent state only after successful order placement
        await _clearPersistentPaymentState();

        // 🔑 CRITICAL: Stop periodic retry timer since order is placed
        _stopPendingOrderRetryTimer();

        orderPlaced = true;

        print(
          '✅ [PAYMENT_SUCCESS] Order placed successfully for payment ID: $paymentId (attempt $attempt)',
        );
        break;
      } catch (e, stackTrace) {
        print('❌ [PAYMENT_SUCCESS] Attempt $attempt failed: $e');
        print('❌ [PAYMENT_SUCCESS] Stack trace: $stackTrace');

        if (attempt < maxRetries) {
          // Wait before retry with exponential backoff (1s, 2s, 4s)
          final waitTime = Duration(seconds: attempt);
          print(
            '⏳ [PAYMENT_SUCCESS] Waiting ${waitTime.inSeconds}s before retry...',
          );
          await Future.delayed(waitTime);

          // Reset flags for retry
          _isOrderBeingCreated = false;
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
        } else {
          // All retries failed
          _processedPaymentIds.remove(paymentId);
          _isOrderBeingCreated = false;
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;

          // 🔑 CRITICAL: Keep payment state persisted for recovery on app resume
          // Don't clear persistent state on error - allow retry when app resumes
          print(
            '⚠️ [PAYMENT_SUCCESS] All retry attempts failed. Payment state kept for recovery. Order will be placed when app resumes.',
          );

          // 🔑 CRITICAL: Start periodic retry timer for failed orders
          _startPendingOrderRetryTimer();

          try {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "Order placement failed after $maxRetries attempts. Your payment is safe. Order will be placed automatically when you reopen the app or within 30 seconds."
                  .tr,
            );
          } catch (e) {
            print(
              '⚠️ [PAYMENT_SUCCESS] Could not show toast (app may be closing): $e',
            );
          }
        }
      }
    }

    // Unlock global state
    _unlockGlobal();
  }

  /// 🔑 CRITICAL: Check for pending payments and auto-place orders when app resumes
  Future<void> checkPendingPaymentAndPlaceOrder() async {
    try {
      final paymentState = Preferences.getString(_paymentStateKey);
      if (paymentState != 'true') {
        return; // No pending payment
      }

      final savedPaymentId = Preferences.getString(_paymentIdKey);
      final paymentTimeStr = Preferences.getString(_paymentTimeKey);

      if (savedPaymentId.isEmpty) {
        await _clearPersistentPaymentState();
        return;
      }

      // Check if payment session has expired
      if (paymentTimeStr.isNotEmpty) {
        final paymentTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(paymentTimeStr),
        );
        final timeSincePayment = DateTime.now().difference(paymentTime);
        if (timeSincePayment > paymentTimeout) {
          print('⚠️ [PENDING_PAYMENT] Payment session expired, clearing state');
          await _clearPersistentPaymentState();
          ShowToastDialog.showToast(
            "Payment session expired. Please try again.".tr,
          );
          return;
        }
      }

      // Restore payment state
      _lastPaymentId = savedPaymentId;
      if (paymentTimeStr.isNotEmpty) {
        _lastPaymentTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(paymentTimeStr),
        );
      }
      isPaymentCompleted = true;
      selectedPaymentMethod = PaymentGateway.razorpay.name;

      print(
        '✅ [PENDING_PAYMENT] Found pending payment: $savedPaymentId, attempting to place order',
      );

      // Check if order was already placed (prevent duplicate)
      if (_isOrderBeingCreated || _isOrderCreationInProgress) {
        print('⚠️ [PENDING_PAYMENT] Order already being created, skipping');
        return;
      }

      // Validate cart is not empty
      if (HomeProvider.cartItem.isEmpty) {
        print('❌ [PENDING_PAYMENT] Cart is empty, cannot place order');
        await _clearPersistentPaymentState();
        ShowToastDialog.showToast(
          "Cart is empty. Payment will be refunded.".tr,
        );
        return;
      }

      // Show loader and place order with retry mechanism
      ShowToastDialog.showLoader("Completing your order...".tr);

      try {
        // Use retry mechanism for pending payments too
        await _placeOrderWithRetry(savedPaymentId, null, maxRetries: 3);

        // 🔑 CRITICAL: Stop periodic retry timer since order is placed
        _stopPendingOrderRetryTimer();

        print(
          '✅ [PENDING_PAYMENT] Order placed successfully for pending payment',
        );
      } catch (e) {
        print('❌ [PENDING_PAYMENT] Error placing order: $e');
        // Keep payment state persisted for retry
        // Start periodic retry timer if not already started
        _startPendingOrderRetryTimer();

        ShowToastDialog.showToast(
          "Order placement failed. Your payment is safe. Order will be retried automatically every 30 seconds."
              .tr,
        );
      }
    } catch (e) {
      print('❌ [PENDING_PAYMENT] Error checking pending payment: $e');
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
      // 🔑 OPTIMIZATION: Invalidate distance cache when vendor changes
      _cachedDistance = null;
      _cachedVendorLat = null;
      _cachedVendorLng = null;

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
    final cacheKey = '${firstPromoItem.id}-${firstPromoItem.vendorID}';

    // 🔑 CRITICAL FIX: Always prioritize promotion cache for promotional items
    // Never fall back to global values - always use promotional delivery charges
    final promoDetails = _promotionalCalculationCache[cacheKey];
    double freeDeliveryKm;
    double extraKmCharge;

    if (promoDetails != null) {
      // 🔑 CRITICAL: Use free_delivery_km from promotion table (e.g., 4 km)
      final promoFreeKm = (promoDetails['free_delivery_km'] as num?)
          ?.toDouble();
      if (promoFreeKm != null && promoFreeKm > 0) {
        freeDeliveryKm = promoFreeKm;
        // Cache it for faster access next time
        _cachedFreeDeliveryKm[cacheKey] = promoFreeKm;
        print(
          '[PROMOTIONAL_DELIVERY] ✅ Using free delivery km from promotion table: $freeDeliveryKm km',
        );
      } else {
        // 🔑 CRITICAL: If promotion table doesn't have free_delivery_km,
        // check cached value (from previous fetch), but NEVER use global fallback
        if (_cachedFreeDeliveryKm.containsKey(cacheKey)) {
          freeDeliveryKm = _cachedFreeDeliveryKm[cacheKey]!;
          print(
            '[PROMOTIONAL_DELIVERY] ⚠️ Promotion table missing free_delivery_km, using cached promotional value: $freeDeliveryKm km',
          );
        } else {
          // 🔑 CRITICAL: For promotional items, we MUST have promotional data
          // If cache is missing, trigger async load and use a safe default that will be updated
          // But don't use global fallback - use a reasonable promotional default
          print(
            '[PROMOTIONAL_DELIVERY] ⚠️ No promotional cache found, triggering load...',
          );
          // Trigger async cache load
          _cachePromotionalData(
            firstPromoItem.id ?? '',
            firstPromoItem.vendorID ?? '',
            cacheKey,
          );
          // Use cached value if available, otherwise wait for cache (will recalculate)
          freeDeliveryKm =
              _cachedFreeDeliveryKm[cacheKey] ??
              4.0; // Default to 4km for promotional
        }
      }

      // Get extra km charge from promotion
      final promoExtraKm = (promoDetails['extra_km_charge'] as num?)
          ?.toDouble();
      if (promoExtraKm != null && promoExtraKm > 0) {
        extraKmCharge = promoExtraKm;
        _cachedExtraKmCharge[cacheKey] = promoExtraKm;
      } else {
        extraKmCharge = _cachedExtraKmCharge[cacheKey] ?? 7.0;
      }
    } else {
      // 🔑 CRITICAL: Promotion cache not loaded - check if we have cached values
      // If not, trigger load and use promotional defaults (NOT global)
      if (_cachedFreeDeliveryKm.containsKey(cacheKey)) {
        freeDeliveryKm = _cachedFreeDeliveryKm[cacheKey]!;
        print(
          '[PROMOTIONAL_DELIVERY] ✅ Using cached promotional free delivery km: $freeDeliveryKm km',
        );
      } else {
        // Trigger async cache load
        _cachePromotionalData(
          firstPromoItem.id ?? '',
          firstPromoItem.vendorID ?? '',
          cacheKey,
        );
        // Use promotional default (4km) instead of global fallback
        freeDeliveryKm = 4.0; // Default promotional free km
        print(
          '[PROMOTIONAL_DELIVERY] ⚠️ Promotion cache not loaded, using promotional default: $freeDeliveryKm km (will update when cache loads)',
        );
      }

      extraKmCharge = _getCachedExtraKmCharge(
        firstPromoItem.id ?? '',
        firstPromoItem.vendorID ?? '',
      );
    }

    // 🔑 DYNAMIC: Get base charge from promotional cache or delivery charge cache
    final baseCharge =
        _cachedPromotionalBaseCharge[cacheKey] ??
        DeliveryChargeCache.instance.getBaseDeliveryCharge(fallback: 21.0);

    // 🔑 NEW: Check if this promotional item should include base charge in calculation
    final includeBaseCharge =
        promoDetails?['include_base_charge'] == true ||
        promoDetails?['consider_base_charge'] == true ||
        promoDetails?['free_up_charge'] == true;

    _calculateDeliveryCharge(
      orderType: 'promotional',
      freeDeliveryKm: freeDeliveryKm,
      perKmCharge: extraKmCharge,
      baseCharge: baseCharge,
      logPrefix: '[PROMOTIONAL_DELIVERY]',
      includeBaseChargeInOriginalFee: includeBaseCharge,
    );
  }

  void _calculateDeliveryCharge({
    required String orderType,
    required double freeDeliveryKm,
    required double perKmCharge,
    required double baseCharge,
    required String logPrefix,
    bool includeBaseChargeInOriginalFee =
        true, // 🔑 NEW: Flag to control base charge inclusion
  }) {
    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (totalDistance <= freeDeliveryKm) {
      // Free delivery within promotional distance
      deliveryCharges = 0.0;
      // 🔑 FIX: For promotional items, ALWAYS include base charge in originalDeliveryFee for GST calculation
      // Even though customer pays 0, GST should be calculated on base charge
      if (orderType == 'promotional') {
        originalDeliveryFee =
            baseCharge; // Always include base charge for tax calculation
      } else {
        originalDeliveryFee = baseCharge;
      }
      print(
        '$logPrefix Free delivery within ${freeDeliveryKm}km - Customer pays: ₹$deliveryCharges, Base charge for GST: ₹$baseCharge',
      );
    } else {
      // Distance exceeds free delivery km - charge extra km only
      double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
      deliveryCharges = extraKm * perKmCharge;

      // 🔑 FIX: For promotional items, ALWAYS include base charge in originalDeliveryFee for GST calculation
      // The flag controls whether base charge is "free up" for customer, but it should always be in originalFee for tax
      if (orderType == 'promotional') {
        // Always include base charge for promotional items (for 18% GST calculation)
        originalDeliveryFee = baseCharge + deliveryCharges;
      } else {
        // For non-promotional, use the flag
        originalDeliveryFee = includeBaseChargeInOriginalFee
            ? baseCharge + deliveryCharges
            : deliveryCharges;
      }
      print(
        '$logPrefix Distance ${totalDistance}km exceeds free ${freeDeliveryKm}km - Extra km: $extraKm, Customer pays: ₹$deliveryCharges, Original fee (base + extra) for GST: ₹$originalDeliveryFee',
      );
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
    // 🔑 DYNAMIC: Use cache utility for all delivery charge values
    final cache = DeliveryChargeCache.instance;
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? cache.getItemTotalThreshold();
    final baseCharge = dc.baseDeliveryCharge ?? cache.getBaseDeliveryCharge();
    final freeKm =
        dc.freeDeliveryDistanceKm ?? cache.getFreeDeliveryDistanceKm();
    // 🔑 CRITICAL: Ensure perKm is properly converted to double from dynamic source
    final perKmValue = dc.perKmChargeAboveFreeDistance;
    final perKm = (perKmValue != null
        ? perKmValue.toDouble()
        : cache.getPerKmChargeAboveFreeDistance());
    final distance = totalDistance;

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal < threshold) {
      // 🔑 FIX: When subtotal < threshold:
      // - If distance <= freeKm: Use baseCharge
      // - Else: Use roundedDistance * perKm (no baseCharge)
      if (distance <= freeKm) {
        deliveryCharges = baseCharge.toDouble();
        originalDeliveryFee = baseCharge.toDouble();
        print(
          '[MART_DELIVERY] Below threshold & within free km: distance=$distance km, baseCharge=₹$baseCharge',
        );
      } else {
        // Round up distance to nearest integer (e.g., 5.17 km -> 6 km)
        final roundedDistance = distance.ceilToDouble();
        deliveryCharges = roundedDistance * perKm;
        originalDeliveryFee = deliveryCharges;
        print(
          '[MART_DELIVERY] Below threshold & beyond free km: distance=$distance km (rounded to $roundedDistance km), perKm=₹$perKm, charge=₹$deliveryCharges',
        );
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
    // 🔑 DYNAMIC: Use cache utility for all delivery charge values
    final cache = DeliveryChargeCache.instance;
    final dc = deliveryChargeModel;
    final subtotal = subTotal;
    final threshold = dc.itemTotalThreshold ?? cache.getItemTotalThreshold();
    final baseCharge = dc.baseDeliveryCharge ?? cache.getBaseDeliveryCharge();
    final freeKm =
        dc.freeDeliveryDistanceKm ?? cache.getFreeDeliveryDistanceKm();
    // 🔑 CRITICAL: Ensure perKm is properly converted to double from dynamic source
    final perKmValue = dc.perKmChargeAboveFreeDistance;
    final perKm = (perKmValue != null
        ? perKmValue.toDouble()
        : cache.getPerKmChargeAboveFreeDistance());

    if (vendorModel.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      deliveryCharges = 0.0;
      originalDeliveryFee = 0.0;
    } else if (subtotal < threshold) {
      // 🔑 FIX: When subtotal < threshold:
      // - If distance <= freeKm: Use baseCharge
      // - Else: Use roundedDistance * perKm (no baseCharge)
      if (totalDistance <= freeKm) {
        deliveryCharges = baseCharge.toDouble();
        originalDeliveryFee = baseCharge.toDouble();
        print(
          '[REGULAR_DELIVERY] Below threshold & within free km: distance=$totalDistance km, baseCharge=₹$baseCharge',
        );
      } else {
        // Round up distance to nearest integer (e.g., 5.17 km -> 6 km)
        final roundedDistance = totalDistance.ceilToDouble();
        deliveryCharges = roundedDistance * perKm;
        originalDeliveryFee = deliveryCharges;
        print(
          '[REGULAR_DELIVERY] Below threshold & beyond free km: distance=$totalDistance km (rounded to $roundedDistance km), perKm=₹$perKm, charge=₹$deliveryCharges',
        );
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

    // 🔑 CRITICAL FIX: For promotional items, ALWAYS prioritize promotion cache
    // First check cached value (from promotion table)
    if (_cachedFreeDeliveryKm.containsKey(cacheKey)) {
      return _cachedFreeDeliveryKm[cacheKey]!;
    }

    // If not in cached map, check promotion cache directly
    final promoDetails = _promotionalCalculationCache[cacheKey];
    if (promoDetails != null) {
      final freeKm = (promoDetails['free_delivery_km'] as num?)?.toDouble();
      if (freeKm != null && freeKm > 0) {
        // Cache it for next time
        _cachedFreeDeliveryKm[cacheKey] = freeKm;
        print(
          '[PROMOTIONAL_DELIVERY] ✅ Retrieved free delivery km from promotion cache: $freeKm km',
        );
        return freeKm;
      }
    }

    // 🔑 CRITICAL: Check if this is a promotional item - if so, NEVER use global fallback
    // Check if item has promoId in cart
    final isPromotionalItem = HomeProvider.cartItem.any(
      (item) =>
          item.id == productId &&
          item.vendorID == restaurantId &&
          item.promoId != null &&
          item.promoId!.isNotEmpty,
    );

    if (isPromotionalItem) {
      // 🔑 CRITICAL: For promotional items, use promotional default (4km) instead of global
      // This ensures promotional items always use promotional delivery charges
      print(
        '[PROMOTIONAL_DELIVERY] ⚠️ Promotional item cache not loaded, using promotional default: 4.0 km',
      );
      return 4.0; // Promotional default, NOT global fallback
    }

    // Only use global fallback for non-promotional items
    final globalFreeKm =
        deliveryChargeModel.freeDeliveryDistanceKm?.toDouble() ??
        DeliveryChargeCache.instance.getFreeDeliveryDistanceKm(fallback: 7.0);
    return globalFreeKm;
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

        // 🔑 CRITICAL FIX: For promotional items, use promotional free_delivery_km from table
        // If null, don't default to 3.0 - use promotional default (4.0) or fetch it
        final promoFreeKm = (promoDetails['free_delivery_km'] as num?)
            ?.toDouble();
        final freeDeliveryKm =
            promoFreeKm ?? 4.0; // 🔑 Use 4.0 as promotional default, not 3.0

        final extraKmCharge =
            (promoDetails['extra_km_charge'] as num?)?.toDouble() ?? 7.0;
        // 🔑 DYNAMIC: Get base charge from cache, with fallback from promo details if available
        final promoBaseCharge =
            (promoDetails['base_delivery_charge'] as num?)?.toDouble() ??
            DeliveryChargeCache.instance.getBaseDeliveryCharge(fallback: 21.0);

        // 🔑 NEW: Check if promotional item should include base charge in "free up" calculation
        // Some promotions consider base charge, some don't - check flag if available
        final includeBaseCharge =
            promoDetails['include_base_charge'] == true ||
            promoDetails['consider_base_charge'] == true ||
            promoDetails['free_up_charge'] ==
                true; // Default to true if not specified

        _cachedFreeDeliveryKm[cacheKey] = freeDeliveryKm;
        _cachedExtraKmCharge[cacheKey] = extraKmCharge;
        // 🔑 DYNAMIC: Store base charge in cache for promotional items
        _cachedPromotionalBaseCharge[cacheKey] = promoBaseCharge;
        // 🔑 NEW: Store flag for whether to include base charge
        _promotionalCalculationCache[cacheKey]?['include_base_charge'] =
            includeBaseCharge;
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
        DeliveryZoneAlertDialog.showZoneMismatchError();
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
          DeliveryZoneAlertDialog.showZoneValidationWarning();
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

  /// 🔑 OPTIMIZATION: Pre-initialize Razorpay in background for faster payment flow
  Future<void> _preInitializeRazorpay() async {
    try {
      if (!_razorpayCrashPrevention.isInitialized) {
        print(
          '🚀 [RAZORPAY_PREINIT] Pre-initializing Razorpay for faster checkout...',
        );
        final initialized = await _razorpayCrashPrevention.safeInitialize(
          onSuccess: handlePaymentSuccess,
          onFailure: handlePaymentError,
          onExternalWallet: handleExternalWallet,
        );
        if (initialized) {
          print('✅ [RAZORPAY_PREINIT] Razorpay pre-initialized successfully');
        } else {
          print(
            '⚠️ [RAZORPAY_PREINIT] Pre-initialization failed, will initialize on demand',
          );
        }
      } else {
        print('✅ [RAZORPAY_PREINIT] Razorpay already initialized');
      }
    } catch (e) {
      print('[RAZORPAY_PREINIT] ⚠️ Pre-initialization error: $e');
      // Don't throw - initialization will happen on demand
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
    // Wallet not allowed when cart has promotional items
    if (hasPromotionalItems()) {
      useWalletBalance = false;
    }
    if (useWalletBalance && isFullyPaidByWallet) {
      selectedPaymentMethod = PaymentGateway.wallet.name;
      if (!_isCalculatingPrice) notifyListeners();
      return;
    }
    if (!useWalletBalance &&
        selectedPaymentMethod == PaymentGateway.wallet.name) {
      selectedPaymentMethod = '';
    }
    final hasPromoItems = hasPromotionalItems();
    final codAmountCheck = useWalletBalance ? amountToChargeViaGateway : subTotal;
    final canUseCod =
        isCodEnabledForCurrentZone &&
        codAmountCheck <= codMaxAmountForCurrentZone &&
        !hasPromoItems;
    final canUseOnline = isRazorpayEnabledForCurrentZone;

    if (selectedPaymentMethod == PaymentGateway.cod.name && !canUseCod) {
      selectedPaymentMethod =
          canUseOnline ? PaymentGateway.razorpay.name : '';
    }
    if (selectedPaymentMethod == PaymentGateway.razorpay.name && !canUseOnline) {
      selectedPaymentMethod = canUseCod ? PaymentGateway.cod.name : '';
    }

    if (hasPromoItems) {
      if (selectedPaymentMethod == PaymentGateway.cod.name ||
          selectedPaymentMethod.isEmpty) {
        selectedPaymentMethod =
            canUseOnline ? PaymentGateway.razorpay.name : '';
      }
    } else if (codAmountCheck > codMaxAmountForCurrentZone) {
      if (selectedPaymentMethod == PaymentGateway.cod.name ||
          selectedPaymentMethod.isEmpty) {
        selectedPaymentMethod =
            canUseOnline ? PaymentGateway.razorpay.name : '';
      }
    } else if (selectedPaymentMethod.isEmpty) {
      if (canUseCod) {
        selectedPaymentMethod = PaymentGateway.cod.name;
      } else if (canUseOnline) {
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

    // Single GET /wallet via WalletProvider, then sync cart (avoids duplicate with cart screen / order placing)
    final wp = context.read<WalletProvider>();
    await wp.refreshWallet();
    syncWalletBalanceFromWallet(wp.moneyBalanceRupees);

    final canProceed = await validateAndPlaceOrderBulletproof(context);
    if (!canProceed) {
      endOrderProcessing();
      return false;
    }

    if (isFullyPaidByWallet) {
      selectedPaymentMethod = PaymentGateway.wallet.name;
      _endOperation('showPaymentMethodDialog');
      return true;
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
                  // Wallet section - so user can see balance and turn on "Use Wallet"
                  Builder(
                    builder: (context) {
                      final walletDisabledByPromos =
                          isWalletDisabledByPromotions;
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: walletDisabledByPromos
                              ? Colors.grey.shade100
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: walletDisabledByPromos
                                ? Colors.grey.shade300
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: walletDisabledByPromos
                                  ? Colors.grey
                                  : Colors.orange.shade700,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    walletDisabledByPromos
                                        ? "Wallet cannot be used for orders with promotional items"
                                        : "Wallet balance: ${Constant.amountShow(amount: walletBalanceRupees.toStringAsFixed(2))}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: walletDisabledByPromos
                                          ? Colors.grey[600]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  if (!walletDisabledByPromos &&
                                      useWalletBalance &&
                                      walletToUse > 0 &&
                                      paymentGatewayAmount > 0)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text(
                                        "₹${walletToUse.toStringAsFixed(2)} from wallet, ₹${paymentGatewayAmount.toStringAsFixed(2)} via payment",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            StatefulBuilder(
                              builder: (context, setSwitchState) {
                                return Switch(
                                  value: walletDisabledByPromos
                                      ? false
                                      : useWalletBalance,
                                  onChanged: walletDisabledByPromos
                                      ? null
                                      : (value) async {
                                          await setUseWalletBalance(value);
                                          setSwitchState(() {});
                                          setState(() {});
                                          if (value && isFullyPaidByWallet) {
                                            selectedPaymentMethod =
                                                PaymentGateway.wallet.name;
                                            notifyListeners();
                                            Get.back(result: true);
                                          }
                                        },
                                  activeColor: Colors.orange,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Choose how you want to pay for your order:",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
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
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Online Payment",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    "Pay securely with Razorpay",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
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

                  // Validation messages (use remaining amount when wallet is used)
                  if ((useWalletBalance ? amountToChargeViaGateway : subTotal) >
                          codMaxAmountForCurrentZone &&
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
                              "COD not available for orders above ₹${codMaxAmountForCurrentZone.toStringAsFixed(0)}",
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
                      final codCheck = useWalletBalance
                          ? amountToChargeViaGateway
                          : subTotal;
                      if (codCheck >
                          codMaxAmountForCurrentZone) {
                        ShowToastDialog.showToast(
                          "COD not available for orders above ₹${codMaxAmountForCurrentZone.toStringAsFixed(0)}. Please select online payment."
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
      // 🔑 OPTIMIZATION: Validate vendor in parallel with order preparation (non-blocking)
      // This allows order placement to proceed faster while vendor check happens in background
      final vendorCheckFuture = vendorModel.id != null
          ? FireStoreUtils.getVendorById(vendorModel.id.toString())
          : Future.value(null);

      // 🔑 CRITICAL: Start order placement immediately without waiting for vendor check
      // Vendor check will be validated inside _setOrderInternal if needed
      // This ensures order placement happens as fast as possible
      notifyListeners();

      // 🔑 CRITICAL: _setOrderInternal() makes API calls directly - works in background
      // Don't await vendor check - let it run in parallel
      final orderFuture = _setOrderInternal();

      // Check vendor result in parallel (non-blocking)
      final latestVendor = await vendorCheckFuture;
      if (latestVendor != null) {
        if (latestVendor.vType == 'mart') {
          if (latestVendor.isOpen == false) {
            // 🔑 CRITICAL: Don't block on UI - continue even if UI fails
            try {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showToast(
                "Jippy Mart is temporarily closed. Please try again later.",
              );
            } catch (e) {
              print(
                '⚠️ [SET_ORDER] Could not show UI (app may be backgrounded): $e',
              );
            }
            endOrderProcessing();
            return;
          }
        } else {
          if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
            // 🔑 CRITICAL: Don't block on UI - continue even if UI fails
            try {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showToast("Restaurant Closed");
            } catch (e) {
              print(
                '⚠️ [SET_ORDER] Could not show UI (app may be backgrounded): $e',
              );
            }
            endOrderProcessing();
            return;
          }
        }
      }

      // Wait for order placement to complete
      return await orderFuture;
    } catch (e) {
      print('❌ [SET_ORDER] Error: $e');
      // 🔑 CRITICAL: Don't block on UI - continue even if UI fails
      try {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Failed to place order. Please try again.".tr,
        );
      } catch (uiError) {
        print(
          '⚠️ [SET_ORDER] Could not show UI (app may be backgrounded): $uiError',
        );
      }
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
        controller.placeOrder(context);
      } else if (controller.selectedPaymentMethod ==
          PaymentGateway.wallet.name) {
        await controller.placeOrder(context);
      } else if (controller.selectedPaymentMethod ==
          PaymentGateway.razorpay.name) {
        await _processRazorpayPayment(controller);
      } else if (controller.selectedPaymentMethod ==
          PaymentGateway.paytm.name) {
        await _processPaytmPayment(controller, context);
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
      try {
        ShowToastDialog.showToast(
          "Payment configuration error. Please contact support.".tr,
        );
      } catch (e) {
        print('⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e');
      }
      controller.endOrderProcessing();
      return;
    }

    print(
      '✅ [RAZORPAY] Razorpay key found: ${controller.razorPayModel.razorpayKey!.substring(0, 10)}...',
    );

    // 🔑 OPTIMIZATION: Clear stale payment state immediately (non-blocking)
    controller.isPaymentInProgress = false;
    controller.isPaymentCompleted = false;
    controller._lastPaymentId = null;

    print(
      '🔑 [RAZORPAY] Starting payment flow for amount: ${controller.totalAmount}',
    );

    // 🔑 OPTIMIZATION: Show loader immediately, then yield so it can paint before async work
    try {
      ShowToastDialog.showLoader("Opening payment gateway...".tr);
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print(
        '⚠️ [RAZORPAY] Could not show loader (app may be backgrounded): $e',
      );
    }

    // 🔑 OPTIMIZATION: Parallelize vendor check and Razorpay initialization for speed
    final vendorCheckFuture = controller.vendorModel.id != null
        ? FireStoreUtils.getVendorById(controller.vendorModel.id!)
        : Future.value(null);

    // 🔑 OPTIMIZATION: Ensure Razorpay is initialized (should be pre-initialized)
    Future<bool> razorpayInitFuture;
    if (!controller._razorpayCrashPrevention.isInitialized) {
      print('🔑 [RAZORPAY] Razorpay not initialized, initializing now...');
      razorpayInitFuture = controller._razorpayCrashPrevention.safeInitialize(
        onSuccess: controller.handlePaymentSuccess,
        onFailure: controller.handlePaymentError,
        onExternalWallet: controller.handleExternalWallet,
      );
    } else {
      print('✅ [RAZORPAY] Razorpay already initialized (fast path)');
      razorpayInitFuture = Future.value(true);
    }

    // 🔑 OPTIMIZATION: Wait for both vendor check and Razorpay init in parallel
    final results = await Future.wait([vendorCheckFuture, razorpayInitFuture]);
    final latestVendor = results[0] as dynamic;
    final razorpayInitialized = results[1] as bool;

    // Validate vendor status
    if (latestVendor != null) {
      if (latestVendor.vType == 'mart') {
        if (latestVendor.isOpen == false) {
          try {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "Jippy Mart is temporarily closed. Please try again later.",
            );
          } catch (e) {
            print(
              '⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e',
            );
          }
          controller.endOrderProcessing();
          return;
        }
      } else {
        if (!RestaurantStatusUtils.canAcceptOrders(latestVendor)) {
          try {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast("Restaurant Closed");
          } catch (e) {
            print(
              '⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e',
            );
          }
          controller.endOrderProcessing();
          return;
        }
      }
    }

    if (!razorpayInitialized) {
      try {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Payment system is temporarily unavailable. Please try again later."
              .tr,
        );
      } catch (e) {
        print('⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e');
      }
      controller.endOrderProcessing();
      return;
    }

    // 🔑 OPTIMIZATION: Create Razorpay order immediately (no delays)
    print('🚀 [RAZORPAY] Creating Razorpay order...');
    final gatewayAmount = controller.amountToChargeViaGateway;
    if (gatewayAmount <= 0) {
      // Full wallet: place order without opening Razorpay
      await controller.setOrder();
      return;
    }
    final orderResult = await RazorPayController().createOrderRazorPay(
      amount: gatewayAmount,
      razorpayModel: controller.razorPayModel,
    );

    if (orderResult == null) {
      print('❌ [RAZORPAY] Order creation returned null');
      try {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Something went wrong, please contact admin.".tr,
        );
      } catch (e) {
        print('⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e');
      }
      controller.endOrderProcessing();
      return;
    }

    print('✅ [RAZORPAY] Order created successfully: ${orderResult.id}');

    // Keep loader visible until checkout is opened so user sees feedback; close only after openCheckout returns.
    // 🔑 OPTIMIZATION: Open checkout immediately without delays
    print('🚀 [RAZORPAY] Opening checkout immediately...');
    final checkoutOpened = await controller.openCheckout(
      amount: orderResult.amount / 100.0,
      orderId: orderResult.id,
    );

    try {
      ShowToastDialog.closeLoader();
    } catch (e) {
      print(
        '⚠️ [RAZORPAY] Could not close loader (app may be backgrounded): $e',
      );
    }

    if (!checkoutOpened) {
      print('❌ [RAZORPAY] Checkout failed to open');
      try {
        ShowToastDialog.showToast(
          "Failed to open payment gateway. Please try again.".tr,
        );
      } catch (e) {
        print('⚠️ [RAZORPAY] Could not show UI (app may be backgrounded): $e');
      }
      controller.endOrderProcessing();
    } else {
      print('✅ [RAZORPAY] Checkout opened successfully');
    }
  }

  Future<void> _processPaytmPayment(
    CartControllerProvider controller,
    BuildContext context,
  ) async {
    try {
      await startPaytmPaymentFlow(context);
    } catch (e, stackTrace) {
      print('❌ [PAYTM_PAYMENT] Error: $e');
      print('❌ [PAYTM_PAYMENT] Stack trace: $stackTrace');
      ShowToastDialog.showToast("Paytm payment failed. Please try again.".tr);
      controller.endOrderProcessing();
    }
  }

  // Future<void> startPaytmPaymentFlow(BuildContext context) async {
  //   bool smartlookStopped = false;
  //   try {
  //     // Paytm flow must create the order ONCE (same as COD/Razorpay UX).
  //     // We use backend Paytm initiate in "legacy payload" mode, which first creates
  //     // the Jippy3... order using the same payload as `mobile/orders`.
  //     selectedPaymentMethod = PaymentGateway.paytm.name;
  //
  //     final authorId = await SqlStorageConst.getFirebaseId();
  //     if (authorId!.isEmpty) {
  //       ShowToastDialog.showToast("Please login again to continue payment.".tr);
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     final double amountToPay = useWalletBalance
  //         ? paymentGatewayAmount
  //         : totalAmount;
  //     if (amountToPay <= 0) {
  //       // Wallet covers everything -> normal order placement (no gateway).
  //       await placeOrder(context);
  //       return;
  //     }
  //
  //     final String amountStr = amountToPay.toStringAsFixed(2);
  //
  //     // Build payload identical to order creation so backend can create ONE orderId.
  //     final cartItems = HomeProvider.cartItem;
  //     if (cartItems.isEmpty) {
  //       ShowToastDialog.showToast(
  //         "Cart is empty. Please add items to cart.".tr,
  //       );
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     final orderPayload = <String, dynamic>{
  //       "author_id": authorId,
  //       "cart_items": cartItems.map((item) => item.toJson()).toList(),
  //       "selected_address": {
  //         "isDefault": selectedAddress?.isDefault,
  //         "address": selectedAddress?.address,
  //         "addressAs": selectedAddress?.addressAs,
  //         "locality": selectedAddress?.locality,
  //         "location": {
  //           "latitude": selectedAddress?.location?.latitude,
  //           "longitude": selectedAddress?.location?.longitude,
  //         },
  //         "id": selectedAddress?.id,
  //         "landmark": selectedAddress?.landmark,
  //       },
  //       "payment_method": PaymentGateway.paytm.name,
  //       "total_amount": totalAmount,
  //       "delivery_charges": deliveryCharges.toString(),
  //       "tip_amount": deliveryTips.toString(),
  //       "coupon_id": selectedCouponModel.id ?? '',
  //       "coupon_code": selectedCouponModel.code ?? '',
  //       "discount": couponAmount,
  //       "schedule_time": scheduleDateTime.toIso8601String(),
  //       "surge_percent": surgePercent,
  //       "admin_surge_fee": surgePercent > 0 ? await getAdminSurgeFee() : "0",
  //       "special_discount": {
  //         "special_discount": specialDiscountAmount,
  //         "special_discount_label": specialDiscount,
  //         "specialType": specialType,
  //       },
  //       "vendor_id": _getVendorIdForOrder(),
  //       "v_type":
  //           vendorModel.vType ?? (hasMartItemsInCart() ? 'mart' : 'restaurant'),
  //       // For Paytm (gateway), order should be created as pending first,
  //       // then backend will update it to Order Placed after TXN_SUCCESS.
  //       "status": paymentGatewayAmount > 0 ? "PENDING" : Constant.orderPlaced,
  //       "created_at": DateTime.now().toIso8601String(),
  //       "wallet_amount": walletToUse,
  //       "payment_gateway_amount": paymentGatewayAmount,
  //     };
  //
  //     ShowToastDialog.showLoader("Creating your order...".tr);
  //
  //     final initUri = Uri.parse('${AppConst.baseUrl}paytm/initiate');
  //     final initHeaders = await getHeaders();
  //     final initHttpResp = await http
  //         .post(initUri, headers: initHeaders, body: jsonEncode(orderPayload))
  //         .timeout(const Duration(seconds: 30));
  //
  //     final initResponse =
  //         jsonDecode(initHttpResp.body) as Map<String, dynamic>?;
  //
  //     if (initHttpResp.statusCode != 200 ||
  //         initResponse == null ||
  //         initResponse['success'] != true ||
  //         initResponse['orderId'] == null) {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast(
  //         "Unable to initiate Paytm payment. Please try again.".tr,
  //       );
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     final String orderId = initResponse['orderId'].toString();
  //     final String? txnTokenRaw = initResponse['txnToken']?.toString();
  //     final String paytmMid = (initResponse['mid'] ?? initResponse['MID'] ?? '')
  //         .toString()
  //         .trim();
  //     if (paytmMid.isEmpty) {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast(
  //         "Paytm configuration error (missing mid).".tr,
  //       );
  //       endOrderProcessing();
  //       return;
  //     }
  //     final dynamic rawIsStaging =
  //         (initResponse['isStaging'] ?? initResponse['is_staging'] ?? true);
  //     final bool isStagingEnv =
  //         rawIsStaging == true ||
  //         rawIsStaging.toString().toLowerCase() == 'true' ||
  //         rawIsStaging.toString() == '1';
  //
  //     String callbackUrl =
  //         (initResponse['callbackUrl'] ?? initResponse['callback_url'] ?? '')
  //             .toString();
  //
  //     // Fallback: if backend doesn't return callbackUrl, build the official Paytm callback.
  //     if (callbackUrl.trim().isEmpty) {
  //       final host = isStagingEnv
  //           ? "https://securestage.paytmpayments.com"
  //           : "https://secure.paytmpayments.com";
  //       callbackUrl = "$host/theia/paytmCallback?ORDER_ID=$orderId";
  //     }
  //
  //     // If gateway payment is not required (wallet covers it), txnToken can be null.
  //     if (txnTokenRaw == null || txnTokenRaw.trim().isEmpty) {
  //       final m = OrderModel()..id = orderId;
  //       try {
  //         // Prefer reading provider from context to avoid late-init issues.
  //         final op = Provider.of<OrderPlacingProvider>(context, listen: false);
  //         op.initFunction(orderModels: m);
  //       } catch (e) {
  //         print('⚠️ [PAYTM_FLOW] Could not init OrderPlacingProvider: $e');
  //       }
  //       try {
  //         ShowToastDialog.closeLoader();
  //       } catch (_) {}
  //       endOrderProcessing();
  //       // Always navigate even if provider init fails.
  //       Get.off(() => const OrderPlacingScreen());
  //       return;
  //     }
  //
  //     final String txnToken = txnTokenRaw.trim();
  //
  //     ShowToastDialog.closeLoader();
  //
  //     // Smartlook recording can cause ANR/crashes when Paytm opens its WebView.
  //     // Pause it during payment flow for smooth gateway launch.
  //     try {
  //       SmartlookService().stopRecording();
  //       smartlookStopped = true;
  //     } catch (_) {}
  //
  //     // Keep UI responsive: do not keep any loader open while the Paytm SDK launches.
  //     try {
  //       ShowToastDialog.closeLoader();
  //     } catch (_) {}
  //
  //     final sdkResult = await PaytmService.startTransaction(
  //       mid: paytmMid,
  //       orderId: orderId,
  //       txnToken: txnToken,
  //       amount: amountStr,
  //       callbackUrl: callbackUrl,
  //       isStaging: isStagingEnv,
  //     );
  //
  //     if (smartlookStopped) {
  //       try {
  //         SmartlookService().startRecording();
  //       } catch (_) {}
  //     }
  //
  //     if (sdkResult == null) {
  //       ShowToastDialog.showToast("Unable to open Paytm. Please try again.".tr);
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     if (sdkResult['error'] == true) {
  //       final msg = (sdkResult['message'] ?? sdkResult['details'] ?? '')
  //           .toString()
  //           .trim();
  //       ShowToastDialog.showToast(
  //         msg.isNotEmpty ? msg : "Unable to open Paytm. Please try again.".tr,
  //       );
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     final status = (sdkResult['STATUS'] ?? sdkResult['resultStatus'] ?? "")
  //         .toString();
  //
  //     if (!status.toUpperCase().contains("SUCCESS")) {
  //       ShowToastDialog.showToast("Payment failed or cancelled.".tr);
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     // Confirm on backend (server-side verification + update same orderId).
  //     // Endpoint: POST /paytm/confirm { orderId }
  //     final confirmUri = Uri.parse('${AppConst.baseUrl}paytm/confirm');
  //     final confirmHeaders = await getHeaders();
  //     String? finalStatus;
  //
  //     // Show loader once (avoid flicker) while confirming status.
  //     ShowToastDialog.showLoader("Confirming payment status...".tr);
  //     for (var attempt = 0; attempt < 6; attempt++) {
  //       final confirmResp = await http
  //           .post(
  //             confirmUri,
  //             headers: confirmHeaders,
  //             body: jsonEncode(<String, dynamic>{"orderId": orderId}),
  //           )
  //           .timeout(const Duration(seconds: 30));
  //
  //       Map<String, dynamic>? confirmJson;
  //       try {
  //         confirmJson = jsonDecode(confirmResp.body) as Map<String, dynamic>?;
  //       } catch (_) {
  //         confirmJson = null;
  //       }
  //
  //       if (confirmResp.statusCode == 200 &&
  //           confirmJson != null &&
  //           confirmJson['success'] == true) {
  //         finalStatus = (confirmJson['resultStatus'] ?? 'TXN_SUCCESS')
  //             .toString();
  //         break;
  //       }
  //
  //       // 409 / pending or other -> wait and retry a few times
  //       if (attempt < 5) {
  //         await Future.delayed(Duration(seconds: 2 + attempt));
  //       }
  //     }
  //
  //     if (finalStatus == null ||
  //         (!finalStatus.toUpperCase().contains('SUCCESS') &&
  //             finalStatus != 'TXN_SUCCESS')) {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast(
  //         "Payment is pending. Please wait and check again in Orders.".tr,
  //       );
  //       endOrderProcessing();
  //       return;
  //     }
  //
  //     // Payment confirmed. Do NOT create a second order via `mobile/orders`.
  //     // Navigate to the order placed screen for the SAME orderId created above.
  //     final m = OrderModel()..id = orderId;
  //     try {
  //       final op = Provider.of<OrderPlacingProvider>(context, listen: false);
  //       op.initFunction(orderModels: m);
  //     } catch (e) {
  //       print('⚠️ [PAYTM_FLOW] Could not init OrderPlacingProvider: $e');
  //     }
  //     try {
  //       ShowToastDialog.closeLoader();
  //     } catch (_) {}
  //     endOrderProcessing();
  //     // Use offAll to avoid any stuck payment routes on back-stack.
  //     Get.offAll(() => const OrderPlacingScreen());
  //   } catch (e, st) {
  //     print("❌ [PAYTM_FLOW] $e");
  //     print(st);
  //     try {
  //       ShowToastDialog.closeLoader();
  //     } catch (_) {}
  //     endOrderProcessing();
  //     ShowToastDialog.showToast(
  //       "Something went wrong while processing Paytm payment.".tr,
  //     );
  //   } finally {
  //     // Always restore Smartlook if we paused it.
  //     if (smartlookStopped) {
  //       try {
  //         SmartlookService().startRecording();
  //       } catch (_) {}
  //     }
  //   }
  // }

  Future<void> startPaytmPaymentFlow(BuildContext context) async {
    bool smartlookStopped = false;

    try {
      selectedPaymentMethod = PaymentGateway.paytm.name;

      final authorId = await SqlStorageConst.getFirebaseId();
      if (authorId == null || authorId.isEmpty) {
        ShowToastDialog.showToast("Please login again".tr);
        return;
      }

      final double amountToPay = useWalletBalance
          ? paymentGatewayAmount
          : totalAmount;

      if (amountToPay <= 0) {
        await placeOrder(context);
        return;
      }

      if (HomeProvider.cartItem.isEmpty) {
        ShowToastDialog.showToast("Cart is empty".tr);
        return;
      }

      final payload = _buildOrderPayload(authorId);

      // ✅ Single loader start
      ShowToastDialog.showLoader("Processing payment...".tr);

      final response = await http
          .post(
            Uri.parse('${AppConst.baseUrl}paytm/initiate'),
            headers: await getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      final json = jsonDecode(response.body);

      if (response.statusCode != 200 || json['success'] != true) {
        throw "INIT_FAILED";
      }

      final String orderId = json['orderId'];
      final String mid = json['mid'] ?? json['MID'] ?? '';
      final String txnToken = json['txnToken'] ?? '';

      if (mid.isEmpty) throw "MID_MISSING";

      final bool isStaging =
          json['isStaging'] == true || json['is_staging'] == true;

      final callbackUrl =
          json['callbackUrl'] ??
          (isStaging
              ? "https://securestage.paytmpayments.com/theia/paytmCallback?ORDER_ID=$orderId"
              : "https://secure.paytmpayments.com/theia/paytmCallback?ORDER_ID=$orderId");

      // ✅ Wallet-only case
      if (txnToken.isEmpty) {
        _navigateToOrderScreen(context, orderId);
        return;
      }

      // ✅ Stop recording BEFORE SDK
      SmartlookService().stopRecording();
      smartlookStopped = true;

      // ✅ Close loader BEFORE opening SDK (IMPORTANT)
      ShowToastDialog.closeLoader();

      final result = await PaytmService.startTransaction(
        mid: mid,
        orderId: orderId,
        txnToken: txnToken,
        amount: amountToPay.toStringAsFixed(2),
        callbackUrl: callbackUrl,
        isStaging: isStaging,
      );

      // ✅ Restart Smartlook
      if (smartlookStopped) {
        SmartlookService().startRecording();
      }

      if (result == null || result['error'] == true) {
        ShowToastDialog.showToast("Payment failed".tr);
        return;
      }

      final status = (result['STATUS'] ?? result['resultStatus'] ?? "")
          .toString();

      if (!status.toUpperCase().contains("SUCCESS")) {
        ShowToastDialog.showToast("Payment cancelled".tr);
        return;
      }

      // ✅ Confirm Payment (Optimized Retry)
      final confirmed = await _confirmPayment(orderId);

      if (!confirmed) {
        ShowToastDialog.showToast("Payment pending".tr);
        return;
      }

      _sendOrderNotification(orderId);

      _navigateToOrderScreen(context, orderId);
    } catch (e) {
      ShowToastDialog.showToast("Payment error. Try again.".tr);
    } finally {
      ShowToastDialog.closeLoader();

      if (smartlookStopped) {
        SmartlookService().startRecording();
      }
    }
  }

  Map<String, dynamic> _buildOrderPayload(String authorId) {
    return {
      "author_id": authorId,
      "cart_items": HomeProvider.cartItem.map((e) => e.toJson()).toList(),
      "selected_address": selectedAddress?.toJson(),
      "payment_method": PaymentGateway.paytm.name,
      "total_amount": totalAmount,
      "delivery_charges": deliveryCharges.toString(),
      "tip_amount": deliveryTips.toString(),
      "coupon_id": selectedCouponModel.id ?? '',
      "coupon_code": selectedCouponModel.code ?? '',
      "discount": couponAmount,
      "schedule_time": scheduleDateTime.toIso8601String(),
      "vendor_id": _getVendorIdForOrder(),
      "status": paymentGatewayAmount > 0 ? "PENDING" : Constant.orderPlaced,
      "wallet_amount": walletToUse,
      "payment_gateway_amount": paymentGatewayAmount,
    };
  }

  Future<bool> _confirmPayment(String orderId) async {
    for (int i = 0; i < 4; i++) {
      final res = await http.post(
        Uri.parse('${AppConst.baseUrl}paytm/confirm'),
        headers: await getHeaders(),
        body: jsonEncode({"orderId": orderId}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return true;
      }

      await Future.delayed(Duration(seconds: 2));
    }
    return false;
  }

  void _navigateToOrderScreen(BuildContext context, String orderId) {
    try {
      Provider.of<OrderPlacingProvider>(
        context,
        listen: false,
      ).initFunction(orderModels: OrderModel()..id = orderId);
    } catch (_) {}

    Get.offAll(() => const OrderPlacingScreen());
  }

  void _sendOrderNotification(String orderId) {
    Future.microtask(() async {
      try {
        if (vendorModel.id == null || vendorModel.author == null) {
          if (kDebugMode) {
            log('[CART] Skipping notification: vendor null');
          }
          return;
        }

        final authorId = vendorModel.author.toString();

        // ✅ Step 1: Get FCM Token (fast path first)
        String fcmToken = vendorModel.fcmToken?.trim() ?? '';

        if (fcmToken.isEmpty) {
          final user = await AddressListProvider.getUserProfile(authorId);

          if (user == null) {
            if (kDebugMode) {
              log('[CART] Vendor profile not found');
            }
            return;
          }

          fcmToken = user.fcmToken?.trim() ?? '';
        }

        if (fcmToken.isEmpty) {
          if (kDebugMode) {
            log('[CART] Empty FCM token');
          }
          return;
        }

        // ✅ Step 2: Build payload
        final type = scheduleDateTime.isAfter(DateTime.now())
            ? Constant.scheduleOrder
            : Constant.newOrderPlaced;

        final payload = {'type': type, 'order_id': orderId};

        // ✅ Step 3: Send notification
        final sent = await SendNotification.sendFcmMessage(
          type,
          fcmToken,
          payload,
        );

        if (kDebugMode && !sent) {
          log('[CART] Notification failed (stale token)');
        }
      } catch (e, stack) {
        if (kDebugMode) {
          log('[CART] Notification error: $e');
          log('$stack');
        }
      }
    });
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

      // 🔑 OPTIMIZATION: Fast validation checks (non-blocking UI)
      if (HomeProvider.cartItem.isEmpty) {
        print('❌ [ORDER_CREATION] Cart is empty, cannot create order');
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Cart is empty. Please add items to cart.".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_CREATION] Could not show UI (app may be backgrounded): $e',
          );
        }
        _isOrderCreationInProgress = false;
        _currentOrderPaymentId = null;
        endOrderProcessing();
        _unlockGlobal();
        return;
      }

      // 🔑 OPTIMIZATION: Calculate price immediately (no await delays)
      await calculatePrice();

      if (subTotal <= 0 || subTotal.isNaN || subTotal.isInfinite) {
        print(
          '❌ [ORDER_CREATION] Invalid subTotal: $subTotal, cannot create order',
        );
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Order calculation error. Please refresh and try again.".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_CREATION] Could not show UI (app may be backgrounded): $e',
          );
        }
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
        try {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Order total is invalid. Please refresh and try again.".tr,
          );
        } catch (e) {
          print(
            '⚠️ [ORDER_CREATION] Could not show UI (app may be backgrounded): $e',
          );
        }
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
          try {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "Unable to process order. Please remove items and add them again from Mart."
                  .tr,
            );
          } catch (e) {
            print(
              '⚠️ [ORDER_CREATION] Could not show UI (app may be backgrounded): $e',
            );
          }
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

      // 🔑 OPTIMIZATION: Check vendor subscription in parallel with order preparation
      // Skip for mart - uses different table
      Future<void>? vendorSubscriptionCheck;
      if (!hasMartItemsInCart() &&
          (Constant.isSubscriptionModelApplied == true ||
              Constant.adminCommission?.isEnabled == true) &&
          vendorModel.subscriptionPlan != null &&
          vendorModel.id != null) {
        vendorSubscriptionCheck =
            FireStoreUtils.getVendorById(vendorModel.id.toString()).then((
              vender,
            ) {
              if (vender?.subscriptionTotalOrders == '0' ||
                  vender?.subscriptionTotalOrders == null) {
                throw Exception('Vendor has reached maximum order capacity');
              }
            });
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

      // 🔑 OPTIMIZATION: Get latest order number in parallel with other operations
      // This is non-critical and can run in background
      int maxNumber = 5;
      final orderNumberFuture = http
          .get(
            Uri.parse('${AppConst.baseUrl}firestore/getLatestOrderInRange'),
            headers: await getHeaders(),
          )
          .timeout(
            const Duration(seconds: 5),
            // 🔑 OPTIMIZATION: Short timeout for faster failure
            onTimeout: () {
              throw Exception('Order number fetch timeout');
            },
          )
          .then((response) {
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
                    return num;
                  }
                }
              }
            }
            return maxNumber;
          })
          .catchError((e) {
            print(
              '⚠️ [ORDER_CREATION] Error fetching latest order (non-critical): $e',
            );
            return maxNumber; // Return default on error
          });

      // 🔑 OPTIMIZATION: Build order model immediately (no await delays)
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

      // 🔑 OPTIMIZATION: Validate vendor subscription before building payload
      // This ensures we don't waste time building payload if vendor is at capacity
      if (vendorSubscriptionCheck != null) {
        try {
          await vendorSubscriptionCheck;
        } catch (e) {
          print('❌ [ORDER_CREATION] Vendor subscription check failed: $e');
          try {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "This vendor has reached their maximum order capacity. Please select a different vendor or try again later."
                  .tr,
            );
          } catch (uiError) {
            print(
              '⚠️ [ORDER_CREATION] Could not show UI (app may be backgrounded): $uiError',
            );
          }
          endOrderProcessing();
          _isOrderCreationInProgress = false;
          _currentOrderPaymentId = null;
          _unlockGlobal();
          return;
        }
      }

      // 🔑 OPTIMIZATION: Get author ID once and reuse (avoid duplicate await)
      final authorId = await SqlStorageConst.getFirebaseId();

      // Build API payload
      Map<String, dynamic> orderPayload = {
        "author_id": authorId,
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
        "admin_surge_fee": surgePercent > 0 ? await getAdminSurgeFee() : "0",
        // 🔑 OPTIMIZATION: Only fetch if needed
        "special_discount": specialDiscountMap,
        "vendor_id": _getVendorIdForOrder(),
        "v_type":
            vendorModel.vType ?? (hasMartItemsInCart() ? 'mart' : 'restaurant'),
        "status": Constant.orderPlaced,
        "created_at": DateTime.now().toIso8601String(),
        "wallet_amount": walletToUse,
        "payment_gateway_amount": paymentGatewayAmount,
      };

      // 🔑 DEBUG: Payload summary for backend wallet/referral debugging (grep ORDER_CREATION_PAYLOAD)
      print(
        '🌐 [ORDER_CREATION_PAYLOAD] author_id=$authorId | total_amount=$totalAmount | '
        'wallet_amount=$walletToUse | payment_gateway_amount=$paymentGatewayAmount | '
        'payment_method=$selectedPaymentMethod',
      );
      if (walletToUse > 0) {
        print(
          '🌐 [ORDER_CREATION_PAYLOAD] Wallet used: ₹$walletToUse (backend must deduct this from user money_wallet)',
        );
      }

      print('🌐 [ORDER_CREATION] Creating order via API...');
      print(
        '🌐 [ORDER_CREATION] vendor_id: ${orderPayload["vendor_id"]}, v_type: ${orderPayload["v_type"]}',
      );
      print('🌐 [ORDER_CREATION] Payment method: $selectedPaymentMethod');
      print('🌐 [ORDER_CREATION] Total amount: ₹$totalAmount');

      // 🔑 OPTIMIZATION: Show loader for user feedback (non-blocking, works in background)
      try {
        ShowToastDialog.showLoader("Creating your order...".tr);
      } catch (e) {
        print(
          '⚠️ [ORDER_CREATION] Could not show loader (app may be backgrounded): $e',
        );
        // Continue with order placement even if loader fails
      }

      // 🔑 OPTIMIZATION: Prepare headers and body in parallel before API call
      final headersFuture = getHeaders();
      final bodyJson = json.encode(orderPayload);
      final headers = await headersFuture;

      // 🔑 OPTIMIZATION: Make API call with optimized timeout (works in background)
      // http package works in background, so this will execute even if app is backgrounded
      final response = await http
          .post(
            Uri.parse('${AppConst.baseUrl}mobile/orders'),
            headers: headers,
            body: bodyJson,
          )
          .timeout(
            const Duration(seconds: 20),
            // 🔑 OPTIMIZATION: Reduced timeout for faster failure detection
            onTimeout: () {
              throw Exception(
                'Order creation API call timed out after 20 seconds',
              );
            },
          );

      print('🌐 [ORDER_CREATION] API response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          '❌ [ORDER_CREATION] API returned error status: ${response.statusCode}',
        );
        print('❌ [ORDER_CREATION] Response body: ${response.body}');
        if (response.statusCode == 422) {
          print(
            '❌ [ORDER_CREATION_DEBUG] 422 = validation failed. Backend: check wallet_amount, payment_gateway_amount, total_amount validation and wallet balance.',
          );
        }
        throw Exception(
          'API returned status code: ${response.statusCode}. Response: ${response.body}',
        );
      }

      final responseData = json.decode(response.body);

      if (responseData['success'] != true) {
        print(
          '❌ [ORDER_CREATION] API returned error: ${responseData['message']}',
        );
        print(
          '❌ [ORDER_CREATION_DEBUG] Backend createOrder: ensure wallet deduction (when wallet_amount>0) and referee 100 coins (first order) run in same transaction.',
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
      if (walletToUse > 0) {
        print(
          '✅ [ORDER_CREATION] Wallet was used (₹$walletToUse). Backend should have deducted; refresh wallet balance to see update.',
        );
      }

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

      if (vendorModel.id == null || vendorModel.author == null) {
        if (kDebugMode) {
          log('[CART] Skipping order notification: vendor id or author null');
        }
      } else {
        final authorIdForNotify = vendorModel.author.toString();
        final orderIdForNotify = orderModel.id ?? '';
        additionalTasks.add(() async {
          try {
            final authorId = authorIdForNotify;
            // Prefer token from vendor model (restaurant/vendor doc); fallback to user profile
            String fcmToken = vendorModel.fcmToken?.trim() ?? '';
            if (fcmToken.isEmpty) {
              final value = await AddressListProvider.getUserProfile(authorId);
              if (value == null) {
                if (kDebugMode) {
                  log('[CART] Order notification: vendor profile not found');
                }
                return;
              }
              fcmToken = value.fcmToken?.trim() ?? '';
            }
            if (fcmToken.isEmpty) {
              if (kDebugMode) {
                log('[CART] Order notification: vendor FCM token empty');
              }
              return;
            }
            final type = scheduleDateTime.isAfter(DateTime.now())
                ? Constant.scheduleOrder
                : Constant.newOrderPlaced;
            final payload = <String, dynamic>{
              'type': type,
              'order_id': orderIdForNotify,
            };
            final sent = await SendNotification.sendFcmMessage(
              type,
              fcmToken,
              payload,
            );
            if (kDebugMode && !sent) {
              log(
                '[CART] Order notification send failed (vendor token may be stale)',
              );
            }
          } catch (e, stack) {
            if (kDebugMode) {
              log('[CART] Order notification error: $e');
              log('[CART] $stack');
            }
          }
        }());
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

      // Wallet refresh: OrderPlacingScreen does single GET /wallet via WalletProvider.refreshWallet() + syncWalletBalanceFromWallet

      // 🔑 OPTIMIZATION: UI operations wrapped in try-catch for background compatibility
      try {
        ShowToastDialog.closeLoader();
      } catch (e) {
        print(
          '⚠️ [ORDER_CREATION] Could not close loader (app may be backgrounded): $e',
        );
      }
      endOrderProcessing();

      // 🔑 OPTIMIZATION: Navigation wrapped in try-catch (may fail if app is backgrounded)
      try {
        orderPlacingProvider.initFunction(orderModels: orderModel);
        Get.off(() => OrderPlacingScreen());
      } catch (e) {
        print(
          '⚠️ [ORDER_CREATION] Could not navigate (app may be backgrounded): $e',
        );
        // Order is still placed successfully, navigation can happen when app resumes
      }

      print('✅ [ORDER_CREATION] Order placement complete!');
    } catch (e, stackTrace) {
      print("❌ [ORDER_CREATION] Error: $e");
      print("❌ [ORDER_CREATION] Stack trace: $stackTrace");

      _isOrderBeingCreated = false;
      _isOrderCreationInProgress = false;
      _currentOrderPaymentId = null;

      // 🔑 OPTIMIZATION: UI operations wrapped in try-catch for background compatibility
      try {
        ShowToastDialog.closeLoader();
      } catch (uiError) {
        print(
          '⚠️ [ORDER_CREATION] Could not close loader (app may be backgrounded): $uiError',
        );
      }
      endOrderProcessing();

      if (isPaymentCompleted && _lastPaymentId != null) {
        _processedPaymentIds.remove(_lastPaymentId!);
        try {
          ShowToastDialog.showToast(
            "Order placement failed. Your payment is safe. Please try again."
                .tr,
          );
        } catch (uiError) {
          print(
            '⚠️ [ORDER_CREATION] Could not show toast (app may be backgrounded): $uiError',
          );
        }
      } else {
        _resetPaymentState();
        try {
          ShowToastDialog.showToast(
            "Failed to place order. Please try again.".tr,
          );
        } catch (uiError) {
          print(
            '⚠️ [ORDER_CREATION] Could not show toast (app may be backgrounded): $uiError',
          );
        }
      }
    } finally {
      // 🔑 CRITICAL: Always unlock global at the end
      _unlockGlobal();
    }
  }

  bool hasPromotionalItems() {
    return _getCachedHasPromotionalItems();
  }

  // 🔑 OPTIMIZATION: Cached version to avoid repeated iterations
  bool _getCachedHasPromotionalItems() {
    final currentCount = HomeProvider.cartItem.length;
    final currentHash = _generateCartHash();

    // Invalidate cache if cart changed
    if (_cachedHasPromotionalItems == null ||
        _lastCartItemCount != currentCount ||
        _lastCartItemHash != currentHash) {
      _cachedHasPromotionalItems = HomeProvider.cartItem.any(
        (item) => item.promoId != null && item.promoId!.isNotEmpty,
      );
      _lastCartItemCount = currentCount;
      _lastCartItemHash = currentHash;
    }

    return _cachedHasPromotionalItems!;
  }

  // 🔑 OPTIMIZATION: Cached version to avoid repeated iterations
  bool _getCachedHasMartItems() {
    final currentCount = HomeProvider.cartItem.length;
    final currentHash = _generateCartHash();

    // Invalidate cache if cart changed
    if (_cachedHasMartItems == null ||
        _lastCartItemCount != currentCount ||
        _lastCartItemHash != currentHash) {
      _cachedHasMartItems = hasMartItemsInCart();
      _lastCartItemCount = currentCount;
      _lastCartItemHash = currentHash;
    }

    return _cachedHasMartItems!;
  }

  // 🔑 OPTIMIZATION: Generate simple hash to detect cart changes
  String _generateCartHash() {
    if (HomeProvider.cartItem.isEmpty) return 'empty';
    return '${HomeProvider.cartItem.length}_${HomeProvider.cartItem.map((e) => '${e.id}_${e.quantity}').join('|')}';
  }

  // 🔑 OPTIMIZATION: Invalidate cart type cache when cart changes
  void _invalidateCartTypeCache() {
    final currentCount = HomeProvider.cartItem.length;
    final currentHash = _generateCartHash();

    if (_lastCartItemCount != currentCount ||
        _lastCartItemHash != currentHash) {
      _cachedHasPromotionalItems = null;
      _cachedHasMartItems = null;
      _lastCartItemCount = currentCount;
      _lastCartItemHash = currentHash;
    }
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

        // 🔑 OPTIMIZATION: Invalidate distance cache when address changes
        _cachedDistance = null;
        _cachedCustomerLat = null;
        _cachedCustomerLng = null;

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

  Future<Map<String, PriceUpdateResult>> validateAndUpdateCartPrices() async {
    final Map<String, PriceUpdateResult> results = {};
    final items = List<CartProductModel>.from(HomeProvider.cartItem);

    print(
      '[PRICE_SYNC] 🔍 Starting IMMEDIATE price validation for ${items.length} items',
    );

    final foodCatalogIds = <String>{};
    final martLineIds = <String>{};
    for (final cartItem in items) {
      if (cartItem.id == null || cartItem.id!.isEmpty) continue;
      if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) continue;
      if (_isMartItem(cartItem)) {
        martLineIds.add(cartItem.id!);
      } else {
        final cid = _catalogProductIdForFetch(cartItem.id!);
        if (cid.isNotEmpty) foodCatalogIds.add(cid);
      }
    }

    var foodByCatalogId = <String, ProductModel?>{};
    var martByLineId = <String, MartItemModel?>{};

    try {
      await Future.wait([
        Future(() async {
          if (foodCatalogIds.isEmpty) return;
          foodByCatalogId.addAll(
            await FireStoreUtils.getProductsByIds(
              foodCatalogIds.toList(),
              forceRefresh: true,
            ),
          );
        }),
        Future(() async {
          if (martLineIds.isEmpty) return;
          final martService = Get.find<MartFirestoreService>();
          await Future.wait(martLineIds.map((lineId) async {
            try {
              martByLineId[lineId] = await martService.getItemById(lineId);
            } catch (_) {
              martByLineId[lineId] = null;
            }
          }));
        }),
      ]);
    } catch (e) {
      print('[PRICE_SYNC] ❌ Prefetch failed: $e');
    }

    var cartDirty = false;

    for (var cartItem in items) {
      try {
        if (cartItem.id == null || cartItem.id!.isEmpty) {
          continue;
        }

        final isPromotionalItem =
            cartItem.promoId != null && cartItem.promoId!.isNotEmpty;

        if (isPromotionalItem) {
          print('[PRICE_SYNC] 🎯 Skipping promotional item: ${cartItem.name}');
          continue;
        }

        final isMart = _isMartItem(cartItem);
        final itemType = isMart ? 'MART' : 'FOOD';

        final storedDiscountPrice =
            double.tryParse(cartItem.discountPrice ?? "0") ?? 0.0;
        final storedRegularPrice =
            double.tryParse(cartItem.price ?? "0") ?? 0.0;
        final storedPrice =
            storedDiscountPrice > 0 && storedDiscountPrice < storedRegularPrice
            ? storedDiscountPrice
            : storedRegularPrice;

        print(
          '[PRICE_SYNC] [$itemType] Checking ${cartItem.name}: Stored price in cart = ₹$storedPrice',
        );

        dynamic currentProduct;
        double currentPrice = 0.0;

        try {
          if (isMart) {
            currentProduct = martByLineId[cartItem.id!];
            if (currentProduct != null && currentProduct is MartItemModel) {
              currentPrice = currentProduct.finalPrice;
            }
          } else {
            final catalogId = _catalogProductIdForFetch(cartItem.id!);
            currentProduct =
                catalogId.isEmpty ? null : foodByCatalogId[catalogId];
            if (currentProduct != null && currentProduct is ProductModel) {
              currentPrice =
                  _getCurrentProductPrice(currentProduct, cartItem);
            }
          }

          print(
            '[PRICE_SYNC] [$itemType] Current price from DB = ₹$currentPrice',
          );

          final priceDifference = (currentPrice - storedPrice).abs();
          const tolerance = 0.01;

          if (priceDifference > tolerance) {
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

            cartItem.price = currentPrice.toStringAsFixed(2);
            cartItem.discountPrice = "0";
            if (currentProduct is ProductModel && cartItem.variantInfo != null) {
              _syncVariantInfoFieldsFromProduct(
                cartItem.variantInfo!,
                currentProduct,
              );
            }

            await DatabaseHelper.instance.updateCartProduct(cartItem);
            cartDirty = true;
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

            if (!isMart &&
                currentProduct is ProductModel &&
                cartItem.variantInfo != null) {
              bool needSave = _syncVariantInfoFieldsFromProduct(
                cartItem.variantInfo!,
                currentProduct,
              );
              final liveLine =
                  _getCurrentProductPrice(currentProduct, cartItem);
              final sdDisc =
                  double.tryParse(cartItem.discountPrice ?? '0') ?? 0.0;
              final sdReg =
                  double.tryParse(cartItem.price ?? '0') ?? 0.0;
              final sdDisplay =
                  sdDisc > 0 && sdDisc < sdReg ? sdDisc : sdReg;
              if ((liveLine - sdDisplay).abs() > 0.01) {
                cartItem.price = liveLine.toStringAsFixed(2);
                cartItem.discountPrice = '0';
                needSave = true;
              }
              if (needSave) {
                await DatabaseHelper.instance.updateCartProduct(cartItem);
                cartDirty = true;
              }
            }
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

    if (cartDirty) {
      _priceSyncVersion++;
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(calculatePrice());
      });
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
    _stopPendingOrderRetryTimer(); // 🔑 CRITICAL: Stop periodic retry timer
    _cleanupResources();
    super.dispose();
  }
}

enum PaymentGateway { razorpay, paytm, cod, wallet }

// Helper for unawaited futures
void unawaited(Future<void> future) {
  future.then((_) {}).catchError((e) {});
}
