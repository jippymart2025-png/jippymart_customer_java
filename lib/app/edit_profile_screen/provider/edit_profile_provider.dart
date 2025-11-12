import 'dart:convert';
import 'dart:io';

import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;

class EditProfileProvider extends ChangeNotifier {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController = TextEditingController(
    text: "+91",
  ).obs;

  void initFunction() {
    getData();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  getData() async {
    try {
      // First try to use the global user model if available
      if (Constant.userModel != null) {
        print(
          '[EDIT_PROFILE] Using global user model: ${Constant.userModel?.toJson()}',
        );
        userModel.value = Constant.userModel!;
      } else {
        print(
          '[EDIT_PROFILE] Global user model is null, fetching from Firestore',
        );
        final userId = await SqlStorageConst.getFirebaseId();
        final value = await AddressListProvider.getUserProfile(
          userId.toString(),
        );
        if (value != null) {
          userModel.value = value;
          // Also update the global user model
          Constant.userModel = value;
          print(
            '[EDIT_PROFILE] Loaded user model from Firestore: ${value.toJson()}',
          );
        } else {
          print('[EDIT_PROFILE] Failed to load user model from Firestore');
        }
      }

      // Set the form fields
      if (userModel.value.id != null) {
        firstNameController.value.text =
            userModel.value.firstName?.toString() ?? "";
        lastNameController.value.text =
            userModel.value.lastName?.toString() ?? "";
        emailController.value.text = userModel.value.email?.toString() ?? "";
        phoneNumberController.value.text =
            userModel.value.phoneNumber?.toString() ?? "";
        countryCodeController.value.text =
            userModel.value.countryCode?.toString() ?? "+91";
        profileImage.value = userModel.value.profilePictureURL ?? "";
        print('[EDIT_PROFILE] Form fields populated successfully');
      } else {
        print('[EDIT_PROFILE] User model is null, cannot populate form fields');
      }
    } catch (e) {
      print('[EDIT_PROFILE] Error loading user data: $e');
    }

    isLoading.value = false;
  }

  saveData(BuildContext context) async {
    if (firstNameController.value.text.isEmpty) {
      // showSnackBar(
      //   "Please enter the first name",
      //   context,
      // );
      ShowToastDialog.showToast("Please enter the first name".tr);
    } else if (lastNameController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter the last name".tr);
      // Get.snackbar(
      //   "Error",
      //   "Please enter the last name",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } else if (emailController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter the email".tr);
      // Get.snackbar(
      //   "Error",
      //   "Please enter the email",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } else if (!isValidEmail(emailController.value.text)) {
      ShowToastDialog.showToast("Invalid email format".tr);
    } else {
      ShowToastDialog.showLoader("Please wait".tr);
      if (Constant().hasValidUrl(profileImage.value) == false &&
          profileImage.value.isNotEmpty) {
        final userId = await SqlStorageConst.getFirebaseId();
        profileImage.value = await Constant.uploadUserImageToFireStorage(
          File(profileImage.value),
          "profileImage/${userId}",
          File(profileImage.value).path.split('/').last,
        );
      }
      userModel.value.firstName = firstNameController.value.text;
      userModel.value.lastName = lastNameController.value.text;
      userModel.value.profilePictureURL = profileImage.value;
      userModel.value.phoneNumber = phoneNumberController.value.text;
      userModel.value.countryCode = countryCodeController.value.text;
      userModel.value.email = emailController.value.text;
      await updateUser(userModel.value).then((value) {
        Constant.userModel = userModel.value;
        print(
          '[EDIT_PROFILE] Updated global user model: ${Constant.userModel?.toJson()}',
        );
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      });
      Get.back(result: "profile_updated");
    }
  }

  static Future<bool> updateUser(UserModel userModel) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      String? uid = userModel.id ?? userId ?? '';
      if (uid.isEmpty) {
        return false;
      }
      userModel.id = uid;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConst.baseUrl}user/profile'),
      );
      final headers = await getHeaders();
      request.headers.addAll(headers);
      // Add text fields
      request.fields['firebase_id'] = uid;
      if (userModel.firstName != null) {
        request.fields['firstName'] = userModel.firstName!;
      }
      if (userModel.lastName != null) {
        request.fields['lastName'] = userModel.lastName!;
      }
      if (userModel.email != null) {
        request.fields['email'] = userModel.email!;
      }
      if (userModel.phoneNumber != null) {
        request.fields['phoneNumber'] = userModel.phoneNumber!;
      }
      if (userModel.countryCode != null) {
        request.fields['countryCode'] = userModel.countryCode!;
      }

      // Add shipping address if available
      if (userModel.shippingAddress != null &&
          userModel.shippingAddress!.isNotEmpty) {
        request.fields['shippingAddress'] = jsonEncode(
          userModel.shippingAddress!,
        );
      }
      // Add location if available
      if (userModel.location != null) {
        request.fields['location'] = userModel.location as String;
      }

      // Add profile picture if it's a file path (not a URL)
      if (userModel.profilePictureURL != null &&
          userModel.profilePictureURL!.isNotEmpty &&
          !userModel.profilePictureURL!.startsWith('http')) {
        try {
          var file = File(userModel.profilePictureURL!);
          if (await file.exists()) {
            var multipartFile = await http.MultipartFile.fromPath(
              'profilePictureURL',
              file.path,
              filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            request.files.add(multipartFile);
          }
        } catch (e) {
          print('Error adding profile picture: $e');
        }
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print("userdata ${response.body}");
      if (response.statusCode == 200) {
        // Parse response and update local user model
        var responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          Constant.userModel = userModel;
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  RxString profileImage = "".obs;

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }
}
