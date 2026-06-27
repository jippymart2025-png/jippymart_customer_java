import 'dart:io';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/services/app_update_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

class MyProfileProvider extends ChangeNotifier {
  // ========== Optimized State Management ==========
  // Using ValueNotifier pattern for better performance
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);
  late LoginProvider loginProvider;

  // Cached states to avoid repeated async calls
  bool _isUserLoggedIn = false;

  bool get isUserLoggedIn => _isUserLoggedIn;

  // Version info cache
  String? _cachedVersionText;

  String get versionText => _cachedVersionText ?? "V : ${Constant.appVersion}";
  bool _isVersionLoaded = false;

  // User data cache timing
  DateTime? _lastUserDataFetch;
  static const Duration _userDataCacheExpiry = Duration(minutes: 10);

  // Theme state (pure Dart, no GetX dependency for these)
  String _isDarkMode = "Light";

  String get isDarkMode => _isDarkMode;

  bool _isDarkModeSwitch = false;

  bool get isDarkModeSwitch => _isDarkModeSwitch;

  set isDarkModeSwitch(bool value) {
    _isDarkModeSwitch = value;
    notifyListeners();
  }

  void initFunction({required BuildContext context}) {
    loginProvider = Provider.of<LoginProvider>(context, listen: false);
    _initializeAsync();
  }

  /// Batch initialization for better performance
  Future<void> _initializeAsync() async {
    // Run independent operations in parallel
    await Future.wait([
      _loadLoginState(),
      _loadTheme(),
      _loadVersionInfo(),
      loadUserData(),
    ]);
  }

  /// Cache login state to avoid repeated async calls
  Future<void> _loadLoginState() async {
    try {
      _isUserLoggedIn = await SqlStorageConst.isUserLoggedIn();
    } catch (e) {
      _isUserLoggedIn = Constant.userModel != null;
      if (kDebugMode) {
        log('[PROFILE] Error checking login state: $e');
      }
    }
  }

  /// Load theme preferences
  Future<void> _loadTheme() async {
    _isDarkMode = Preferences.getString(Preferences.themKey);
    if (_isDarkMode == "Dark") {
      _isDarkModeSwitch = true;
    } else {
      _isDarkModeSwitch = false;
    }
  }

  /// Kept for backward compatibility
  void getThem() {
    _isDarkMode = Preferences.getString(Preferences.themKey);
    if (_isDarkMode == "Dark") {
      _isDarkModeSwitch = true;
    } else if (_isDarkMode == "Light") {
      _isDarkModeSwitch = false;
    } else {
      _isDarkModeSwitch = false;
    }
  }

  /// Load and cache version info (avoids repeated API calls)
  Future<void> _loadVersionInfo() async {
    if (_isVersionLoaded && _cachedVersionText != null) return;

    try {
      final versionInfo = await AppUpdateService.getLatestVersionInfo();
      if (versionInfo != null) {
        if (Platform.isAndroid) {
          final androidVersion = versionInfo['android_version'] ?? '';
          if (androidVersion.isNotEmpty) {
            _cachedVersionText = "V : $androidVersion";
          }
        } else if (Platform.isIOS) {
          final iosVersion = versionInfo['ios_version'] ?? '';
          if (iosVersion.isNotEmpty) {
            _cachedVersionText = "V : $iosVersion";
          }
        }
      }
      _cachedVersionText ??= "V : ${Constant.appVersion}";
      _isVersionLoaded = true;
    } catch (e) {
      _cachedVersionText = "V : ${Constant.appVersion}";
      _isVersionLoaded = true;
      if (kDebugMode) {
        log('[PROFILE] Error loading version info: $e');
      }
    }
  }

  Future<void> deleteUserAccount({required BuildContext context}) async {
    try {
      ShowToastDialog.showLoader("Please wait".tr);
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Starting to delete user account');
      }
      isLoading.value = true;
      notifyListeners();
      final userId = await SqlStorageConst.getFirebaseId();
      if (kDebugMode) {
        log('[PROFILE_SCREEN] User ID for deletion: $userId');
      }
      final bool isDeleted = await _makeDeleteAccountCall(userId.toString());
      if (isDeleted) {
        loginProvider.logout(context);
        if (kDebugMode) {
          log('[PROFILE_SCREEN] Account deleted successfully');
        }
        // Navigate to login screen or show success message
      } else {
        if (kDebugMode) {
          log('[PROFILE_SCREEN] Failed to delete account');
        }
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Error deleting account: $e');
      }
      rethrow; // Or handle the error as needed
    } finally {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      notifyListeners();
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Delete account process completed');
      }
    }
  }

  Future<bool> _makeDeleteAccountCall(String userId) async {
    try {
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Making DELETE API call for user: $userId');
      }
      final response = await http.delete(
        Uri.parse('${AppConst.outletBaseUrl}co/customers/$userId'),
        headers: await getHeaders(),
      );
      if (kDebugMode) {
        log(
          '[PROFILE_SCREEN] Delete API response status: ${response.statusCode}',
        );
        log('[PROFILE_SCREEN] Delete API response body: ${response.body}');
      }
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          log('[PROFILE_SCREEN] Account deletion API call successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          log(
            '[PROFILE_SCREEN] Account deletion API call failed with status: ${response.statusCode}',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Error in delete API call: $e');
      }
      return false;
    }
  }

  /// Load user data with caching to reduce API calls
  Future<void> loadUserData({bool forceRefresh = false}) async {
    try {
      // Check if cache is still valid (skip API call if data is fresh)
      if (!forceRefresh &&
          Constant.userModel != null &&
          _lastUserDataFetch != null &&
          DateTime.now().difference(_lastUserDataFetch!) <
              _userDataCacheExpiry) {
        if (kDebugMode) {
          log('[PROFILE_SCREEN] Using cached user data');
        }
        isLoading.value = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        log('[PROFILE_SCREEN] Starting to load user data');
      }
      if (Constant.userModel == null) {
        if (kDebugMode) {
          log(
            '[PROFILE_SCREEN] Constant.userModel is null, fetching from server',
          );
        }
        final userId = await SqlStorageConst.getFirebaseId();
        final userModel = await AddressListProvider.getUserProfile(
          userId.toString(),
        );
        if (kDebugMode) {
          log(
            '[PROFILE_SCREEN] getUserProfile result: ${userModel != null ? "SUCCESS" : "NULL"}',
          );
        }
        if (userModel != null) {
          Constant.userModel = userModel;
          _lastUserDataFetch = DateTime.now();
          _isUserLoggedIn = true;
          notifyListeners();
          if (kDebugMode) {
            log('[PROFILE_SCREEN] Set Constant.userModel successfully');
          }
        } else {
          if (kDebugMode) {
            log('[PROFILE_SCREEN] Failed to load user model');
          }
        }
      } else {
        // Update cache timestamp even if using existing data
        _lastUserDataFetch = DateTime.now();
        _isUserLoggedIn = true;
        if (kDebugMode) {
          log('[PROFILE_SCREEN] Constant.userModel already exists');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Error loading user data: $e');
      }
    } finally {
      isLoading.value = false;
      notifyListeners();
      if (kDebugMode) {
        log('[PROFILE_SCREEN] Loading completed, isLoading set to false');
      }
    }
  }

  /// Refresh user data (force fetch from server)
  Future<void> refreshUserData() async {
    await loadUserData(forceRefresh: true);
  }

  /// Clear cache when user logs out
  void clearCache() {
    _lastUserDataFetch = null;
    _isUserLoggedIn = false;
    _cachedVersionText = null;
    _isVersionLoaded = false;
    notifyListeners();
  }

  Future<bool> deleteUserFromServer() async {
    var url = '${Constant.websiteUrl}/api/delete-user';
    final userId = await SqlStorageConst.getFirebaseId();
    try {
      var response = await http.post(Uri.parse(url), body: {'uuid': userId});
      if (kDebugMode) {
        log("deleteUserFromServer :: ${response.body}");
      }
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }
}
