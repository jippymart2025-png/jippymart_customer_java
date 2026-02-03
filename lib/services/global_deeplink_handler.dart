import 'package:jippymart_customer/app/category_service/category__service_screen.dart';
import 'package:jippymart_customer/app/DealsScreen/DealsScreen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/crash_prevention.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../app/mart/provider/category_details_provider.dart'
    show CategoryDetailsProvider;
import 'cart_provider.dart';
import 'mart_firestore_service.dart';

/// 🔗 Global Deeplink Handler Service
///
/// This service handles deep links using a singleton pattern
/// and ensures navigation happens only after home screen is ready.
class GlobalDeeplinkHandler {
  GlobalDeeplinkHandler._privateConstructor();

  static final GlobalDeeplinkHandler _instance =
      GlobalDeeplinkHandler._privateConstructor();

  static GlobalDeeplinkHandler get instance => _instance;

  static final navigatorKey = GlobalKey<NavigatorState>();

  String? _pendingDeeplink;
  bool _isProcessing = false;
  String? _currentRestaurantId;

  /// Initialize the GlobalDeeplinkHandler
  static void init() {
    print('🔗 [MAIN] Initializing GlobalDeeplinkHandler FIRST...');

    _instance._handleInitialLink();
    _instance._listenToIncomingLinks();

    print('🔗 [MAIN] GlobalDeeplinkHandler initialized successfully');
  }

