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
  MartZoneUtils.prefetchMartVendors();

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

    // Delay loader so quick loads (e.g. cache hit) feel instant
    bool loaderShown = false;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isMartChecking && !loaderShown) {
        loaderShown = true;
        ShowToastDialog.showLoader("Checking mart availability...".tr);
      }
    });

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

      debugPrint("✅ Zone ID: $currentZoneId - proceeding to Mart");

      // Skip vendor pre-check - mart_provider.initFunction() loads vendors.
      // Avoids false "Coming Soon" when zone/API formats differ.

      // Close checking loader before showing loading
      ShowToastDialog.closeLoader();

      // Delay "Loading mart..." so quick inits feel instant
      bool loadingLoaderShown = false;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_isMartChecking && !loadingLoaderShown) {
          loadingLoaderShown = true;
          ShowToastDialog.showLoader("Loading mart...".tr);
        }
      });

      try {
        // Initialize providers – must await so Mart content loads before navigation
        martNavigationProvider.initFunction(context: context);
        await martProvider.initFunction();

        // Navigate to mart screen after data is loaded
        Get.to(() => const MartNavigationScreen());
        
        // Close loader immediately after navigation starts
        // Use multiple safety measures to ensure loader is closed
        ShowToastDialog.closeLoader();
        
        // Additional safety: Close loader after a delay to handle any edge cases
        Future.delayed(const Duration(milliseconds: 300), () {
          ShowToastDialog.closeLoader();
        });
        
      } catch (e) {
        // Ensure loader is closed if anything fails
        ShowToastDialog.closeLoader();
        rethrow;
      }
      
    } catch (e) {
      debugPrint("❌ Mart load failed: $e");
      ShowToastDialog.closeLoader();
      // Don't show Coming Soon on load errors - may be temporary (network, etc.)
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
