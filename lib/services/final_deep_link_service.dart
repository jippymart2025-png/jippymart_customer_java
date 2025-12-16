import 'dart:async';
import 'dart:developer';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/global_deeplink_handler.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart' show Provider;
import '../app/category_service/category__service_screen.dart';
import 'mart_firestore_service.dart';

class FinalDeepLinkService {
  // Singleton pattern
  static final FinalDeepLinkService _instance =
      FinalDeepLinkService._internal();

  factory FinalDeepLinkService() => _instance;

  FinalDeepLinkService._internal();

  static const EventChannel _eventChannel = EventChannel('deep_link_events');
  static const MethodChannel _methodChannel = MethodChannel(
    'deep_link_methods',
  );

  StreamSubscription? _sub;
  bool _initialized = false;
  String? _pendingDeepLink; // Added to store pending deep link
  bool _hasProcessedDeepLink = false; // Flag to prevent duplicate processing

  Future<void> init(
    GlobalKey<NavigatorState> navigatorKey,
    BuildContext context,
  ) async {
    if (_initialized) {
      return; // Prevent multiple subscriptions
    }

    _initialized = true;

    // 1) Listen to event stream (real-time links) - persistent subscription
    log('🔗 [FLUTTER] Setting up persistent event channel listener...');
    print('🔗 [FLUTTER] PRINT TEST - Setting up event channel listener...');
    _sub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic link) {
        if (link != null) {
          final String url = link as String;
          log('🔗 [FLUTTER] Received link from Android (event): $url');
          print(
            '🔗 [FLUTTER] PRINT TEST - Received link from Android (event): $url',
          );
          _handleLink(url, context);
        }
      },
      onError: (error) {
        log('❌ [FLUTTER] Deep link stream error: $error');
        print('❌ [FLUTTER] PRINT TEST - Deep link stream error: $error');
      },
    );

    // 2) Also query initial link (fallback if stream did not get cold-start link)
    log('🔗 [FLUTTER] Querying initial link...');
    await _getInitialLink(context);

    log('🔗 [FINAL DEEP LINK SERVICE] ✅ Singleton initialized successfully');
  }

  Future<void> _getInitialLink(
    BuildContext context,
  ) async {
    try {
      final String? initial = await _methodChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initial != null) {
        _handleLink(initial, context);
      } else {}
    } on PlatformException catch (e) {
      log('❌ [FLUTTER] getInitialLink failed: $e');
      print('❌ [FLUTTER] PRINT TEST - getInitialLink failed: $e');
    }
  }

  /// Safely obtain a [CategoryDetailsProvider] from whatever context is available.
  /// We prefer the [GlobalDeeplinkHandler.navigatorKey] context (inside the
  /// provider tree); if that is not ready yet, we fall back to the passed
  /// [fallbackContext]. If no suitable context is available or the provider
  /// is not found yet, this returns null instead of throwing.
  CategoryDetailsProvider? _getCategoryDetailsProvider(
    BuildContext? fallbackContext,
  ) {
    final ctx =
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? fallbackContext;
    if (ctx == null) return null;
    try {
      return Provider.of<CategoryDetailsProvider>(
        ctx,
        listen: false,
      );
    } catch (_) {
      // Provider tree may not be ready yet; we'll gracefully skip in that case.
      return null;
    }
  }

  void _handleLink(
    String url,
    BuildContext context,
  ) async {
    _hasProcessedDeepLink = false;
    if (_hasProcessedDeepLink) {
      print(
        '🔥🔥🔥 [FLUTTER] Deep link already processed, ignoring duplicate: $url',
      );
      return;
    }

    // Mark as processed immediately to prevent duplicate calls
    _hasProcessedDeepLink = true;

    // Store the deep link so we can retry once providers / login are ready
    print(
      '🔥🔥🔥 [FLUTTER] Storing deep link for processing after login: $url',
    );
    _pendingDeepLink = url;
    print(
      '🔥🔥🔥 [FLUTTER] Deep link stored successfully. _pendingDeepLink: $_pendingDeepLink',
    );

    // Check if user is already logged in
    final isLoggedIn = await _checkUserLoginStatus();

    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
      await Future.delayed(Duration(seconds: 2));
      print('🔗 [GLOBAL_DEEPLINK] Catering link clicked, navigating...');
      _navigateToCatering();
    }

    if (isLoggedIn) {
      try {
        GlobalDeeplinkHandler.instance.storeDeeplink(url, context);
        print(
          '🔥🔥🔥 [FLUTTER] TEST: ✅ Successfully called GlobalDeeplinkHandler.storeDeeplink()',
        );
      } catch (e) {
        print(
          '🔥🔥🔥 [FLUTTER] TEST: ❌ Error calling GlobalDeeplinkHandler.storeDeeplink(): $e',
        );
      }

      // Try to obtain CategoryDetailsProvider only when actually needed.
      final categoryDetailsProvider = _getCategoryDetailsProvider(
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? context,
      );
      _newSimpleDeepLinkHandler(
        url,
        context,
        categoryDetailsProvider,
      );
    } else {
      print(
        '🔥🔥🔥 [FLUTTER] User not logged in, deep link will be processed after login',
      );
    }
  }

  /// Check if user is logged in
  Future<bool> _checkUserLoginStatus() async {
    try {
      // Check if user is authenticated by checking Firebase Auth
      final user = await SqlStorageConst.getFirebaseId();

      final isLoggedIn = user != null;
      print('🔍 [FLUTTER] User login status: $isLoggedIn (UID: $user)');
      return isLoggedIn;
    } catch (e) {
      print('❌ [FLUTTER] Error checking login status: $e');
      return false;
    }
  }

  /// Process pending deep link after user login
  void processPendingDeepLinkAfterLogin(BuildContext context) {
    print('🔥🔥🔥 [FLUTTER] processPendingDeepLinkAfterLogin() called');
    print('🔥🔥🔥 [FLUTTER] _pendingDeepLink: $_pendingDeepLink');
    print(
      '🔥🔥🔥 [FLUTTER] _pendingDeepLink != null: ${_pendingDeepLink != null}',
    );
    print(
      '🔥🔥🔥 [FLUTTER] _pendingDeepLink!.isNotEmpty: ${_pendingDeepLink?.isNotEmpty ?? false}',
    );

    if (_pendingDeepLink != null && _pendingDeepLink!.isNotEmpty) {
      print(
        '🔥🔥🔥 [FLUTTER] Processing pending deep link after login: $_pendingDeepLink',
      );

      // **Process the pending deep link now that the user is logged in**
      print(
        '🔥🔥🔥 [FLUTTER] Calling GlobalDeeplinkHandler.storeDeeplink() with pending URL: $_pendingDeepLink',
      );
      GlobalDeeplinkHandler.instance.storeDeeplink(_pendingDeepLink!, context);

      final categoryDetailsProvider = _getCategoryDetailsProvider(
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? context,
      );
      _newSimpleDeepLinkHandler(
        _pendingDeepLink!,
        context,
        categoryDetailsProvider,
      );
      _pendingDeepLink = null; // Clear after processing
    } else {
      print('🔥🔥🔥 [FLUTTER] No pending deep link to process');
    }
  }

  /// **NEW: Navigate to restaurant with actual data**
  void _navigateToRestaurantWithData(
    String restaurantId,
    BuildContext context,
  ) async {
    try {
      print('🔥 [NEW HANDLER] ===== RESTAURANT DEEP LINK NAVIGATION =====');
      print('🔥 [NEW HANDLER] Restaurant ID: $restaurantId');

      // Import FireStoreUtils for fetching restaurant data
      final restaurant = await FireStoreUtils.getVendorById(restaurantId);

      if (restaurant != null) {
        print('🔥 [NEW HANDLER] ✅ Restaurant found: ${restaurant.title}');
        print('🔥 [NEW HANDLER] Restaurant ID: ${restaurant.id}');
        print(
          '🔥 [NEW HANDLER] Restaurant Status: ${restaurant.isOpen == true ? "OPEN" : "CLOSED"}',
        );

        // Wait briefly for app to be ready
        print('🔥 [NEW HANDLER] Waiting briefly for app to be ready...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to restaurant details with actual data
        print('🔥 [NEW HANDLER] Navigating to restaurant details with data...');
        // Use GetX navigation with restaurant data
        RestaurantDetailsProvider restaurantDetailsProvider =
            Provider.of<RestaurantDetailsProvider>(context, listen: false);
        restaurantDetailsProvider.initFunction(vendorModels: restaurant);
        Get.to(() => const RestaurantDetailsScreen());
      } else {
        // Navigate to dashboard instead of showing nothing
        _navigateToDashboard();
      }
    } catch (e) {
      print('❌ [NEW HANDLER] Error navigating to restaurant: $e');
      print('🔍 [NEW HANDLER] Redirecting to dashboard due to error...');

      // Navigate to dashboard on error
      _navigateToDashboard();
    }
  }

  /// **NEW: Navigate to category with actual data**
  void _navigateToCategoryWithData(
    String categoryId,
    CategoryDetailsProvider categoryDetailsProvider,
  ) async {
    try {
      print('🔥 [NEW HANDLER] ===== CATEGORY DEEP LINK NAVIGATION =====');
      print('🔥 [NEW HANDLER] Category ID: $categoryId');
      // **FIXED: Fetch actual category name from API**
      print('🔥 [NEW HANDLER] 🔍 Fetching category data for ID: $categoryId');
      // Use API to get all categories and find the specific one
      MartCategoryModel? category;
      final categories = await MartFirestoreService().getCategories(
        limit: 1000,
      );
      for (var cat in categories) {
        if (cat.id == categoryId) {
          category = cat;
          break;
        }
      }

      if (category != null) {
        print('🔥 [NEW HANDLER] ✅ Found category: ${category.title}');
        print(
          '🔥 [NEW HANDLER] Category Status: ${category.publish == true ? "PUBLISHED" : "UNPUBLISHED"}',
        );

        // Wait briefly for app to be ready
        print('🔥 [NEW HANDLER] Waiting briefly for app to be ready...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to specific category detail screen with actual category name
        print(
          '🔥 [NEW HANDLER] Navigating to specific category detail screen...',
        );
        categoryDetailsProvider.initFunction(
          categoryIds: categoryId,
          categoryNames: category.title ?? 'Category',
        );
        Get.to(() => const MartCategoryDetailScreen());
        print(
          '🔥✅ [NEW HANDLER] Successfully navigated to specific category detail screen!',
        );
      } else {
        print('❌ [NEW HANDLER] Category not found for ID: $categoryId');
        print('🔍 [NEW HANDLER] Redirecting to dashboard...');
        _navigateToDashboard();
      }
    } catch (e) {
      print('❌ [NEW HANDLER] Error navigating to category: $e');
      print('🔍 [NEW HANDLER] Redirecting to dashboard due to error...');

      // Navigate to dashboard on error
      _navigateToDashboard();
    }
  }

  // NOTE: _navigateToMartHome was previously used as a fallback when product
  // lookup failed. Deep link routing for products now prefers:
  // 1) Mart item details (MartProductDetailsScreen)
  // 2) Restaurant details (RestaurantDetailsScreen)
  // and no longer redirects to mart home implicitly.

  void _navigateToDashboard() {
    try {
      log('🔍 [FLUTTER] Navigating to dashboard');
      print('🔍 [FLUTTER] PRINT TEST - Navigating to dashboard');

      // Navigate to dashboard screen using GlobalDeeplinkHandler navigator key
      GlobalDeeplinkHandler.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const DashBoardScreen()),
      );
      log('🎯 [FLUTTER] Successfully navigated to dashboard');
      print('🎯 [FLUTTER] PRINT TEST - Successfully navigated to dashboard');
    } catch (e) {
      log('❌ [FLUTTER] Error navigating to dashboard: $e');
      print('❌ [FLUTTER] PRINT TEST - Error navigating to dashboard: $e');
    }
  }

  void dispose() {
    log('🔗 [FINAL DEEP LINK SERVICE] Disposing...');
    _sub?.cancel();
    _sub = null;
    _initialized = false;
    _pendingDeepLink = null;
    _hasProcessedDeepLink = false;
  }

  void clearLastProcessedLink() {
    _pendingDeepLink = null;
    _hasProcessedDeepLink = false;
    print('🔥🔥🔥 [FLUTTER] Cleared all deep link processing flags');
  }

  /// Force reset all deep link processing flags (for new deep links)
  void resetForNewDeepLink() {
    _hasProcessedDeepLink = false;
    _pendingDeepLink = null;
    print('🔥🔥🔥 [FLUTTER] Reset all flags for new deep link processing');
  }

  void _newSimpleDeepLinkHandler(
    String url,
    BuildContext context,
    CategoryDetailsProvider? categoryDetailsProvider,
  ) async {
    // Wait briefly for Navigator to be available (fast path, max ~2 seconds)
    int attempts = 0;
    while (GlobalDeeplinkHandler.navigatorKey.currentState == null &&
        attempts < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    if (GlobalDeeplinkHandler.navigatorKey.currentState == null) {
      print(
        '❌ [NEW HANDLER] Navigator not ready, skipping deep link handling for $url',
      );
      return;
    }
    // Small extra delay to let the current frame finish (avoid jank)
    await Future.delayed(const Duration(milliseconds: 200));

    // Extract product ID from URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    String? productId;

    // Handle different URL formats
    if (uri.scheme == 'jippymart') {
      // Custom scheme: jippymart://product/123 or jippymart://restaurant/123
      if (pathSegments.isNotEmpty) {
        if (pathSegments.length >= 2 && pathSegments[0] == 'product') {
          // Format: jippymart://product/123
          productId = pathSegments[1];
        } else if (pathSegments.length >= 2 &&
            pathSegments[0] == 'restaurant') {
          // Format: jippymart://restaurant/123
          final restaurantId = pathSegments[1];
          _navigateToRestaurantWithData(restaurantId, context);
          return;
        }
        if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
          return;
        } else {
          productId = pathSegments[0];
          print(
            '🔥 [NEW HANDLER] Custom scheme direct - Product ID: $productId',
          );
        }
      }
      // categories
    } else if (uri.scheme == 'https' || uri.scheme == 'http') {
      // HTTPS scheme: https://jippymart.in/product/123 or https://jippymart.in/restaurant/123
      if (pathSegments.length >= 2 && pathSegments[0] == 'product') {
        productId = pathSegments[1];
        print('🔥 [NEW HANDLER] HTTPS scheme - Product ID: $productId');
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'restaurant') {
        final restaurantId = pathSegments[1];
        print('🔥 [NEW HANDLER] HTTPS scheme - Restaurant ID: $restaurantId');
        _navigateToRestaurantWithData(restaurantId, context);
        return;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'restaurants') {
        final restaurantId = pathSegments[1];
        print(
          '🔥 [NEW HANDLER] HTTPS scheme (plural) - Restaurant ID: $restaurantId',
        );
        _navigateToRestaurantWithData(restaurantId, context);
        return;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'category') {
        final categoryId = pathSegments[1];
        print('🔥 [NEW HANDLER] HTTPS scheme - Category ID: $categoryId');
        if (categoryDetailsProvider != null) {
          _navigateToCategoryWithData(categoryId, categoryDetailsProvider);
        } else {
          print(
            '❌ [NEW HANDLER] CategoryDetailsProvider not available yet, skipping category navigation',
          );
        }
        return;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'categories') {
        final categoryId = pathSegments[1];
        print('🔥 ¸ $categoryId');
        if (categoryDetailsProvider != null) {
          _navigateToCategoryWithData(categoryId, categoryDetailsProvider);
        } else {
          print(
            '❌ [NEW HANDLER] CategoryDetailsProvider not available yet, skipping category navigation',
          );
        }
        return;
      }
      if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
        // print('🔗 [GLOBAL_DEEPLINK] Catering link clicked, navigating...');
        // _navigateToCatering();
        return;
      } else if (pathSegments.isNotEmpty) {
        // Direct product ID in path
        productId = pathSegments[0];
      }
    }

    if (productId != null) {
      print('🔥 [NEW HANDLER] Handling product deep link for ID: $productId');
      await _handleProductDeepLink(productId, context);
    } else {
      print('❌ [NEW HANDLER] No product ID found in URL');
    }
  }

  /// Handle product deep links in a robust way:
  /// 1) Try mart item (MartItemModel) via MartFirestoreService.
  /// 2) Fallback to restaurant product (ProductModel) via FireStoreUtils,
  ///    then navigate to the corresponding restaurant details.
  Future<void> _handleProductDeepLink(
    String productId,
    BuildContext context,
  ) async {
    try {
      // Try mart item first
      MartItemModel? martItem;
      try {
        final martService = Get.find<MartFirestoreService>();
        martItem = await martService.getItemById(productId);
      } catch (e) {
        print(
          '❌ [DEEP_LINK_PRODUCT] Error fetching mart item, will try restaurant product: $e',
        );
      }

      if (martItem != null) {
        print(
          '✅ [DEEP_LINK_PRODUCT] Found mart item for ID: $productId, navigating to MartProductDetailsScreen',
        );
        GlobalDeeplinkHandler.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (ctx) => MartProductDetailsScreen(product: martItem),
          ),
        );
        return;
      }

      // Fallback to restaurant product
      print(
        '🔍 [DEEP_LINK_PRODUCT] Mart item not found, trying restaurant product for ID: $productId',
      );
      ProductModel? productModel =
          await FireStoreUtils.getProductById(productId);
      if (productModel == null) {
        print(
          '❌ [DEEP_LINK_PRODUCT] No product (mart or restaurant) found for ID: $productId',
        );
        ShowToastDialog.showToast("Product not found".tr);
        return;
      }

      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        productModel.vendorID.toString(),
      );
      if (vendorModel == null) {
        print(
          '❌ [DEEP_LINK_PRODUCT] Vendor not found for product ID: $productId',
        );
        ShowToastDialog.showToast("Store not found".tr);
        return;
      }

      // Ensure zone matches current selected zone
      if (vendorModel.zoneId != Constant.selectedZone?.id) {
        print(
          '⚠️ [DEEP_LINK_PRODUCT] Vendor zone ${vendorModel.zoneId} != selected zone ${Constant.selectedZone?.id}',
        );
        ShowToastDialog.showToast(
          "Sorry, The Zone is not available in your area. Change the other location first."
              .tr,
        );
        return;
      }

      print(
        '✅ [DEEP_LINK_PRODUCT] Navigating to RestaurantDetailsScreen for vendor ${vendorModel.id}',
      );
      try {
        final ctx =
            GlobalDeeplinkHandler.navigatorKey.currentContext ?? context;
        final restaurantDetailsProvider =
            Provider.of<RestaurantDetailsProvider>(
          ctx,
          listen: false,
        );
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
      } catch (e) {
        print(
          '⚠️ [DEEP_LINK_PRODUCT] Could not initialize RestaurantDetailsProvider: $e',
        );
      }

      Get.to(
        () => const RestaurantDetailsScreen(),
        arguments: {"vendorModel": vendorModel},
      );
    } catch (e) {
      print(
        '❌ [DEEP_LINK_PRODUCT] Error handling product deep link for ID $productId: $e',
      );
      ShowToastDialog.showToast("Error loading product details".tr);
    }
  }

  void _navigateToCatering() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to CateringServiceScreen ');
      // Navigator.of(context).push(MaterialPageRoute(builder: (context)=>CateringServiceScreen()))
      Get.to(() => CateringServiceScreen()); // <-- your screen widget
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to catering: $e');
    }
  }
}
