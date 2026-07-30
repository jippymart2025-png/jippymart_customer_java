import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../services/cart_provider.dart';
import '../../../themes/app_them_data.dart';
import '../../cart_screen/cart_screen.dart';
import '../provider/swiggy_search_provider.dart';

PreferredSizeWidget buildAppBar(
  TextEditingController searchController,
  FocusNode searchFocusNode,
) {
  return AppBar(
    backgroundColor: AppThemeData.grey50,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios, color: AppThemeData.grey900),
      onPressed: () => Get.back(),
    ),
    title: Selector<SwiggySearchProvider, String>(
      selector: (_, provider) => provider.searchText,
      builder: (context, searchText, _) {
        final controller = context.read<SwiggySearchProvider>();
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppThemeData.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: controller.updateSearchText,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                controller.performUnifiedSearch(value.trim());
              }
            },
            style: TextStyle(color: AppThemeData.grey900, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Search for restaurants, dishes, or cuisines",
              hintStyle: TextStyle(color: AppThemeData.grey400, fontSize: 16),
              prefixIcon: Icon(
                Icons.search,
                color: AppThemeData.grey400,
                size: 20,
              ),
              suffixIcon: searchText.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppThemeData.grey400,
                        size: 20,
                      ),
                      onPressed: () {
                        searchController.clear();
                        controller.clearSearch();
                      },
                    )
                  : const SizedBox.shrink(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        );
      },
    ),
    actions: [
      Selector<CartProvider, int>(
        selector: (_, provider) => provider.totalQuantity,
        builder: (context, cartCount, __) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart_outlined,
                  color: AppThemeData.grey900,
                ),
                onPressed: () {
                  Get.to(() => const CartScreen());
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : cartCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(width: 8),
    ],
  );
}
