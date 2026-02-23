// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/firebase_options.dart';
import 'package:jippymart_customer/models/notification_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  /// Fallback URL for FCM service account JSON when settings API does not provide one.
  static const String _fallbackServiceJsonUrl =
      'https://firebasestorage.googleapis.com/v0/b/jippymart-27c08.firebasestorage.app/o/jippymart-27c08-7191b6fdcd74_1752328782480.json?alt=media&token=9fd11e87-6cf7-4f40-8942-9d67492a8bc1';

  static Future<String> getAccessToken() async {
    Map<String, dynamic> jsonData = {};

    // Prefer URL; fallback to cached JSON string from settings API
    final url = Constant.jsonNotificationFileURL.trim();
    if (url.isNotEmpty) {
      try {
        if (kDebugMode) {
          dev.log('Fetching service JSON from URL', name: 'SendNotification');
        }
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            jsonData = decoded;
          } else if (kDebugMode) {
            dev.log('Service JSON URL did not return a JSON object', name: 'SendNotification');
          }
        } else if (kDebugMode) {
          dev.log('Service JSON URL returned ${response.statusCode}', name: 'SendNotification');
        }
      } catch (e) {
        if (kDebugMode) {
          dev.log('Failed to fetch service JSON from URL: $e', name: 'SendNotification');
        }
      }
    }
    if (jsonData.isEmpty) {
      final cached = Preferences.getString(Preferences.fcmServiceAccountJson);
      if (cached.isNotEmpty) {
        try {
          jsonData = json.decode(cached) as Map<String, dynamic>;
        } catch (e) {
          if (kDebugMode) {
            dev.log('Invalid cached service JSON: $e', name: 'SendNotification');
          }
        }
      }
    }
    if (jsonData.isEmpty) {
      throw StateError(
        'No FCM service account: set notification_setting.serviceJson (URL) or serviceAccountJson (inline JSON) in settings API',
      );
    }
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      jsonData,
    );
    final client = await clientViaServiceAccount(
      serviceAccountCredentials,
      _scopes,
    );
    return client.credentials.accessToken.data;
  }

  /// Load senderId and service JSON URL from cache if not set (e.g. when sending from cart before getSettings ran).
  /// If still empty, uses app's Firebase projectId from firebase_options so FCM can send.
  static void _ensureNotificationSettingsFromCache() {
    if (Constant.senderId.isEmpty) {
      final cached = Preferences.getString(Preferences.fcmSenderId);
      if (cached.isNotEmpty) {
        Constant.senderId = cached;
        return;
      }
      // Fallback: use app's Firebase project ID so notifications work before getSettings runs or when API omits notification_setting
      try {
        final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
        if (projectId.isNotEmpty) {
          Constant.senderId = projectId;
        }
      } catch (_) {
        // Use cached or leave empty; no need to log in production
      }
    }
    if (Constant.jsonNotificationFileURL.isEmpty) {
      final cached = Preferences.getString(Preferences.fcmServiceJsonUrl);
      if (cached.isNotEmpty) {
        Constant.jsonNotificationFileURL = cached;
      } else {
        Constant.jsonNotificationFileURL = _fallbackServiceJsonUrl;
      }
    }
  }

  /// True if we have either a service JSON URL or cached inline JSON to get FCM token.
  static bool _hasServiceAccountSource() {
    if (Constant.jsonNotificationFileURL.trim().isNotEmpty) return true;
    if (Preferences.getString(Preferences.fcmServiceAccountJson).trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<bool> sendFcmMessage(
    String type,
    String token,
    Map<String, dynamic>? payload,
  ) async {
    try {
      _ensureNotificationSettingsFromCache();
      if (Constant.senderId.isEmpty) {
        if (kDebugMode) dev.log('Send failed: senderId empty', name: 'SendNotification');
        return false;
      }
      final trimmedToken = token.trim();
      if (trimmedToken.isEmpty) {
        if (kDebugMode) dev.log('Send failed: recipient token empty', name: 'SendNotification');
        return false;
      }
      if (!_hasServiceAccountSource()) {
        if (kDebugMode) dev.log('Send failed: no service account source', name: 'SendNotification');
        return false;
      }
      String accessToken;
      try {
        accessToken = await getAccessToken();
      } catch (e) {
        if (kDebugMode) dev.log('Send failed: getAccessToken: $e', name: 'SendNotification');
        return false;
      }
      NotificationModel? notificationModel;
      try {
        notificationModel = await FireStoreUtils.getNotificationContent(type);
      } catch (_) {
        // Use defaults below
      }
      final title = notificationModel?.subject ?? 'New order';
      final body = notificationModel?.message ?? 'You have a new order';
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': trimmedToken,
            'notification': {
              'body': body,
              'title': title,
            },
            'android': {
              'priority': 'high',
              'notification': {
                // No channel_id: uses app default channel so notification shows even if vendor app has no "order_channel"
                'default_sound': true,
                'default_vibrate_timings': true,
                'default_light_settings': true,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'data': payload?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ?? {},
          },
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw StateError('FCM request timed out'),
      );
      final ok = response.statusCode == 200;
      if (!ok && kDebugMode) {
        // 404/UNREGISTERED = vendor token stale (e.g. restaurant app reinstalled). Fix: restaurant app must re-upload FCM token. See RESTAURANT_APP_FCM_TOKEN_FIX.md.
        final isUnregistered = response.statusCode == 404 || response.body.contains('UNREGISTERED');
        dev.log(
          'FCM rejected: ${response.statusCode}${isUnregistered ? " (token stale/unregistered)" : ""}',
          name: 'SendNotification',
        );
      }
      return ok;
    } catch (e, stack) {
      if (kDebugMode) {
        dev.log('Send failed: $e', name: 'SendNotification');
        dev.log(stack.toString(), name: 'SendNotification');
      }
      return false;
    }
  }

  static Future<bool> sendOneNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      _ensureNotificationSettingsFromCache();
      if (Constant.senderId.isEmpty || token.trim().isEmpty) return false;
      final String accessToken = await getAccessToken();
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token.trim(),
            'notification': {'body': body, 'title': title},
            'data': payload.map((k, v) => MapEntry(k, v?.toString() ?? '')),
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendChatFcmMessage(
    String title,
    String message,
    String token,
    Map<String, dynamic>? payload,
  ) async {
    try {
      _ensureNotificationSettingsFromCache();
      if (Constant.senderId.isEmpty || token.trim().isEmpty) return false;
      final String accessToken = await getAccessToken();
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token.trim(),
            'notification': {'body': message, 'title': title},
            'data': payload?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ?? {},
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
