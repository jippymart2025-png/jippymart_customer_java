import 'package:jippymart_customer/app/cart_screen/cart_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    hide unawaited;
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_product_details_image_widget.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:provider/provider.dart';

class CartCheckOutScreen extends StatefulWidget {
  final bool hideBackButton;
  final String? source;
  final bool isFromMartNavigation;

  const CartCheckOutScreen({
    super.key,
    this.hideBackButton = false,
    this.source,
    this.isFromMartNavigation = false,
  });

  @override
  State<CartCheckOutScreen> createState() => _CartCheckOutScreenState();
}

class _CartCheckOutScreenState extends State<CartCheckOutScreen> {
  late CartControllerProvider controller;
  late DashBoardProvider _dashboardProvider;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  int? _lastSelectedIndex;
  static const Duration _minRefreshInterval = Duration(
    seconds: 3,
  ); // Increased to 3 seconds
  static const Duration _tabChangeDebounce = Duration(milliseconds: 500);
  DateTime? _lastTabChangeTime;

  // Cache for theme colors to avoid recalculating
  CartThemeColors? _cachedThemeColors;
  CartTheme? _lastTheme;

  @override
  void initState() {
    super.initState();
    controller = Provider.of<CartControllerProvider>(context, listen: false);
    _dashboardProvider = Provider.of<DashBoardProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    // Initial setup without heavy API calls
    controller.initFunction(context);

    // Only do full refresh if cart is empty or hasn't been loaded recently
    if (HomeProvider.cartItem.isEmpty ||
        _lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!) >
            const Duration(minutes: 5)) {
      await _refreshCartData(context);
    } else {
      // Just update UI state without API calls
      controller.checkAndUpdatePaymentMethod();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if coming from background or after significant time
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > const Duration(minutes: 2)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshCartDataIfNeeded(context);
      });
    }
  }

  Future<void> _refreshCartDataIfNeeded(BuildContext context) async {
    // Prevent unnecessary refreshes
    if (_isRefreshing || HomeProvider.cartItem.isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minRefreshInterval) {
      return;
    }

    await _refreshCartData(context);
  }

  Future<void> _refreshCartData(BuildContext context) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    print('[CART_CHECKOUT] 🔄 Refreshing cart data...');

    try {
      // Only force refresh if cart has items
      if (HomeProvider.cartItem.isNotEmpty) {
        await controller.forceRefreshCart();
      }

      // Initialize address only if needed
      if (controller.selectedAddress == null ||
          controller.selectedAddress!.location?.latitude == null ||
          controller.selectedAddress!.location?.longitude == null) {
        await controller.initializeAddress(context);
      } else {
        // Sync address but don't wait for completion
        unawaited(controller.syncAddressWithHomeLocation(context));
      }

      // Check payment method
      controller.checkAndUpdatePaymentMethod();

      // Start background price sync only if cart has items
      if (HomeProvider.cartItem.isNotEmpty) {
        _startBackgroundPriceSync();
      }
    } catch (e) {
      print('[CART_CHECKOUT] ❌ Error refreshing cart: $e');
    } finally {
      _isRefreshing = false;
      print('[CART_CHECKOUT] ✅ Cart refresh complete');
    }
  }

  void _startBackgroundPriceSync() {
    // Only sync prices in background, don't wait for it
    unawaited(
      controller.syncCartPricesInBackground().catchError((error) {
        print('[CART_CHECKOUT] ❌ Error in background price sync: $error');
      }),
    );
  }

  void _handleTabChange(int newIndex) {
    final now = DateTime.now();

    // Debounce tab changes
    if (_lastTabChangeTime != null &&
        now.difference(_lastTabChangeTime!) < _tabChangeDebounce) {
      return;
    }

    _lastTabChangeTime = now;

    // Only refresh when switching TO cart tab (index 2)
    if (newIndex == 2 && _lastSelectedIndex != 2) {
      _lastSelectedIndex = 2;

      // Use a slight delay to allow UI to settle
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _refreshCartDataIfNeeded(context);
        }
      });
    } else if (newIndex != 2) {
      _lastSelectedIndex = newIndex;
    }
  }

  // Get theme colors with caching
  CartThemeColors _getThemeColors(CartTheme theme) {
    // Return cached value if theme hasn't changed
    if (_lastTheme == theme && _cachedThemeColors != null) {
      return _cachedThemeColors!;
    }

    _lastTheme = theme;

    switch (theme) {
      case CartTheme.mart:
        _cachedThemeColors = CartThemeColors(
          primary: MartTheme.jippyMartButton,
          primaryDark: const Color(0xFF005A52),
          accent: const Color(0xFF00A896),
          surface: Colors.white,
          onSurface: Colors.black87,
        );
        break;
      case CartTheme.food:
        _cachedThemeColors = CartThemeColors(
          primary: const Color(0xFFFF6B35),
          primaryDark: const Color(0xFFE55A2B),
          accent: const Color(0xFFFF8A65),
          surface: AppThemeData.surface,
          onSurface: Colors.black87,
        );
        break;
      case CartTheme.mixed:
        _cachedThemeColors = CartThemeColors(
          primary: const Color(0xFFFF6B35),
          primaryDark: const Color(0xFFE55A2B),
          accent: const Color(0xFFFF8A65),
          surface: AppThemeData.surface,
          onSurface: Colors.black87,
        );
        break;
    }

    return _cachedThemeColors!;
  }

  // Determine cart theme with optimization
  CartTheme _getCartTheme() {
    // If source is explicitly provided, use it
    if (widget.source != null) {
      if (widget.source == 'mart') {
        return CartTheme.mart;
      } else if (widget.source == 'food') {
        return CartTheme.food;
      }
    }

    // Check if cart is empty early
    if (HomeProvider.cartItem.isEmpty) {
      return CartTheme.food; // Default theme for empty cart
    }

    // Use a single loop instead of two separate any() checks
    bool hasMartItems = false;
    bool hasFoodItems = false;

    for (final item in HomeProvider.cartItem) {
      final vendorID = item.vendorID;
      final isMartItem =
          vendorID?.contains('mart') == true ||
          vendorID?.startsWith('demo_') == true ||
          vendorID?.contains('vendor') == true;

      if (isMartItem) {
        hasMartItems = true;
      } else {
        hasFoodItems = true;
      }

      // Early exit if we found both types
      if (hasMartItems && hasFoodItems) {
        return CartTheme.mixed;
      }
    }

    if (hasMartItems && !hasFoodItems) {
      return CartTheme.mart;
    } else if (hasFoodItems && !hasMartItems) {
      return CartTheme.food;
    } else {
      return CartTheme.mixed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartTheme = _getCartTheme();
    final themeColors = _getThemeColors(cartTheme);

    return Consumer2<CartControllerProvider, DashBoardProvider>(
      builder: (context, controller, dashboardProvider, _) {
        // Handle tab changes with optimization
        _handleTabChange(dashboardProvider.selectedIndex);

        return WillPopScope(
          onWillPop: () async {
            if (controller.isGlobalLocked) {
              ShowToastDialog.showToast(
                "Please wait, payment is processing...",
              );
              return false;
            }

            // Don't force refresh on back navigation - it's unnecessary
            // Only refresh if cart has items and hasn't been refreshed recently
            final now = DateTime.now();
            if (HomeProvider.cartItem.isNotEmpty &&
                (_lastRefreshTime == null ||
                    now.difference(_lastRefreshTime!) >
                        const Duration(seconds: 10))) {
              unawaited(controller.forceRefreshCart());
            }

            return true;
          },
          child: Scaffold(
            backgroundColor: themeColors.surface,
            appBar: AppBar(
              backgroundColor: themeColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: !widget.hideBackButton,
              centerTitle: true,
              title: Text(
                'Cart',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: _buildBody(context, controller, themeColors),
            bottomNavigationBar: HomeProvider.cartItem.isEmpty
                ? null
                : _buildBottomNavigationBar(themeColors),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CartControllerProvider controller,
    CartThemeColors themeColors,
  ) {
    if (HomeProvider.cartItem.isEmpty) {
      return Center(
        child: Text(
          "No Available Items",
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.primary300,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageConst.backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          // Use a memoized or cached version of this widget if possible
          cartProductDetailsImageWidget(controller),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(CartThemeColors themeColors) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: RoundedButtonFill(
          textColor: AppThemeData.surface,
          isEnabled: true,
          title: "Check Out".tr,
          height: 5,
          color: AppThemeData.primary300,
          fontSizes: 16,
          onPress: () => _navigateToCartScreen(context),
        ),
      ),
    );
  }

  void _navigateToCartScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CartScreen()));
  }

  @override
  void dispose() {
    // Clear cache
    _cachedThemeColors = null;
    _lastTheme = null;
    super.dispose();
  }
}

// Keep your existing CartTheme enum and CartThemeColors class
enum CartTheme { mart, food, mixed }

class CartThemeColors {
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color surface;
  final Color onSurface;

  CartThemeColors({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.surface,
    required this.onSurface,
  });
}
