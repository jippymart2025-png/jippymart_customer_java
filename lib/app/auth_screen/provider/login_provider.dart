import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:jippymart_customer/app/auth_screen/otp_screen.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/provider/signup_provider.dart';
import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/signup_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart'
    show SqlStorageConst;
import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// class LoginProvider extends ChangeNotifier {
//   static const Duration _authTimeout = Duration(seconds: 20);
//   TextEditingController emailEditingController = TextEditingController();
//   TextEditingController passwordEditingController = TextEditingController();
//   bool passwordVisible = true;
//   TextEditingController phoneEditingController = TextEditingController();
//
//   // TextEditingController otpEditingController = TextEditingController();
//   bool isOtpSent = false;
//   bool isVerifying = false;
//   String authToken = '';
//   String countryCode = '+91';
//   String phoneNumber = '';
//   int resendSeconds = 0;
//   bool resendTimerStarted = false;
//
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   void startResendTimer() {
//     if (resendTimerStarted) return;
//     resendTimerStarted = true;
//     resendSeconds = 60;
//     Future.doWhile(() async {
//       await Future.delayed(const Duration(seconds: 1));
//       resendSeconds--;
//       notifyListeners();
//       if (resendSeconds <= 0) {
//         resendTimerStarted = false;
//         return false;
//       }
//       return true;
//     });
//   }
//
//   // Helper method for API calls
//   Future<Map<String, dynamic>> _makeApiCall(
//     String endpoint,
//     Map<String, dynamic> data,
//     String method,
//   ) async {
//     try {
//       final url = Uri.parse('${AppConst.baseUrl}$endpoint');
//       final headers = {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       };
//       http.Response? response;
//       if (method == 'POST') {
//         response = await SafeHttpClient.safePost(
//           url,
//           headers: headers,
//           body: json.encode(data),
//           timeout: _authTimeout,
//         );
//       } else {
//         throw Exception('Unsupported HTTP method');
//       }
//
//       if (response == null) {
//         throw SocketException('No internet connection');
//       }
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } on SocketException {
//       throw Exception(
//         'No internet connection. Please check your network and try again.',
//       );
//     } on TimeoutException {
//       throw Exception('Request timed out. Please try again.');
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<void> sendOtp({String countryCode = '+91'}) async {
//     final phone = phoneEditingController.value.text.trim();
//     if (phone.isEmpty) {
//       ShowToastDialog.showToast("Please enter mobile number".tr);
//       return;
//     } else if (phone.length != 10) {
//       ShowToastDialog.showToast("Phone number must be 10 digits".tr);
//       return;
//     }
//     this.countryCode = countryCode;
//     String cleanCountryCode = countryCode.replaceAll('+', '');
//     String fullPhoneNumber = phone;
//     print('[DEBUG] sendOtp() called with full phone: $fullPhoneNumber');
//     print(
//       '[DEBUG] Country code: $countryCode, Clean country code: $cleanCountryCode',
//     );
//     ShowToastDialog.showLoader("Please wait".tr);
//     try {
//       phoneNumber = fullPhoneNumber;
//       final response = await _makeApiCall('send-otp', {'phone': phone}, 'POST');
//       print('[DEBUG] sendOtp() response: $response');
//       if (response['success'] == true) {
//         isOtpSent = true;
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("OTP sent successfully".tr);
//         Get.to(() => OtpScreen());
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           response['message'] ?? "Failed to send OTP".tr,
//         );
//       }
//     } catch (e) {
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Error sending OTP".tr);
//     }
//   }
//
//   Future<void> verifyOtp(
//     BuildContext context,
//     SplashProvider splashProvider,
//     String otps,
//   ) async {
//     final otp = otps;
//     if (otp.length < 4) {
//       ShowToastDialog.showToast("Please enter valid OTP".tr);
//       return;
//     }
//     ShowToastDialog.showLoader("Verifying OTP...".tr);
//     isVerifying = true;
//     notifyListeners();
//     try {
//       final cleanCountryCode = countryCode.replaceAll('+', '');
//       final enteredPhone = phoneEditingController.value.text.trim();
//       String fullPhoneNumber = phoneNumber.isNotEmpty
//           ? phoneNumber
//           : enteredPhone;
//       if (fullPhoneNumber.isEmpty) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Phone number missing. Please retry.".tr);
//         return;
//       }
//       SignupProvider signupProvider = Provider.of<SignupProvider>(
//         context,
//         listen: false,
//       );
//       var bodyOtp = {'phone': fullPhoneNumber, 'otp': otp};
//       print("verifyOtp $bodyOtp");
//       final response = await _makeApiCall('verify-otp', bodyOtp, 'POST');
//       if (response['success'] == true) {
//         authToken = response['token'] ?? '';
//         await secureStorage.write(key: 'api_token', value: authToken);
//         if (response['user'] != null && response['user']['id'] != null) {
//           await secureStorage.write(
//             key: 'user_id',
//             value: response['user']['id'].toString(),
//           );
//         }
//         final userData = response['user'] ?? {};
//         final firebaseId =
//             (userData['firebase_id'] ??
//                     userData['firebaseId'] ??
//                     userData['firebaseID'] ??
//                     userData['id'])
//                 ?.toString();
//         if (firebaseId != null && firebaseId.isNotEmpty) {
//           await secureStorage.write(key: 'firebase_id', value: firebaseId);
//         }
//         if (response['is_registered'] == true) {
//           UserModel userModel = UserModel(
//             id: userData['id'].toString(),
//             firstName: userData['firstName'] ?? '',
//             lastName: userData['lastName'] ?? '',
//             email: userData['email'] ?? '',
//             phoneNumber: userData['phoneNumber'] ?? '',
//             firebaseId: firebaseId ?? '',
//             role: Constant.userRoleCustomer,
//             active: true,
//             walletAmount: userData['wallet_amount'] ?? 0,
//           );
//           Constant.userModel = userModel;
//           await SqlStorageConst.storeUserData(
//             userModel,
//             countryCode: countryCode,
//           );
//           notifyListeners();
//
//           // IMPORTANT: Wait for location and zone check before navigating
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showLoader("Setting up your location...");
//
//           try {
//             // Get home provider
//             final homeProvider = Provider.of<HomeProvider>(context, listen: false);
//
//             // Initialize home provider first
//             print('[LOGIN] Initializing home provider...');
//             await homeProvider.initFunction(context: context);
//
//             // Wait for location and zone check before navigating
//             print('[LOGIN] Waiting for location and zone detection...');
//             await homeProvider.ensureLocationAndZoneChecked().timeout(
//               const Duration(seconds: 20),
//               onTimeout: () {
//                 print('[LOGIN] ⚠️ Location and zone check timed out after 20s, continuing to dashboard');
//                 // Set flags so UI doesn't hang
//                 homeProvider.zoneCheckCompleted = true;
//                 homeProvider.hasActuallyCheckedZone = true;
//                 homeProvider.isLoadingFunction(false);
//                 homeProvider.notifyListeners();
//               },
//             );
//
//             print('[LOGIN] ✅ Location and zone check completed. Zone: ${Constant.selectedZone?.id}, Available: ${Constant.isZoneAvailable}');
//           } catch (e) {
//             print('[LOGIN] ❌ Error during location/zone check: $e');
//             // Continue anyway - zone will be checked in background
//           }
//
//           ShowToastDialog.closeLoader();
//
//           // Navigate to dashboard AFTER location/zone check is complete
//           if (context.mounted) {
//             Get.offAll(() => const DashBoardScreen());
//
//             // Load address list in background after navigation
//             Future.microtask(() async {
//               try {
//                 final addressListProvider = Provider.of<AddressListProvider>(context, listen: false);
//                 await addressListProvider.initFunction(context: context)
//                     .timeout(const Duration(seconds: 10));
//               } catch (e) {
//                 print('[LOGIN] Error in addressListProvider.initFunction: ${e.toString()}');
//               }
//             });
//
//             // Process deep links in background
//             Future.microtask(() {
//               try {
//                 final deepLinkService = FinalDeepLinkService();
//                 deepLinkService.processPendingDeepLinkAfterLogin(context);
//               } catch (e) {
//                 print('[LOGIN] Error in deepLinkService: ${e.toString()}');
//               }
//             });
//           }
//         } else {
//           ShowToastDialog.closeLoader();
//           signupProvider.initFunction(
//             phoneNumber: phoneEditingController.value.text.trim(),
//             countryCode: countryCode,
//           );
//           Get.offAll(() => SignupScreen());
//         }
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           response['message'] ?? 'OTP verification failed',
//         );
//       }
//       notifyListeners();
//     } catch (e) {
//       print('[DEBUG] verifyOtp() error: ${e.toString()}');
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Error verifying OTP. Please try again.");
//     } finally {
//       isVerifying = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> resendOtp() async {
//     String cleanCountryCode = countryCode.replaceAll('+', '');
//     String fullPhoneNumber = '${phoneEditingController.value.text.trim()}';
//     print('[DEBUG] resendOtp() called with full phone: $fullPhoneNumber');
//     ShowToastDialog.showLoader("Resending OTP...");
//     try {
//       final response = await _makeApiCall('resend-otp', {
//         'phone': fullPhoneNumber,
//       }, 'POST');
//       print('[DEBUG] resendOtp() response: $response');
//       if (response['success'] == true) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("OTP resent successfully");
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(
//           response['message'] ?? "Failed to resend OTP".tr,
//         );
//       }
//     } catch (e) {
//       print('[DEBUG] resendOtp() error: ${e.toString()}');
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Error resending OTP".tr);
//     }
//   }
//
//   // Load user data from local storage
//   Future<UserModel?> loadUserData() async {
//     try {
//       final userId = await secureStorage.read(key: 'user_id');
//       if (userId == null) return null;
//       final storedCountryCode =
//           await secureStorage.read(key: 'user_countryCode') ?? '+91';
//       return UserModel(
//         id: userId,
//         firstName: await secureStorage.read(key: 'user_firstName') ?? '',
//         lastName: await secureStorage.read(key: 'user_lastName') ?? '',
//         email: await secureStorage.read(key: 'user_email') ?? '',
//         phoneNumber: await secureStorage.read(key: 'user_phone') ?? '',
//         countryCode: storedCountryCode,
//         role: Constant.userRoleCustomer,
//         active: true,
//       );
//     } catch (e) {
//       print('Error loading user data: $e');
//       return null;
//     }
//   }
//
//   Future<void> logout(BuildContext context) async {
//     print('DEBUG: LoginController logout - Starting cart clearing process');
//     CartControllerProvider cartControllerProvider =
//         Provider.of<CartControllerProvider>(context, listen: false);
//     await cartControllerProvider.clearCart();
//     await secureStorage.delete(key: 'api_token');
//     await secureStorage.delete(key: 'user_id');
//     await secureStorage.delete(key: 'user_firstName');
//     await secureStorage.delete(key: 'user_lastName');
//     await secureStorage.delete(key: 'user_email');
//     await secureStorage.delete(key: 'user_phone');
//     await secureStorage.delete(key: 'user_countryCode');
//     phoneEditingController.clear();
//     phoneEditingController = TextEditingController();
//     Get.offAll(() => PhoneNumberScreen());
//   }
// }

class LoginProvider extends ChangeNotifier {
  static const Duration _authTimeout = Duration(seconds: 20);
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Controllers
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController phoneEditingController = TextEditingController();

  // State variables
  bool passwordVisible = true;
  bool isOtpSent = false;
  bool isVerifying = false;
  String authToken = '';
  String countryCode = '+91';
  String phoneNumber = '';
  int resendSeconds = 0;
  bool resendTimerStarted = false;

  // Caching
  Map<String, dynamic> _apiResponseCache = {};
  Timer? _debounceTimer;
  DateTime? _lastOtpRequestTime;
  static const Duration _otpCooldown = Duration(seconds: 30);

  // Storage
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  void startResendTimer() {
    if (resendTimerStarted) return;
    resendTimerStarted = true;
    resendSeconds = 60;

    // Use a single timer instead of Future.doWhile to reduce CPU usage
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds <= 0) {
        timer.cancel();
        resendTimerStarted = false;
        notifyListeners();
        return;
      }
      resendSeconds--;
      // Only notify listeners every 5 seconds to reduce rebuilds
      if (resendSeconds % 5 == 0 || resendSeconds <= 0) {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Optimized API call with caching
  Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic> data,
    String method, {
    bool cacheable = false,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    // Check cache first for GET-like requests (not for OTP/verification)
    if (cacheable &&
        method == 'POST' &&
        _apiResponseCache.containsKey(endpoint)) {
      final cached = _apiResponseCache[endpoint];
      if (cached['timestamp'] != null) {
        final now = DateTime.now();
        final cachedTime = DateTime.parse(cached['timestamp']);
        if (now.difference(cachedTime) < cacheDuration) {
          return cached['data'];
        }
      }
    }

    try {
      final url = Uri.parse('${AppConst.baseUrl}$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      http.Response? response;
      if (method == 'POST') {
        response = await SafeHttpClient.safePost(
          url,
          headers: headers,
          body: json.encode(data),
          timeout: _authTimeout,
        );
      } else {
        throw Exception('Unsupported HTTP method');
      }

      if (response == null) {
        throw SocketException('No internet connection');
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Cache successful responses
        if (cacheable && result['success'] == true) {
          _apiResponseCache[endpoint] = {
            'data': result,
            'timestamp': DateTime.now().toIso8601String(),
          };
        }

        return result;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  // Debounced OTP sending to prevent spam
  Future<void> sendOtp({String countryCode = '+91'}) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Rate limiting check
    if (_lastOtpRequestTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastOtpRequestTime!) < _otpCooldown) {
        ShowToastDialog.showToast(
          "Please wait before requesting another OTP".tr,
        );
        return;
      }
    }

    // Debounce the OTP request
    _debounceTimer = Timer(_debounceDuration, () async {
      _sendOtpInternal(countryCode);
    });
  }

  Future<void> _sendOtpInternal(String countryCode) async {
    final phone = phoneEditingController.value.text.trim();
    if (phone.isEmpty) {
      ShowToastDialog.showToast("Please enter mobile number".tr);
      return;
    } else if (phone.length != 10) {
      ShowToastDialog.showToast("Phone number must be 10 digits".tr);
      return;
    }

    this.countryCode = countryCode;
    String fullPhoneNumber = phone;

    _lastOtpRequestTime = DateTime.now();

    ShowToastDialog.showLoader("Please wait".tr);
    try {
      phoneNumber = fullPhoneNumber;
      final response = await _makeApiCall('send-otp', {'phone': phone}, 'POST');

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
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error sending OTP".tr);
    }
  }

  Future<void> verifyOtp(
    BuildContext context,
    SplashProvider splashProvider,
    String otps,
  ) async {
    final otp = otps;
    if (otp.length < 4) {
      ShowToastDialog.showToast("Please enter valid OTP".tr);
      return;
    }

    if (isVerifying) return; // Prevent multiple verification attempts

    ShowToastDialog.showLoader("Verifying OTP...".tr);
    isVerifying = true;
    notifyListeners();

    try {
      final enteredPhone = phoneEditingController.value.text.trim();
      String fullPhoneNumber = phoneNumber.isNotEmpty
          ? phoneNumber
          : enteredPhone;

      if (fullPhoneNumber.isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Phone number missing. Please retry.".tr);
        isVerifying = false;
        notifyListeners();
        return;
      }

      SignupProvider signupProvider = Provider.of<SignupProvider>(
        context,
        listen: false,
      );

      final response = await _makeApiCall('verify-otp', {
        'phone': fullPhoneNumber,
        'otp': otp,
      }, 'POST');

      if (response['success'] == true) {
        await _handleSuccessfulVerification(context, response, signupProvider);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message'] ?? 'OTP verification failed',
        );
        isVerifying = false;
        notifyListeners();
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error verifying OTP. Please try again.");
      isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> _handleSuccessfulVerification(
    BuildContext context,
    Map<String, dynamic> response,
    SignupProvider signupProvider,
  ) async {
    authToken = response['token'] ?? '';
    await secureStorage.write(key: 'api_token', value: authToken);

    final userData = response['user'] ?? {};

    if (userData['id'] != null) {
      await secureStorage.write(
        key: 'user_id',
        value: userData['id'].toString(),
      );
    }

    final firebaseId = _extractFirebaseId(userData);
    if (firebaseId != null && firebaseId.isNotEmpty) {
      await secureStorage.write(key: 'firebase_id', value: firebaseId);
    }

    if (response['is_registered'] == true) {
      await _handleRegisteredUser(context, userData, firebaseId);
    } else {
      ShowToastDialog.closeLoader();
      signupProvider.initFunction(
        phoneNumber: phoneEditingController.value.text.trim(),
        countryCode: countryCode,
      );
      Get.offAll(() => SignupScreen());
    }

    isVerifying = false;
    notifyListeners();
  }

  String? _extractFirebaseId(Map<String, dynamic> userData) {
    return (userData['firebase_id'] ??
            userData['firebaseId'] ??
            userData['firebaseID'] ??
            userData['id'])
        ?.toString();
  }

  Future<void> _handleRegisteredUser(
    BuildContext context,
    Map<String, dynamic> userData,
    String? firebaseId,
  ) async {
    UserModel userModel = UserModel(
      id: userData['id'].toString(),
      firstName: userData['firstName'] ?? '',
      lastName: userData['lastName'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      firebaseId: firebaseId ?? '',
      role: Constant.userRoleCustomer,
      active: true,
      walletAmount: userData['wallet_amount'] ?? 0,
    );

    Constant.userModel = userModel;
    await SqlStorageConst.storeUserData(userModel, countryCode: countryCode);

    // Proceed to dashboard immediately for better UX
    ShowToastDialog.closeLoader();

    if (context.mounted) {
      Get.offAll(() => const DashBoardScreen());

      // Run location and zone check in background without blocking UI
      _performBackgroundInitialization(context);
    }
  }

  Future<void> _performBackgroundInitialization(BuildContext context) async {
    // Use isolate-like approach with Future.wait for parallel execution
    await Future.wait([
      _initializeHomeProvider(context),
      _initializeAddressList(context),
    ], eagerError: false).catchError((e) {
      print('[LOGIN] Background initialization error: $e');
    });

    // Process deep links after everything else
    _processDeepLinks(context);
  }

  Future<void> _initializeHomeProvider(BuildContext context) async {
    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      await homeProvider.initFunction(context: context);

      // Start zone check but don't wait for it indefinitely
      unawaited(
        homeProvider.ensureLocationAndZoneChecked().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('[LOGIN] Zone check timed out, continuing in background');
            return null;
          },
        ),
      );
    } catch (e) {
      print('[LOGIN] Error initializing home provider: $e');
    }
  }

  Future<void> _initializeAddressList(BuildContext context) async {
    try {
      final addressListProvider = Provider.of<AddressListProvider>(
        context,
        listen: false,
      );
      await addressListProvider
          .initFunction(context: context)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('[LOGIN] Error initializing address list: $e');
    }
  }

  void _processDeepLinks(BuildContext context) {
    try {
      final deepLinkService = FinalDeepLinkService();
      deepLinkService.processPendingDeepLinkAfterLogin(context);
    } catch (e) {
      print('[LOGIN] Error processing deep links: $e');
    }
  }

  Future<void> resendOtp() async {
    // Rate limiting for resend
    if (_lastOtpRequestTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastOtpRequestTime!) < const Duration(seconds: 30)) {
        ShowToastDialog.showToast("Please wait before resending OTP".tr);
        return;
      }
    }

    String fullPhoneNumber = '${phoneEditingController.value.text.trim()}';

    ShowToastDialog.showLoader("Resending OTP...");
    try {
      final response = await _makeApiCall('resend-otp', {
        'phone': fullPhoneNumber,
      }, 'POST');

      if (response['success'] == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("OTP resent successfully");
        _lastOtpRequestTime = DateTime.now();
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message'] ?? "Failed to resend OTP".tr,
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error resending OTP".tr);
    }
  }

  // Load user data from local storage with cache
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

    // Clear cache on logout
    _apiResponseCache.clear();

    CartControllerProvider cartControllerProvider =
        Provider.of<CartControllerProvider>(context, listen: false);
    await cartControllerProvider.clearCart();

    // Batch delete storage keys
    await Future.wait([
      secureStorage.delete(key: 'api_token'),
      secureStorage.delete(key: 'user_id'),
      secureStorage.delete(key: 'user_firstName'),
      secureStorage.delete(key: 'user_lastName'),
      secureStorage.delete(key: 'user_email'),
      secureStorage.delete(key: 'user_phone'),
      secureStorage.delete(key: 'user_countryCode'),
    ]);

    phoneEditingController.clear();
    Get.offAll(() => PhoneNumberScreen());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    phoneEditingController.dispose();
    super.dispose();
  }
}
