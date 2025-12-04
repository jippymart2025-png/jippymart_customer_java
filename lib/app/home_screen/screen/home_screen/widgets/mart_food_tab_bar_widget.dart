import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/widgets/coming_soon_dialog.dart';

// Static flag to prevent multiple simultaneous clicks
bool _isMartChecking = false;

Widget martFoodTabBarWidgetHome({
  required MartProvider martProvider,
  required MartNavigationProvider martNavigationProvider,
  required BuildContext context,
}) {

  Future<void> checkMartAvailability(
    MartProvider martProvider,
    MartNavigationProvider martNavigationProvider,
    BuildContext context,
  ) async {
    // Prevent multiple simultaneous clicks
    if (_isMartChecking) {
      debugPrint("⚠️ Mart check already in progress, ignoring duplicate click");
      return;
    }

    _isMartChecking = true;
    ShowToastDialog.showLoader("Checking mart availability...".tr);

    try {
      // First, verify zone is available and fresh
      final currentZoneId = Constant.selectedZone?.id;
      
      if (currentZoneId == null || currentZoneId.isEmpty) {
        debugPrint("❌ No zone selected");
        ShowToastDialog.closeLoader();
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        _isMartChecking = false;
        return;
      }

      debugPrint("✅ Zone ID: $currentZoneId");

      // Check mart vendors availability BEFORE initializing provider
      final martVendors = await MartZoneUtils.getCachedMartVendors();
      
      if (martVendors.isEmpty) {
        debugPrint("❌ No mart vendors found in zone");
        ShowToastDialog.closeLoader();
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        _isMartChecking = false;
        return;
      }

      // Check if all vendors are closed
      final allClosed = martVendors.every((v) => v.isOpen == false);
      if (allClosed) {
        debugPrint("❌ All mart vendors are closed");
        ShowToastDialog.closeLoader();
        ComingSoonDialogHelper.show(
          title: "Mart Available from 7AM to 9PM".tr,
          message: "",
        );
        _isMartChecking = false;
        return;
      }

      debugPrint("✅ Mart is available, initializing...");

      // Only initialize AFTER confirming mart is available
      // This prevents unnecessary loading if mart is not available
      ShowToastDialog.showLoader("Loading mart...".tr);
      
      // Initialize providers (these are synchronous setup calls)
      martProvider.initFunction();
      martNavigationProvider.initFunction(context: context);
      
      // CRITICAL: Close loader IMMEDIATELY after initialization
      // Don't wait for navigation - close it right away
      ShowToastDialog.closeLoader();
      
      // Small delay to ensure UI updates and loader dismissal completes
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to mart screen
      await Get.to(() => const MartNavigationScreen());
      
      // Final safety check: Ensure loader is closed after navigation
      // This handles edge cases where loader might persist
      ShowToastDialog.closeLoader();
      
    } catch (e) {
      debugPrint("❌ Mart check failed: $e");
      ShowToastDialog.closeLoader();
      ComingSoonDialogHelper.show(
        title: "COMING SOON".tr,
        message:
            "We're working hard to bring Jippy Mart to your area. Stay tuned!",
      );
    } finally {
      // Ensure loader is always closed, even if navigation fails
      ShowToastDialog.closeLoader();
      _isMartChecking = false;
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
              checkMartAvailability(
                martProvider,
                martNavigationProvider,
                context,
              );
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
