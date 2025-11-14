import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/widgets/coming_soon_dialog.dart';

Widget martFoodTabBarWidgetHome({required MartProvider martProvider}) {
  Future<void> checkMartAvailability(MartProvider martProvider) async {
    // martProvider.initFunction();
    try {
      if (Constant.selectedZone?.id == null) {
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        return;
      }
      final martVendors = await MartZoneUtils.getCachedMartVendors();
      if (martVendors.isEmpty) {
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        return;
      }
      final allClosed = martVendors.every((v) => v.isOpen == false);
      if (allClosed) {
        ComingSoonDialogHelper.show(
          title: "Mart Available from 7AM to 9PM".tr,
          message: "",
        );
        return;
      }
      Get.to(() => const MartNavigationScreen());
    } catch (e) {
      debugPrint("❌ Mart check failed: $e");
      ComingSoonDialogHelper.show(
        title: "COMING SOON".tr,
        message:
            "We're working hard to bring Jippy Mart to your area. Stay tuned!",
      );
    }
  }

  return Container(
    margin: const EdgeInsets.only(top: 16, bottom: 16),
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'FOOD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              checkMartAvailability(martProvider);
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'MART',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
