import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/currency_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

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
    await FireStoreUtils().getSettings(context);
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
            FireStoreUtils.updateUser(driverUserModel);
          }
        });
      }
    });
  }
}
