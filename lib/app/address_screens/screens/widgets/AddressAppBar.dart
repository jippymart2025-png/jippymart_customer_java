import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';

class AddressAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: Tokens.sp16,
      backgroundColor: Tokens.canvas,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: Tokens.sp8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(50),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Tokens.textPrimary,
            ),
          ),
        ),
      ),
      title: Text(
        "Your Addresses".tr,
        style: const TextStyle(
          fontSize: Tokens.textXL,
          color: Tokens.textPrimary,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
