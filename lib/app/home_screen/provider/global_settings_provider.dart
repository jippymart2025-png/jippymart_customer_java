import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/edit_profile_screen/provider/edit_profile_provider.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
import 'package:jippymart_customer/models/currency_model.dart';
import 'package:jippymart_customer/models/mail_setting.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;

class GlobalSettingsProvider extends ChangeNotifier {
  void initFunction(BuildContext context) {
    notificationInit();
    getCurrentCurrency(context);
  }

  getCurrentCurrency(BuildContext context) async {
    FireStoreUtils.fireStore
        .collection(CollectionName.currencies)
        .where("isActive", isEqualTo: true)
        .snapshots()
        .listen((event) {
          if (event.docs.isNotEmpty) {
            Constant.currencyModel = CurrencyModel.fromJson(
              event.docs.first.data(),
            );
          } else {
            Constant.currencyModel = CurrencyModel(
              id: "",
              code: "USD",
              decimalDigits: 2,
              enable: true,
              name: "US Dollar",
              symbol: "\$",
              symbolAtRight: false,
            );
          }
        });
    await getSettings(context);
  }

  getSettings(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/mobile'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> documents = data['data']['documents'];
          final Map<String, dynamic> derived = data['data']['derived'];
          // Set all constants from the API response
          _setConstantsFromApi(documents, derived);
        }
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } catch (e) {}
  }

  _setConstantsFromApi(
    Map<String, dynamic> documents,
    Map<String, dynamic> derived,
  ) {
    // Subscription model
    Constant.isSubscriptionModelApplied =
        documents['restaurant']?['subscription_model'] ?? false;

    // Restaurant nearby settings
    Constant.radius = documents['RestaurantNearBy']?['radios'] ?? '15';
    Constant.driverRadios =
        documents['RestaurantNearBy']?['driverRadios'] ?? '5';
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
    Constant.mapAPIKey = documents['googleMapKey']?['key'] ?? '';
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

    // Referral amount
    Constant.referralAmount =
        documents['referral_amount']?['referralAmount']?.toString() ?? '0';

    // Placeholder image
    Constant.placeholderImage = documents['placeHolderImage']?['image'] ?? '';

    // Email settings
    if (documents['emailSetting'] != null) {
      Constant.mailSettings = MailSettings.fromJson(documents['emailSetting']!);
    }

    // Special discount offer
    Constant.specialDiscountOffer =
        documents['specialDiscountOffer']?['isEnable'] == "true";

    // Dine-in settings
    Constant.isEnabledForCustomer =
        documents['DineinForRestaurant']?['isEnabledForCustomer'] ?? false;

    // Admin commission
    if (documents['AdminCommission'] != null) {
      Constant.adminCommission = AdminCommission.fromJson(
        documents['AdminCommission']!,
      );
    }

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
            EditProfileProvider.updateUser(driverUserModel);
          }
        });
      }
    });
  }
}
