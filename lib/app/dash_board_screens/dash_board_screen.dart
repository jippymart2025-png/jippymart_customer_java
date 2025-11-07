import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashBoardProvider>(context, listen: false);
      provider.initFunction(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashBoardProvider>(
      builder: (context, controller, _) {
        // Ensure pageList is initialized and has items
        final safePageList = controller.pageList.isNotEmpty
            ? controller.pageList
            : [const SizedBox()]; // Fallback empty widget

        final safeIndex = controller.selectedIndex.clamp(
          0,
          safePageList.length - 1,
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
              controller.changeNavbar(0);
            }
          },
          child: Scaffold(
            body: IndexedStack(index: safeIndex, children: safePageList),
            bottomNavigationBar: _buildBottomNavigationBar(controller),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(DashBoardProvider controller) {
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
        controller.changeNavbar(index.clamp(0, items.length - 1));
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
