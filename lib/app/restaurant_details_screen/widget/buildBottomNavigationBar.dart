import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../themes/app_them_data.dart';
import '../../cart_check_out_page/cart_check_out_screen.dart';
import '../../home_screen/screen/home_screen/provider/home_provider.dart';
import '../provider/restaurant_details_provider.dart'
    show RestaurantDetailsProvider;

Widget? buildBottomNavigationBar(RestaurantDetailsProvider controller) {
  if (controller.isGroupOrderMode || HomeProvider.cartItem.isEmpty) {
    return null;
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final sw = constraints.maxWidth;
      final isSmall = sw < 360;
      final fontSize = isSmall ? 16.0 : (sw > 600 ? 22.0 : 18.0);
      final barHeight = isSmall ? 60.0 : 70.0;

      return InkWell(
        onTap: () => Get.to(const CartCheckOutScreen()),
        child: Container(
          height: barHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF48000), Color(0xFFff0404)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${HomeProvider.cartItem.length} ${'items'.tr}',
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey50,
                  fontSize: fontSize,
                ),
              ),
              Text(
                'View Cart'.tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey50,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
