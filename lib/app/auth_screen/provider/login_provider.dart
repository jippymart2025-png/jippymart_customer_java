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
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart'
    show SqlStorageConst;
import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

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
  Timer? _resendCountdownTimer;
  DateTime? _lastOtpRequestTime;
  static const Duration _otpCooldown = Duration(seconds: 30);

  // Storage
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  void startResendTimer() {
    _resendCountdownTimer?.cancel();
    resendTimerStarted = true;
    resendSeconds = 60;

    _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds <= 0) {
        timer.cancel();
        resendTimerStarted = false;
        notifyListeners();
        return;
      }
      resendSeconds--;
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
      final headers = await getHeaders();

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

    await _sendOtpInternal(countryCode);
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
      final url = Uri.parse('${AppConst.outletBaseUrl}co/auth/send-otp');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMzgzNTQ4LCJleHAiOjE3ODI0Njk5NDh9.Pm96Vs395-fbNIPWjYhX5AmqIjq-WHG-h4QU4IbrBdc",
      };
      final httpResponse = await SafeHttpClient.safePost(
        url,
        headers: headers,
        body: json.encode({'mobileNumber': phone}),
        timeout: _authTimeout,
      );

      if (httpResponse == null) {
        throw const SocketException('No internet connection');
      }

      if (httpResponse.statusCode != 200) {
        throw Exception(
          'HTTP ${httpResponse.statusCode}: ${httpResponse.body}',
        );
      }

      final response = json.decode(httpResponse.body) as Map<String, dynamic>;

      if (response['success'] == true) {
        isOtpSent = true;
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message']?.toString() ?? "OTP sent successfully".tr,
        );
        Get.to(() => OtpScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message']?.toString() ?? "Failed to send OTP".tr,
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

      final url = Uri.parse('${AppConst.outletBaseUrl}co/auth/verify-otp');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMzgzNTQ4LCJleHAiOjE3ODI0Njk5NDh9.Pm96Vs395-fbNIPWjYhX5AmqIjq-WHG-h4QU4IbrBdc",
      };
      final httpResponse = await SafeHttpClient.safePost(
        url,
        headers: headers,
        body: json.encode({'mobileNumber': fullPhoneNumber, 'otp': otp}),
        timeout: _authTimeout,
      );

      if (httpResponse == null) {
        throw const SocketException('No internet connection');
      }

      if (httpResponse.statusCode != 200) {
        throw Exception(
          'HTTP ${httpResponse.statusCode}: ${httpResponse.body}',
        );
      }

      final response = json.decode(httpResponse.body) as Map<String, dynamic>;

      final accessToken = response['accessToken']?.toString() ?? '';
      if (accessToken.isNotEmpty) {
        await _handleSuccessfulVerification(context, response, signupProvider);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('OTP verification failed');
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
    authToken = response['accessToken']?.toString() ?? '';
    await saveAuthToken(
      authToken,
      tokenType: response['tokenType']?.toString() ?? 'Bearer',
    );

    final customerId = response['customerId']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      await secureStorage.write(key: 'user_id', value: customerId);
    }

    final firstName = response['firstName']?.toString().trim() ?? '';
    final lastName = response['lastName']?.toString().trim() ?? '';
    final mobileNumber = response['mobileNumber']?.toString() ?? phoneNumber;

    final isRegistered = firstName.isNotEmpty && lastName.isNotEmpty;

    if (isRegistered) {
      final userData = <String, dynamic>{
        'id': customerId,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': mobileNumber,
      };
      await _handleRegisteredUser(context, userData, customerId);
    } else {
      ShowToastDialog.closeLoader();
      signupProvider.authToken = authToken;
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

    if (!context.mounted) return;

    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast("Login successful".tr);
    Get.offAll(() => const DashBoardScreen());

    Future.microtask(() async {
      try {
        final navContext = Get.context;
        if (navContext == null) return;

        final homeProvider = Provider.of<HomeProvider>(
          navContext,
          listen: false,
        );
        await homeProvider.ensureLocationAndZoneChecked().timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('[LOGIN] Location/zone check timed out');
            return null;
          },
        );

        await _performBackgroundInitialization(navContext);
      } catch (e) {
        print('[LOGIN] Error during background location/zone check: $e');
      }
    });

    isVerifying = false;
    notifyListeners();
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
    if (_lastOtpRequestTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastOtpRequestTime!) < const Duration(seconds: 30)) {
        ShowToastDialog.showToast("Please wait before resending OTP".tr);
        return;
      }
    }

    final enteredPhone = phoneEditingController.value.text.trim();
    final fullPhoneNumber = phoneNumber.isNotEmpty ? phoneNumber : enteredPhone;

    if (fullPhoneNumber.isEmpty) {
      ShowToastDialog.showToast(
        "Phone number missing. Please go back and retry.".tr,
      );
      return;
    }

    if (fullPhoneNumber.length != 10) {
      ShowToastDialog.showToast("Phone number must be 10 digits".tr);
      return;
    }

    ShowToastDialog.showLoader("Resending OTP...".tr);
    try {
      final url = Uri.parse('${AppConst.outletBaseUrl}co/auth/resend-otp');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMzgzNTQ4LCJleHAiOjE3ODI0Njk5NDh9.Pm96Vs395-fbNIPWjYhX5AmqIjq-WHG-h4QU4IbrBdc",
      };
      final httpResponse = await SafeHttpClient.safePost(
        url,
        headers: headers,
        body: json.encode({'mobileNumber': fullPhoneNumber}),
        timeout: _authTimeout,
      );

      if (httpResponse == null) {
        throw const SocketException('No internet connection');
      }

      if (httpResponse.statusCode != 200) {
        throw Exception(
          'HTTP ${httpResponse.statusCode}: ${httpResponse.body}',
        );
      }

      final response = json.decode(httpResponse.body) as Map<String, dynamic>;

      if (response['success'] == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message']?.toString() ?? "OTP resent successfully".tr,
        );
        _lastOtpRequestTime = DateTime.now();
        startResendTimer();
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          response['message']?.toString() ?? "Failed to resend OTP".tr,
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
      clearAuthToken(),
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
    _resendCountdownTimer?.cancel();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    phoneEditingController.dispose();
    super.dispose();
  }
}
