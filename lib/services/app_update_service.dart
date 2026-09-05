import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'dart:io';

class AppUpdateService {
  /// Check if a version is older than another version
  static bool isVersionOlder(String current, String latest) {
    try {
      debugPrint('[UPDATE DEBUG] Comparing versions:');
      debugPrint('[UPDATE DEBUG]   Current: "$current"');
      debugPrint('[UPDATE DEBUG]   Latest: "$latest"');

      List<int> currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      List<int> latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      debugPrint('[UPDATE DEBUG]   Current parts: $currentParts');
      debugPrint('[UPDATE DEBUG]   Latest parts: $latestParts');

      // Pad with zeros if needed
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      debugPrint(
        '[UPDATE DEBUG]   After padding - Current: $currentParts, Latest: $latestParts',
      );

      for (int i = 0; i < latestParts.length; i++) {
        debugPrint(
          '[UPDATE DEBUG]   Comparing part $i: ${currentParts[i]} vs ${latestParts[i]}',
        );
        if (i >= currentParts.length || currentParts[i] < latestParts[i]) {
          debugPrint(
            '[UPDATE DEBUG]   Result: Current is OLDER (returning true)',
          );
          return true;
        }
        if (currentParts[i] > latestParts[i]) {
          debugPrint(
            '[UPDATE DEBUG]   Result: Current is NEWER (returning false)',
          );
          return false;
        }
      }
      debugPrint(
        '[UPDATE DEBUG]   Result: Versions are EQUAL (returning false)',
      );
      return false;
    } catch (e) {
      debugPrint('[UPDATE] Version comparison error: $e');
      return false;
    }
  }

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      debugPrint('[UPDATE DEBUG] Current app version: "$version"');
      return version;
    } catch (e) {
      debugPrint('[UPDATE] Error getting current version: $e');
      return '1.0.0';
    }
  }

  /// Get current app build number
  static Future<String> getCurrentBuildNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String buildNumber = packageInfo.buildNumber;
      debugPrint('[UPDATE DEBUG] Current app build number: "$buildNumber"');
      return buildNumber;
    } catch (e) {
      debugPrint('[UPDATE] Error getting current build number: $e');
      return '1';
    }
  }

  /// Get platform-specific version info
  static String getPlatformVersion(Map<String, dynamic> versionInfo) {
    String platformVersion = '';
    if (Platform.isAndroid) {
      platformVersion =
          versionInfo['android_version'] ?? versionInfo['latest_version'] ?? '';
      debugPrint('[UPDATE DEBUG] Platform: Android');
      debugPrint(
        '[UPDATE DEBUG]   android_version from Firestore: "${versionInfo['android_version']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   latest_version from Firestore: "${versionInfo['latest_version']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   Selected platform version: "$platformVersion"',
      );
    } else if (Platform.isIOS) {
      platformVersion =
          versionInfo['ios_version'] ?? versionInfo['latest_version'] ?? '';
      debugPrint('[UPDATE DEBUG] Platform: iOS');
      debugPrint(
        '[UPDATE DEBUG]   ios_version from Firestore: "${versionInfo['ios_version']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   latest_version from Firestore: "${versionInfo['latest_version']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   Selected platform version: "$platformVersion"',
      );
    } else {
      platformVersion = versionInfo['latest_version'] ?? '';
      debugPrint('[UPDATE DEBUG] Platform: Unknown');
      debugPrint(
        '[UPDATE DEBUG]   latest_version from Firestore: "${versionInfo['latest_version']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   Selected platform version: "$platformVersion"',
      );
    }
    return platformVersion;
  }

  /// Get platform-specific build number
  static String getPlatformBuildNumber(Map<String, dynamic> versionInfo) {
    String platformBuild = '';
    if (Platform.isAndroid) {
      platformBuild = versionInfo['android_build'] ?? '';
      debugPrint(
        '[UPDATE DEBUG]   android_build from Firestore: "${versionInfo['android_build']}"',
      );
    } else if (Platform.isIOS) {
      platformBuild = versionInfo['ios_build'] ?? '';
      debugPrint(
        '[UPDATE DEBUG]   ios_build from Firestore: "${versionInfo['ios_build']}"',
      );
    }
    debugPrint('[UPDATE DEBUG]   Selected platform build: "$platformBuild"');
    return platformBuild;
  }

  /// Get platform-specific update URL
  static String getPlatformUpdateUrl(Map<String, dynamic> versionInfo) {
    String platformUrl = '';
    if (Platform.isAndroid) {
      // Check if googlePlayLink is a valid URL (not a placeholder)
      String androidUrl =
          versionInfo['googlePlayLink'] ??
          versionInfo['android_update_url'] ??
          '';
      if (androidUrl.isNotEmpty &&
          androidUrl != "update_url" &&
          androidUrl.startsWith('http')) {
        platformUrl = androidUrl;
        debugPrint('[UPDATE DEBUG]   Using googlePlayLink: "$androidUrl"');
      } else {
        platformUrl =
            versionInfo['update_url'] ??
            "https://play.google.com/store/apps/details?id=com.jippymart.customer";
        debugPrint(
          '[UPDATE DEBUG]   googlePlayLink is placeholder, using update_url: "$platformUrl"',
        );
      }
      debugPrint(
        '[UPDATE DEBUG]   googlePlayLink from Firestore: "${versionInfo['googlePlayLink']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   update_url from Firestore: "${versionInfo['update_url']}"',
      );
    } else if (Platform.isIOS) {
      // Check if appStoreLink is a valid URL (not a placeholder)
      String iosUrl =
          versionInfo['appStoreLink'] ?? versionInfo['ios_update_url'] ?? '';
      if (iosUrl.isNotEmpty &&
          iosUrl != "update_url" &&
          iosUrl.startsWith('http')) {
        platformUrl = iosUrl;
        debugPrint('[UPDATE DEBUG]   Using appStoreLink: "$iosUrl"');
      } else {
        platformUrl =
            versionInfo['update_url'] ??
            "https://apps.apple.com/app/jippy-mart/id123456789";
        debugPrint(
          '[UPDATE DEBUG]   appStoreLink is placeholder, using update_url: "$platformUrl"',
        );
      }
      debugPrint(
        '[UPDATE DEBUG]   appStoreLink from Firestore: "${versionInfo['appStoreLink']}"',
      );
      debugPrint(
        '[UPDATE DEBUG]   update_url from Firestore: "${versionInfo['update_url']}"',
      );
    } else {
      platformUrl =
          versionInfo['update_url'] ??
          "https://play.google.com/store/apps/details?id=com.jippymart.customer";
      debugPrint(
        '[UPDATE DEBUG]   update_url from Firestore: "${versionInfo['update_url']}"',
      );
    }
    debugPrint('[UPDATE DEBUG]   Selected platform URL: "$platformUrl"');
    return platformUrl;
  }

  static Future<Map<String, dynamic>?> getLatestVersionInfo() async {
    try {
      debugPrint('[UPDATE DEBUG] Fetching version info from API...');
      debugPrint(
        '[UPDATE DEBUG] Endpoint: ${AppConst.baseUrl}fm/app-settings/getApplicationVersionByAppType?appType=customer',
      );

      final response = await SafeHttpClient.safeGet(
        Uri.parse(
          '${AppConst.baseUrl}fm/app-settings/getApplicationVersionByAppType?appType=customer',
        ),
        headers: await getHeaders(),
        timeout: const Duration(seconds: 10),
      );

      if (response == null) {
        // Network error - return null gracefully
        debugPrint('[UPDATE] Network error - unable to fetch version info');
        return null;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // The app-settings endpoint returns the settings object directly.
        // Also support a { success: true, data: {...} } envelope.
        dynamic data = responseData['data'] ?? responseData;
        if (data is! Map) {
          debugPrint(
            '[UPDATE DEBUG] API response did not contain a version object',
          );
          return null;
        }
        final Map<String, dynamic> versionData = Map<String, dynamic>.from(
          data,
        );
        debugPrint('[UPDATE DEBUG] API response successful!');
        debugPrint('[UPDATE DEBUG] Version data:');
        versionData.forEach((key, value) {
          debugPrint('[UPDATE DEBUG]   $key: "$value" (${value.runtimeType})');
        });
        return versionData;
      } else {
        debugPrint(
          '[UPDATE DEBUG] API request failed with status: ${response.statusCode}',
        );
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('[UPDATE] Network error: $e');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('[UPDATE] Timeout error: $e');
      return null;
    } catch (e) {
      debugPrint('[UPDATE] Error fetching version info: $e');
      return null;
    }
  }

  /// Show update dialog
  static void showUpdateDialog({
    required String latestVersion,
    required bool forceUpdate,
    required String updateUrl,
    String? currentVersion,
    String? updateMessage,
  }) {
    debugPrint('[UPDATE DEBUG] Showing update dialog:');
    debugPrint('[UPDATE DEBUG]   Latest version: "$latestVersion"');
    debugPrint('[UPDATE DEBUG]   Force update: $forceUpdate');
    debugPrint('[UPDATE DEBUG]   Update URL: "$updateUrl"');
    debugPrint('[UPDATE DEBUG]   Current version: "$currentVersion"');
    debugPrint('[UPDATE DEBUG]   Update message: "$updateMessage"');

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update_alt, color: Colors.blue, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Update Available",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          content: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updateMessage ??
                          "A new version of Jippy Mart is available!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (currentVersion != null) ...[
                      Text(
                        "Current Version: $currentVersion",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        "Latest Version: $latestVersion",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 12),
                    ],
                    if (forceUpdate)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "This update is required to continue using the app",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  "assets/images/ic_logo.png",
                  width: 76,
                  height: 76,
                ),
              ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () async {
                  debugPrint('[UPDATE DEBUG] User clicked "Later"');
                  Get.back();
                  // Navigate to main app after dismissing dialog
                  await _navigateAfterUpdate();
                },
                child: Text(
                  "Later",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                debugPrint('[UPDATE DEBUG] User clicked "Update Now"');
                try {
                  final uri = Uri.parse(updateUrl);
                  debugPrint(
                    '[UPDATE DEBUG] Attempting to launch URL: $updateUrl',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    debugPrint('[UPDATE DEBUG] Successfully launched URL');
                  } else {
                    debugPrint(
                      '[UPDATE DEBUG] Could not launch URL, trying fallback',
                    );
                    // Fallback to Play Store
                    final playStoreUrl =
                        "https://play.google.com/store/apps/details?id=com.jippymart.customer";
                    final fallbackUri = Uri.parse(playStoreUrl);
                    if (await canLaunchUrl(fallbackUri)) {
                      await launchUrl(
                        fallbackUri,
                        mode: LaunchMode.externalApplication,
                      );
                      debugPrint(
                        '[UPDATE DEBUG] Successfully launched fallback URL',
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('[UPDATE] Error launching URL: $e');
                  // Show error message
                  Get.snackbar(
                    "Error",
                    "Could not open app store. Please update manually.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Update Now",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: !forceUpdate,
    );
  }

  /// Check for app updates
  static Future<bool> checkForUpdate() async {
    try {
      debugPrint('[UPDATE DEBUG] ==========================================');
      debugPrint('[UPDATE DEBUG] STARTING UPDATE CHECK');
      debugPrint('[UPDATE DEBUG] ==========================================');

      // Get current version
      String currentVersion = await getCurrentVersion();
      String currentBuild = await getCurrentBuildNumber();
      debugPrint(
        '[UPDATE DEBUG] Current version: $currentVersion (build: $currentBuild)',
      );
      // Get latest version info from Firestore
      Map<String, dynamic>? versionInfo = await getLatestVersionInfo();
      if (versionInfo == null) {
        debugPrint(
          '[UPDATE DEBUG] No version info found in Firestore - EXITING',
        );
        return false;
      }
      // Get platform-specific version info
      String latestVersion = getPlatformVersion(versionInfo);
      String latestBuild = getPlatformBuildNumber(versionInfo);
      bool forceUpdate = versionInfo['force_update'] ?? false;
      String updateUrl = getPlatformUpdateUrl(versionInfo);
      String updateMessage = versionInfo['update_message'] ?? '';

      debugPrint('[UPDATE DEBUG] ==========================================');
      debugPrint('[UPDATE DEBUG] VERSION COMPARISON SUMMARY');
      debugPrint('[UPDATE DEBUG] ==========================================');
      debugPrint('[UPDATE DEBUG] Current version: "$currentVersion"');
      debugPrint('[UPDATE DEBUG] Latest version: "$latestVersion"');
      debugPrint('[UPDATE DEBUG] Current build: "$currentBuild"');
      debugPrint('[UPDATE DEBUG] Latest build: "$latestBuild"');
      debugPrint('[UPDATE DEBUG] Force update: $forceUpdate');
      debugPrint('[UPDATE DEBUG] Update URL: "$updateUrl"');
      debugPrint('[UPDATE DEBUG] Update message: "$updateMessage"');

      // Check if latest version is empty or invalid
      if (latestVersion.isEmpty) {
        debugPrint('[UPDATE DEBUG] Latest version is empty - EXITING');
        return false;
      }

      // Check if latest version is a placeholder
      if (latestVersion == "latest_version" ||
          latestVersion == "Android build number" ||
          latestVersion == "iOS build number" ||
          latestVersion == "update_url") {
        debugPrint(
          '[UPDATE DEBUG] Latest version is a placeholder string - EXITING',
        );
        debugPrint(
          '[UPDATE DEBUG] This means your Firestore document has placeholder values instead of real version numbers',
        );
        return false;
      }

      bool isUpdateAvailable = isVersionOlder(currentVersion, latestVersion);
      debugPrint('[UPDATE DEBUG] Is update available? $isUpdateAvailable');

      if (isUpdateAvailable) {
        debugPrint('[UPDATE DEBUG] Update available! Showing dialog...');
        showUpdateDialog(
          latestVersion: latestVersion,
          forceUpdate: forceUpdate,
          updateUrl: updateUrl,
          currentVersion: currentVersion,
          updateMessage: updateMessage,
        );
        debugPrint('[UPDATE DEBUG] ==========================================');
        debugPrint('[UPDATE DEBUG] UPDATE CHECK COMPLETED - UPDATE REQUIRED');
        debugPrint('[UPDATE DEBUG] ==========================================');
        return true; // Update is required
      } else {
        debugPrint('[UPDATE DEBUG] App is up to date - no dialog shown');
        debugPrint('[UPDATE DEBUG] ==========================================');
        debugPrint(
          '[UPDATE DEBUG] UPDATE CHECK COMPLETED - NO UPDATE REQUIRED',
        );
        debugPrint('[UPDATE DEBUG] ==========================================');
        return false; // No update required
      }
    } catch (e) {
      debugPrint('[UPDATE] Error checking for updates: $e');
      return false; // Allow navigation on error
    }
  }

  /// Navigate to main app after update dialog is dismissed
  static Future<void> _navigateAfterUpdate() async {
    debugPrint(
      '[UPDATE DEBUG] Navigating to main app after update dialog dismissed',
    );
    // Check if user is logged in and navigate accordingly
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    final apiToken = await secureStorage.read(key: 'api_token');
    final firebaseUser = await SqlStorageConst.getFirebaseId();

    if (apiToken != null && apiToken.isNotEmpty && firebaseUser != null) {
      Get.offAll(
        () => const DashBoardScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 1200),
      );
    } else {
      Get.offAll(
        () => PhoneNumberScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 1200),
      );
    }
  }

  /// Check if app meets minimum required version
  static Future<bool> checkMinimumVersion() async {
    try {
      debugPrint('[UPDATE DEBUG] Checking minimum required version...');
      String currentVersion = await getCurrentVersion();
      Map<String, dynamic>? versionInfo = await getLatestVersionInfo();

      if (versionInfo == null) {
        debugPrint('[UPDATE DEBUG] No version info found - allowing access');
        return true; // Allow if no version info
      }

      String minRequiredVersion = versionInfo['min_required_version'] ?? '';
      debugPrint(
        '[UPDATE DEBUG] Minimum required version: "$minRequiredVersion"',
      );

      if (minRequiredVersion.isNotEmpty &&
          isVersionOlder(currentVersion, minRequiredVersion)) {
        debugPrint(
          '[UPDATE DEBUG] App version below minimum required version - BLOCKING ACCESS',
        );
        return false;
      }

      debugPrint(
        '[UPDATE DEBUG] App version meets minimum requirement - ALLOWING ACCESS',
      );
      return true;
    } catch (e) {
      debugPrint('[UPDATE] Error checking minimum version: $e');
      return true; // Allow if error
    }
  }
}
