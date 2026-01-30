// import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
// import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
// import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:jippymart_customer/utils/utils/app_constant.dart';
// import 'package:jippymart_customer/utils/utils/common.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:provider/provider.dart';
//
// class SignupProvider extends ChangeNotifier {
//   TextEditingController firstNameEditingController = TextEditingController();
//   TextEditingController lastNameEditingController = TextEditingController();
//   TextEditingController emailEditingController = TextEditingController();
//   TextEditingController phoneNUmberEditingController = TextEditingController();
//   TextEditingController countryCodeEditingController = TextEditingController(
//     text: "+91",
//   );
//   String type = "";
//   String authToken = "";
//   UserModel userModel = UserModel();
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   bool isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return emailRegex.hasMatch(email);
//   }
//
//   void initFunction({
//     required String phoneNumber,
//     required String countryCode,
//   }) {
//     phoneNUmberEditingController.text = phoneNumber;
//     countryCodeEditingController.text = countryCode;
//     firstNameEditingController.clear();
//     lastNameEditingController.clear();
//     emailEditingController.clear();
//     notifyListeners();
//   }
//
//   Future<dynamic> _makeApiCall(
//     String endpoint,
//     Map<String, dynamic> data,
//     String method, {
//     String? token,
//   }) async {
//     try {
//       final headers = await getHeaders();
//       if (token != null) {
//         headers['Authorization'] = 'Bearer $token';
//       }
//
//       final response = method == 'POST'
//           ? await http.post(
//               Uri.parse('${AppConst.baseUrl}$endpoint'),
//               headers: headers,
//               body: json.encode(data),
//             )
//           : await http.get(
//               Uri.parse('${AppConst.baseUrl}$endpoint'),
//               headers: headers,
//             );
//       print('[API_CALL] Response status: ${response.statusCode}');
//       print('[API_CALL] Response body: ${response.body}');
//       // Accept both 200 and 201 as success statuses
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } catch (e) {
//       print('[API_CALL] Error: $e');
//       rethrow;
//     }
//   }
//
//   signUpWithEmailAndPassword(
//     BuildContext context,
//     SplashProvider splashProvider,
//   ) async {
//     ShowToastDialog.showLoader("Please wait".tr);
//     try {
//       String countryCode = countryCodeEditingController.text.replaceAll(
//         '+',
//         '',
//       );
//       Map<String, dynamic> signupData = {
//         "firstName": firstNameEditingController.value.text.trim(),
//         "lastName": lastNameEditingController.value.text.trim(),
//         "email": emailEditingController.value.text.trim().toLowerCase(),
//         "phone": phoneNUmberEditingController.value.text.trim(),
//         "countryCode": "+91",
//       };
//       final endpoint = authToken.isNotEmpty ? 'complete-profile' : 'signup';
//       print("signupData ${signupData} ");
//       final response = await _makeApiCall(
//         endpoint,
//         signupData,
//         'POST',
//         token: authToken.isNotEmpty ? authToken : null,
//       );
//       if (response['success'] == true) {
//         if (response['token'] != null) {
//           await secureStorage.write(key: 'api_token', value: response['token']);
//         }
//         final userData = response['user'] ?? {};
//         UserModel newUser = UserModel(
//           id: userData['id']?.toString() ?? '',
//           firebaseId: userData['firebase_id'] ?? '',
//           firstName:
//               userData['firstName'] ??
//               firstNameEditingController.value.text.trim(),
//           lastName:
//               userData['lastName'] ??
//               lastNameEditingController.value.text.trim(),
//           email: userData['email'] ?? emailEditingController.value.text.trim(),
//           phoneNumber:
//               userData['phoneNumber'] ??
//               phoneNUmberEditingController.value.text.trim(),
//           role: Constant.userRoleCustomer,
//           active: true,
//           countryCode: countryCodeEditingController.value.text,
//           walletAmount: userData['wallet_amount'] ?? 0.0,
//         );
//         // Store user data locally
//         await SqlStorageConst.storeUserData(newUser);
//         Constant.userModel = newUser;
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Account created successfully".tr);
//         if (newUser.shippingAddress != null &&
//             newUser.shippingAddress!.isNotEmpty) {
//           // IMPORTANT: Wait for location and zone check before navigating
//           ShowToastDialog.showLoader("Setting up your location...");
//
//           try {
//             // Get home provider
//             final homeProvider = Provider.of<HomeProvider>(context, listen: false);
//
//             // Initialize home provider first
//             print('[SIGNUP] Initializing home provider...');
//             await homeProvider.initFunction(context: context);
//
//             // Wait for location and zone check before navigating
//             print('[SIGNUP] Waiting for location and zone detection...');
//             await homeProvider.ensureLocationAndZoneChecked().timeout(
//               const Duration(seconds: 20),
//               onTimeout: () {
//                 print('[SIGNUP] ⚠️ Location and zone check timed out after 20s, continuing to dashboard');
//                 // Set flags so UI doesn't hang
//                 homeProvider.zoneCheckCompleted = true;
//                 homeProvider.hasActuallyCheckedZone = true;
//                 homeProvider.isLoadingFunction(false);
//                 homeProvider.notifyListeners();
//               },
//             );
//
//             print('[SIGNUP] ✅ Location and zone check completed. Zone: ${Constant.selectedZone?.id}, Available: ${Constant.isZoneAvailable}');
//           } catch (e) {
//             print('[SIGNUP] ❌ Error during location/zone check: $e');
//             // Continue anyway - zone will be checked in background
//           }
//
//           ShowToastDialog.closeLoader();
//
//           // Navigate to dashboard AFTER location/zone check is complete
//           if (context.mounted) {
//             Get.offAll(const DashBoardScreen());
//           }
//         } else {
//           Get.offAll(() => LocationPermissionScreen());
//         }
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(response['message'] ?? "Signup failed".tr);
//       }
//       notifyListeners();
//     } catch (e) {
//       print('[DEBUG] signUp() error: ${e.toString()}');
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Error creating account. Please try again.");
//     }
//   }
// }

import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
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
    // Prevent multiple signup attempts
    if (_isSigningUp) return;

    _isSigningUp = true;
    ShowToastDialog.showLoader("Creating your account...".tr);

    try {
      String countryCode = countryCodeEditingController.text.replaceAll(
        '+',
        '',
      );
      Map<String, dynamic> signupData = {
        "firstName": firstNameEditingController.value.text.trim(),
        "lastName": lastNameEditingController.value.text.trim(),
        "email": emailEditingController.value.text.trim().toLowerCase(),
        "phone": phoneNUmberEditingController.value.text.trim(),
        "countryCode": "+91",
      };

      final endpoint = authToken.isNotEmpty ? 'complete-profile' : 'signup';
      print("signupData $signupData");

      final response = await _makeApiCall(
        endpoint,
        signupData,
        'POST',
        token: authToken.isNotEmpty ? authToken : null,
      );

      print('[SIGNUP] Full API response: $response');

      // Convert response to Map<String, dynamic> and check success
      final Map<String, dynamic> responseMap = _convertToResponseMap(response);

      if (responseMap['success'] == true) {
        await _handleSuccessfulSignup(context, responseMap, countryCode);
      } else {
        ShowToastDialog.closeLoader();
        final errorMessage = responseMap['message'] ?? "Signup failed".tr;
        ShowToastDialog.showToast(errorMessage);
        print('[SIGNUP] API Error Response: $response');
      }
      notifyListeners();
    } catch (e) {
      print('[DEBUG] signUp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();

      // More specific error messages
      if (e.toString().contains('timeout')) {
        ShowToastDialog.showToast(
          "Request timed out. Please check your connection and try again.",
        );
      } else if (e.toString().contains('socket') ||
          e.toString().contains('connection')) {
        ShowToastDialog.showToast(
          "No internet connection. Please check your network.",
        );
      } else if (e.toString().contains('email already exists') ||
          e.toString().contains('Email already registered')) {
        ShowToastDialog.showToast(
          "Email already registered. Please use a different email.",
        );
      } else if (e.toString().contains('phone already exists') ||
          e.toString().contains('Phone already registered')) {
        ShowToastDialog.showToast("Phone number already registered.");
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

  Future<dynamic> _makeApiCall(
    String endpoint,
    Map<String, dynamic> data,
    String method, {
    String? token,
  }) async {
    try {
      final headers = await _getHeaders();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = Uri.parse('${AppConst.baseUrl}$endpoint');
      print('[API] Calling: $url');
      print('[API] Data: $data');

      http.Response response;
      if (method == 'POST') {
        response = await http
            .post(url, headers: headers, body: json.encode(data))
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 15));
      }

      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      // Parse response body - this may return Map<dynamic, dynamic>
      final responseBody = json.decode(response.body);

      // Accept both 200 and 201 as success statuses
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        // Include the parsed response body in the exception
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      print('[API] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await secureStorage.read(key: 'api_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _handleSuccessfulSignup(
    BuildContext context,
    Map<String, dynamic> response,
    String countryCode,
  ) async {
    try {
      // Store token if provided
      if (response['token'] != null) {
        await secureStorage.write(
          key: 'api_token',
          value: response['token'].toString(),
        );
        print('[SIGNUP] Token stored successfully');
      }

      // Safely get user data
      final userData = (response['user'] is Map)
          ? _convertToResponseMap(response['user'])
          : <String, dynamic>{};

      print('[SIGNUP] User data received: $userData');

      UserModel newUser = UserModel(
        id: userData['id']?.toString() ?? '',
        firebaseId: userData['firebase_id']?.toString() ?? '',
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

      print('[SIGNUP] Created user model: ${newUser.toJson()}');

      // Store user data locally
      await SqlStorageConst.storeUserData(newUser);
      Constant.userModel = newUser;

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Account created successfully".tr);

      // Navigate immediately, handle location in background
      await _navigateAfterSignup(context, newUser);
    } catch (e) {
      ShowToastDialog.closeLoader();
      print('[SIGNUP] Error in handleSuccessfulSignup: $e');
      ShowToastDialog.showToast("Account created! Please login to continue.");

      // Even if there's an error in processing, navigate to dashboard
      if (context.mounted) {
        Get.offAll(const DashBoardScreen());
      }
    }
  }

  Future<void> _navigateAfterSignup(
    BuildContext context,
    UserModel newUser,
  ) async {
    try {
      final hasAddress =
          newUser.shippingAddress != null &&
          newUser.shippingAddress!.isNotEmpty;

      print('[SIGNUP] User has address: $hasAddress');
      print('[SIGNUP] Shipping address: ${newUser.shippingAddress}');

      if (hasAddress) {
        // Navigate to dashboard immediately
        if (context.mounted) {
          print('[SIGNUP] Navigating to Dashboard');
          Get.offAll(const DashBoardScreen());

          // Initialize location in background
          _performBackgroundLocationCheck(context);
        }
      } else {
        // Navigate to location permission
        if (context.mounted) {
          print('[SIGNUP] Navigating to LocationPermissionScreen');
          Get.offAll(() => LocationPermissionScreen());
        }
      }
    } catch (e) {
      print('[SIGNUP] Error in navigateAfterSignup: $e');
      if (context.mounted) {
        Get.offAll(const DashBoardScreen());
      }
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
    super.dispose();
  }
}
