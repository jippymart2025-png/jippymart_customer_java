import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:jippymart_customer/app/auth_screen/otp_screen.dart';
import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/signup_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:jippymart_customer/utils/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class LoginProvider extends ChangeNotifier {
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  bool passwordVisible = true;

  TextEditingController phoneEditingController = TextEditingController();
  TextEditingController otpEditingController = TextEditingController();
  bool isOtpSent = false;
  bool isVerifying = false;
  String authToken = '';
  String countryCode = '+91'; // Default country code
  String phoneNumber = '';
  int resendSeconds = 0;
  bool resendTimerStarted = false;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  void startResendTimer() {
    if (resendTimerStarted) return;
    resendTimerStarted = true;
    resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      resendSeconds--;
      notifyListeners();
      if (resendSeconds <= 0) {
        resendTimerStarted = false;
        return false;
      }
      return true;
    });
  }

  void initFunction() {
    // No Firebase initialization needed
  }

  // Helper method for API calls
  Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic> data,
    String method,
  ) async {
    try {
      final url = Uri.parse('${AppConst.baseUrl}$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
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

  Future<void> sendOtp({String countryCode = '+91'}) async {
    final phone = phoneEditingController.value.text.trim();
    if (phone.isEmpty) {
      ShowToastDialog.showToast("Please enter mobile number".tr);
      return;
    } else if (phone.length < 10 || phone.length > 15) {
      ShowToastDialog.showToast("Phone number must be 10-15 digits".tr);
      return;
    }
    // Update the country code
    this.countryCode = countryCode;

    // Remove '+' from country code if present and combine with phone number
    String cleanCountryCode = countryCode.replaceAll('+', '');
    String fullPhoneNumber = '$cleanCountryCode$phone';

    print('[DEBUG] sendOtp() called with full phone: $fullPhoneNumber');
    print(
      '[DEBUG] Country code: $countryCode, Clean country code: $cleanCountryCode',
    );

    ShowToastDialog.showLoader("Please wait".tr);
    try {
      phoneNumber = fullPhoneNumber;
      final response = await _makeApiCall('api/send-otp', {
        'phone': fullPhoneNumber,
      }, 'POST');

      print('[DEBUG] sendOtp() response: $response');

      if (response['success'] == true) {
        isOtpSent = true;
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("OTP sent successfully".tr);
        Get.to(() => OtpScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message'] ?? "Failed to send OTP".tr,
        );
      }
    } catch (e) {
      print('[DEBUG] sendOtp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error sending OTP".tr);
    }
  }

  Future<void> verifyOtp(BuildContext context) async {
    ShowToastDialog.showLoader("Verifying OTP...".tr);
    isVerifying = true;
    notifyListeners();

    try {
      // Remove '+' from country code if present and combine with phone number
      String cleanCountryCode = countryCode.replaceAll('+', '');
      String fullPhoneNumber =
          '$cleanCountryCode${phoneEditingController.value.text.trim()}';

      final response = await _makeApiCall('api/verify-otp', {
        'phone': fullPhoneNumber,
        // Use the combined phone number for verification too
        'otp': otpEditingController.value.text.trim(),
      }, 'POST');

      if (response['success'] == true) {
        authToken = response['token'] ?? '';
        await secureStorage.write(key: 'api_token', value: authToken);

        // Store user ID for future use
        if (response['user'] != null && response['user']['id'] != null) {
          await secureStorage.write(
            key: 'user_id',
            value: response['user']['id'].toString(),
          );
        }

        // Check if user is registered
        if (response['is_registered'] == true) {
          // User is registered - proceed to dashboard
          final userData = response['user'];
          UserModel userModel = UserModel(
            id: userData['id'].toString(),
            firstName: userData['firstName'] ?? '',
            lastName: userData['lastName'] ?? '',
            email: userData['email'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            role: Constant.userRoleCustomer,
            active: true,
            walletAmount: userData['wallet_amount'] ?? 0,
          );

          // Store user data locally
          await _storeUserData(userModel);
          Constant.userModel = userModel;

          ShowToastDialog.closeLoader();
          Get.offAll(() => const DashBoardScreen());
        } else {
          // User not registered - go to signup
          ShowToastDialog.closeLoader();
          UserModel newUser = UserModel();
          newUser.phoneNumber = phoneEditingController.value.text.trim();
          newUser.countryCode = countryCode;

          Get.offAll(
            () => SignupScreen(),
            arguments: {
              "userModel": newUser,
              "type": "mobileNumber",
              "token": authToken,
            },
          );
        }
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message'] ?? 'OTP verification failed',
        );
      }
    } catch (e) {
      print('[DEBUG] verifyOtp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error verifying OTP. Please try again.");
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp() async {
    // Remove '+' from country code if present and combine with phone number
    String cleanCountryCode = countryCode.replaceAll('+', '');
    String fullPhoneNumber =
        '$cleanCountryCode${phoneEditingController.value.text.trim()}';

    print('[DEBUG] resendOtp() called with full phone: $fullPhoneNumber');

    ShowToastDialog.showLoader("Resending OTP...");
    try {
      final response = await _makeApiCall('api/resend-otp', {
        'phone': fullPhoneNumber,
        // Use the combined phone number for resend too
      }, 'POST');

      print('[DEBUG] resendOtp() response: $response');

      if (response['success'] == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("OTP resent successfully");
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message'] ?? "Failed to resend OTP".tr,
        );
      }
    } catch (e) {
      print('[DEBUG] resendOtp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error resending OTP".tr);
    }
  }

  // Store user data locally
  Future<void> _storeUserData(UserModel user) async {
    await secureStorage.write(key: 'user_id', value: user.id);
    await secureStorage.write(key: 'user_firstName', value: user.firstName);
    await secureStorage.write(key: 'user_lastName', value: user.lastName);
    await secureStorage.write(key: 'user_email', value: user.email);
    await secureStorage.write(key: 'user_phone', value: user.phoneNumber);
    await secureStorage.write(key: 'user_countryCode', value: countryCode);
  }

  // Load user data from local storage
  Future<UserModel?> loadUserData() async {
    try {
      final userId = await secureStorage.read(key: 'user_id');
      if (userId == null) return null;

      final storedCountryCode =
          await secureStorage.read(key: 'user_countryCode') ?? '+91';

      return UserModel(
        id: userId,
        firstName: await secureStorage.read(key: 'user_firstName') ?? '',
        lastName: await secureStorage.read(key: 'user_lastName') ?? '',
        email: await secureStorage.read(key: 'user_email') ?? '',
        phoneNumber: await secureStorage.read(key: 'user_phone') ?? '',
        countryCode: storedCountryCode,
        role: Constant.userRoleCustomer,
        active: true,
      );
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    print('DEBUG: LoginController logout - Starting cart clearing process');
    CartControllerProvider cartControllerProvider =
        Provider.of<CartControllerProvider>(context, listen: false);
    await cartControllerProvider.clearCart();
    // Clear all stored data
    await secureStorage.delete(key: 'api_token');
    await secureStorage.delete(key: 'user_id');
    await secureStorage.delete(key: 'user_firstName');
    await secureStorage.delete(key: 'user_lastName');
    await secureStorage.delete(key: 'user_email');
    await secureStorage.delete(key: 'user_phone');
    await secureStorage.delete(key: 'user_countryCode');
    Get.offAllNamed('/LoginScreen');
  }
}
