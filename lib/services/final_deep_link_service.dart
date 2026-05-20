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
  bool _isAppResumed = false; // Track if app was resumed from background
  DateTime? _lastResumeTime; // Track when app was last resumed

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
      print(
        '🔗 [FLUTTER] PRINT TEST - Setting up Android event channel listener...',
      );
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
          print(
            '🔗 [FLUTTER] PRINT TEST - Received link from iOS (app_links): $url',
          );
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
          print(
            '🔗 [FLUTTER] PRINT TEST - Received initial link from iOS: $url',
          );
          _handleLink(url, context);
        }
      } catch (e) {
        log('❌ [FLUTTER] Error getting initial iOS link: $e');
        print('❌ [FLUTTER] PRINT TEST - Error getting initial iOS link: $e');
      }
    }

    log('🔗 [FINAL DEEP LINK SERVICE] ✅ Singleton initialized successfully');
  }

  Future<void> _getInitialLink(BuildContext context) async {
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

  /// Wait for navigator to be available
  Future<bool> _waitForNavigator() async {
    int attempts = 0;
    while (GlobalDeeplinkHandler.navigatorKey.currentState == null &&
        attempts < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    return GlobalDeeplinkHandler.navigatorKey.currentState != null;
  }

  /// Safely obtain a [CategoryDetailsProvider] from available context
  CategoryDetailsProvider? _getCategoryDetailsProvider(
    BuildContext? fallbackContext,
  ) {
    final ctx =
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? fallbackContext;
    if (ctx == null) return null;
    try {
      return Provider.of<CategoryDetailsProvider>(ctx, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _handleLink(String url, BuildContext context) async {
    // Check if this is a duplicate within a short time window
    if (_hasProcessedDeepLink && _pendingDeepLink == url) {
      print(
        '🔥🔥🔥 [FLUTTER] Deep link already processed, ignoring duplicate: $url',
      );
      return;
    }

    // If app was recently resumed, wait longer for app to be ready
    final isRecentlyResumed =
        _isAppResumed &&
        _lastResumeTime != null &&
        DateTime.now().difference(_lastResumeTime!).inSeconds < 3;

    if (isRecentlyResumed) {
      print(
        '🔥🔥🔥 [FLUTTER] App recently resumed, waiting for app to be ready...',
      );
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    _hasProcessedDeepLink = true;
    _pendingDeepLink = url;
    print('🔥🔥🔥 [FLUTTER] Storing deep link for processing: $url');

    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Handle deals and catering early (no login required)
    if (pathSegments.isNotEmpty) {
      if (pathSegments[0] == 'deals') {
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToDeals();
        return;
      }
      if (pathSegments[0] == 'catering') {
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToCatering();
        return;
      }
    }

    final isLoggedIn = await _checkUserLoginStatus();
    if (!isLoggedIn) {
      print(
        '🔥🔥🔥 [FLUTTER] User not logged in, deep link will be processed after login',
      );
      return;
    }

    try {
      GlobalDeeplinkHandler.instance.storeDeeplink(url, context);
      final categoryDetailsProvider = _getCategoryDetailsProvider(
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? context,
      );
      _newSimpleDeepLinkHandler(url, context, categoryDetailsProvider);
    } catch (e) {
      print('🔥🔥🔥 [FLUTTER] Error processing deep link: $e');
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
    if (_pendingDeepLink == null || _pendingDeepLink!.isEmpty) {
      print('🔥🔥🔥 [FLUTTER] No pending deep link to process');
      return;
    }

    print(
      '🔥🔥🔥 [FLUTTER] Processing pending deep link after login: $_pendingDeepLink',
    );

    try {
      GlobalDeeplinkHandler.instance.storeDeeplink(_pendingDeepLink!, context);
      final categoryDetailsProvider = _getCategoryDetailsProvider(
        GlobalDeeplinkHandler.navigatorKey.currentContext ?? context,
      );
      _newSimpleDeepLinkHandler(
        _pendingDeepLink!,
        context,
        categoryDetailsProvider,
      );
      _pendingDeepLink = null;
    } catch (e) {
      print('🔥🔥🔥 [FLUTTER] Error processing pending deep link: $e');
    }
  }

  /// Navigate to restaurant with actual data
  void _navigateToRestaurantWithData(
    String restaurantId,
    BuildContext context,
  ) async {
    try {
      print('🔥 [NEW HANDLER] ===== RESTAURANT DEEP LINK NAVIGATION =====');
      print('🔥 [NEW HANDLER] Restaurant ID: $restaurantId');
      restaurantId = restaurantId.trim().replaceAll(RegExp(r'[/\s]+$'), '');
      print('🔥 [NEW HANDLER] Cleaned Restaurant ID: $restaurantId');

      // Check if app was recently resumed
      final isRecentlyResumedLocal =
          _isAppResumed &&
          _lastResumeTime != null &&
          DateTime.now().difference(_lastResumeTime!).inSeconds < 5;

      if (isRecentlyResumedLocal) {
        print(
          '🔥 [NEW HANDLER] App recently resumed, waiting longer for stability...',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      // Ensure navigator is ready with longer wait if resumed
      final maxAttempts = isRecentlyResumedLocal ? 60 : 40;
      int attempts = 0;
      while (GlobalDeeplinkHandler.navigatorKey.currentState == null &&
          attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      if (GlobalDeeplinkHandler.navigatorKey.currentState == null) {
        print('❌ [NEW HANDLER] Navigator not ready, waiting...');
        await Future.delayed(
          Duration(milliseconds: isRecentlyResumedLocal ? 1500 : 1000),
        );
        if (!await _waitForNavigator()) {
          print(
            '❌ [NEW HANDLER] Navigator still not ready after wait, aborting',
          );
          return;
        }
      }

      print('🔥 [NEW HANDLER] Fetching restaurant data...');
      final restaurant = await FireStoreUtils.getVendorById(restaurantId);
      if (restaurant == null) {
        print('❌ [NEW HANDLER] Restaurant not found for ID: $restaurantId');
        ShowToastDialog.showToast("Restaurant not found".tr);
        return;
      }

      print('🔥 [NEW HANDLER] Restaurant found: ${restaurant.title}');

      if (!_validateRestaurantZone(restaurant.zoneId)) {
        print('❌ [NEW HANDLER] Zone validation failed');
        return;
      }

      // Wait a bit more to ensure UI is ready (longer if resumed)
      await Future.delayed(
        Duration(milliseconds: isRecentlyResumedLocal ? 800 : 500),
      );

      // Get context - try multiple times if needed
      BuildContext? ctx =
          GlobalDeeplinkHandler.navigatorKey.currentContext ?? context;
      int contextAttempts = 0;
      while (ctx == null && contextAttempts < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        ctx = GlobalDeeplinkHandler.navigatorKey.currentContext ?? context;
        contextAttempts++;
      }

      if (ctx == null) {
        print('❌ [NEW HANDLER] Context is null after retries, cannot navigate');
        return;
      }

      print('🔥 [NEW HANDLER] Context obtained, attempting navigation...');

      // Try navigation with multiple strategies
      bool navigationSuccess = false;
      int retryCount = 0;
      const maxRetries = 5;

      while (!navigationSuccess && retryCount < maxRetries) {
        try {
          print(
            '🔥 [NEW HANDLER] Navigation attempt ${retryCount + 1}/$maxRetries',
          );

          // Strategy 1: Use Provider + Navigator Key
          if (GlobalDeeplinkHandler.navigatorKey.currentState != null) {
            try {
              final restaurantDetailsProvider =
                  Provider.of<RestaurantDetailsProvider>(ctx, listen: false);
              restaurantDetailsProvider.initFunction(vendorModels: restaurant);

              GlobalDeeplinkHandler.navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => const RestaurantDetailsScreen(),
                ),
              );
              navigationSuccess = true;
              print(
                '✅ [NEW HANDLER] Successfully navigated using Provider + Navigator Key',
              );
              break;
            } catch (e) {
              print('⚠️ [NEW HANDLER] Provider + Navigator Key failed: $e');
            }
          }

          // Strategy 2: Use GetX directly
          try {
            Get.to(() => const RestaurantDetailsScreen());
            navigationSuccess = true;
            print('✅ [NEW HANDLER] Successfully navigated using GetX');
            break;
          } catch (e) {
            print('⚠️ [NEW HANDLER] GetX navigation failed: $e');
          }

          // Strategy 3: Use GetX with arguments
          try {
            Get.to(
              () => const RestaurantDetailsScreen(),
              arguments: {"vendorModel": restaurant},
            );
            navigationSuccess = true;
            print(
              '✅ [NEW HANDLER] Successfully navigated using GetX with arguments',
            );
            break;
          } catch (e) {
            print('⚠️ [NEW HANDLER] GetX with arguments failed: $e');
          }
        } catch (e) {
          retryCount++;
          print('⚠️ [NEW HANDLER] Navigation attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 400 * retryCount));
          }
        }
      }

      if (!navigationSuccess) {
        print('❌ [NEW HANDLER] Failed to navigate after $maxRetries attempts');
        // Final attempt with GetX and arguments
        try {
          Get.to(
            () => const RestaurantDetailsScreen(),
            arguments: {"vendorModel": restaurant},
          );
          print('✅ [NEW HANDLER] Final navigation attempt succeeded');
          navigationSuccess = true;
        } catch (e) {
          print('❌ [NEW HANDLER] All navigation attempts failed: $e');
          // Reset flag so it can be retried
          _hasProcessedDeepLink = false;
        }
      } else {
        // Reset flag after successful navigation to allow future deep links
        Future.delayed(const Duration(seconds: 2), () {
          _hasProcessedDeepLink = false;
          print(
            '🔥🔥🔥 [FLUTTER] Reset processed flag after successful navigation',
          );
        });
      }
    } catch (e, stackTrace) {
      print('❌ [NEW HANDLER] Error navigating to restaurant: $e');
      print('🔍 [NEW HANDLER] Stack trace: $stackTrace');
      // Reset flag on error so it can be retried
      _hasProcessedDeepLink = false;
    }
  }

  /// Validate restaurant zone matches selected zone
  bool _validateRestaurantZone(String? restaurantZoneId) {
    if (Constant.selectedZone?.id == null) {
      // ShowToastDialog.showToast("Please select a zone first".tr);
      _navigateToDashboard();
      return false;
    }

    if (restaurantZoneId != Constant.selectedZone?.id) {
      ShowToastDialog.showToast(
        "Sorry, The Zone is not available in your area. Change the other location first."
            .tr,
      );
      _navigateToDashboard();
      return false;
    }

    return true;
  }

  /// Navigate to category with actual data
  void _navigateToCategoryWithData(
    String categoryId,
    CategoryDetailsProvider categoryDetailsProvider,
  ) async {
    try {
      print('🔥 [NEW HANDLER] ===== CATEGORY DEEP LINK NAVIGATION =====');

      final categories = await MartFirestoreService().getCategories(
        limit: 1000,
      );
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => MartCategoryModel(),
      );

      if (category.id == null) {
        print('❌ [NEW HANDLER] Category not found for ID: $categoryId');
        _navigateToDashboard();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      categoryDetailsProvider.initFunction(
        categoryIds: categoryId,
        categoryNames: category.title ?? 'Category',
      );
      Get.to(() => const MartCategoryDetailScreen());
      print(
        '🔥✅ [NEW HANDLER] Successfully navigated to category detail screen!',
      );
    } catch (e) {
      print('❌ [NEW HANDLER] Error navigating to category: $e');
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

  /// Called when app resumes from background
  void onAppResumed() {
    _isAppResumed = true;
    _lastResumeTime = DateTime.now();
    // Reset processed flag when app resumes to allow new deep links
    _hasProcessedDeepLink = false;
    print(
      '🔥🔥🔥 [FLUTTER] App resumed from background, resetting deep link flags',
    );
  }

  /// Called when app goes to background
  void onAppPaused() {
    _isAppResumed = false;
    print('🔥🔥🔥 [FLUTTER] App paused, marking as not resumed');
  }

  void _newSimpleDeepLinkHandler(
    String url,
    BuildContext context,
    CategoryDetailsProvider? categoryDetailsProvider,
  ) async {
    print('🔥 [NEW HANDLER] Starting deep link handler for: $url');

    // If app was recently resumed, wait longer
    final isRecentlyResumedLocal =
        _isAppResumed &&
        _lastResumeTime != null &&
        DateTime.now().difference(_lastResumeTime!).inSeconds < 5;

    if (isRecentlyResumedLocal) {
      print(
        '🔥 [NEW HANDLER] App recently resumed, waiting longer for stability...',
      );
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Wait for Navigator to be available (max ~3 seconds when resumed)
    final maxAttempts = isRecentlyResumedLocal ? 60 : 40;
    int attempts = 0;
    while (GlobalDeeplinkHandler.navigatorKey.currentState == null &&
        attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (GlobalDeeplinkHandler.navigatorKey.currentState == null) {
      print('❌ [NEW HANDLER] Navigator not ready, retrying...');
      // Retry once more with longer delay
      await Future.delayed(
        Duration(milliseconds: isRecentlyResumedLocal ? 1000 : 500),
      );
      if (!await _waitForNavigator()) {
        print(
          '❌ [NEW HANDLER] Navigator still not ready, skipping deep link: $url',
        );
        return;
      }
    }

    // Extra delay when resumed to ensure UI is stable
    await Future.delayed(
      Duration(milliseconds: isRecentlyResumedLocal ? 500 : 300),
    );

    // Check for restaurant pattern first (before parsing) - PRIORITY HANDLING
    final restaurantId = _extractRestaurantIdFromUrl(url);
    if (restaurantId != null && restaurantId.isNotEmpty) {
      print('🔥 [NEW HANDLER] ✅ Restaurant ID extracted: $restaurantId');
      _navigateToRestaurantWithData(restaurantId, context);
      return;
    }

    // Extract product ID from URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String? productId;

    print('🔥 [NEW HANDLER] Parsing URL: $url (scheme: ${uri.scheme})');

    // Handle deals early
    if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
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
          final restaurantId = pathSegments[1].trim().replaceAll(
            RegExp(r'[/\s]+$'),
            '',
          );
          print(
            '🔥 [NEW HANDLER] Custom scheme - Restaurant ID: $restaurantId',
          );
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
      if (pathSegments.isNotEmpty &&
          pathSegments[0] == 'restaurant' &&
          pathSegments.length >= 2) {
        // Handle restaurant ID - clean it (remove trailing slashes)
        String restaurantId = pathSegments[1].trim();
        // Remove any trailing slashes that might be in the ID itself
        restaurantId = restaurantId.replaceAll(RegExp(r'[/\s]+$'), '');
        print('🔥 [NEW HANDLER] HTTPS scheme - Restaurant ID: $restaurantId');
        _navigateToRestaurantWithData(restaurantId, context);
        return;
      } else if (pathSegments.isNotEmpty &&
          pathSegments[0] == 'restaurants' &&
          pathSegments.length >= 2) {
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
      } else if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
        _navigateToDeals();
        return;
      } else if (pathSegments.isNotEmpty &&
          _isValidProductPath(pathSegments[0])) {
        productId = pathSegments[0];
        print('🔥 [NEW HANDLER] Direct path segment as Product ID: $productId');
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
      ProductModel? productModel = await FireStoreUtils.getProductById(
        productId,
      );
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
            Provider.of<RestaurantDetailsProvider>(ctx, listen: false);
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
      print('🔗 [GLOBAL_DEEPLINK] Navigating to CateringServiceScreen');
      Get.to(() => CateringServiceScreen());
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to catering: $e');
    }
  }

  /// Helper method to get all required providers for dashboard navigation
  _DashboardProviders? _getDashboardProviders(BuildContext? context) {
    if (context == null) return null;
    try {
      return _DashboardProviders(
        dashBoardProvider: Provider.of<DashBoardProvider>(
          context,
          listen: false,
        ),
        homeProvider: Provider.of<HomeProvider>(context, listen: false),
        splashProvider: Provider.of<SplashProvider>(context, listen: false),
        cartProvider: Provider.of<CartControllerProvider>(
          context,
          listen: false,
        ),
        orderProvider: Provider.of<OrderProvider>(context, listen: false),
        favouriteProvider: Provider.of<FavouriteProvider>(
          context,
          listen: false,
        ),
      );
    } catch (e) {
      print('⚠️ [FLUTTER] Error getting providers: $e');
      return null;
    }
  }

  /// Helper method to change dashboard tab
  void _changeDashboardTab(BuildContext context, int tabIndex) {
    final providers = _getDashboardProviders(context);
    if (providers == null) return;

    providers.dashBoardProvider.changeNavbar(
      tabIndex,
      providers.homeProvider,
      providers.splashProvider,
      providers.cartProvider,
      providers.orderProvider,
      context,
      providers.favouriteProvider,
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PATCH NOTES – FinalDeepLinkService (_navigateToDeals fix)
  //
  // Problem: _navigateToDeals() immediately switches the dashboard to
  // tab 2 (DealsScreen).  If the app just cold-started from the deep
  // link, Constant.selectedZone is still null at that point, so
  // DealsScreen.initState() finds no zone and renders "No deals".
  //
  // Fix: before switching tab, wait up to ~3 s for the zone to be
  // available (polling at 200 ms intervals).  If it never arrives,
  // navigate anyway so the user at least sees the screen (the Retry
  // button in _buildEmpty lets them reload manually).
  // ════════════════════════════════════════════════════════════════

  // ─── Drop-in replacement for _navigateToDeals() in FinalDeepLinkService ───

  void _navigateToDeals() async {
    try {
      print('🔗 [DEEP_LINK] Navigating to DealsScreen via Dashboard');

      // ── Wait for zone to be ready (up to ~3 s) ──────────────────
      int waited = 0;
      const pollMs = 200;
      const maxWaitMs = 3000;

      while (waited < maxWaitMs) {
        final zoneId =
            Constant.selectedZone?.id?.trim() ??
            Constant.selectedLocation.zoneId?.trim();
        if (zoneId != null && zoneId.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: pollMs));
        waited += pollMs;
      }

      final zoneReady =
          (Constant.selectedZone?.id?.trim() ?? '').isNotEmpty ||
          (Constant.selectedLocation.zoneId?.trim() ?? '').isNotEmpty;

      if (!zoneReady) {
        print(
          '⚠️ [DEEP_LINK] Zone still not ready after ${maxWaitMs}ms – '
          'navigating to Deals anyway; user can retry.',
        );
      } else {
        print('✅ [DEEP_LINK] Zone ready, navigating to Deals now.');
      }

      // ── Switch to Deals tab ──────────────────────────────────────
      final ctx = GlobalDeeplinkHandler.navigatorKey.currentContext;
      if (ctx == null) {
        Get.offAll(() => const DashBoardScreen());
        return;
      }

      final currentRoute = Get.currentRoute;
      if (currentRoute == '/') {
        // Already on dashboard – just switch the tab.
        _changeDashboardTab(ctx, 2);
      } else {
        Get.offAll(() => const DashBoardScreen());
        Future.delayed(const Duration(milliseconds: 500), () {
          final newCtx = GlobalDeeplinkHandler.navigatorKey.currentContext;
          if (newCtx != null) {
            _changeDashboardTab(newCtx, 2);
          }
        });
      }
    } catch (e) {
      print('❌ [DEEP_LINK] Error navigating to deals: $e');
      Get.offAll(() => const DashBoardScreen());
    }
  }

  // ─── ALSO update the same method in GlobalDeeplinkHandler ───────────────────
  // The GlobalDeeplinkHandler._navigateToDeals() is identical in logic;
  // replace it with the same polling approach (copy the method body above,
  // only difference is the print tag changes to '[GLOBAL_DEEPLINK]').
  /// Extract restaurant ID from URL using regex
  String? _extractRestaurantIdFromUrl(String url) {
    print('🔥 [NEW HANDLER] Extracting restaurant ID from URL: $url');

    if (!url.contains('/restaurant/') && !url.contains('/restaurants/')) {
      print('🔥 [NEW HANDLER] URL does not contain restaurant pattern');
      return null;
    }

    // Try multiple regex patterns to catch different URL formats
    final patterns = [
      RegExp(r'/(?:restaurant|restaurants)/([^/?]+)'),
      RegExp(r'/(?:restaurant|restaurants)/([^/?\s]+)'),
      RegExp(r'restaurant[es]?/([^/?\s]+)'),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(url);
      if (match != null) {
        final restaurantId = match
            .group(1)
            ?.trim()
            .replaceAll(RegExp(r'[/\s]+$'), '');
        if (restaurantId != null && restaurantId.isNotEmpty) {
          print('🔥 [NEW HANDLER] ✅ Extracted Restaurant ID: $restaurantId');
          return restaurantId;
        }
      }
    }

    print('🔥 [NEW HANDLER] ❌ Could not extract restaurant ID from URL');
    return null;
  }

  /// Check if path segment is a valid product path (not a reserved route)
  bool _isValidProductPath(String segment) {
    const reservedPaths = {
      'restaurant',
      'restaurants',
      'category',
      'categories',
      'catering',
      'deals',
    };
    return !reservedPaths.contains(segment);
  }
}

/// Helper class to hold dashboard providers
class _DashboardProviders {
  final DashBoardProvider dashBoardProvider;
  final HomeProvider homeProvider;
  final SplashProvider splashProvider;
  final CartControllerProvider cartProvider;
  final OrderProvider orderProvider;
  final FavouriteProvider favouriteProvider;

  _DashboardProviders({
    required this.dashBoardProvider,
    required this.homeProvider,
    required this.splashProvider,
    required this.cartProvider,
    required this.orderProvider,
    required this.favouriteProvider,
  });
}
