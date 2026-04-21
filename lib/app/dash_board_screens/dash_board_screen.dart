import 'dart:async';

import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/network_status_banner.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:provider/provider.dart';

import '../../services/cart_provider.dart';

// Hero gradient — keep in sync with home_screen_two.dart
const Color _kGradStart = Color(0xFFFF2D2D);
const Color _kGradEnd = Color(0xFFFF8C42);

const LinearGradient _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 1.0],
  colors: [_kGradStart, _kGradEnd],
);

/// Status bar can only be one opaque colour; use a blended tone from
/// the hero gradient so the transition into home feels smooth.
Color _statusBarTintFromHeroGradient() {
  return Color.lerp(_kGradStart, _kGradEnd, 0.18)!;
}

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _orderCountdownDuration = Duration(minutes: 30);
  static const Duration _orderStatusRefreshInterval = Duration(seconds: 20);
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Duration _remainingOrderTime = _orderCountdownDuration;
  final ValueNotifier<Duration> _remainingOrderTimeNotifier = ValueNotifier(
    _orderCountdownDuration,
  );
  DateTime? _activeOrderStartTime;
  String? _activeOrderId;
  Timer? _countdownTimer;
  Timer? _orderStatusRefreshTimer;
  bool _isOrderRefreshInFlight = false;
  final NotificationService _notificationService = NotificationService();
  int _lastCartItemCount = 0;
  int _lastSelectedIndex = -1;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdownTicker();
    _startOrderStatusRefreshTicker();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 800
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
      _syncActiveOrderCountdown(context.read<OrderProvider>());
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    unawaited(_notificationService.cancelOrderTimerNotification());
    _countdownTimer?.cancel();
    _orderStatusRefreshTimer?.cancel();
    _remainingOrderTimeNotifier.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startOrderStatusRefreshTicker() {
    _orderStatusRefreshTimer?.cancel();
    _orderStatusRefreshTimer = Timer.periodic(_orderStatusRefreshInterval, (
      _,
    ) async {
      if (!mounted) return;
      if (_activeOrderStartTime == null) return;
      if (_isOrderRefreshInFlight) return;
      final orderProvider = context.read<OrderProvider>();
      _isOrderRefreshInFlight = true;
      try {
        await orderProvider.getOrder(forceRefresh: true);
        if (mounted) _syncActiveOrderCountdown(orderProvider);
      } finally {
        _isOrderRefreshInFlight = false;
      }
    });
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeOrderStartTime == null) return;
      final endTime = _activeOrderStartTime!.add(_orderCountdownDuration);
      final remaining = endTime.difference(DateTime.now());
      final nextDuration = remaining.isNegative ? Duration.zero : remaining;
      if (nextDuration == Duration.zero) {
        setState(() {
          _activeOrderId = null;
          _activeOrderStartTime = null;
          _remainingOrderTime = Duration.zero;
        });
        _remainingOrderTimeNotifier.value = Duration.zero;
        unawaited(_notificationService.cancelOrderTimerNotification());
        return;
      }
      if (nextDuration != _remainingOrderTime) {
        _remainingOrderTime = nextDuration;
        _remainingOrderTimeNotifier.value = nextDuration;
        unawaited(
          _notificationService.showOrUpdateOrderTimerNotification(nextDuration),
        );
      }
    });
  }

  void _syncActiveOrderCountdown(OrderProvider orderProvider) {
    final activeOrder = _getLatestActiveOrder(orderProvider);
    if (activeOrder == null) {
      if (_activeOrderId != null || _activeOrderStartTime != null) {
        setState(() {
          _activeOrderId = null;
          _activeOrderStartTime = null;
          _remainingOrderTime = _orderCountdownDuration;
        });
        _remainingOrderTimeNotifier.value = _orderCountdownDuration;
      }
      unawaited(_notificationService.cancelOrderTimerNotification());
      return;
    }

    final orderId = activeOrder.id ?? '';
    final createdAt = activeOrder.createdAt?.toDate();
    final nextStart = createdAt ?? DateTime.now();
    if (_activeOrderId == orderId && _activeOrderStartTime == nextStart) {
      return;
    }

    final endTime = nextStart.add(_orderCountdownDuration);
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      if (_activeOrderId != null || _activeOrderStartTime != null) {
        setState(() {
          _activeOrderId = null;
          _activeOrderStartTime = null;
          _remainingOrderTime = Duration.zero;
        });
      }
      _remainingOrderTimeNotifier.value = Duration.zero;
      unawaited(_notificationService.cancelOrderTimerNotification());
      return;
    }
    setState(() {
      _activeOrderId = orderId;
      _activeOrderStartTime = nextStart;
      _remainingOrderTime = remaining.isNegative ? Duration.zero : remaining;
    });
    _remainingOrderTimeNotifier.value = _remainingOrderTime;
    unawaited(
      _notificationService.showOrUpdateOrderTimerNotification(
        _remainingOrderTime,
      ),
    );
  }

  OrderModel? _getLatestActiveOrder(OrderProvider orderProvider) {
    final activeOrders = orderProvider.allList.where((order) {
      final status = _normalizedStatus(order.status);
      return _isTimerEligibleStatus(status);
    }).toList();
    if (activeOrders.isEmpty) return null;
    activeOrders.sort((a, b) {
      final aTime =
          a.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return activeOrders.first;
  }

  String _normalizedStatus(String? status) {
    return status
            ?.toString()
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ')
            .replaceAll(RegExp(r'\s+'), ' ') ??
        '';
  }

  bool _isTerminalOrderStatus(String status) {
    return status == 'order completed' ||
        status == 'completed' ||
        status == 'delivered' ||
        status == 'order rejected' ||
        status == 'rejected' ||
        status == 'order_rejected' ||
        status == 'order cancelled' ||
        status == 'cancelled';
  }

  bool _isTimerEligibleStatus(String status) {
    if (status.isEmpty || _isTerminalOrderStatus(status)) {
      return false;
    }

    // Do not start timer on pending/new. Start from order placed onwards.
    if (status == 'pending' || status == 'new') {
      return false;
    }

    return status == 'order placed' ||
        status == 'order accepted' ||
        status == 'driver accepted' ||
        status == 'accepted' ||
        status == 'driver pending' ||
        status == 'order shipped' ||
        status == 'shipped' ||
        status == 'order in transit' ||
        status == 'in transit';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final orderProvider = context.read<OrderProvider>();
      unawaited(
        orderProvider.getOrder(forceRefresh: true).then((_) {
          if (mounted) _syncActiveOrderCountdown(orderProvider);
        }),
      );
      // Re-apply status bar style when returning from background
      final idx = context.read<DashBoardProvider>().selectedIndex;
      _applyStatusBarStyle(idx);

      final now = DateTime.now();
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime!) > const Duration(seconds: 5)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeDashboard();
        });
      }
    }
  }

  Future<void> _initializeDashboard() async {
    if (!mounted || _isInitialized) return;

    final dashBoardProvider = context.read<DashBoardProvider>();

    // Initialize only once
    if (dashBoardProvider.pageList.isEmpty) {
      await dashBoardProvider.initFunction(context);
    }

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashBoardProvider = context.read<DashBoardProvider>();
    final dashboardState = context.select<DashBoardProvider, (int, int)>(
      (p) => (p.pageList.length, p.selectedIndex),
    );
    if (dashboardState.$1 == 0) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _buildMainContent(dashBoardProvider);
  }

  void _applyStatusBarStyle(int tabIndex) {
    SystemChrome.setSystemUIOverlayStyle(
      tabIndex == 0
          ? SystemUiOverlayStyle(
              statusBarColor: _statusBarTintFromHeroGradient(),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
            ),
    );
  }

  Widget _buildMainContent(DashBoardProvider dashBoardProvider) {
    final safeIndex = dashBoardProvider.selectedIndex.clamp(
      0,
      dashBoardProvider.pageList.length - 1,
    );

    // Apply now (avoids one white frame) and again after layout.
    _applyStatusBarStyle(safeIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyStatusBarStyle(safeIndex);
    });

    final cartControllerProvider = context.read<CartControllerProvider>();
    final cartItemCount = context.select<CartProvider, int>(
      (provider) => provider.totalQuantity,
    );
    final orderProvider = context.read<OrderProvider>();
    final splashProvider = context.read<SplashProvider>();
    final homeProvider = context.read<HomeProvider>();
    final favouriteProvider = context.read<FavouriteProvider>();
    final _ = context.select<DashBoardProvider, bool>((p) => p.canPopNow);

    final hasActiveOrder = _activeOrderStartTime != null;
    return PopScope(
      canPop: dashBoardProvider.canPopNow,
      onPopInvoked: (didPop) => _handleBackPress(
        didPop,
        dashBoardProvider,
        homeProvider,
        splashProvider,
        cartControllerProvider,
        orderProvider,
        context,
        favouriteProvider,
      ),
      child: Scaffold(
        body: _buildAnimatedBody(dashBoardProvider, safeIndex),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasActiveOrder) _buildOrderTimerBanner(),
            _buildOptimizedBottomBar(
              dashBoardProvider,
              cartControllerProvider,
              cartItemCount,
              orderProvider,
              context,
              splashProvider,
              homeProvider,
              favouriteProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimerBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppThemeData.danger300,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: AppThemeData.surface, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Order in progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppThemeData.surface,
              ),
            ),
          ),
          ValueListenableBuilder<Duration>(
            valueListenable: _remainingOrderTimeNotifier,
            builder: (_, remaining, __) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppThemeData.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDuration(remaining),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleBackPress(
    bool didPop,
    DashBoardProvider dashBoardProvider,
    HomeProvider homeProvider,
    SplashProvider splashProvider,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
    FavouriteProvider favouriteProvider,
  ) {
    if (didPop) return;

    if (dashBoardProvider.selectedIndex == 0) {
      final now = DateTime.now();
      _lastBackPressTime = now;

      if (dashBoardProvider.currentBackPressTime == null ||
          now.difference(dashBoardProvider.currentBackPressTime!) >
              const Duration(seconds: 2)) {
        dashBoardProvider.currentBackPressTime = now;
        dashBoardProvider.canPopNow = false;
        ShowToastDialog.showToast("Double press to exit".tr);
      } else {
        SystemNavigator.pop();
      }
    } else {
      dashBoardProvider.changeNavbar(
        0,
        homeProvider,
        splashProvider,
        cartControllerProvider,
        orderProvider,
        context,
        favouriteProvider,
      );
    }
  }

  Widget _buildAnimatedBody(
    DashBoardProvider dashBoardProvider,
    int safeIndex,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.getMaxContentWidth(context),
                ),
                child: Column(
                  children: [
                    const NetworkStatusBanner(),
                    Expanded(
                      child: IndexedStack(
                        index: safeIndex,
                        children: dashBoardProvider.pageList,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedBottomBar(
    DashBoardProvider controller,
    CartControllerProvider cartControllerProvider,
    int cartItemCount,
    OrderProvider orderProvider,
    BuildContext context,
    SplashProvider splashProvider,
    HomeProvider homeProvider,
    FavouriteProvider favouriteProvider,
  ) {
    final shouldUpdateBadge = cartItemCount != _lastCartItemCount;
    if (shouldUpdateBadge) {
      _lastCartItemCount = cartItemCount;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _BottomNavigationBar(
              controller: controller,
              cartControllerProvider: cartControllerProvider,
              orderProvider: orderProvider,
              splashProvider: splashProvider,
              homeProvider: homeProvider,
              favouriteProvider: favouriteProvider,
              context: context,
              cartItemCount: cartItemCount,
            ),
          ),
        );
      },
    );
  }
}

// Extracted bottom navigation bar widget to reduce rebuild scope
class _BottomNavigationBar extends StatelessWidget {
  final DashBoardProvider controller;
  final CartControllerProvider cartControllerProvider;
  final OrderProvider orderProvider;
  final SplashProvider splashProvider;
  final HomeProvider homeProvider;
  final FavouriteProvider favouriteProvider;
  final BuildContext context;
  final int cartItemCount;

  const _BottomNavigationBar({
    required this.controller,
    required this.cartControllerProvider,
    required this.orderProvider,
    required this.splashProvider,
    required this.homeProvider,
    required this.favouriteProvider,
    required this.context,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White background
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.white,
            height: 65 + MediaQuery.of(context).padding.bottom,
          ),
        ),
        // Navigation bar
        SafeArea(
          top: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background with shadow
              Container(
                width: MediaQuery.of(context).size.width,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/svg/courve3.svg',
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              // Navigation items
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 55,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Navigation items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            index: 0,
                            svgIcon: ImageConst.homeOne,
                            label: 'Home'.tr,
                            controller: controller,
                            homeProvider: homeProvider,
                            splashProvider: splashProvider,
                            cartControllerProvider: cartControllerProvider,
                            orderProvider: orderProvider,
                            context: context,
                            favouriteProvider: favouriteProvider,
                          ),
                          _NavItem(
                            index: 1,
                            svgIcon: ImageConst.cartOne,
                            label: 'Cart'.tr,
                            controller: controller,
                            homeProvider: homeProvider,
                            splashProvider: splashProvider,
                            cartControllerProvider: cartControllerProvider,
                            orderProvider: orderProvider,
                            context: context,
                            favouriteProvider: favouriteProvider,
                            cartItemCount: cartItemCount,
                          ),
                          const SizedBox(width: 60),
                          _NavItem(
                            index: 3,
                            svgIcon: ImageConst.orderOne,
                            label: 'Orders'.tr,
                            controller: controller,
                            homeProvider: homeProvider,
                            splashProvider: splashProvider,
                            cartControllerProvider: cartControllerProvider,
                            orderProvider: orderProvider,
                            context: context,
                            favouriteProvider: favouriteProvider,
                          ),
                          _NavItem(
                            index: 4,
                            svgIcon: ImageConst.profile,
                            label: 'Profile'.tr,
                            controller: controller,
                            homeProvider: homeProvider,
                            splashProvider: splashProvider,
                            cartControllerProvider: cartControllerProvider,
                            orderProvider: orderProvider,
                            context: context,
                            favouriteProvider: favouriteProvider,
                          ),
                        ],
                      ),
                      // Floating deals button
                      Positioned(
                        top: -30,
                        left: 0,
                        right: 0,
                        child: _FloatingDealsButton(
                          controller: controller,
                          homeProvider: homeProvider,
                          splashProvider: splashProvider,
                          cartControllerProvider: cartControllerProvider,
                          orderProvider: orderProvider,
                          context: context,
                          favouriteProvider: favouriteProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Extracted nav item widget for better performance
class _NavItem extends StatelessWidget {
  final int index;
  final String svgIcon;
  final String label;
  final DashBoardProvider controller;
  final HomeProvider homeProvider;
  final SplashProvider splashProvider;
  final CartControllerProvider cartControllerProvider;
  final OrderProvider orderProvider;
  final BuildContext context;
  final FavouriteProvider favouriteProvider;
  final int? cartItemCount;

  const _NavItem({
    required this.index,
    required this.svgIcon,
    required this.label,
    required this.controller,
    required this.homeProvider,
    required this.splashProvider,
    required this.cartControllerProvider,
    required this.orderProvider,
    required this.context,
    required this.favouriteProvider,
    this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedIndex == index;
    final hasCartBadge = cartItemCount != null && cartItemCount! > 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppThemeData.primary300.withOpacity(0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Opacity(
                      opacity: isSelected ? 0.9 : 0.6,
                      child: SvgPicture.asset(
                        svgIcon,
                        height: 14,
                        width: 14,
                        colorFilter: ColorFilter.mode(
                          isSelected
                              ? AppThemeData.primary300
                              : AppThemeData.grey600,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  // Cart badge
                  if (hasCartBadge && cartItemCount! > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartItemCount! > 9 ? '9+' : cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppThemeData.primary300
                      : AppThemeData.grey600,
                  fontFamily: AppThemeData.bold,
                ),
              ),
              // Selection indicator
              const SizedBox(height: 1),
              Container(
                width: isSelected ? 3 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppThemeData.primary300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    controller.changeNavbar(
      index,
      homeProvider,
      splashProvider,
      cartControllerProvider,
      orderProvider,
      context,
      favouriteProvider,
    );
  }
}

// Extracted floating deals button
class _FloatingDealsButton extends StatelessWidget {
  final DashBoardProvider controller;
  final HomeProvider homeProvider;
  final SplashProvider splashProvider;
  final CartControllerProvider cartControllerProvider;
  final OrderProvider orderProvider;
  final BuildContext context;
  final FavouriteProvider favouriteProvider;

  const _FloatingDealsButton({
    required this.controller,
    required this.homeProvider,
    required this.splashProvider,
    required this.cartControllerProvider,
    required this.orderProvider,
    required this.context,
    required this.favouriteProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedIndex == 2;

    return GestureDetector(
      onTap: () => _handleTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.purple,
                  AppThemeData.primary300.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeData.primary300.withOpacity(0.4),
                  blurRadius: isSelected ? 20 : 15,
                  spreadRadius: isSelected ? 2 : 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                // Deals icon
                Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    ImageConst.deals,
                    height: 45,
                    width: 45,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Deals label
          Text(
            'Deals'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? AppThemeData.primary300
                  : AppThemeData.grey600,
              fontFamily: AppThemeData.extraBold,
            ),
          ),
          // Selection indicator dot
          const SizedBox(height: 1),
          Container(
            width: isSelected ? 3 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppThemeData.primary300,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap() {
    controller.changeNavbar(
      2,
      homeProvider,
      splashProvider,
      cartControllerProvider,
      orderProvider,
      context,
      favouriteProvider,
    );
  }
}