  /// Handle initial deep link (cold start)
  void _handleInitialLink() async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Ready to handle initial links');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Failed to handle initial link: $e');
    }
  }

  /// Listen to incoming deep links (app already running)
  void _listenToIncomingLinks() {
    print(' [GLOBAL_DEEPLINK] Listening for incoming deep links...');
  }

  /// Store a deep link for later processing
  void storeDeeplink(String url, BuildContext context) {
    if (url.isEmpty) return;

    // Rate limiting: Prevent too many deep links at once
    if (_isProcessing) {
      _pendingDeeplink = url;
      return;
    }

    _isProcessing = true;
    _pendingDeeplink = url;

    DeepLinkCrashPrevention.safeProcessDeepLink(url, () async {
      await _processDeeplink(url, context);
      _isProcessing = false;
    });
  }

  /// Check if there's a pending deep link
  bool get hasPendingDeeplink =>
      _pendingDeeplink != null && _pendingDeeplink!.isNotEmpty;

  /// Get the pending deep link
  String? get pendingDeeplink => _pendingDeeplink;

  /// Navigate to pending deep link (call this after home screen is ready)
  void navigatePendingDeeplink(BuildContext context) {
    if (!hasPendingDeeplink || _isProcessing) {
      return;
    }
    _isProcessing = true;
    try {
      navigateToLink(_pendingDeeplink!, context);
      clearPending();
    } catch (e) {
    } finally {
      _isProcessing = false;
    }
  }

  void navigateToLink(String link, BuildContext context) {
    final uri = Uri.parse(link);
    List<String> pathSegments;

    if (uri.scheme == 'jippymart') {
      // Custom scheme: jippymart://product/123 -> host is "product", path is "/123"
      pathSegments = uri.host.isNotEmpty 
          ? [uri.host, ...uri.pathSegments]
          : uri.pathSegments;
    } else {
      pathSegments = uri.pathSegments;
    }

    if (pathSegments.isEmpty) return;

    final routeType = pathSegments[0];
    final id = pathSegments.length > 1 ? pathSegments[1] : null;

    switch (routeType) {
      case 'product':
        if (id != null) _navigateToProduct(id, context);
        break;
      case 'restaurant':
        if (id != null) _navigateToRestaurant(id, context);
        break;
      case 'catering':
        _navigateToCatering();
        break;
      case 'deals':
        _navigateToDeals();
        break;
    }
  }

  void _navigateToCatering() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to CateringServiceScreen');
      Get.to(() => CateringServiceScreen()); // <-- your screen widget
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to catering: $e');
    }
  }

  /// Helper method to get all required providers for dashboard navigation
  _DashboardProviders? _getDashboardProviders(BuildContext? context) {
    if (context == null) return null;
    try {
      return _DashboardProviders(
        dashBoardProvider: Provider.of<DashBoardProvider>(context, listen: false),
        homeProvider: Provider.of<HomeProvider>(context, listen: false),
        splashProvider: Provider.of<SplashProvider>(context, listen: false),
        cartProvider: Provider.of<CartControllerProvider>(context, listen: false),
        orderProvider: Provider.of<OrderProvider>(context, listen: false),
        favouriteProvider: Provider.of<FavouriteProvider>(context, listen: false),
      );
    } catch (e) {
      print('⚠️ [GLOBAL_DEEPLINK] Error getting providers: $e');
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

  void _navigateToDeals() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to DealsScreen via Dashboard');
      final ctx = navigatorKey.currentContext;
      if (ctx == null) {
        Get.offAll(() => const DashBoardScreen());
        return;
      }

      final currentRoute = Get.currentRoute;
      if (currentRoute == '/') {
        // Already on dashboard, just change the tab
        _changeDashboardTab(ctx, 2);
      } else {
        // Not on dashboard, navigate to it first
        Get.offAll(() => const DashBoardScreen());
        Future.delayed(const Duration(milliseconds: 500), () {
          final newCtx = navigatorKey.currentContext;
          if (newCtx != null) {
            _changeDashboardTab(newCtx, 2);
          }
        });
      }
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to deals: $e');
      Get.offAll(() => const DashBoardScreen());
    }
  }

  /// Navigate to product details using GetX
  void _navigateToProduct(String productId, BuildContext context) async {
    final martController = Provider.of<MartProvider>(context, listen: false);
    final martNavigationProvider = Provider.of<MartNavigationProvider>(
      context,
      listen: false,
    );
    try {
      final product = await martController.getProductById(productId);
      if (product != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.to(() => MartProductDetailsScreen(product: product));
      } else {
        _navigateToMartHome(martNavigationProvider, context);
      }
      print('🔗 [GLOBAL_DEEPLINK] ===== END PRODUCT NAVIGATION =====');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to product: $e');
      _navigateToMartHome(martNavigationProvider, context);
    }
  }

  /// Navigate to mart home screen
  void _navigateToMartHome(
    MartNavigationProvider provider,
    BuildContext context,
  ) {
    provider.initFunction(context: context);
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const MartNavigationScreen()),
    );
  }

  /// Navigate to restaurant details
  void _navigateToRestaurant(String restaurantId, BuildContext context) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 🍽️ Navigating to restaurant: $restaurantId');

      // Clean restaurant ID
      restaurantId = restaurantId.trim().replaceAll(RegExp(r'[/\s]+$'), '');
      
      // Prevent duplicate navigation
      if (_currentRestaurantId == restaurantId) {
        print('🔗 [GLOBAL_DEEPLINK] ⚠️ Same restaurant already loaded, skipping');
        return;
      }
      _currentRestaurantId = restaurantId;

      // Wait for navigator to be ready
      if (!await _waitForNavigatorReady()) {
        print('❌ [GLOBAL_DEEPLINK] Navigator not ready, retrying navigation...');
        // Retry after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (!await _waitForNavigatorReady()) {
          print('❌ [GLOBAL_DEEPLINK] Navigator still not ready, aborting');
          return;
        }
      }

      final restaurant = await FireStoreUtils.getVendorById(restaurantId);
      if (restaurant == null) {
        print('❌ [GLOBAL_DEEPLINK] Restaurant not found for ID: $restaurantId');
        Get.toNamed('/');
        return;
      }

      // Validate zone
      if (!_validateRestaurantZone(restaurant.zoneId)) {
        return;
      }

      // Ensure context is available
      await Future.delayed(const Duration(milliseconds: 200));
      final ctx = navigatorKey.currentContext ?? context;
      
      if (ctx == null) {
        print('❌ [GLOBAL_DEEPLINK] Context is null, cannot navigate');
        return;
      }

      // Try to navigate with retry logic
      bool navigationSuccess = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!navigationSuccess && retryCount < maxRetries) {
        try {
          final restaurantDetailsProvider = Provider.of<RestaurantDetailsProvider>(
            ctx,
            listen: false,
          );
          restaurantDetailsProvider.initFunction(vendorModels: restaurant);
          
          // Use navigator key for more reliable navigation
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => const RestaurantDetailsScreen(),
              ),
            );
            navigationSuccess = true;
            print('✅ [GLOBAL_DEEPLINK] Successfully navigated to restaurant details');
          } else {
            // Fallback to GetX
            Get.to(() => const RestaurantDetailsScreen());
            navigationSuccess = true;
            print('✅ [GLOBAL_DEEPLINK] Successfully navigated to restaurant details (GetX)');
          }
        } catch (e) {
          retryCount++;
          print('⚠️ [GLOBAL_DEEPLINK] Navigation attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 300 * retryCount));
            // Try with arguments as fallback
            try {
              Get.to(
                () => const RestaurantDetailsScreen(),
                arguments: {'vendorModel': restaurant},
              );
              navigationSuccess = true;
              print('✅ [GLOBAL_DEEPLINK] Successfully navigated using arguments fallback');
            } catch (e2) {
              print('⚠️ [GLOBAL_DEEPLINK] Arguments fallback also failed: $e2');
            }
          }
        }
      }

      if (!navigationSuccess) {
        print('❌ [GLOBAL_DEEPLINK] Failed to navigate after $maxRetries attempts');
        // Reset current restaurant ID so it can be retried
        _currentRestaurantId = null;
        // Last resort: use GetX with arguments
        try {
          Get.to(
            () => const RestaurantDetailsScreen(),
            arguments: {'vendorModel': restaurant},
          );
          print('✅ [GLOBAL_DEEPLINK] Final navigation attempt succeeded');
        } catch (e) {
          print('❌ [GLOBAL_DEEPLINK] Final navigation attempt failed: $e');
          // Reset so it can be retried later
          _currentRestaurantId = null;
        }
      }
    } catch (e, stackTrace) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to restaurant: $e');
      print('🔍 [GLOBAL_DEEPLINK] Stack trace: $stackTrace');
      // Reset current restaurant ID so it can be retried
      _currentRestaurantId = null;
      // Don't navigate to home on error, let the user stay where they are
    }
  }

  /// Wait for navigator to be ready
  Future<bool> _waitForNavigatorReady() async {
    int attempts = 0;
    const maxAttempts = 40;
    while (navigatorKey.currentState == null && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    return navigatorKey.currentState != null;
  }

  /// Validate restaurant zone matches selected zone
  bool _validateRestaurantZone(String? restaurantZoneId) {
    if (Constant.selectedZone?.id == null) {
      ShowToastDialog.showToast("Please select a zone first".tr);
      Get.toNamed('/');
      return false;
    }

    if (restaurantZoneId != Constant.selectedZone?.id) {
      ShowToastDialog.showToast(
        "Sorry, The Zone is not available in your area. Change the other location first.".tr,
      );
      Get.toNamed('/');
      return false;
    }

    return true;
  }

  /// Clear pending deep link
  void clearPending() {
    _pendingDeeplink = null;
  }

  /// Test method to verify handler is working
  void testHandler() {
    print(
      '🔗 [GLOBAL_DEEPLINK] ✅ Handler is working! Test method called successfully',
    );
  }

  /// Process deep link with enhanced crash prevention
  Future<void> _processDeeplink(String url, BuildContext context) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Processing deep link: $url');

      // Enhanced crash prevention: delay for app stability
      await Future.delayed(const Duration(milliseconds: 1000));
      await Future.delayed(const Duration(milliseconds: 200));

      // Wait for navigator to be ready
      if (!await _waitForNavigatorReady()) {
        print('❌ [GLOBAL_DEEPLINK] Navigator not ready for processing');
        return;
      }

      // Process the deep link based on URL pattern
      // NOTE: Restaurant links are handled by FinalDeepLinkService._newSimpleDeepLinkHandler
      // to avoid duplicate processing. Only handle non-restaurant links here.
      if (url.contains('/mart/')) {
        try {
          final martNavigationProvider = Provider.of<MartNavigationProvider>(
            context,
            listen: false,
          );
          _navigateToMart(url, martNavigationProvider, context);
        } catch (e) {
          print('⚠️ [GLOBAL_DEEPLINK] Could not get MartNavigationProvider: $e');
        }
      } else if (url.contains('/product/')) {
        final productId = _extractProductId(url);
        if (productId != null) {
          _navigateToProduct(productId, context);
        }
      } else if (url.contains('/category/')) {
        final categoryId = _extractCategoryId(url);
        if (categoryId != null) {
          _navigateToCategory(categoryId, context);
        }
      } else if (url.contains('/deals') || url.contains('/deals/')) {
        _navigateToDeals();
      }
      // Restaurant links are handled by FinalDeepLinkService to avoid conflicts

      print('🔗 [GLOBAL_DEEPLINK] Deep link processed successfully: $url');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error processing deep link: $url - $e');
    }
  }

  /// Extract restaurant ID from URL
  String? _extractRestaurantId(String url) {
    final regex = RegExp(r'/(?:restaurant|restaurants)/([^/?]+)');
    final match = regex.firstMatch(url);
    String? restaurantId = match?.group(1);
    // Clean restaurant ID (remove any trailing slashes or whitespace)
    if (restaurantId != null) {
      restaurantId = restaurantId.trim().replaceAll(RegExp(r'[/\s]+$'), '');
    }
    return restaurantId;
  }

  /// Extract product ID from URL
  String? _extractProductId(String url) {
    final regex = RegExp(r'/product/([^/?]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Extract category ID from URL
  String? _extractCategoryId(String url) {
    final regex = RegExp(r'/category/([^/?]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Navigate to mart
  void _navigateToMart(
    String url,
    MartNavigationProvider martNavigationProvider,
    BuildContext context,
  ) {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 🛒 Navigating to mart: $url');
      // Navigate to mart home screen
      martNavigationProvider.initFunction(context: context);
      Get.offAll(() => const MartNavigationScreen());
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to mart: $e');
    }
  }

  /// Navigate to category
  Future<void> _navigateToCategory(
    String categoryId,
    BuildContext context,
  ) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 📂 Navigating to category: $categoryId');

      final categoryItems = await MartFirestoreService().getItemsByCategoryOnly(
        categoryId: categoryId,
      );

      if (categoryItems.isEmpty) {
        print('🔗 [GLOBAL_DEEPLINK] ❌ No items found for category ID: $categoryId');
        Get.toNamed('/');
        return;
      }

      final categoryName = categoryItems.first.name;
      await Future.delayed(const Duration(milliseconds: 500));

      final categoryDetailsProvider = Provider.of<CategoryDetailsProvider>(
        context,
        listen: false,
      );
      categoryDetailsProvider.initFunction(
        categoryIds: categoryId,
        categoryNames: categoryName,
      );
      Get.to(() => const MartCategoryDetailScreen());
      
      print('🔗 [GLOBAL_DEEPLINK] ✅ Successfully navigated to category detail screen');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to category: $e');
      Get.toNamed('/');
    }
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
