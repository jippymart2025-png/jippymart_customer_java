import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

class SignupProvider extends ChangeNotifier {
  // Controllers
  TextEditingController firstNameEditingController = TextEditingController();
  TextEditingController lastNameEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController phoneNUmberEditingController = TextEditingController();
  TextEditingController countryCodeEditingController = TextEditingController(
    text: "+91",
  );
  TextEditingController referralCodeEditingController = TextEditingController();

  // State variables
  String type = "";
  String authToken = "";
  UserModel userModel = UserModel();
  bool _isSigningUp = false;

  // Storage
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Email validation pattern
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  bool isValidEmail(String email) => _emailRegex.hasMatch(email);

  void initFunction({
    required String phoneNumber,
    required String countryCode,
  }) {
    phoneNUmberEditingController.text = phoneNumber;
    countryCodeEditingController.text = countryCode;
    notifyListeners();
  }

  Future<void> signUpWithEmailAndPassword(
    BuildContext context,
    SplashProvider splashProvider,
  ) async {
    if (_isSigningUp) return;

    _isSigningUp = true;
    ShowToastDialog.showLoader("Creating your account...".tr);

    try {
      final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
      if (customerId == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Please log in to complete signup".tr);
        return;
      }

      final referralCode = referralCodeEditingController.text.trim();
      final profileData = <String, dynamic>{
        'firstName': firstNameEditingController.value.text.trim(),
        'lastName': lastNameEditingController.value.text.trim(),
        'email': emailEditingController.value.text.trim().toLowerCase(),
        'phoneNumber': phoneNUmberEditingController.value.text.trim(),
        'createdBy': customerId,
        'customerId': customerId,
        'referralCode': referralCode,
      };

      print('[SIGNUP] updateCustomerProfile body: $profileData');

      final headers = await getHeaders();
      final response = await http
          .put(
            Uri.parse(
              '${AppConst.outletBaseUrl}co/customers/updateCustomerProfile',
            ),
            headers: headers,
            body: json.encode(profileData),
          )
          .timeout(const Duration(seconds: 20));

      print('[SIGNUP] status: ${response.statusCode}');
      print('[SIGNUP] response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      Map<String, dynamic> responseMap = {};
      if (response.body.trim().isNotEmpty) {
        responseMap = _convertToResponseMap(json.decode(response.body));
      }
      final isSuccess = responseMap['success'] != false;

      if (isSuccess) {
        final countryCode = countryCodeEditingController.text.replaceAll(
          '+',
          '',
        );
        await _handleSuccessfulSignup(context, responseMap, countryCode);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          responseMap['message']?.toString() ?? "Signup failed".tr,
        );
      }
      notifyListeners();
    } catch (e) {
      print('[DEBUG] signUp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();

      if (e.toString().contains('timeout')) {
        ShowToastDialog.showToast(
          "Request timed out. Please check your connection and try again.",
        );
      } else if (e.toString().contains('socket') ||
          e.toString().contains('connection')) {
        ShowToastDialog.showToast(
          "No internet connection. Please check your network.",
        );
      } else {
        ShowToastDialog.showToast("Error creating account. Please try again.");
      }
    } finally {
      _isSigningUp = false;
    }
  }

  // Helper method to safely convert response to Map<String, dynamic>
  Map<String, dynamic> _convertToResponseMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    } else if (response is Map<dynamic, dynamic>) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> result = {};
      for (final key in response.keys) {
        result[key.toString()] = response[key];
      }
      return result;
    } else if (response is String) {
      // Try to parse as JSON
      try {
        final parsed = json.decode(response) as Map<String, dynamic>;
        return parsed;
      } catch (e) {
        return {'success': false, 'message': 'Invalid response format'};
      }
    } else {
      return {'success': false, 'message': 'Unknown response type'};
    }
  }

  Future<void> _handleSuccessfulSignup(
    BuildContext context,
    Map<String, dynamic> response,
    String countryCode,
  ) async {
    try {
      if (response['token'] != null) {
        await saveAuthToken(response['token'].toString());
      } else if (response['accessToken'] != null) {
        await saveAuthToken(
          response['accessToken'].toString(),
          tokenType: response['tokenType']?.toString() ?? 'Bearer',
        );
      } else if (authToken.isNotEmpty) {
        await saveAuthToken(authToken);
      }

      final storedCustomerId = await SqlStorageConst.getUserId() ?? '';
      final userData = (response['user'] is Map || response['data'] is Map)
          ? _convertToResponseMap(response['user'] ?? response['data'])
          : response;

      UserModel newUser = UserModel(
        id: userData['customerId']?.toString() ??
            userData['id']?.toString() ??
            storedCustomerId,
        firebaseId: userData['firebase_id']?.toString() ?? storedCustomerId,
        firstName:
            userData['firstName']?.toString() ??
            firstNameEditingController.value.text.trim(),
        lastName:
            userData['lastName']?.toString() ??
            lastNameEditingController.value.text.trim(),
        email:
            userData['email']?.toString() ??
            emailEditingController.value.text.trim(),
        phoneNumber:
            userData['phoneNumber']?.toString() ??
            phoneNUmberEditingController.value.text.trim(),
        role: Constant.userRoleCustomer,
        active: true,
        countryCode: countryCodeEditingController.value.text,
        walletAmount:
            int.tryParse(userData['wallet_amount']?.toString() ?? '0') ?? 0,
      );

      await SqlStorageConst.storeUserData(newUser, countryCode: countryCode);
      Constant.userModel = newUser;

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        response['message']?.toString() ?? "Account created successfully".tr,
      );

      if (!context.mounted) {
        Get.offAll(() => const DashBoardScreen());
        return;
      }

      Get.offAll(() => const DashBoardScreen());
      _performBackgroundLocationCheck(context);
    } catch (e) {
      ShowToastDialog.closeLoader();
      print('[SIGNUP] Error in handleSuccessfulSignup: $e');
      Get.offAll(() => const DashBoardScreen());
    }
  }

  void _performBackgroundLocationCheck(BuildContext context) {
    // Run in background without blocking UI
    Future.microtask(() async {
      try {
        print('[SIGNUP] Starting background location check');
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        await homeProvider.initFunction(context: context);

        // Start zone check but don't wait
        unawaited(
          homeProvider.ensureLocationAndZoneChecked().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[SIGNUP] Background zone check completed');
              return null;
            },
          ),
        );
      } catch (e) {
        print('[SIGNUP] Background location error: $e');
      }
    });
  }

  @override
  void dispose() {
    firstNameEditingController.dispose();
    lastNameEditingController.dispose();
    emailEditingController.dispose();
    phoneNUmberEditingController.dispose();
    countryCodeEditingController.dispose();
    referralCodeEditingController.dispose();
    super.dispose();
  }
}
