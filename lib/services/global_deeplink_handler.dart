import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/category_service/category__service_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/utils/crash_prevention.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

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
  bool _isNavigating = false;
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
  void storeDeeplink(String url,BuildContext context) {
    print('🔗 [GLOBAL_DEEPLINK] 🚀 storeDeeplink() called with URL: $url');
    print(' [GLOBAL_DEEPLINK]  storeDeeplink() called with URL: $url');
    if (url.isEmpty) {
      print('🔗 [GLOBAL_DEEPLINK] ❌ Empty URL provided, skipping storage');
      return;
    }

    // **RATE LIMITING: Prevent too many deep links at once**
    if (_isProcessing) {
      print(
          '🔗 [GLOBAL_DEEPLINK] ⚠️ Already processing a deep link, queuing this one...');
      _pendingDeeplink = url;
      return;
    }

    print('🔗 [GLOBAL_DEEPLINK] ✅ Storing deeplink: $url');

    // Set processing flag to prevent concurrent processing
    _isProcessing = true;
    print(
        '🔗 [GLOBAL_DEEPLINK] ✅ Set processing flag to prevent concurrent processing');

    _pendingDeeplink = url;
    print(
        '🔗 [GLOBAL_DEEPLINK] ✅ Deeplink stored. Has pending: ${hasPendingDeeplink}');
    print('🔗 [GLOBAL_DEEPLINK] ✅ Pending deeplink value: $_pendingDeeplink');

    // **ENHANCED PROCESSING: Use crash prevention for ALL deep links**
    print(
        '🔗 [GLOBAL_DEEPLINK] 🛡️ Using enhanced crash prevention for all deep links');
    DeepLinkCrashPrevention.safeProcessDeepLink(url, () async {
      await _processDeeplink(url,context);
      // Reset processing flag after completion
      _isProcessing = false;
      print('🔗 [GLOBAL_DEEPLINK] ✅ Reset processing flag after completion');
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
      navigateToLink(_pendingDeeplink!,context);
      clearPending();
    } catch (e) {
    } finally {
      _isProcessing = false;
    }
  }

  void navigateToLink(String link,BuildContext context) {
    final uri = Uri.parse(link);
    // Handle both custom scheme and HTTPS URLs
    String pathToCheck;
    List<String> pathSegments;

    if (uri.scheme == 'jippymart') {
      // For custom scheme: jippymart://product/123 -> host is "product", path is "/123"
      if (uri.host.isNotEmpty) {
        pathToCheck = '/${uri.host}${uri.path}';
        pathSegments = [uri.host, ...uri.pathSegments];
      } else {
        pathToCheck = uri.path;
        pathSegments = uri.pathSegments;
      }
    } else {
      // For HTTP URLs: https://jippymart.in/product/123 -> path is "/product/123"
      pathToCheck = uri.path;
      pathSegments = uri.pathSegments;
    }

    if (pathSegments.isNotEmpty && pathSegments[0] == 'product') {
      final productId = pathSegments.length > 1 ? pathSegments[1] : null;
      if (productId != null) {
        _navigateToProduct(productId,context);
      } else {
      }
    } else if (pathSegments.isNotEmpty && pathSegments[0] == 'restaurant') {
      final restaurantId = pathSegments.length > 1 ? pathSegments[1] : null;
      if (restaurantId != null) {
        _navigateToRestaurant(restaurantId,context);
      } else {
      }
    } else if (pathSegments.isNotEmpty && pathSegments[0] == 'catering') {
      _navigateToCatering();
    } else {
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

  /// Navigate to product details using GetX
  void _navigateToProduct(String productId,BuildContext context) async {
    try {
      final martController =Provider.of<MartProvider>(context,listen: false);

      final product = await martController.getProductById(productId);
      if (product != null) {

        await Future.delayed(Duration(milliseconds: 500));
        Get.to(() => MartProductDetailsScreen(product: product));
      } else {

        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => const MartNavigationScreen(),
        ));
      }
      print('🔗 [GLOBAL_DEEPLINK] ===== END PRODUCT NAVIGATION =====');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to product: $e');
      print('🔗 [GLOBAL_DEEPLINK] Redirecting to mart home due to error...');
      // Navigate to mart home on error
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => const MartNavigationScreen(),
      ));
    }
  }

  /// Navigate to restaurant details
  void _navigateToRestaurant(String restaurantId,BuildContext context) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 🍽️ Navigating to restaurant: $restaurantId');
      // Track current restaurant to prevent duplicate navigation
      if (_currentRestaurantId == restaurantId) {
        print(
            '🔗 [GLOBAL_DEEPLINK] ⚠️ Same restaurant already loaded, skipping: $restaurantId');
        return;
      }
      _currentRestaurantId = restaurantId;

      // **FIXED: Fetch restaurant data first**
      print(
          '🔗 [GLOBAL_DEEPLINK] 🔍 Fetching restaurant data for ID: $restaurantId');

      // Import FireStoreUtils for fetching restaurant data
      final restaurant = await FireStoreUtils.getVendorById(restaurantId);

      if (restaurant != null) {
        print('🔗 [GLOBAL_DEEPLINK] ✅ Restaurant found: ${restaurant.title}');
        print('🔗 [GLOBAL_DEEPLINK] Restaurant ID: ${restaurant.id}');
        print(
            '🔗 [GLOBAL_DEEPLINK] Restaurant Status: ${restaurant.isOpen == true ? "OPEN" : "CLOSED"}');

        // **FIXED: Minimal delay for faster navigation**
        print(
            '🔗 [GLOBAL_DEEPLINK] DEBUG - Minimal delay for faster navigation...');
        await Future.delayed(Duration(milliseconds: 100));

        // **FIXED: Use GetX navigation with restaurant data and allow override**
        print(
            '🔗 [GLOBAL_DEEPLINK] DEBUG - Using GetX navigation to restaurant details with data...');

        // **FIXED: Use Get.to() instead of Get.offAll() to preserve navigation stack**
        // This allows the back button to work properly
        print(
            '🔗 [GLOBAL_DEEPLINK] DEBUG - Using Get.to() to preserve navigation stack...');
        Get.to(() => RestaurantDetailsScreen(), arguments: {
          'vendorModel': restaurant,
        });

        // Force a delay to ensure navigation completes
        await Future.delayed(Duration(milliseconds: 300));

        // Try to update the controller with new restaurant data after navigation
        try {

            print(
                '🔗 [GLOBAL_DEEPLINK] 🔍 Controller is registered, attempting update...');
            final controller = Provider.of<RestaurantDetailsProvider>(context,listen: false);

            print(
                '🔗 [GLOBAL_DEEPLINK] 🔍 Controller found, calling updateRestaurant...');
            controller.updateRestaurant(restaurant);

        } catch (e) {
          print('🔗 [GLOBAL_DEEPLINK] ❌ Could not update controller: $e');
        }

        print(
            '🔗 [GLOBAL_DEEPLINK] ✅ Successfully navigated to restaurant details with data: ${restaurant.title}');
      } else {
        print('🔗 [GLOBAL_DEEPLINK] ❌ Restaurant not found: $restaurantId');
        print('🔗 [GLOBAL_DEEPLINK] This could mean:');
        print('🔗 [GLOBAL_DEEPLINK] 1. Restaurant ID is incorrect');
        print('🔗 [GLOBAL_DEEPLINK] 2. Restaurant doesn\'t exist in database');
        print('🔗 [GLOBAL_DEEPLINK] 3. Restaurant is not published/available');
        print('🔗 [GLOBAL_DEEPLINK] Redirecting to home screen...');

        // Navigate to home screen instead of showing nothing
        Get.toNamed('/');
      }
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to restaurant: $e');
      print('🔗 [GLOBAL_DEEPLINK] Redirecting to home screen due to error...');

      // Navigate to home screen on error
      Get.toNamed('/');
    }
  }

  /// Clear pending deep link
  void clearPending() {
    print('🔗 [GLOBAL_DEEPLINK] 🧹 Clearing pending deeplink');
    _pendingDeeplink = null;
  }

  /// Test method to verify handler is working
  void testHandler() {
    print(
        '🔗 [GLOBAL_DEEPLINK] ✅ Handler is working! Test method called successfully');
  }

  /// Process deep link with enhanced crash prevention
  Future<void> _processDeeplink(String url,BuildContext context) async {
    try {
      print(
          '🔗 [GLOBAL_DEEPLINK] Processing deep link with enhanced crash prevention: $url');

      // **ENHANCED CRASH PREVENTION: Longer delay and memory management**
      print('🔗 [GLOBAL_DEEPLINK] 🛡️ Applying enhanced crash prevention...');
      await Future.delayed(
          const Duration(milliseconds: 1000)); // Increased delay

      // **MEMORY MANAGEMENT: Force garbage collection before processing**
      print('🔗 [GLOBAL_DEEPLINK] 🧹 Running garbage collection...');
      await Future.delayed(const Duration(milliseconds: 200));

      // Process the deep link with error handling
      if (url.contains('/restaurant/') || url.contains('/restaurants/')) {
        final restaurantId = _extractRestaurantId(url);
        if (restaurantId != null) {
          print(
              '🔗 [GLOBAL_DEEPLINK] 🍽️ Processing restaurant deep link: $restaurantId');
          _navigateToRestaurant(restaurantId,context);
        }
      } else if (url.contains('/mart/')) {
        _navigateToMart(url);
      } else if (url.contains('/product/')) {
        final productId = _extractProductId(url);
        if (productId != null) {
          _navigateToProduct(productId,context);
        }
      } else if (url.contains('/category/')) {
        final categoryId = _extractCategoryId(url);
        if (categoryId != null) {
          _navigateToCategory(categoryId);
        }
      }

      print('🔗 [GLOBAL_DEEPLINK] Deep link processed successfully: $url');
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error processing deep link: $url - $e');
      // **GRACEFUL ERROR HANDLING: Don't crash the app**
      print(
          '🔗 [GLOBAL_DEEPLINK] 🛡️ Graceful error handling - app continues running');
    }
  }

  /// Extract restaurant ID from URL
  String? _extractRestaurantId(String url) {
    final regex = RegExp(r'/(?:restaurant|restaurants)/([^/?]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
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
  void _navigateToMart(String url) {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 🛒 Navigating to mart: $url');
      // Navigate to mart home screen
      Get.offAll(() => const MartNavigationScreen());
    } catch (e) {
      print('❌ [GLOBAL_DEEPLINK] Error navigating to mart: $e');
    }
  }

  /// Navigate to category
  Future<void> _navigateToCategory(String categoryId) async {
    try {
      print('🔗 [GLOBAL_DEEPLINK] 📂 Navigating to category: $categoryId');

      // **FIXED: Use the same working logic as FinalDeepLinkService**
      print(
          '🔗 [GLOBAL_DEEPLINK] 🔍 Fetching category data for ID: $categoryId');

      // Use direct Firestore query to get category by ID
      final categoryDoc = await FirebaseFirestore.instance
          .collection('mart_categories')
          .doc(categoryId)
          .get();

      MartCategoryModel? category;
      if (categoryDoc.exists) {
        final data = categoryDoc.data()!;
        data['id'] = categoryDoc.id;
        category = MartCategoryModel.fromJson(data);
      }

      if (category != null) {
        print('🔗 [GLOBAL_DEEPLINK] ✅ Found category: ${category.title}');
        print(
            '🔗 [GLOBAL_DEEPLINK] Category Status: ${category.publish == true ? "PUBLISHED" : "UNPUBLISHED"}');

        // Wait briefly for app to be ready
        print('🔗 [GLOBAL_DEEPLINK] Waiting briefly for app to be ready...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to specific category detail screen with actual category name
        print(
            '🔗 [GLOBAL_DEEPLINK] Navigating to specific category detail screen...');
        Get.to(() => const MartCategoryDetailScreen(), arguments: {
          'categoryId': categoryId,
          'categoryName':
              category.title ?? 'Category', // Use actual category title
        });
        print(
            '🔗 [GLOBAL_DEEPLINK] ✅ Successfully navigated to specific category detail screen!');
      } else {
        print('🔗 [GLOBAL_DEEPLINK] ❌ Category not found for ID: $categoryId');
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
