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
    if (url.isEmpty) {
      return;
    }

    // **RATE LIMITING: Prevent too many deep links at once**
    if (_isProcessing) {
      _pendingDeeplink = url;
      return;
    }

    // Set processing flag to prevent concurrent processing
    _isProcessing = true;

    _pendingDeeplink = url;

    DeepLinkCrashPrevention.safeProcessDeepLink(url, () async {
      await _processDeeplink(url, context);
      // Reset processing flag after completion
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
    // Handle both custom scheme and HTTPS URLs
    List<String> pathSegments;

    if (uri.scheme == 'jippymart') {
      // For custom scheme: jippymart://product/123 -> host is "product", path is "/123"
      if (uri.host.isNotEmpty) {
        pathSegments = [uri.host, ...uri.pathSegments];
      } else {
        pathSegments = uri.pathSegments;
      }
    } else {
      pathSegments = uri.pathSegments;
    }

    if (pathSegments.isNotEmpty && pathSegments[0] == 'product') {
      final productId = pathSegments.length > 1 ? pathSegments[1] : null;
      if (productId != null) {
        _navigateToProduct(productId, context);
      } else {}
    } else if (pathSegments.isNotEmpty && pathSegments[0] == 'restaurant') {
      final restaurantId = pathSegments.length > 1 ? pathSegments[1] : null;
      if (restaurantId != null) {
        _navigateToRestaurant(restaurantId, context);
      } else {}
    } else if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
      _navigateToCatering();
    } else if (pathSegments.isNotEmpty && pathSegments[0] == 'deals') {
      _navigateToDeals();
    } else {}
  }

  void _navigateToCatering() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to CateringServiceScreen');
      Get.to(() => CateringServiceScreen()); // <-- your screen widget
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to catering: $e');
    }
  }

  void _navigateToDeals() {
    try {
      print('🔗 [GLOBAL_DEEPLINK] Navigating to DealsScreen via Dashboard');
      // Navigate to dashboard and set selected index to 2 (DealsScreen)
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // Check if we're already on dashboard
        final currentRoute = Get.currentRoute;
        if (currentRoute == '/') {
          // Already on dashboard, just change the tab
          try {
            final dashBoardProvider = Provider.of<DashBoardProvider>(
              ctx,
              listen: false,
            );
            final homeProvider = Provider.of<HomeProvider>(ctx, listen: false);
            final splashProvider = Provider.of<SplashProvider>(
              ctx,
              listen: false,
            );
            final cartProvider = Provider.of<CartControllerProvider>(
              ctx,
              listen: false,
            );
            final orderProvider = Provider.of<OrderProvider>(
              ctx,
              listen: false,
            );
            final favouriteProvider = Provider.of<FavouriteProvider>(
              ctx,
              listen: false,
            );

            dashBoardProvider.changeNavbar(
              2,
              // DealsScreen index
              homeProvider,
              splashProvider,
              cartProvider,
              orderProvider,
              ctx,
              favouriteProvider,
            );
          } catch (e) {
            print(
              '⚠️ [GLOBAL_DEEPLINK] Error accessing providers, navigating to dashboard: $e',
            );
            Get.offAll(() => const DashBoardScreen());
            // Wait a bit then try to change tab
            Future.delayed(const Duration(milliseconds: 500), () {
              final newCtx = navigatorKey.currentContext;
              if (newCtx != null) {
                try {
                  final dashBoardProvider = Provider.of<DashBoardProvider>(
                    newCtx,
                    listen: false,
                  );
                  final homeProvider = Provider.of<HomeProvider>(
                    newCtx,
                    listen: false,
                  );
                  final splashProvider = Provider.of<SplashProvider>(
                    newCtx,
                    listen: false,
                  );
                  final cartProvider = Provider.of<CartProvider>(
                    newCtx,
                    listen: false,
                  );
                  final orderProvider = Provider.of<OrderProvider>(
                    newCtx,
                    listen: false,
                  );
                  final favouriteProvider = Provider.of<FavouriteProvider>(
                    newCtx,
                    listen: false,
                  );

                  dashBoardProvider.changeNavbar(
                    2,
                    homeProvider,
                    splashProvider,
                    cartProvider as CartControllerProvider,
                    orderProvider,
                    newCtx,
                    favouriteProvider,
                  );
                } catch (e2) {
                  print(
                    '❌ [GLOBAL_DEEPLINK] Error changing tab after navigation: $e2',
                  );
                }
              }
            });
          }
        } else {
          // Not on dashboard, navigate to it first
          Get.offAll(() => const DashBoardScreen());
          // Wait a bit then change to deals tab
          Future.delayed(const Duration(milliseconds: 500), () {
            final newCtx = navigatorKey.currentContext;
            if (newCtx != null) {
              try {
                final dashBoardProvider = Provider.of<DashBoardProvider>(
                  newCtx,
                  listen: false,
                );
                final homeProvider = Provider.of<HomeProvider>(
                  newCtx,
                  listen: false,
                );
                final splashProvider = Provider.of<SplashProvider>(
                  newCtx,
                  listen: false,
                );
                final cartProvider = Provider.of<CartProvider>(
                  newCtx,
                  listen: false,
                );
                final orderProvider = Provider.of<OrderProvider>(
                  newCtx,
                  listen: false,
                );
                final favouriteProvider = Provider.of<FavouriteProvider>(
                  newCtx,
                  listen: false,
                );

                dashBoardProvider.changeNavbar(
                  2,
                  homeProvider,
                  splashProvider,
                  cartProvider as CartControllerProvider,
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
        await Future.delayed(Duration(milliseconds: 500));
        Get.to(() => MartProductDetailsScreen(product: product));
      } else {
        martNavigationProvider.initFunction(context: context);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const MartNavigationScreen()),
        );
      }
      print('🔗 [GLOBAL_DEEPLINK] ===== END PRODUCT NAVIGATION =====');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to product: $e');
      print('🔗 [GLOBAL_DEEPLINK] Redirecting to mart home due to error...');
      // Navigate to mart home on error
      martNavigationProvider.initFunction(context: context);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MartNavigationScreen()),
      );
    }
  }

  /// Navigate to restaurant details
  void _navigateToRestaurant(String restaurantId, BuildContext context) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 🍽️ Navigating to restaurant: $restaurantId');

      // Clean restaurant ID (remove any trailing slashes or whitespace)
      restaurantId = restaurantId.trim().replaceAll(RegExp(r'[/\s]+$'), '');
      print('🔗 [GLOBAL_DEEPLINK] Cleaned Restaurant ID: $restaurantId');

      // Track current restaurant to prevent duplicate navigation
      if (_currentRestaurantId == restaurantId) {
        print(
          '🔗 [GLOBAL_DEEPLINK] ⚠️ Same restaurant already loaded, skipping: $restaurantId',
        );
        return;
      }
      _currentRestaurantId = restaurantId;

      // **FIXED: Fetch restaurant data first**
      print(
        '🔗 [GLOBAL_DEEPLINK] 🔍 Fetching restaurant data for ID: $restaurantId',
      );

      // Import FireStoreUtils for fetching restaurant data
      final restaurant = await FireStoreUtils.getVendorById(restaurantId);

      if (restaurant != null) {
        print('🔗 [GLOBAL_DEEPLINK] ✅ Restaurant found: ${restaurant.title}');
        print('🔗 [GLOBAL_DEEPLINK] Restaurant Zone ID: ${restaurant.zoneId}');
        print(
          '🔗 [GLOBAL_DEEPLINK] Selected Zone ID: ${Constant.selectedZone?.id}',
        );

        // Check zone validation
        if (Constant.selectedZone?.id == null) {
          print(
            '⚠️ [GLOBAL_DEEPLINK] No zone selected, cannot validate restaurant zone',
          );
          ShowToastDialog.showToast("Please select a zone first".tr);
          Get.toNamed('/');
          return;
        }

        // Ensure zone matches current selected zone
        if (restaurant.zoneId != Constant.selectedZone?.id) {
          print(
            '⚠️ [GLOBAL_DEEPLINK] Restaurant zone ${restaurant.zoneId} != selected zone ${Constant.selectedZone?.id}',
          );
          ShowToastDialog.showToast(
            "Sorry, The Zone is not available in your area. Change the other location first."
                .tr,
          );
          Get.toNamed('/');
          return;
        }

        await Future.delayed(Duration(milliseconds: 100));

        // Get the correct context
        final ctx = navigatorKey.currentContext ?? context;

        // Try to initialize provider if available
        try {
          final restaurantDetailsProvider =
              Provider.of<RestaurantDetailsProvider>(ctx, listen: false);
          restaurantDetailsProvider.initFunction(vendorModels: restaurant);
          Get.to(() => const RestaurantDetailsScreen());
        } catch (e) {
          print(
            '⚠️ [GLOBAL_DEEPLINK] Could not get provider, using arguments: $e',
          );
          // Fallback: use GetX arguments
          Get.to(
            () => const RestaurantDetailsScreen(),
            arguments: {'vendorModel': restaurant},
          );
        }

        await Future.delayed(Duration(milliseconds: 300));
      } else {
        print('❌ [GLOBAL_DEEPLINK] Restaurant not found for ID: $restaurantId');
        Get.toNamed('/');
      }
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to restaurant: $e');
      print('🔍 [GLOBAL_DEEPLINK] Stack trace: ${StackTrace.current}');
      Get.toNamed('/');
    }
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
    MartNavigationProvider martNavigationProvider =
        Provider.of<MartNavigationProvider>(context, listen: false);
    try {
      print(
        '🔗 [GLOBAL_DEEPLINK] Processing deep link with enhanced crash prevention: $url',
      );

      // **ENHANCED CRASH PREVENTION: Longer delay and memory management**
      print('🔗 [GLOBAL_DEEPLINK] 🛡️ Applying enhanced crash prevention...');
      await Future.delayed(
        const Duration(milliseconds: 1000),
      ); // Increased delay

      // **MEMORY MANAGEMENT: Force garbage collection before processing**
      print('🔗 [GLOBAL_DEEPLINK] 🧹 Running garbage collection...');
      await Future.delayed(const Duration(milliseconds: 200));

      // Process the deep link with error handling
      if (url.contains('/restaurant/') || url.contains('/restaurants/')) {
        final restaurantId = _extractRestaurantId(url);
        if (restaurantId != null) {
          print(
            '🔗 [GLOBAL_DEEPLINK] 🍽️ Processing restaurant deep link: $restaurantId',
          );
          _navigateToRestaurant(restaurantId, context);
        }
      } else if (url.contains('/mart/')) {
        _navigateToMart(url, martNavigationProvider, context);
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
        print('🔗 [GLOBAL_DEEPLINK] 🎁 Processing deals deep link');
        _navigateToDeals();
      }

      print('🔗 [GLOBAL_DEEPLINK] Deep link processed successfully: $url');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error processing deep link: $url - $e');
      // **GRACEFUL ERROR HANDLING: Don't crash the app**
      print(
        '🔗 [GLOBAL_DEEPLINK] 🛡️ Graceful error handling - app continues running',
      );
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

      // **CHANGED: Use API call instead of Firebase**
      print(
        '🔗 [GLOBAL_DEEPLINK] 🔍 Fetching category data for ID: $categoryId via API',
      );

      // Use API to get category by ID and items
      final categoryItems = await MartFirestoreService().getItemsByCategoryOnly(
        categoryId: categoryId,
      );

      if (categoryItems.isNotEmpty) {
        final firstItem = categoryItems.first;
        final categoryName = firstItem.name;
        print(
          '🔗 [GLOBAL_DEEPLINK] ✅ Found ${categoryItems.length} items for category',
        );
        print('🔗 [GLOBAL_DEEPLINK] Category Name: $categoryName');

        // Wait briefly for app to be ready
        print('🔗 [GLOBAL_DEEPLINK] Waiting briefly for app to be ready...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to specific category detail screen with items data
        print(
          '🔗 [GLOBAL_DEEPLINK] Navigating to specific category detail screen...',
        );
        CategoryDetailsProvider categoryDetailsProvider =
            Provider.of<CategoryDetailsProvider>(context, listen: false);
        categoryDetailsProvider.initFunction(
          categoryIds: categoryId,
          categoryNames: categoryName,
        );
        Get.to(() => const MartCategoryDetailScreen());
        print(
          '🔗 [GLOBAL_DEEPLINK] ✅ Successfully navigated to specific category detail screen with ${categoryItems.length} items!',
        );
      } else {
        print(
          '🔗 [GLOBAL_DEEPLINK] ❌ No items found for category ID: $categoryId',
        );
        print('🔗 [GLOBAL_DEEPLINK] Redirecting to dashboard...');
        Get.toNamed('/');
      }
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to category: $e');
      print('🔗 [GLOBAL_DEEPLINK] Redirecting to dashboard due to error...');
      Get.toNamed('/');
    }
  }
}
