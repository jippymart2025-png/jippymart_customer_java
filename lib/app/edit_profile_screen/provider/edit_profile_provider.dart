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
  bool isLoading = true;
  UserModel userModel = UserModel();

  // ShippingAddress? _selectedAddress;
  // ShippingAddress? get selectedAddress => _selectedAddress;
  //
  // void updateSelectedAddress(ShippingAddress address) {
  //   _selectedAddress = address;
  //   notifyListeners();
  // }

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController countryCodeController = TextEditingController(
    text: "+91",
  );

  void initFunction() {
    getData();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  getData() async {
    try {
      if (Constant.userModel != null) {
        print(
          '[EDIT_PROFILE] Using global user model: ${Constant.userModel?.toJson()}',
        );
        userModel = Constant.userModel!;
      } else {
        print(
          '[EDIT_PROFILE] Global user model is null, fetching from Firestore',
        );
        final userId = await SqlStorageConst.getFirebaseId();
        final value = await AddressListProvider.getUserProfile(
          userId.toString(),
        );
        if (value != null) {
          userModel = value;
          Constant.userModel = value;
          notifyListeners();
          print(
            '[EDIT_PROFILE] Loaded user model from Firestore: ${value.toJson()}',
          );
        } else {
          print('[EDIT_PROFILE] Failed to load user model from Firestore');
        }
      }

      // Set the form fields
      if (userModel.id != null) {
        firstNameController.text = userModel.firstName?.toString() ?? "";
        lastNameController.text = userModel.lastName?.toString() ?? "";
        emailController.text = userModel.email?.toString() ?? "";
        phoneNumberController.text = userModel.phoneNumber?.toString() ?? "";
        countryCodeController.text = userModel.countryCode?.toString() ?? "+91";
        profileImage = userModel.profilePictureURL ?? "";
        print('[EDIT_PROFILE] Form fields populated successfully');
      } else {
        print('[EDIT_PROFILE] User model is null, cannot populate form fields');
      }
    } catch (e) {
      print('[EDIT_PROFILE] Error loading user data: $e');
    }

    isLoading = false;
  }

  saveData(BuildContext context) async {
    if (firstNameController.text.isEmpty) {
      // showSnackBar(
      //   "Please enter the first name",
      //   context,
      // );
      ShowToastDialog.showToast("Please enter the first name".tr);
    } else if (lastNameController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter the last name".tr);
      // Get.snackbar(
      //   "Error",
      //   "Please enter the last name",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } else if (emailController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter the email".tr);
      // Get.snackbar(
      //   "Error",
      //   "Please enter the email",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } else if (!isValidEmail(emailController.text)) {
      ShowToastDialog.showToast("Invalid email format".tr);
    } else {
      ShowToastDialog.showLoader("Please wait".tr);
      if (Constant().hasValidUrl(profileImage) == false &&
          profileImage.isNotEmpty) {
        final userId = await SqlStorageConst.getFirebaseId();
        profileImage = await Constant.uploadUserImageToFireStorage(
          File(profileImage),
          "profileImage/$userId",
          File(profileImage).path.split('/').last,
        );
      }
      userModel.firstName = firstNameController.text;
      userModel.lastName = lastNameController.text;
      userModel.profilePictureURL = profileImage;
      userModel.phoneNumber = phoneNumberController.text;
      userModel.countryCode = countryCodeController.text;
      userModel.email = emailController.text;
      await updateUser(userModel).then((value) {
        Constant.userModel = userModel;
        notifyListeners();
        print(
          '[EDIT_PROFILE] Updated global user model: ${Constant.userModel?.toJson()}',
        );
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      });
      notifyListeners();
      Get.back(result: "profile_updated");
    }
  }

  static Future<bool> updateUser(UserModel userModel) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      String? uid = userModel.firebaseId ?? userId ?? '';
      if (uid.isEmpty) {
        return false;
      }
      print("userdata ${userModel.toJson()}");
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
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print("userdata ${response.body}");
      if (response.statusCode == 200) {
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
      print(" updateUser $error");
      return false;
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  String profileImage = "";

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }
}
