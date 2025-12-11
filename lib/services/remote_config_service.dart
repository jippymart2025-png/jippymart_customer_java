import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';

/// Handles fetching runtime configuration from Firebase Remote Config.
///
/// Usage:
/// ```dart
/// await RemoteConfigService.instance.initialize();
/// final apiBaseUrl = RemoteConfigService.instance.baseUrl;
/// ```
class RemoteConfigService {
  RemoteConfigService._internal();

  static final RemoteConfigService instance = RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String get baseUrl => AppConst.baseUrl;

  /// Fetches Remote Config values and updates [AppConst.baseUrl] if present.
  ///
  /// Falls back to [AppConst.defaultBaseUrl] on any failure.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );
      await _remoteConfig.setDefaults({'base_url': AppConst.defaultBaseUrl});
      await _remoteConfig.fetchAndActivate();
      final fetchedUrl = _remoteConfig.getString('base_url');
      if (fetchedUrl.isNotEmpty) {
        AppConst.baseUrl = "http://192.168.0.126:8002/api/";
        // _normalizeUrl(fetchedUrl);
        if (kDebugMode) {
          print('[RemoteConfig] base_url fetched: $fetchedUrl');
          print('[RemoteConfig] base_url applied: ${AppConst.baseUrl}');
        }
      } else {
        AppConst.baseUrl = AppConst.defaultBaseUrl;
        if (kDebugMode) {
          print(
            '[RemoteConfig] base_url empty, fallback to default ${AppConst.baseUrl}',
          );
        }
      }
    } catch (e) {
      AppConst.baseUrl = AppConst.defaultBaseUrl;
      if (kDebugMode) {
        print('[RemoteConfig] Failed to load, using default: $e');
      }
    }
  }

  String _normalizeUrl(String raw) {
    var url = raw.trim();
    if (!url.endsWith('/')) {
      url = '$url/';
    }
    // Ensure it ends with /api/ to match existing calls
    if (url.endsWith('api')) {
      url = '$url/';
    } else if (!url.endsWith('api/')) {
      url = '${url}api/';
    }
    return url;
  }
}
