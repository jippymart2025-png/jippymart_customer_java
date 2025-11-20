import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class MyProfileProvider extends ChangeNotifier {
  RxBool isLoading = true.obs;
  late LoginProvider loginProvider;

  void initFunction({required BuildContext context}) {
    loginProvider = Provider.of<LoginProvider>(context, listen: false);
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

  Future<void> deleteUserAccount({required BuildContext context}) async {
    try {
      ShowToastDialog.showLoader("Please wait".tr);
      log('[PROFILE_SCREEN] Starting to delete user account');
      isLoading.value = true;
      notifyListeners();
      final userId = await SqlStorageConst.getFirebaseId();
      log('[PROFILE_SCREEN] User ID for deletion: $userId');
      final bool isDeleted = await _makeDeleteAccountCall(userId.toString());
      if (isDeleted) {
        loginProvider.logout(context);
        log('[PROFILE_SCREEN] Account deleted successfully');
        // Navigate to login screen or show success message
      } else {
        log('[PROFILE_SCREEN] Failed to delete account');
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      log('[PROFILE_SCREEN] Error deleting account: $e');
      rethrow; // Or handle the error as needed
    } finally {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      notifyListeners();
      log('[PROFILE_SCREEN] Delete account process completed');
    }
  }

  Future<bool> _makeDeleteAccountCall(String userId) async {
    try {
      log('[PROFILE_SCREEN] Making DELETE API call for user: $userId');
      final response = await http.delete(
        Uri.parse('${AppConst.baseUrl}users/profile/$userId'),
        headers: await getHeaders(),
      );
      log(
        '[PROFILE_SCREEN] Delete API response status: ${response.statusCode}',
      );
      log('[PROFILE_SCREEN] Delete API response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        log('[PROFILE_SCREEN] Account deletion API call successful');
        return true;
      } else {
        log(
          '[PROFILE_SCREEN] Account deletion API call failed with status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      log('[PROFILE_SCREEN] Error in delete API call: $e');
      return false;
    }
  }

  Future<void> loadUserData() async {
    try {
      log('[PROFILE_SCREEN] Starting to load user data');
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
      notifyListeners();
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
