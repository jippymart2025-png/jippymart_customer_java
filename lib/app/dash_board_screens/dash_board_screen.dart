import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
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

class _DashBoardScreenState extends State<DashBoardScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    if (!mounted || _isInitialized) return;
    final dashBoardProvider = context.read<DashBoardProvider>();
    await dashBoardProvider.initFunction(context);
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
                body: Center(
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
                bottomNavigationBar: _buildBottomNavigationBar(
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

  Widget _buildBottomNavigationBar(
    DashBoardProvider controller,
    CartControllerProvider cartControllerProvider,
    OrderProvider orderProvider,
    BuildContext context,
    SplashProvider splashProvider,
    HomeProvider homeProvider,
    FavouriteProvider favouriteProvider,
  ) {
    final List<BottomNavigationBarItem> items = [
      _buildNavigationBarItem(
        index: 0,
        assetIcon: ImageConst.homeOne,
        label: 'Home'.tr,
        controller: controller,
      ),
      _buildNavigationBarItem(
        index: 1,
        assetIcon: ImageConst.favoriteOne,
        label: 'Favourites'.tr,
        controller: controller,
      ),
      _buildNavigationBarItem(
        index: 2,
        assetIcon: ImageConst.cartOne,
        label: 'Cart'.tr,
        controller: controller,
      ),
      _buildNavigationBarItem(
        index: 3,
        assetIcon: ImageConst.orderOne,
        label: 'Orders'.tr,
        controller: controller,
      ),
    ];
    final safeIndex = controller.selectedIndex.clamp(0, items.length - 1);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      selectedFontSize: 12,
      selectedLabelStyle: const TextStyle(fontFamily: AppThemeData.bold),
      unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.bold),
      currentIndex: safeIndex,
      backgroundColor: AppThemeData.grey50,
      selectedItemColor: AppThemeData.primary300,
      unselectedItemColor: AppThemeData.grey600,
      onTap: (int index) {
        controller.changeNavbar(
          index.clamp(0, items.length - 1),
          homeProvider,
          splashProvider,
          cartControllerProvider,
          orderProvider,
          context,
          favouriteProvider,
        );
      },
      items: items,
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem({
    required int index,
    required String label,
    required String assetIcon,
    required DashBoardProvider controller,
  }) {
    final isSelected = controller.selectedIndex == index;
    final iconColor = isSelected
        ? (AppThemeData.primary300)
        : (AppThemeData.grey600);

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: assetIcon.endsWith('.svg')
            ? SvgPicture.asset(
                assetIcon,
                height: 22,
                width: 22,
                color: iconColor,
              )
            : Image.asset(assetIcon, height: 22, width: 22, color: iconColor),
      ),
      label: label,
    );
  }
}
