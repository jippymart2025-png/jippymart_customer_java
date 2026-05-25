import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:provider/provider.dart';

class LocationPermissionProvider extends ChangeNotifier {
  final GetStorage _storage = GetStorage();

  bool isCheckingZone = false;
  bool isOutOfServiceArea = false;

  /// Simple cache for auth checks
  Future<bool> checkAuthCached() async {
    final cachedAuth = _storage.read('cached_auth_check');
    if (cachedAuth != null) {
      final cachedTime = DateTime.parse(cachedAuth['timestamp']);
      if (DateTime.now().difference(cachedTime) < const Duration(minutes: 1)) {
        return cachedAuth['hasAuth'] == true;
      }
    }
    return false;
  }

  /// Simple location cache
  Map<String, dynamic>? getCachedLocation() {
    return _storage.read('user_location');
  }

  /// Clear cache if needed
  void clearCache() {
    _storage.remove('cached_auth_check');
    _storage.remove('user_location');
    notifyListeners();
  }

  static bool hasValidSelectedLocation() {
    final loc = Constant.selectedLocation.location;
    return loc?.latitude != null &&
        loc?.longitude != null &&
        loc!.latitude != 0.0 &&
        loc.longitude != 0.0;
  }

  /// Sync UI from Constant (e.g. after splash zone check).
  void syncOutOfServiceFromConstant() {
    final outOfService =
        hasValidSelectedLocation() && Constant.isZoneAvailable != true;
    if (isOutOfServiceArea != outOfService) {
      isOutOfServiceArea = outOfService;
      notifyListeners();
    }
  }

  void setOutOfService(bool value) {
    if (isOutOfServiceArea != value) {
      isOutOfServiceArea = value;
      notifyListeners();
    }
  }

  static Future<void> cacheZoneData() async {
    try {
      final box = GetStorage();
      box.write('zone_data', {
        'isZoneAvailable': Constant.isZoneAvailable,
        'zoneId':
            Constant.selectedZone?.id ?? Constant.selectedLocation.zoneId ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final zoneId =
          Constant.selectedZone?.id ?? Constant.selectedLocation.zoneId;
      if (Constant.isZoneAvailable == true &&
          zoneId != null &&
          zoneId.isNotEmpty) {
        await Preferences.setString(Preferences.selectedZoneId, zoneId);
        print('[LOCATION_PERMISSION] ✅ Cached zone ID: $zoneId');
      } else {
        await Preferences.setString(Preferences.selectedZoneId, '');
        print('[LOCATION_PERMISSION] Out of zone — zone ID not saved');
      }
      if (Constant.selectedLocation.location != null) {
        final location = Constant.selectedLocation.location!;
        box.write('user_location', {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'zoneId': zoneId ?? '',
          'isZoneAvailable': Constant.isZoneAvailable,
          'address':
              Constant.selectedLocation.address ??
              Constant.selectedLocation.locality ??
              '',
          'locality': Constant.selectedLocation.locality ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('[LOCATION_PERMISSION] ✅ Cached location with zone data');
      }
    } catch (e) {
      print('[LOCATION_PERMISSION] Error caching zone data: $e');
    }
  }

  /// Calls zones/current for the selected coordinates and updates [isOutOfServiceArea].
  Future<void> refreshZoneStatus(BuildContext context) async {
    if (!hasValidSelectedLocation()) {
      setOutOfService(false);
      return;
    }

    isCheckingZone = true;
    notifyListeners();

    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      await homeProvider.getZone();
      await cacheZoneData();
      setOutOfService(Constant.isZoneAvailable != true);
    } catch (e) {
      print('[LOCATION_PERMISSION_PROVIDER] Zone refresh error: $e');
      setOutOfService(true);
    } finally {
      isCheckingZone = false;
      notifyListeners();
    }
  }
}
