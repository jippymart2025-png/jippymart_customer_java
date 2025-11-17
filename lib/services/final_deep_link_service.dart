import 'dart:async';
import 'dart:developer';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/services/global_deeplink_handler.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  late CategoryDetailsProvider categoryDetailsProvider;

  Future<void> init(
    GlobalKey<NavigatorState> navigatorKey,
    BuildContext context,
  ) async {
    categoryDetailsProvider = Provider.of<CategoryDetailsProvider>(
      context,
      listen: false,
    );
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
          _handleLink(url, context, categoryDetailsProvider);
        }
      },
      onError: (error) {
        log('❌ [FLUTTER] Deep link stream error: $error');
        print('❌ [FLUTTER] PRINT TEST - Deep link stream error: $error');
      },
    );

    // 2) Also query initial link (fallback if stream did not get cold-start link)
    log('🔗 [FLUTTER] Querying initial link...');
    await _getInitialLink(context, categoryDetailsProvider);

    log('🔗 [FINAL DEEP LINK SERVICE] ✅ Singleton initialized successfully');
  }

  Future<void> _getInitialLink(
    BuildContext context,
    CategoryDetailsProvider categoryDetailsProvider,
  ) async {
    try {
      final String? initial = await _methodChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initial != null) {
        _handleLink(initial, context, categoryDetailsProvider);
      } else {}
    } on PlatformException catch (e) {
      log('❌ [FLUTTER] getInitialLink failed: $e');
      print('❌ [FLUTTER] PRINT TEST - getInitialLink failed: $e');
    }
  }

  void _handleLink(
    String url,
    BuildContext context,
    CategoryDetailsProvider categoryDetailsProvider,
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

    // Store the deep link for processing when user is logged in
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

      _newSimpleDeepLinkHandler(url, context, categoryDetailsProvider);
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

      // **FIXED: Call GlobalDeeplinkHandler.storeDeeplink() to process the pending deep link**
      print(
        '🔥🔥🔥 [FLUTTER] Calling GlobalDeeplinkHandler.storeDeeplink() with pending URL: $_pendingDeepLink',
      );
      GlobalDeeplinkHandler.instance.storeDeeplink(_pendingDeepLink!, context);

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

  void _navigateToMartHome({
    required MartNavigationProvider martNavigationProvider,
    required BuildContext context,
  }) async {
    try {
      print(
        '\n🔗 [DEEP_LINK_SERVICE] ===== DEEP LINK MART NAVIGATION STARTED =====',
      );
      log('🔍 [FLUTTER] Navigating to mart home via deep link');
      print('🔍 [FLUTTER] PRINT TEST - Navigating to mart home via deep link');
      print(
        '📍 [DEEP_LINK_SERVICE] Current Zone: ${Constant.selectedZone?.id ?? "NULL"} (${Constant.selectedZone?.name ?? "NULL"})',
      );
      print(
        '📍 [DEEP_LINK_SERVICE] User Location: ${Constant.selectedLocation.location?.latitude ?? "NULL"}, ${Constant.selectedLocation.location?.longitude ?? "NULL"}',
      );

      // Check if mart is available in current zone
      final isMartAvailable =
          await MartZoneUtils.isMartAvailableInCurrentZone();

      if (isMartAvailable) {
        print(
          '✅ [DEEP_LINK_SERVICE] Mart is available - Navigating to MartNavigationScreen',
        );
        print(
          '🎯 [DEEP_LINK_SERVICE] Navigation: Deep Link -> MartNavigationScreen',
        );
        martNavigationProvider.initFunction(context: context);
        // Navigate to mart navigation screen using GlobalDeeplinkHandler navigator key
        GlobalDeeplinkHandler.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const MartNavigationScreen()),
        );
        log('🎯 [FLUTTER] Successfully navigated to mart home');
        print('🎯 [FLUTTER] PRINT TEST - Successfully navigated to mart home');
        print(
          '✅ [DEEP_LINK_SERVICE] Deep link navigation completed successfully',
        );
      } else {
        print(
          '❌ [DEEP_LINK_SERVICE] Mart not available - Redirecting to dashboard',
        );
        // Show coming soon message for zones without mart
        log(
          '⚠️ [FLUTTER] Mart not available in current zone: ${Constant.selectedZone?.id}',
        );
        print(
          '⚠️ [FLUTTER] PRINT TEST - Mart not available in current zone: ${Constant.selectedZone?.id}',
        );
        print(
          '🎯 [DEEP_LINK_SERVICE] Navigation: Deep Link -> Dashboard (fallback)',
        );
        _navigateToDashboard();
      }

      print(
        '🔗 [DEEP_LINK_SERVICE] ===== DEEP LINK MART NAVIGATION COMPLETED =====\n',
      );
    } catch (e) {
      print('❌ [DEEP_LINK_SERVICE] Error navigating to mart home: $e');
      log('❌ [FLUTTER] Error navigating to mart home: $e');
      print('❌ [FLUTTER] PRINT TEST - Error navigating to mart home: $e');
      print(
        '🎯 [DEEP_LINK_SERVICE] Navigation: Deep Link -> Dashboard (error fallback)',
      );
      _navigateToDashboard();
      print(
        '🔗 [DEEP_LINK_SERVICE] ===== DEEP LINK MART NAVIGATION COMPLETED (ERROR) =====\n',
      );
    }
  }

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
    CategoryDetailsProvider categoryDetailsProvider,
  ) async {
    // Wait for Navigator to be available
    int attempts = 0;
    while (GlobalDeeplinkHandler.navigatorKey.currentState == null &&
        attempts < 100) {
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }
    if (GlobalDeeplinkHandler.navigatorKey.currentState == null) {
      return;
    }
    // Wait additional 10 seconds for app to be fully ready

    await Future.delayed(Duration(seconds: 5));

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
        _navigateToCategoryWithData(categoryId, categoryDetailsProvider);
        return;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'categories') {
        final categoryId = pathSegments[1];
        print('🔥 ¸ $categoryId');
        _navigateToCategoryWithData(categoryId, categoryDetailsProvider);
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
    final martNavigationProvider = Provider.of<MartNavigationProvider>(
      context,
      listen: false,
    );
    if (productId != null) {
      try {
        try {
          final martController = Provider.of<MartProvider>(
            context,
            listen: false,
          );

          final product = await martController.getProductById(productId);

          if (product != null) {
            GlobalDeeplinkHandler.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) =>
                    MartProductDetailsScreen(product: product),
              ),
            );
          } else {
            _navigateToMartHome(
              martNavigationProvider: martNavigationProvider,
              context: context,
            );
          }
        } catch (e) {
          _navigateToMartHome(
            martNavigationProvider: martNavigationProvider,
            context: context,
          );
        }
      } catch (e) {
        _navigateToMartHome(
          martNavigationProvider: martNavigationProvider,
          context: context,
        );
      }
    } else {
      print('❌ [NEW HANDLER] No product ID found in URL');
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
