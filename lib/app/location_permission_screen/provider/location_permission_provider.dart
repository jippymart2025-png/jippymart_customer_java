// import 'package:flutter/cupertino.dart';
//
// class LocationPermissionProvider extends ChangeNotifier {
//
// }
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';

class LocationPermissionProvider extends ChangeNotifier {
  final GetStorage _storage = GetStorage();

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
}
