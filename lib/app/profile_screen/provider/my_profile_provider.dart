import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class MyProfileProvider extends ChangeNotifier {
  RxBool isLoading = true.obs;

  void initFunction() {
    getThem();
    loadUserData();
  }

  RxString isDarkMode = "Light".obs;
  RxBool isDarkModeSwitch = false.obs;

  getThem() {
    isDarkMode.value = Preferences.getString(Preferences.themKey);
    if (isDarkMode.value == "Dark") {
      isDarkModeSwitch.value = true;
    } else if (isDarkMode.value == "Light") {
      isDarkModeSwitch.value = false;
    } else {
      isDarkModeSwitch.value = false;
    }
  }

  Future<void> loadUserData() async {
    try {
      log('[PROFILE_SCREEN] Starting to load user data');
      // Load user data if not already loaded
      if (Constant.userModel == null) {
        log(
          '[PROFILE_SCREEN] Constant.userModel is null, fetching from Firestore',
        );
        final userId = await SqlStorageConst.getFirebaseId();
        final userModel = await AddressListProvider.getUserProfile(
          userId.toString(),
        );
        log(
          '[PROFILE_SCREEN] getUserProfile result: ${userModel != null ? "SUCCESS" : "NULL"}',
        );
        if (userModel != null) {
          Constant.userModel = userModel;
          log('[PROFILE_SCREEN] Set Constant.userModel: ${userModel.toJson()}');
        } else {
          log('[PROFILE_SCREEN] Failed to load user model');
        }
      } else {
        log(
          '[PROFILE_SCREEN] Constant.userModel already exists: ${Constant.userModel?.toJson()}',
        );
      }
    } catch (e) {
      log('[PROFILE_SCREEN] Error loading user data: $e');
    } finally {
      isLoading.value = false;
      log('[PROFILE_SCREEN] Loading completed, isLoading set to false');
    }
  }

  Future<bool> deleteUserFromServer() async {
    var url = '${Constant.websiteUrl}/api/delete-user';
    final userId = await SqlStorageConst.getFirebaseId();
    try {
      var response = await http.post(Uri.parse(url), body: {'uuid': userId});
      log("deleteUserFromServer :: ${response.body}");
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
