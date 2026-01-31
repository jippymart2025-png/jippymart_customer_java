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
      // First, try to load from local storage as fallback
      _loadApiKeyFromLocalStorage();

      final response = await SafeHttpClient.safeGet(
        Uri.parse('${AppConst.baseUrl}settings/mobile'),
        headers: await getHeaders(),
        timeout: const Duration(seconds: 15),
      );

      if (response == null) {
        // Network error - use locally stored API key if available
        log(
          '[SETTINGS] ⚠️ API request failed - using locally stored API key if available',
        );
        _loadApiKeyFromLocalStorage();
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
        }
      } else {
        // HTTP error - use local storage
        log(
          '[SETTINGS] ⚠️ API returned status ${response.statusCode} - using locally stored API key',
        );
        _loadApiKeyFromLocalStorage();
      }
    } catch (e) {
      // Any error - use local storage
      log(
        '[SETTINGS] ⚠️ Error loading settings: $e - using locally stored API key',
      );
      _loadApiKeyFromLocalStorage();
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

    // Notification settings
    Constant.senderId = documents['notification_setting']?['projectId'] ?? '';
    Constant.jsonNotificationFileURL =
        documents['notification_setting']?['serviceJson'] ?? '';
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
      print('[SETTINGS] Privacy Policy length: ${Constant.privacyPolicy.length}');
      print('[SETTINGS] Terms & Conditions length: ${Constant.termsAndConditions.length}');
      if (Constant.privacyPolicy.isEmpty) {
        print('[SETTINGS] ⚠️ Privacy Policy is empty - check API data structure');
        print('[SETTINGS] Privacy Policy data: ${documents['privacyPolicy']}');
      }
      if (Constant.termsAndConditions.isEmpty) {
        print('[SETTINGS] ⚠️ Terms & Conditions is empty - check API data structure');
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
