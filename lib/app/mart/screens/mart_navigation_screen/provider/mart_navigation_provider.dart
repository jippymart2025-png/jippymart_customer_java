import 'package:jippymart_customer/app/cart_screen/cart_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categories_screen/mart_categories_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/mart_home_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_profile_screen/mart_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MartNavigationProvider extends ChangeNotifier {
  RxInt selectedIndex = 0.obs;
  RxList<Widget> pageList = <Widget>[].obs;

  MartNavigationProvider() {
    initFunction();
  }

  void initFunction() {
    _initializePages();
  }

  void _initializePages() {
    pageList.value = [
      const MartHomeScreen(),
      const MartCategoriesScreen(),
      const CartScreen(
        hideBackButton: false,
        source: 'mart',
        isFromMartNavigation: true,
      ),
      const MartProfileScreen(),
    ];
    notifyListeners();
  }

  void changeIndex(int index) {
    selectedIndex.value = index;
    notifyListeners(); // Add this to ensure UI updates
  }

  // Navigation methods
  void goToHome() => changeIndex(0);

  void goToCategories() => changeIndex(1);

  void goToCart() => changeIndex(2);

  void goToProfile() => changeIndex(3);
}
