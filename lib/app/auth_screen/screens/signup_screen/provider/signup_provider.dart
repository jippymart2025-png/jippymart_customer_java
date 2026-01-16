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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

class SignupProvider extends ChangeNotifier {
  TextEditingController firstNameEditingController = TextEditingController();
  TextEditingController lastNameEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController phoneNUmberEditingController = TextEditingController();
  TextEditingController countryCodeEditingController = TextEditingController(
    text: "+91",
  );
  String type = "";
  String authToken = "";
  UserModel userModel = UserModel();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void initFunction({
    required String phoneNumber,
    required String countryCode,
  }) {
    phoneNUmberEditingController.text = phoneNumber;
    countryCodeEditingController.text = countryCode;
    firstNameEditingController.clear();
    lastNameEditingController.clear();
    emailEditingController.clear();
    notifyListeners();
  }

  Future<dynamic> _makeApiCall(
    String endpoint,
    Map<String, dynamic> data,
    String method, {
    String? token,
  }) async {
    try {
      final headers = await getHeaders();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = method == 'POST'
          ? await http.post(
              Uri.parse('${AppConst.baseUrl}$endpoint'),
              headers: headers,
              body: json.encode(data),
            )
          : await http.get(
              Uri.parse('${AppConst.baseUrl}$endpoint'),
              headers: headers,
            );
      print('[API_CALL] Response status: ${response.statusCode}');
      print('[API_CALL] Response body: ${response.body}');
      // Accept both 200 and 201 as success statuses
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[API_CALL] Error: $e');
      rethrow;
    }
  }

  signUpWithEmailAndPassword(
    BuildContext context,
    SplashProvider splashProvider,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
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
      print("signupData ${signupData} ");
      final response = await _makeApiCall(
        endpoint,
        signupData,
        'POST',
        token: authToken.isNotEmpty ? authToken : null,
      );
      if (response['success'] == true) {
        if (response['token'] != null) {
          await secureStorage.write(key: 'api_token', value: response['token']);
        }
        final userData = response['user'] ?? {};
        UserModel newUser = UserModel(
          id: userData['id']?.toString() ?? '',
          firebaseId: userData['firebase_id'] ?? '',
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
        await SqlStorageConst.storeUserData(newUser);
        Constant.userModel = newUser;
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Account created successfully".tr);
        if (newUser.shippingAddress != null &&
            newUser.shippingAddress!.isNotEmpty) {
          // IMPORTANT: Wait for location and zone check before navigating
          ShowToastDialog.showLoader("Setting up your location...");
          
          try {
            // Get home provider
            final homeProvider = Provider.of<HomeProvider>(context, listen: false);
            
            // Initialize home provider first
            print('[SIGNUP] Initializing home provider...');
            await homeProvider.initFunction(context: context);
            
            // Wait for location and zone check before navigating
            print('[SIGNUP] Waiting for location and zone detection...');
            await homeProvider.ensureLocationAndZoneChecked().timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                print('[SIGNUP] ⚠️ Location and zone check timed out after 20s, continuing to dashboard');
                // Set flags so UI doesn't hang
                homeProvider.zoneCheckCompleted = true;
                homeProvider.hasActuallyCheckedZone = true;
                homeProvider.isLoadingFunction(false);
                homeProvider.notifyListeners();
              },
            );
            
            print('[SIGNUP] ✅ Location and zone check completed. Zone: ${Constant.selectedZone?.id}, Available: ${Constant.isZoneAvailable}');
          } catch (e) {
            print('[SIGNUP] ❌ Error during location/zone check: $e');
            // Continue anyway - zone will be checked in background
          }
          
          ShowToastDialog.closeLoader();
          
          // Navigate to dashboard AFTER location/zone check is complete
          if (context.mounted) {
            Get.offAll(const DashBoardScreen());
          }
        } else {
          Get.offAll(() => LocationPermissionScreen());
        }
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(response['message'] ?? "Signup failed".tr);
      }
      notifyListeners();
    } catch (e) {
      print('[DEBUG] signUp() error: ${e.toString()}');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error creating account. Please try again.");
    }
  }
}
