import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/app_update_service.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class SplashProvider extends ChangeNotifier {
  late HomeProvider homeProvider;
  late AddressListProvider addressListProvider;

  void initFunction(BuildContext context) async {
    _initializeLogo(context);
  }

  _initializeLogo(BuildContext context) async {
    await Future.delayed(const Duration(microseconds: 500)).then((value) {
      _navigateToMainApp(context);
    });
  }

  void _navigateToMainApp(BuildContext context) async {
    try {
      homeProvider = Provider.of<HomeProvider>(context, listen: false);
      addressListProvider = Provider.of<AddressListProvider>(
        context,
        listen: false,
      );
      final apiToken = await SqlStorageConst.getAuthToken();
      final userId = await SqlStorageConst.getFirebaseId();
      if (apiToken == null || apiToken.isEmpty || userId == null) {
        Get.offAll(
          () => const PhoneNumberScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
        _checkUpdatesInBackground();
        return;
      }
      addressListProvider.initFunction();
      await _loadUserDataFromStorage();
      homeProvider.initFunction(context: context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => DashBoardScreen()),
        (Route<dynamic> route) => false,
      );
      try {
        final deepLinkService = FinalDeepLinkService();
        deepLinkService.processPendingDeepLinkAfterLogin(context);
      } catch (e) {}
      _checkUpdatesInBackground();
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => PhoneNumberScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _loadUserDataFromStorage() async {
    try {
      print(" _loadAllDataInParallel  first ");
      final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
      final userId = await secureStorage.read(key: 'user_id');
      final firebaseId = await secureStorage.read(key: 'firebase_id');
      final firstName = await secureStorage.read(key: 'user_firstName') ?? '';
      final lastName = await secureStorage.read(key: 'user_lastName') ?? '';
      final email = await secureStorage.read(key: 'user_email') ?? '';
      final phone = await secureStorage.read(key: 'user_phone') ?? '';
      final countryCode =
          await secureStorage.read(key: 'user_countryCode') ?? '+91';
      if (firebaseId != null) {
        UserModel userModel = UserModel(
          id: userId,
          firstName: firstName,
          firebaseId: firebaseId,
          lastName: lastName,
          email: email,
          phoneNumber: phone,
          countryCode: countryCode,
          role: Constant.userRoleCustomer,
          active: true,
        );
        Constant.userModel = userModel;
        notifyListeners();
      } else {}
    } catch (e) {}
  }

  void _checkUpdatesInBackground() {
    Future.microtask(() async {
      try {
        bool updateRequired = await AppUpdateService.checkForUpdate().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return false;
          },
        );
        if (updateRequired) {
        } else {}
      } catch (e) {}
    });
  }
}
