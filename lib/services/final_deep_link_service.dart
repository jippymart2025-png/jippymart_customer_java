import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/DealsScreen/DealsScreen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
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

  // iOS support using app_links package
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _appLinksSubscription;

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

    // Platform-specific initialization
    if (Platform.isAndroid) {
      // Android: Use event channels
      log('🔗 [FLUTTER] Setting up Android event channel listener...');
      print('🔗 [FLUTTER] PRINT TEST - Setting up Android event channel listener...');
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

      // Query initial link for Android
      log('🔗 [FLUTTER] Querying initial link (Android)...');
      await _getInitialLink(context);
    } else if (Platform.isIOS) {
      // iOS: Use app_links package
      log('🔗 [FLUTTER] Setting up iOS app_links listener...');
      print('🔗 [FLUTTER] PRINT TEST - Setting up iOS app_links listener...');
      _appLinks = AppLinks();

      // Listen to incoming links (app already running)
      _appLinksSubscription = _appLinks!.uriLinkStream.listen(
        (Uri uri) {
          final String url = uri.toString();
          log('🔗 [FLUTTER] Received link from iOS (app_links): $url');
          print('🔗 [FLUTTER] PRINT TEST - Received link from iOS (app_links): $url');
          _handleLink(url, context);
        },
        onError: (error) {
          log('❌ [FLUTTER] iOS app_links stream error: $error');
          print('❌ [FLUTTER] PRINT TEST - iOS app_links stream error: $error');
        },
      );

      // Handle initial link (cold start)
      try {
        final Uri? initialUri = await _appLinks!.getInitialLink();
        if (initialUri != null) {
          final String url = initialUri.toString();
          log('🔗 [FLUTTER] Received initial link from iOS: $url');
          print('🔗 [FLUTTER] PRINT TEST - Received initial link from iOS: $url');
          _handleLink(url, context);
        }
      } catch (e) {
        log('❌ [FLUTTER] Error getting initial iOS link: $e');
        print('❌ [FLUTTER] PRINT TEST - Error getting initial iOS link: $e');
      }
    }

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
    // Clean path segments - remove empty strings from trailing slashes
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    
    // Handle deals - check for 'deals' with or without trailing slash
    if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
      print('🔗 [GLOBAL_DEEPLINK] Deals link detected, navigating...');
      // Wait for app to be ready, then navigate
      await Future.delayed(Duration(milliseconds: 500));
      _navigateToDeals();
      return; // Don't process further
    }
    
    if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
      await Future.delayed(Duration(milliseconds: 500));
      print('🔗 [GLOBAL_DEEPLINK] Catering link clicked, navigating...');
      _navigateToCatering();
      return; // Don't process further
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

      // Clean restaurant ID (remove any trailing slashes or whitespace)
      restaurantId = restaurantId.trim().replaceAll(RegExp(r'[/\s]+$'), '');
      print('🔥 [NEW HANDLER] Cleaned Restaurant ID: $restaurantId');

      // Import FireStoreUtils for fetching restaurant data
      final restaurant = await FireStoreUtils.getVendorById(restaurantId);

      if (restaurant != null) {
        print('🔥 [NEW HANDLER] ✅ Restaurant found: ${restaurant.title}');
        print('🔥 [NEW HANDLER] Restaurant ID: ${restaurant.id}');
        print(
          '🔥 [NEW HANDLER] Restaurant Status: ${restaurant.isOpen == true ? "OPEN" : "CLOSED"}',
        );
        print('🔥 [NEW HANDLER] Restaurant Zone ID: ${restaurant.zoneId}');
        print('🔥 [NEW HANDLER] Selected Zone ID: ${Constant.selectedZone?.id}');

        // Check zone validation
        if (Constant.selectedZone?.id == null) {
          print('⚠️ [NEW HANDLER] No zone selected, cannot validate restaurant zone');
          ShowToastDialog.showToast(
            "Please select a zone first".tr,
          );
          _navigateToDashboard();
          return;
        }

        // Ensure zone matches current selected zone
        if (restaurant.zoneId != Constant.selectedZone?.id) {
          print(
            '⚠️ [NEW HANDLER] Restaurant zone ${restaurant.zoneId} != selected zone ${Constant.selectedZone?.id}',
          );
          ShowToastDialog.showToast(
            "Sorry, The Zone is not available in your area. Change the other location first."
                .tr,
          );
          _navigateToDashboard();
          return;
        }

        // Wait briefly for app to be ready
        print('🔥 [NEW HANDLER] Waiting briefly for app to be ready...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to restaurant details with actual data
        print('🔥 [NEW HANDLER] Navigating to restaurant details with data...');
        
        // Get the correct context (prefer navigator key context)
        final ctx = GlobalDeeplinkHandler.navigatorKey.currentContext ?? context;
        
        // Use GetX navigation with restaurant data
        try {
          RestaurantDetailsProvider restaurantDetailsProvider =
              Provider.of<RestaurantDetailsProvider>(ctx, listen: false);
          restaurantDetailsProvider.initFunction(vendorModels: restaurant);
          Get.to(() => const RestaurantDetailsScreen());
        } catch (e) {
          print('⚠️ [NEW HANDLER] Could not get provider from context, using arguments: $e');
          // Fallback: use GetX arguments
          Get.to(
            () => const RestaurantDetailsScreen(),
            arguments: {"vendorModel": restaurant},
          );
        }
      } else {
        print('❌ [NEW HANDLER] Restaurant not found for ID: $restaurantId');
        // Navigate to dashboard instead of showing nothing
        _navigateToDashboard();
      }
    } catch (e) {
      print('❌ [NEW HANDLER] Error navigating to restaurant: $e');
      print('🔍 [NEW HANDLER] Stack trace: ${StackTrace.current}');
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
    _appLinksSubscription?.cancel();
    _appLinksSubscription = null;
    _appLinks = null;
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

    // FIRST: Check if URL contains restaurant pattern (before parsing)
    if (url.contains('/restaurant/') || url.contains('/restaurants/')) {
      print('🔥 [NEW HANDLER] ✅ Detected restaurant URL pattern in: $url');
      // Use regex to extract restaurant ID, handling trailing slashes
      final regex = RegExp(r'/(?:restaurant|restaurants)/([^/?]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        String restaurantId = match.group(1)!.trim();
        // Remove any trailing slashes or whitespace
        restaurantId = restaurantId.replaceAll(RegExp(r'[/\s]+$'), '');
        print('🔥 [NEW HANDLER] ✅ Extracted Restaurant ID from URL: $restaurantId');
        if (restaurantId.isNotEmpty) {
          _navigateToRestaurantWithData(restaurantId, context);
          return;
        } else {
          print('❌ [NEW HANDLER] Restaurant ID is empty after extraction');
        }
      } else {
        print('❌ [NEW HANDLER] Could not extract restaurant ID from URL: $url');
      }
    }

    // Extract product ID from URL
    final uri = Uri.parse(url);
    // Clean path segments - remove empty strings from trailing slashes
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String? productId;

    // Log URL parsing for debugging
    print('🔥 [NEW HANDLER] Parsing URL: $url');
    print('🔥 [NEW HANDLER] Scheme: ${uri.scheme}');
    print('🔥 [NEW HANDLER] Path segments (cleaned): $pathSegments');
    print('🔥 [NEW HANDLER] Path segments length: ${pathSegments.length}');
    
    // Handle deals early - check for deals with or without trailing slash
    if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
      print('🔥 [NEW HANDLER] HTTPS scheme - Deals screen detected');
      _navigateToDeals();
      return;
    }

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
          final restaurantId = pathSegments[1].trim().replaceAll(RegExp(r'[/\s]+$'), '');
          print('🔥 [NEW HANDLER] Custom scheme - Restaurant ID: $restaurantId');
          _navigateToRestaurantWithData(restaurantId, context);
          return;
        }
        if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
          return;
        } else if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
          print('🔥 [NEW HANDLER] Custom scheme - Deals screen');
          _navigateToDeals();
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
      
      // Check for restaurant URLs FIRST (before product handling)
      if (pathSegments.isNotEmpty && pathSegments[0] == 'restaurant' && pathSegments.length >= 2) {
        // Handle restaurant ID - clean it (remove trailing slashes)
        String restaurantId = pathSegments[1].trim();
        // Remove any trailing slashes that might be in the ID itself
        restaurantId = restaurantId.replaceAll(RegExp(r'[/\s]+$'), '');
        print('🔥 [NEW HANDLER] HTTPS scheme - Restaurant ID: $restaurantId');
        _navigateToRestaurantWithData(restaurantId, context);
        return;
      } else if (pathSegments.isNotEmpty && pathSegments[0] == 'restaurants' && pathSegments.length >= 2) {
        // Handle restaurant ID - clean it (remove trailing slashes)
        String restaurantId = pathSegments[1].trim();
        // Remove any trailing slashes that might be in the ID itself
        restaurantId = restaurantId.replaceAll(RegExp(r'[/\s]+$'), '');
        print(
          '🔥 [NEW HANDLER] HTTPS scheme (plural) - Restaurant ID: $restaurantId',
        );
        _navigateToRestaurantWithData(restaurantId, context);
        return;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'product') {
        productId = pathSegments[1];
        print('🔥 [NEW HANDLER] HTTPS scheme - Product ID: $productId');
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
        print('🔥 [NEW HANDLER] HTTPS scheme - Category ID: $categoryId');
        if (categoryDetailsProvider != null) {
          _navigateToCategoryWithData(categoryId, categoryDetailsProvider);
        } else {
          print(
            '❌ [NEW HANDLER] CategoryDetailsProvider not available yet, skipping category navigation',
          );
        }
        return;
      } else if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
        // print('🔗 [GLOBAL_DEEPLINK] Catering link clicked, navigating...');
        // _navigateToCatering();
        return;
      } else if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
        print('🔥 [NEW HANDLER] HTTPS scheme - Deals screen (already handled above)');
        _navigateToDeals();
        return;
      } else if (pathSegments.isNotEmpty) {
        // Direct product ID in path (only if not restaurant/category)
        // Don't treat "restaurant" as a product ID
        if (            pathSegments[0] != 'restaurant' && 
            pathSegments[0] != 'restaurants' && 
            pathSegments[0] != 'category' && 
            pathSegments[0] != 'categories' &&
            pathSegments[0] != 'catering' &&
            pathSegments[0] != 'deals') {
          productId = pathSegments[0];
          print('🔥 [NEW HANDLER] Direct path segment as Product ID: $productId');
        } else {
          print('❌ [NEW HANDLER] Unknown URL pattern, cannot determine type');
        }
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

  void _navigateToDeals() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to DealsScreen via Dashboard');
      // Navigate to dashboard and set selected index to 2 (DealsScreen)
      final ctx = GlobalDeeplinkHandler.navigatorKey.currentContext;
      if (ctx != null) {
        // Check if we're already on dashboard
        final currentRoute = Get.currentRoute;
        if (currentRoute == '/') {
          // Already on dashboard, just change the tab
          try {
            final dashBoardProvider = Provider.of<DashBoardProvider>(ctx, listen: false);
            final homeProvider = Provider.of<HomeProvider>(ctx, listen: false);
            final splashProvider = Provider.of<SplashProvider>(ctx, listen: false);
            final cartProvider = Provider.of<CartControllerProvider>(ctx, listen: false);
            final orderProvider = Provider.of<OrderProvider>(ctx, listen: false);
            final favouriteProvider = Provider.of<FavouriteProvider>(ctx, listen: false);
            
            dashBoardProvider.changeNavbar(
              2, // DealsScreen index
              homeProvider,
              splashProvider,
              cartProvider,
              orderProvider,
              ctx,
              favouriteProvider,
            );
          } catch (e) {
            print('⚠️ [GLOBAL_DEEPLINK] Error accessing providers, navigating to dashboard: $e');
            Get.offAll(() => const DashBoardScreen());
            // Wait a bit then try to change tab
            Future.delayed(const Duration(milliseconds: 500), () {
              final newCtx = GlobalDeeplinkHandler.navigatorKey.currentContext;
              if (newCtx != null) {
                try {
                  final dashBoardProvider = Provider.of<DashBoardProvider>(newCtx, listen: false);
                  final homeProvider = Provider.of<HomeProvider>(newCtx, listen: false);
                  final splashProvider = Provider.of<SplashProvider>(newCtx, listen: false);
                  final cartProvider = Provider.of<CartControllerProvider>(newCtx, listen: false);
                  final orderProvider = Provider.of<OrderProvider>(newCtx, listen: false);
                  final favouriteProvider = Provider.of<FavouriteProvider>(newCtx, listen: false);
                  
                  dashBoardProvider.changeNavbar(
                    2,
                    homeProvider,
                    splashProvider,
                    cartProvider,
                    orderProvider,
                    newCtx,
                    favouriteProvider,
                  );
                } catch (e2) {
                  print('❌ [GLOBAL_DEEPLINK] Error changing tab after navigation: $e2');
                }
              }
            });
          }
        } else {
          // Not on dashboard, navigate to it first
          Get.offAll(() => const DashBoardScreen());
          // Wait a bit then change to deals tab
          Future.delayed(const Duration(milliseconds: 500), () {
            final newCtx = GlobalDeeplinkHandler.navigatorKey.currentContext;
            if (newCtx != null) {
              try {
                final dashBoardProvider = Provider.of<DashBoardProvider>(newCtx, listen: false);
                final homeProvider = Provider.of<HomeProvider>(newCtx, listen: false);
                final splashProvider = Provider.of<SplashProvider>(newCtx, listen: false);
                final cartProvider = Provider.of<CartControllerProvider>(newCtx, listen: false);
                final orderProvider = Provider.of<OrderProvider>(newCtx, listen: false);
                final favouriteProvider = Provider.of<FavouriteProvider>(newCtx, listen: false);
                
                dashBoardProvider.changeNavbar(
                  2,
                  homeProvider,
                  splashProvider,
                  cartProvider,
                  orderProvider,
                  newCtx,
                  favouriteProvider,
                );
              } catch (e) {
                print('❌ [GLOBAL_DEEPLINK] Error changing tab: $e');
              }
            }
          });
        }
      } else {
        // No context available, navigate to dashboard
        Get.offAll(() => const DashBoardScreen());
      }
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to deals: $e');
    }
  }
}
