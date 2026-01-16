import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/services/cart_provider.dart'
    as ServicesCartProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/network_status_banner.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    if (!mounted || _isInitialized) return;
    final dashBoardProvider = context.read<DashBoardProvider>();
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
    return Consumer6<
      DashBoardProvider,
      CartControllerProvider,
      OrderProvider,
      SplashProvider,
      HomeProvider,
      FavouriteProvider
    >(
      builder:
          (
            context,
            controller,
            cartControllerProvider,
            orderProvider,
            splashProvider,
            homeProvider,
            favouriteProvider,
            _,
          ) {
            if (controller.pageList.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && controller.pageList.isEmpty) {
                  controller.initFunction(context);
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final safeIndex = controller.selectedIndex.clamp(
              0,
              controller.pageList.length - 1,
            );

            return PopScope(
              canPop: controller.canPopNow,
              onPopInvoked: (didPop) {
                if (didPop) return;
                if (controller.selectedIndex == 0) {
                  final now = DateTime.now();
                  if (controller.currentBackPressTime == null ||
                      now.difference(controller.currentBackPressTime!) >
                          const Duration(seconds: 2)) {
                    controller.currentBackPressTime = now;
                    controller.canPopNow = false;
                    ShowToastDialog.showToast("Double press to exit".tr);
                  } else {
                    SystemNavigator.pop();
                  }
                } else {
                  controller.changeNavbar(
                    0,
                    homeProvider,
                    splashProvider,
                    cartControllerProvider,
                    orderProvider,
                    context,
                    favouriteProvider,
                  );
                }
              },
              child: Scaffold(
                // backgroundColor: AppThemeData.primary300,

                /// BODY (no top SafeArea)
                body: AnimatedBuilder(
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
                                    children: controller.pageList,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                /// ✅ Bottom Navigation Bar
                bottomNavigationBar: _buildEnhancedBottomBar(
                  controller,
                  cartControllerProvider,
                  orderProvider,
                  context,
                  splashProvider,
                  homeProvider,
                  favouriteProvider,
                ),
              ),
            );
          },
    );
  }

  Widget _buildEnhancedBottomBar(
    DashBoardProvider controller,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
    SplashProvider splashProvider,
    HomeProvider homeProvider,
    FavouriteProvider favouriteProvider,
  ) {
    return Stack(
      children: [
        // White background covering entire bottom area including safe area
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.white,
            height: 65 + MediaQuery.of(context).padding.bottom,
          ),
        ),
        // Navigation bar content
        SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 80 * (1 - _fadeAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Navigation bar with curve SVG - white background
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.white, // White background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 65,
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12, // lighter shadow
                                blurRadius: 3, // ✅ reduced blur
                                offset: Offset(0, -2), // ✅ less height
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
                      ),

                      // Navigation items container
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
                              // Bottom nav items
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildNavItem(
                                    index: 0,
                                    svgIcon: ImageConst.homeOne,
                                    label: 'Home'.tr,
                                    controller: controller,
                                    homeProvider: homeProvider,
                                    splashProvider: splashProvider,
                                    cartControllerProvider:
                                        cartControllerProvider,
                                    orderProvider: orderProvider,
                                    context: context,
                                    favouriteProvider: favouriteProvider,
                                  ),
                                  _buildNavItem(
                                    index: 1,
                                    svgIcon: ImageConst.cartOne,
                                    label: 'Cart'.tr,
                                    controller: controller,
                                    homeProvider: homeProvider,
                                    splashProvider: splashProvider,
                                    cartControllerProvider:
                                        cartControllerProvider,
                                    orderProvider: orderProvider,
                                    context: context,
                                    favouriteProvider: favouriteProvider,
                                    showCartBadge: true,
                                  ),
                                  const SizedBox(width: 60),
                                  // Space for center button
                                  _buildNavItem(
                                    index: 3,
                                    svgIcon: ImageConst.orderOne,
                                    label: 'Orders'.tr,
                                    controller: controller,
                                    homeProvider: homeProvider,
                                    splashProvider: splashProvider,
                                    cartControllerProvider:
                                        cartControllerProvider,
                                    orderProvider: orderProvider,
                                    context: context,
                                    favouriteProvider: favouriteProvider,
                                  ),
                                  _buildNavItem(
                                    index: 4,
                                    svgIcon: ImageConst.profile,
                                    label: 'Profile'.tr,
                                    controller: controller,
                                    homeProvider: homeProvider,
                                    splashProvider: splashProvider,
                                    cartControllerProvider:
                                        cartControllerProvider,
                                    orderProvider: orderProvider,
                                    context: context,
                                    favouriteProvider: favouriteProvider,
                                  ),
                                ],
                              ),
                              // Floating center Deals button
                              Positioned(
                                top: -30,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildFloatingDealsButton(
                                    controller,
                                    homeProvider,
                                    splashProvider,
                                    cartControllerProvider,
                                    orderProvider,
                                    context,
                                    favouriteProvider,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingDealsButton(
    DashBoardProvider controller,
    HomeProvider homeProvider,
    SplashProvider splashProvider,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
    FavouriteProvider favouriteProvider,
  ) {
    final isSelected = controller.selectedIndex == 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Hand GIF positioned to the right
        // Positioned(
        //   right: -120,
        //   top: -60,
        //   child: Image.asset(
        //     'assets/svg/hand3.gif',
        //     width: 130,
        //     height: 130,
        //     fit: BoxFit.contain,
        //   ),
        // ),

        // Deals button
        GestureDetector(
          onTap: () {
            controller.changeNavbar(
              2,
              homeProvider,
              splashProvider,
              cartControllerProvider,
              orderProvider,
              context,
              favouriteProvider,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
                    // Rotating background effect when selected
                    if (isSelected)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 6.28),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value,
                            child: Container(
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
                          );
                        },
                      ),
                    // Deals icon
                    Opacity(
                      opacity: 0.9,
                      child: Image.asset(
                        ImageConst.deals, // your .gif path
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
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppThemeData.primary300
                      : AppThemeData.grey600,
                  fontFamily: AppThemeData.extraBold,
                ),
                child: Text('Deals'.tr),
              ),
              // Selection indicator dot
              const SizedBox(height: 1),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String svgIcon,
    required String label,
    required DashBoardProvider controller,
    required HomeProvider homeProvider,
    required SplashProvider splashProvider,
    required CartControllerProvider cartControllerProvider,
    required OrderProvider orderProvider,
    required BuildContext context,
    required FavouriteProvider favouriteProvider,
    bool showCartBadge = false,
  }) {
    final isSelected = controller.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.changeNavbar(
            index,
            homeProvider,
            splashProvider,
            cartControllerProvider,
            orderProvider,
            context,
            favouriteProvider,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with background and badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
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
                  if (showCartBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Consumer<HomeProvider>(
                        builder: (context, homeProvider, _) {
                          final cartItemCount = HomeProvider.cartItem.length;
                          if (cartItemCount == 0) return const SizedBox();

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey<int>(cartItemCount),
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
                                cartItemCount > 9
                                    ? '9+'
                                    : cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppThemeData.primary300
                      : AppThemeData.grey600,
                  fontFamily: AppThemeData.bold,
                ),
                child: Text(label),
              ),
              // Selection indicator
              const SizedBox(height: 1),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
}
