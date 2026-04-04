import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/edit_profile_screen/provider/edit_profile_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:jippymart_customer/utils/preferences.dart';

class GlobalSettingsProvider extends ChangeNotifier {
  void initFunction(BuildContext context) {
    notificationInit();
    getCurrentCurrency(context);
  }

  getCurrentCurrency(BuildContext context) async {
    await getSettings(context);
  }

  getSettings(BuildContext context) async {
    try {
      // First, load from local storage so we have valid senderId/API key even if API fails
      _loadNotificationSettingsFromLocalStorage();

      final response = await SafeHttpClient.safeGet(
        Uri.parse('${AppConst.baseUrl}settings/mobile'),
        headers: await getHeaders(),
        timeout: const Duration(seconds: 15),
      );

      if (response == null) {
        // Network error - use locally stored API key and notification settings if available
        log(
          '[SETTINGS] ⚠️ API request failed - using locally stored API key if available',
        );
        _loadApiKeyFromLocalStorage();
        _loadNotificationSettingsFromLocalStorage();
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> documents = data['data']['documents'];
          final Map<String, dynamic> derived = data['data']['derived'];
          _setConstantsFromApi(documents, derived);
        } else {
          // API returned but success=false - use local storage
          log(
            '[SETTINGS] ⚠️ API returned success=false - using locally stored API key',
          );
          _loadApiKeyFromLocalStorage();
          _loadNotificationSettingsFromLocalStorage();
        }
      } else {
        // HTTP error - use local storage
        log(
          '[SETTINGS] ⚠️ API returned status ${response.statusCode} - using locally stored API key',
        );
        _loadApiKeyFromLocalStorage();
        _loadNotificationSettingsFromLocalStorage();
      }
    } catch (e) {
      // Any error - use local storage
      log(
        '[SETTINGS] ⚠️ Error loading settings: $e - using locally stored API key',
      );
      _loadApiKeyFromLocalStorage();
      _loadNotificationSettingsFromLocalStorage();
    }
  }

  /// Load FCM senderId and service JSON URL from local storage (for notifications when API not available)
  void _loadNotificationSettingsFromLocalStorage() {
    try {
      final cachedSenderId = Preferences.getString(Preferences.fcmSenderId);
      final cachedServiceJsonUrl = Preferences.getString(
        Preferences.fcmServiceJsonUrl,
      );
      if (cachedSenderId.isNotEmpty) {
        Constant.senderId = cachedSenderId;
        log(
          '[SETTINGS] ✅ Loaded FCM senderId from cache: ${cachedSenderId.substring(0, cachedSenderId.length > 8 ? 8 : cachedSenderId.length)}...',
        );
      }
      if (cachedServiceJsonUrl.isNotEmpty) {
        Constant.jsonNotificationFileURL = cachedServiceJsonUrl;
        log('[SETTINGS] ✅ Loaded FCM service JSON URL from cache');
      }
    } catch (e) {
      log('[SETTINGS] ⚠️ Error loading notification settings from cache: $e');
    }
  }

  /// Load API key from local storage as fallback
  void _loadApiKeyFromLocalStorage() {
    try {
      final localApiKey = Preferences.getString(Preferences.googleMapsApiKey);
      if (localApiKey.isNotEmpty && localApiKey.length > 10) {
        Constant.mapAPIKey = localApiKey;
        log(
          '[SETTINGS] ✅ Loaded API key from local storage: ${localApiKey.substring(0, 10)}...',
        );
      } else {
        // If local storage is also empty, use static fallback
        Constant.mapAPIKey = 'AIzaSyCKCRzqaR1-uzbnEmB-JqVkbUKNGOJHv34';
        log('[SETTINGS] ⚠️ Local storage empty - using static fallback key');
      }
    } catch (e) {
      // If Preferences not initialized, use static fallback
      Constant.mapAPIKey = 'AIzaSyCKCRzqaR1-uzbnEmB-JqVkbUKNGOJHv34';
      log(
        '[SETTINGS] ⚠️ Error loading from local storage: $e - using static fallback key',
      );
    }
  }

  _setConstantsFromApi(
    Map<String, dynamic> documents,
    Map<String, dynamic> derived,
  ) async {
    // Subscription model
    Constant.isSubscriptionModelApplied =
        documents['restaurant']?['subscription_model'] ?? false;
    // Restaurant nearby settings
    Constant.radius = documents['RestaurantNearBy']?['radios'] ?? '15';

    Constant.distanceType =
        documents['RestaurantNearBy']?['distanceType'] ?? 'km';
    // Global settings
    Constant.isEnableAdsFeature =
        documents['globalSettings']?['isEnableAdsFeature'] ?? false;
    Constant.isSelfDeliveryFeature =
        documents['globalSettings']?['isSelfDelivery'] ?? false;

    // Theme color
    if (documents['globalSettings']?['app_customer_color'] != null) {
      AppThemeData.primary300 = Color(
        int.parse(
          documents['globalSettings']!['app_customer_color'].replaceFirst(
            "#",
            "0xff",
          ),
        ),
      );
    }

    // Map API key and placeholder
    // Try multiple sources: documents['googleMapKey']['key'], then derived['mapAPIKey']
    String? apiKeyFromDocuments = documents['googleMapKey']?['key'];
    String? apiKeyFromDerived = derived['mapAPIKey'];

    final newApiKey = apiKeyFromDocuments ?? apiKeyFromDerived ?? '';

    // Only update if we got a valid key from API
    if (newApiKey.isNotEmpty && newApiKey.length > 10) {
      Constant.mapAPIKey = newApiKey;

      // Save to local storage for future use if API fails
      try {
        await Preferences.setString(Preferences.googleMapsApiKey, newApiKey);
        log(
          '[SETTINGS] ✅ Google Maps API Key loaded and saved locally: ${newApiKey.substring(0, 10)}... (length: ${newApiKey.length})',
        );
      } catch (e) {
        log('[SETTINGS] ⚠️ Error saving API key to local storage: $e');
        log(
          '[SETTINGS] ✅ Google Maps API Key loaded: ${newApiKey.substring(0, 10)}... (length: ${newApiKey.length})',
        );
      }
    } else {
      // API didn't return a valid key - try local storage
      log(
        '[SETTINGS] ⚠️ API returned empty/invalid key - checking local storage',
      );
      _loadApiKeyFromLocalStorage();
    }

    Constant.placeHolderImage =
        documents['googleMapKey']?['placeHolderImage'] ?? '';

    // Notification settings (persist for FCM when API is unavailable)
    // Support both camelCase and snake_case from API
    final notificationSetting =
        documents['notification_setting'] as Map<String, dynamic>?;
    final projectId =
        (notificationSetting?['projectId'] ??
                notificationSetting?['project_id'] ??
                '')
            .toString()
            .trim();
    final serviceJson =
        (notificationSetting?['serviceJson'] ??
                notificationSetting?['service_json'] ??
                '')
            .toString()
            .trim();
    if (projectId.isNotEmpty) {
      Constant.senderId = projectId;
      await Preferences.setString(Preferences.fcmSenderId, projectId);
      log('[SETTINGS] ✅ FCM senderId saved to cache');
    }
    if (serviceJson.isNotEmpty) {
      Constant.jsonNotificationFileURL = serviceJson;
      await Preferences.setString(Preferences.fcmServiceJsonUrl, serviceJson);
      log('[SETTINGS] ✅ FCM service JSON URL saved to cache');
    }
    // Inline service account JSON (when API returns it instead of URL)
    final inlineJson = notificationSetting?['serviceAccountJson'] ??
        notificationSetting?['service_account_json'];
    if (inlineJson != null) {
      String jsonStr = '';
      if (inlineJson is String) {
        jsonStr = inlineJson.trim();
      } else if (inlineJson is Map) {
        jsonStr = json.encode(inlineJson);
      }
      if (jsonStr.isNotEmpty && jsonStr.length > 100) {
        await Preferences.setString(
          Preferences.fcmServiceAccountJson,
          jsonStr,
        );
        log('[SETTINGS] ✅ FCM service account JSON (inline) saved to cache');
      }
    }
    // Driver nearby settings
    Constant.selectedMapType =
        documents['DriverNearBy']?['selectedMapType'] ?? 'google';
    Constant.mapType = documents['DriverNearBy']?['mapType'];
    // Privacy policy and terms
    Constant.privacyPolicy =
        documents['privacyPolicy']?['privacy_policy'] ?? '';
    Constant.termsAndConditions =
        documents['termsAndConditions']?['termsAndConditions'] ?? '';

    if (kDebugMode) {
      print(
        '[SETTINGS] Privacy Policy length: ${Constant.privacyPolicy.length}',
      );
      print(
        '[SETTINGS] Terms & Conditions length: ${Constant.termsAndConditions.length}',
      );
      if (Constant.privacyPolicy.isEmpty) {
        print(
          '[SETTINGS] ⚠️ Privacy Policy is empty - check API data structure',
        );
        print('[SETTINGS] Privacy Policy data: ${documents['privacyPolicy']}');
      }
      if (Constant.termsAndConditions.isEmpty) {
        print(
          '[SETTINGS] ⚠️ Terms & Conditions is empty - check API data structure',
        );
        print('[SETTINGS] Terms data: ${documents['termsAndConditions']}');
      }
    }

    // Wallet settings
    Constant.walletSetting = documents['walletSettings']?['isEnabled'] ?? false;

    // Version info
    Constant.googlePlayLink = documents['Version']?['googlePlayLink'] ?? '';
    Constant.appStoreLink = documents['Version']?['appStoreLink'] ?? '';
    Constant.appVersion = documents['Version']?['app_version'] ?? '';
    Constant.websiteUrl = documents['Version']?['websiteUrl'] ?? '';

    // Story settings
    Constant.storyEnable = documents['story']?['isEnabled'] ?? false;
    print('[DEBUG] Story enable setting loaded: ${Constant.storyEnable}');

    // Placeholder image
    Constant.placeholderImage = documents['placeHolderImage']?['image'] ?? '';

    // Admin commission
    if (documents['AdminCommission'] != null) {
      Constant.adminCommission = AdminCommission.fromJson(
        documents['AdminCommission']!,
      );
    }
    notifyListeners();
    // You can also use derived data if needed
    print('[DEBUG] Settings loaded successfully from API');
  }

  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId != null) {
        await AddressListProvider.getUserProfile(userId).then((value) {
          if (value != null) {
            UserModel driverUserModel = value;
            driverUserModel.fcmToken = token;
            EditProfileProvider.updateUserStatic(driverUserModel);
          }
        });
      }
    });
  }
}
