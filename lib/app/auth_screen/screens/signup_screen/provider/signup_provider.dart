import 'dart:io';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';

class SignupProvider extends ChangeNotifier {
  Rx<TextEditingController> firstNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> lastNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController(text: "+91").obs;
  Rx<TextEditingController> passwordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> conformPasswordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> referralCodeEditingController =
      TextEditingController().obs;

  RxBool passwordVisible = true.obs;
  RxBool conformPasswordVisible = true.obs;

  RxString type = "".obs;
  String authToken = "";

  Rx<UserModel> userModel = UserModel().obs;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  void initFunction() {
    getArgument();
  }

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      type.value = argumentData['type'];
      userModel.value = argumentData['userModel'];
      authToken = argumentData['token'] ?? '';

      if (type.value == "mobileNumber") {
        phoneNUmberEditingController.value.text = userModel.value.phoneNumber
            .toString();
        countryCodeEditingController.value.text = userModel.value.countryCode
            .toString();
      }
    }
  }

  Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic> data,
    String method, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('${AppConst.baseUrl}$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if token is provided
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      http.Response response;

      if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: json.encode(data),
        );
      } else {
        throw Exception('Unsupported HTTP method');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  signUpWithEmailAndPassword() async {
    if (referralCodeEditingController.value.text.toString().isNotEmpty) {
      // You might want to implement referral code validation with your API
      // For now, we'll proceed with signup
      await signUp();
    } else {
      await signUp();
    }
  }

  signUp() async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      Map<String, dynamic> signupData = {
        "firstName": firstNameEditingController.value.text.trim(),
        "lastName": lastNameEditingController.value.text.trim(),
        "email": emailEditingController.value.text.trim().toLowerCase(),
        "phone": phoneNUmberEditingController.value.text.trim(),
      };

      // If we have a token from OTP verification, use it for authenticated signup
      final endpoint = authToken.isNotEmpty
          ? 'api/complete-profile'
          : 'api/signup';

      final response = await _makeApiCall(
        endpoint,
        signupData,
        'POST',
        token: authToken.isNotEmpty ? authToken : null,
      );

      if (response['success'] == true) {
        // Store the token if this is a new registration
        if (response['token'] != null) {
          await secureStorage.write(key: 'api_token', value: response['token']);
        }

        // Create user model from response
        final userData = response['user'] ?? {};
        UserModel newUser = UserModel(
          id: userData['id']?.toString() ?? '',
          firstName:
              userData['firstName'] ??
              firstNameEditingController.value.text.trim(),
          lastName:
              userData['lastName'] ??
              lastNameEditingController.value.text.trim(),
          email: userData['email'] ?? emailEditingController.value.text.trim(),
          phoneNumber:
              userData['phoneNumber'] ??
              phoneNUmberEditingController.value.text.trim(),
          role: Constant.userRoleCustomer,
          active: true,
          countryCode: countryCodeEditingController.value.text,
          walletAmount: userData['wallet_amount'] ?? 0.0,
        );

        // Store user data locally
        await _storeUserData(newUser);
        Constant.userModel = newUser;

        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Account created successfully".tr);

        // Navigate to appropriate screen
        if (newUser.shippingAddress != null &&
            newUser.shippingAddress!.isNotEmpty) {
          Get.offAll(const DashBoardScreen());
        } else {
          Get.offAll(const LocationPermissionScreen());
        }
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(response['message'] ?? "Signup failed".tr);
      }
    } catch (e) {
      print('[DEBUG] signUp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error creating account. Please try again.");
    }
  }

  // Store user data locally
  Future<void> _storeUserData(UserModel user) async {
    await secureStorage.write(key: 'user_id', value: user.id);
    await secureStorage.write(key: 'user_firstName', value: user.firstName);
    await secureStorage.write(key: 'user_lastName', value: user.lastName);
    await secureStorage.write(key: 'user_email', value: user.email);
    await secureStorage.write(key: 'user_phone', value: user.phoneNumber);
    await secureStorage.write(key: 'user_countryCode', value: user.countryCode);
  }
}
