import 'dart:async';

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

Future<void> _loadMartDataInBackground(MartProvider martProvider) async {
  try {
    await martProvider.initFunction();
    debugPrint("✅ Mart data loaded successfully");
  } catch (e) {
    debugPrint("⚠️ Error loading mart data in background: $e");
  }
}

Widget martFoodTabBarWidgetHome({
  Key? key,
  required MartProvider martProvider,
  required MartNavigationProvider martNavigationProvider,
  required BuildContext context,
  VoidCallback? onAddressTap,
}) {
  return _MartFoodTabBarContent(
    key: key,
    martProvider: martProvider,
    martNavigationProvider: martNavigationProvider,
    context: context,
    onAddressTap: onAddressTap,
  );
}

/// Stateful wrapper: shows MART button only when mart is available in current zone.
/// When bar is hidden, shows a compact delivery address strip.
class _MartFoodTabBarContent extends StatefulWidget {
  final MartProvider martProvider;
  final MartNavigationProvider martNavigationProvider;
  final BuildContext context;
  final VoidCallback? onAddressTap;

  const _MartFoodTabBarContent({
    super.key,
    required this.martProvider,
    required this.martNavigationProvider,
    required this.context,
    this.onAddressTap,
  });

  @override
  State<_MartFoodTabBarContent> createState() => _MartFoodTabBarContentState();
}

class _MartFoodTabBarContentState extends State<_MartFoodTabBarContent> {
  bool? _martAvailableInZone;

  @override
  void initState() {
    super.initState();
    _checkMartAvailability();
  }

  @override
  void didUpdateWidget(covariant _MartFoodTabBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check when widget is updated (e.g. after zone/location change)
    if (oldWidget.context != widget.context) {
      setState(() => _martAvailableInZone = null);
      _checkMartAvailability();
    }
  }

  Future<void> _checkMartAvailability() async {
    MartZoneUtils.prefetchMartVendors();
    final available = await MartZoneUtils.isMartAvailableInCurrentZone();
    if (mounted) {
      setState(() => _martAvailableInZone = available);
    }
  }

  Widget _buildSafeAddressStrip(BuildContext context) {
    final address = Constant.selectedLocation.getFullAddress();
    final hasAddress = address.isNotEmpty;
    final label = hasAddress ? address : "Set delivery address".tr;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAddressTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: hasAddress ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasAddress ? Colors.grey[800] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.onAddressTap != null)
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When mart is not available, show compact delivery address strip instead of bar
    if (_martAvailableInZone != true) {
      return _buildSafeAddressStrip(context);
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
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                checkMartAvailability(
                  widget.martProvider,
                  widget.martNavigationProvider,
                  widget.context,
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
}

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

    // OPTIMIZATION: Early synchronous validation (no async needed)
    final location = Constant.selectedLocation.location;
    final currentZoneId = Constant.selectedZone?.id;

    // Fast path: Validate location synchronously
    if (location?.latitude == null ||
        location?.longitude == null ||
        location!.latitude == 0.0 ||
        location.longitude == 0.0) {
      debugPrint("❌ No valid location - cannot check mart availability");
      _isMartChecking = false;
      ComingSoonDialogHelper.show(
        title: "LOCATION REQUIRED".tr,
        message: "Please set your location to check mart availability in your area.",
      );
      return;
    }

    // Fast path: Validate zone synchronously
    if (currentZoneId == null || currentZoneId.isEmpty) {
      debugPrint("❌ No zone selected - cannot check mart availability");
      _isMartChecking = false;
      ComingSoonDialogHelper.show(
        title: "COMING SOON".tr,
        message: "We're working hard to bring Jippy Mart to your area. Stay tuned!",
      );
      return;
    }

    // Fast path: Validate zone match synchronously
    if (Constant.selectedLocation.zoneId != null &&
        Constant.selectedLocation.zoneId!.isNotEmpty &&
        Constant.selectedLocation.zoneId != currentZoneId) {
      debugPrint(
        "❌ Zone mismatch: location zone (${Constant.selectedLocation.zoneId}) != selected zone ($currentZoneId)",
      );
      _isMartChecking = false;
      ComingSoonDialogHelper.show(
        title: "ZONE MISMATCH".tr,
        message: "Location and zone don't match. Please update your location.",
      );
      return;
    }

    // OPTIMIZATION: Delay loader only if check takes time (cache hits feel instant)
    bool loaderShown = false;
    Timer? loaderTimer;
    loaderTimer = Timer(const Duration(milliseconds: 100), () {
      if (_isMartChecking && !loaderShown) {
        loaderShown = true;
        ShowToastDialog.showLoader("Checking mart availability...".tr);
      }
    });

    try {
      debugPrint(
        "✅ Zone ID: $currentZoneId, Location: (${location.latitude}, ${location.longitude}) - checking mart availability",
      );

      // OPTIMIZED: Check availability (uses cache when available)
      final isMartAvailable = await MartZoneUtils.isMartAvailableInCurrentZone();

      // Cancel loader if check was fast
      loaderTimer?.cancel();
      if (loaderShown) {
        ShowToastDialog.closeLoader();
      }

      if (!isMartAvailable) {
        debugPrint("❌ Mart not available in zone: $currentZoneId");
        _isMartChecking = false;
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message: "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        return;
      }

      debugPrint("✅ Mart available in zone: $currentZoneId - proceeding to Mart");

      // OPTIMIZATION: Initialize navigation provider synchronously (it's just getting providers)
      martNavigationProvider.initFunction(context: context);

      // OPTIMIZATION: Navigate immediately, let screen handle loading state
      // This makes the UI feel instant - user sees mart screen right away
      Get.to(() => const MartNavigationScreen());

      // OPTIMIZATION: Load data in background after navigation
      // Screen will show its own loading indicators
      _loadMartDataInBackground(martProvider);
    } catch (e) {
      debugPrint("❌ Mart check failed: $e");
      loaderTimer?.cancel();
      ShowToastDialog.closeLoader();
      
      // OPTIMIZATION: Try to proceed with cached data if available
      try {
        final cachedVendors = await MartZoneUtils.getCachedMartVendors();
        if (cachedVendors.isNotEmpty) {
          debugPrint("✅ Using cached vendors despite error - proceeding to Mart");
          martNavigationProvider.initFunction(context: context);
          Get.to(() => const MartNavigationScreen());
          _loadMartDataInBackground(martProvider);
        }
      } catch (e2) {
        debugPrint("❌ Failed to use cached vendors: $e2");
      }
    } finally {
      ShowToastDialog.closeLoader();
      _isMartChecking = false;
    }
  }
