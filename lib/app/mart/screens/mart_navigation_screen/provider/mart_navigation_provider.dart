import 'package:jippymart_customer/app/cart_screen/cart_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categories_screen/mart_categories_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/mart_home_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categories_screen/provider/mart_category_controller.dart';
import 'package:jippymart_customer/app/mart/screens/mart_profile_screen/mart_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../profile_screen/profile_screen.dart';

class MartNavigationProvider extends ChangeNotifier {
  int selectedIndex = 0;
  List<Widget> pageList = <Widget>[];
  late MartCategoryProvider martCategoryProvider;
  late MartProvider martProvider;

  int get currentPageIndex {
    switch (selectedIndex) {
      case 2:
        return 1; // Cart page in pageList
      case 3:
        return 2; // Profile page in pageList
      case 1:
        return 1; // Backward-compatible mapping
      default:
        return 0; // Home page
    }
  }

  void initFunction({required BuildContext context}) {
    martCategoryProvider = Provider.of<MartCategoryProvider>(
      context,
      listen: false,
    );
    martProvider = Provider.of<MartProvider>(context, listen: false);
    _initializePages();
    selectedIndex = 0;
  }

  void _initializePages() {
    pageList = [
      const MartHomeScreen(),
      // const MartCategoriesScreen(),
      const CartScreen(
        hideBackButton: false,
        source: 'mart',
        isFromMartNavigation: true,
      ),
      const ProfileScreen(),
    ];
    notifyListeners();
  }

  void changeIndex(int index) {
    selectedIndex = index;
    if (index == 1) {
      // Use loadCategoriesStreaming (with full fallback chain) for Categories tab,
      // not loadVendorCategories which can overwrite with empty/failed result
      if (martProvider.martCategories.isEmpty) {
        // martProvider.loadCategoriesStreaming(skipSubcategories: true);
      }
    }
    notifyListeners();
  }

  // Navigation methods
  void goToHome() => changeIndex(0);

  // void goToCategories() => changeIndex(1);

  void goToCart() => changeIndex(2);

  void goToProfile() => changeIndex(3);
}
