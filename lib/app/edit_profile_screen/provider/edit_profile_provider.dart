// import 'dart:convert';
// import 'dart:io';
//
// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:jippymart_customer/utils/utils/app_constant.dart';
// import 'package:jippymart_customer/utils/utils/common.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:http/http.dart' as http;
//
// class EditProfileProvider extends ChangeNotifier {
//   bool isLoading = true;
//   UserModel userModel = UserModel();
//
//   // ShippingAddress? _selectedAddress;
//   // ShippingAddress? get selectedAddress => _selectedAddress;
//   //
//   // void updateSelectedAddress(ShippingAddress address) {
//   //   _selectedAddress = address;
//   //   notifyListeners();
//   // }
//
//   TextEditingController firstNameController = TextEditingController();
//   TextEditingController lastNameController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController phoneNumberController = TextEditingController();
//   TextEditingController countryCodeController = TextEditingController(
//     text: "+91",
//   );
//
//   void initFunction() {
//     getData();
//   }
//
//   bool isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return emailRegex.hasMatch(email);
//   }
//
//   getData() async {
//     try {
//       if (Constant.userModel != null) {
//         print(
//           '[EDIT_PROFILE] Using global user model: ${Constant.userModel?.toJson()}',
//         );
//         userModel = Constant.userModel!;
//       } else {
//         print(
//           '[EDIT_PROFILE] Global user model is null, fetching from Firestore',
//         );
//         final userId = await SqlStorageConst.getFirebaseId();
//         final value = await AddressListProvider.getUserProfile(
//           userId.toString(),
//         );
//         if (value != null) {
//           userModel = value;
//           Constant.userModel = value;
//           notifyListeners();
//           print(
//             '[EDIT_PROFILE] Loaded user model from Firestore: ${value.toJson()}',
//           );
//         } else {
//           print('[EDIT_PROFILE] Failed to load user model from Firestore');
//         }
//       }
//
//       // Set the form fields
//       if (userModel.id != null) {
//         firstNameController.text = userModel.firstName?.toString() ?? "";
//         lastNameController.text = userModel.lastName?.toString() ?? "";
//         emailController.text = userModel.email?.toString() ?? "";
//         phoneNumberController.text = userModel.phoneNumber?.toString() ?? "";
//         countryCodeController.text = userModel.countryCode?.toString() ?? "+91";
//         profileImage = userModel.profilePictureURL ?? "";
//         print('[EDIT_PROFILE] Form fields populated successfully');
//       } else {
//         print('[EDIT_PROFILE] User model is null, cannot populate form fields');
//       }
//     } catch (e) {
//       print('[EDIT_PROFILE] Error loading user data: $e');
//     }
//
//     isLoading = false;
//   }
//
//   saveData(BuildContext context) async {
//     if (firstNameController.text.isEmpty) {
//       // showSnackBar(
//       //   "Please enter the first name",
//       //   context,
//       // );
//       ShowToastDialog.showToast("Please enter the first name".tr);
//     } else if (lastNameController.text.isEmpty) {
//       ShowToastDialog.showToast("Please enter the last name".tr);
//       // Get.snackbar(
//       //   "Error",
//       //   "Please enter the last name",
//       //   snackPosition: SnackPosition.BOTTOM,
//       // );
//     } else if (emailController.text.isEmpty) {
//       ShowToastDialog.showToast("Please enter the email".tr);
//       // Get.snackbar(
//       //   "Error",
//       //   "Please enter the email",
//       //   snackPosition: SnackPosition.BOTTOM,
//       // );
//     } else if (!isValidEmail(emailController.text)) {
//       ShowToastDialog.showToast("Invalid email format".tr);
//     } else {
//       ShowToastDialog.showLoader("Please wait".tr);
//       if (Constant().hasValidUrl(profileImage) == false &&
//           profileImage.isNotEmpty) {
//         final userId = await SqlStorageConst.getFirebaseId();
//         profileImage = await Constant.uploadUserImageToFireStorage(
//           File(profileImage),
//           "profileImage/$userId",
//           File(profileImage).path.split('/').last,
//         );
//       }
//       userModel.firstName = firstNameController.text;
//       userModel.lastName = lastNameController.text;
//       userModel.profilePictureURL = profileImage;
//       userModel.phoneNumber = phoneNumberController.text;
//       userModel.countryCode = countryCodeController.text;
//       userModel.email = emailController.text;
//       await updateUser(userModel).then((value) {
//         Constant.userModel = userModel;
//         notifyListeners();
//         print(
//           '[EDIT_PROFILE] Updated global user model: ${Constant.userModel?.toJson()}',
//         );
//         ShowToastDialog.closeLoader();
//         Get.back(result: true);
//       });
//       notifyListeners();
//       ShowToastDialog.showToast("Profile Data Updated");
//       Get.back(result: "profile_updated");
//     }
//   }
//
//   static Future<bool> updateUser(UserModel userModel) async {
//     try {
//       final userId = await SqlStorageConst.getFirebaseId();
//       String? uid = userModel.firebaseId ?? userId ?? '';
//       if (uid.isEmpty) {
//         return false;
//       }
//       print("userdata ${userModel.toJson()}");
//       userModel.id = uid;
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${AppConst.baseUrl}user/profile'),
//       );
//       final headers = await getHeaders();
//       request.headers.addAll(headers);
//       // Add text fields
//       request.fields['firebase_id'] = uid;
//       if (userModel.firstName != null) {
//         request.fields['firstName'] = userModel.firstName!;
//       }
//       if (userModel.lastName != null) {
//         request.fields['lastName'] = userModel.lastName!;
//       }
//       if (userModel.email != null) {
//         request.fields['email'] = userModel.email!;
//       }
//       if (userModel.phoneNumber != null) {
//         request.fields['phoneNumber'] = userModel.phoneNumber!;
//       }
//       if (userModel.countryCode != null) {
//         request.fields['countryCode'] = userModel.countryCode!;
//       }
//
//       // Add shipping address if available
//       if (userModel.shippingAddress != null &&
//           userModel.shippingAddress!.isNotEmpty) {
//         request.fields['shippingAddress'] = jsonEncode(
//           userModel.shippingAddress!,
//         );
//       }
//       // Add location if available
//       if (userModel.location != null) {
//         request.fields['location'] = userModel.location as String;
//       }
//
//       // Add profile picture if it's a file path (not a URL)
//       if (userModel.profilePictureURL != null &&
//           userModel.profilePictureURL!.isNotEmpty &&
//           !userModel.profilePictureURL!.startsWith('http')) {
//         try {
//           var file = File(userModel.profilePictureURL!);
//           if (await file.exists()) {
//             var multipartFile = await http.MultipartFile.fromPath(
//               'profilePictureURL',
//               file.path,
//               filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
//             );
//             request.files.add(multipartFile);
//           }
//         } catch (e) {
//           print('Error adding profile picture: $e');
//         }
//       }
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);
//       print("userdata ${response.body}");
//       if (response.statusCode == 200) {
//         var responseData = jsonDecode(response.body);
//         if (responseData['success'] == true) {
//           Constant.userModel = userModel;
//           return true;
//         } else {
//           return false;
//         }
//       } else {
//         return false;
//       }
//     } catch (error) {
//       print(" updateUser $error");
//       return false;
//     }
//   }
//
//   final ImagePicker _imagePicker = ImagePicker();
//   String profileImage = "";
//
//   Future pickFile({required ImageSource source}) async {
//     try {
//       XFile? image = await _imagePicker.pickImage(source: source);
//       if (image == null) return;
//       Get.back();
//       profileImage = image.path;
//     } on PlatformException catch (e) {
//       ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class EditProfileProvider extends ChangeNotifier {
  bool _isSaving = false;

  // State variables
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  UserModel _userModel = UserModel();

  UserModel get userModel => _userModel;

  // Controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;
  late TextEditingController countryCodeController;

  // Image
  String _profileImage = "";

  String get profileImage => _profileImage;
  bool _hasProfileImageChanged = false;

  // Cache user ID to avoid repeated calls
  String? _cachedUserId;
  static bool _isUserModelInitialized = false;

  // Debouncing for save operation
  DateTime? _lastSaveTime;
  static const int _saveDebounceMs = 2000; // 2 seconds debounce

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  EditProfileProvider() {
    _initControllers();
  }

  void _initControllers() {
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneNumberController = TextEditingController();
    countryCodeController = TextEditingController(text: "+91");
  }

  // Initialize with existing user data (no API call if already loaded)
  Future<void> initFunction({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isUserModelInitialized &&
        Constant.userModel != null) {
      _loadFromCache();
      return;
    }

    await _loadUserData();
  }

  void _loadFromCache() {
    if (Constant.userModel != null) {
      _userModel = Constant.userModel!;
      _populateFormFields();
      _profileImage = _userModel.profilePictureURL ?? "";
      _isUserModelInitialized = true;
    }
  }

  Future<void> _loadUserData() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (Constant.userModel != null) {
        _userModel = Constant.userModel!;
      } else {
        final userId = await _getUserId();
        final user = await AddressListProvider.getUserProfile(userId);
        if (user != null) {
          _userModel = user;
          Constant.userModel = user;
        }
      }

      _populateFormFields();
      _profileImage = _userModel.profilePictureURL ?? "";
      _isUserModelInitialized = true;
    } catch (e) {
      print('[EDIT_PROFILE] Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    _cachedUserId = await SqlStorageConst.getFirebaseId() ?? '';
    return _cachedUserId!;
  }

  void _populateFormFields() {
    if (_userModel.id != null) {
      firstNameController.text = _userModel.firstName?.toString() ?? "";
      lastNameController.text = _userModel.lastName?.toString() ?? "";
      emailController.text = _userModel.email?.toString() ?? "";
      phoneNumberController.text = _userModel.phoneNumber?.toString() ?? "";
      countryCodeController.text = _userModel.countryCode?.toString() ?? "+91";
    }
  }

  // Image handling
  Future<void> pickFile({required ImageSource source}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality for faster upload
        maxWidth: 800, // Limit image size
        maxHeight: 800, // Add maxHeight for consistency
      );

      if (image != null) {
        Get.back();
        _profileImage = image.path;
        _hasProfileImageChanged = true;
        notifyListeners();
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }

  // Validation
  bool _validateForm() {
    if (firstNameController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter the first name".tr);
      return false;
    }

    if (lastNameController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter the last name".tr);
      return false;
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      ShowToastDialog.showToast("Please enter the email".tr);
      return false;
    }

    if (!isValidEmail(email)) {
      ShowToastDialog.showToast("Invalid email format".tr);
      return false;
    }

    return true;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Debounced save to prevent rapid clicks
  Future<void> saveData(BuildContext context) async {
    if (_isSaving) return; // Prevent multiple saves

    // Debounce check
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!).inMilliseconds < _saveDebounceMs) {
      ShowToastDialog.showToast("Please wait before saving again".tr);
      return;
    }

    if (!_validateForm()) return;

    // Check if any changes were made
    if (!_hasChanges()) {
      ShowToastDialog.showToast("No changes to save".tr);
      Get.back();
      return;
    }

    _lastSaveTime = now;

    ShowToastDialog.showLoader("Please wait".tr);

    _isSaving = true;
    notifyListeners();

    try {
      await _performSave();

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Profile updated successfully".tr);

      // Return result to trigger refresh in parent
      Get.back(result: true);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to update profile".tr);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  bool _hasChanges() {
    // Check if any field has changed from original values
    if (_hasProfileImageChanged) return true;

    if (firstNameController.text != (_userModel.firstName ?? "")) return true;
    if (lastNameController.text != (_userModel.lastName ?? "")) return true;
    if (emailController.text != (_userModel.email ?? "")) return true;
    if (phoneNumberController.text != (_userModel.phoneNumber ?? ""))
      return true;

    return false;
  }

  Future<void> _performSave() async {
    // Update local model
    _userModel.firstName = firstNameController.text.trim();
    _userModel.lastName = lastNameController.text.trim();
    _userModel.email = emailController.text.trim();
    _userModel.phoneNumber = phoneNumberController.text.trim();
    _userModel.countryCode = countryCodeController.text.trim();

    // Handle image upload only if changed
    if (_hasProfileImageChanged && _profileImage.isNotEmpty) {
      if (!Constant().hasValidUrl(_profileImage)) {
        final userId = await _getUserId();
        _userModel.profilePictureURL =
            await Constant.uploadUserImageToFireStorage(
              File(_profileImage),
              "profileImage/$userId",
              File(_profileImage).path.split('/').last,
            );
      } else {
        _userModel.profilePictureURL = _profileImage;
      }
      _hasProfileImageChanged = false;
    }

    // Only call API if there are changes - use the static method
    final success = await EditProfileProvider.updateUserStatic(_userModel);

    if (success) {
      // Update cache
      Constant.userModel = _userModel;
      notifyListeners();
    } else {
      throw Exception('Update failed');
    }
  }

  // Instance method for internal use
  Future<bool> updateUserInstance(UserModel userModel) async {
    return await EditProfileProvider.updateUserStatic(userModel);
  }

  // Static method for external access (kept from original code)
  static Future<bool> updateUserStatic(UserModel userModel) async {
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

  // Clean up controllers
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    countryCodeController.dispose();
    super.dispose();
  }
}
