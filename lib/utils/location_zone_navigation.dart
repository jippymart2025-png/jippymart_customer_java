import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/model/zone_model.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/provider/location_permission_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:provider/provider.dart';

/// Navigation helpers when [zones/current] reports no service at coordinates.
class LocationZoneNavigation {
  static bool isZoneModelInService(ZoneModel? zoneModel) {
    return zoneModel?.success == true &&
        zoneModel?.isZoneAvailable == true &&
        zoneModel?.zone != null &&
        zoneModel!.zone!.publish == true;
  }

  static bool isInServiceArea() {
    return Constant.isZoneAvailable == true &&
        Constant.selectedZone?.id != null &&
        Constant.selectedZone!.id!.isNotEmpty;
  }

  static void _markOutOfService(BuildContext? context) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;
    try {
      Provider.of<LocationPermissionProvider>(ctx, listen: false)
          .setOutOfService(true);
    } catch (_) {}
  }

  /// Opens [LocationPermissionScreen] with out-of-service messaging.
  static Future<void> openOutOfServiceScreen({BuildContext? context}) async {
    await LocationPermissionProvider.cacheZoneData();
    _markOutOfService(context);
    await Get.offAll(() => const LocationPermissionScreen());
  }
}
