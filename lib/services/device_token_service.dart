import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart'
    show SqlStorageConst;

/// Owns the lifecycle of the FCM device token.
///
/// Push delivery only works if the backend holds a token that matches the
/// currently installed build, so the token is pushed:
///   * after Firebase init (launch),
///   * on every [FirebaseMessaging.onTokenRefresh],
///   * after login/signup,
///   * after a profile update.
///
/// The previous implementation only registered on OTP login and posted to a
/// hardcoded LAN address, so the backend kept a stale or missing token and no
/// notification was ever delivered.
class DeviceTokenService {
  DeviceTokenService._();

  static final DeviceTokenService instance = DeviceTokenService._();

  static const String _tag = '[FCM_TOKEN]';

  /// Guards against overlapping registrations and pointless re-posts.
  static const String _prefKey = 'fcm_last_registered_token';
  static const Duration _retryDelay = Duration(seconds: 30);

  Timer? _retryTimer;
  bool _isRegistering = false;
  String? _token;
  String? _pendingCustomerId;
  bool _pendingForce = false;

  /// The last token that the backend acknowledged.
  String? get token => _token;

  /// Fetches the current FCM registration token from Firebase.
  ///
  /// On iOS this returns null until APNs has handed the device token to
  /// Firebase, so a null here is retried rather than treated as a failure.
  static Future<String?> fetchToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        log('$_tag getToken() returned empty');
        return null;
      }
      return token;
    } catch (e) {
      log('$_tag getToken() failed: $e');
      return null;
    }
  }

  /// Registers [customerId]'s device token with the backend.
  ///
  /// Safe to call repeatedly: the network call is skipped when the token has
  /// not changed since the last successful registration.
  Future<bool> register({String? customerId, bool force = false}) async {
    // The guard is taken before the first await so two concurrent callers
    // (launch + login, or login + token refresh) cannot both post.
    if (_isRegistering) {
      log('$_tag registration already in progress, queueing');
      _pendingCustomerId = customerId;
      _pendingForce = force;
      return false;
    }
    _isRegistering = true;

    try {
      final id = int.tryParse(customerId ?? '');
      if (id == null) {
        log('$_tag no valid customerId, cannot register token');
        return false;
      }

      final fcmToken = await fetchToken();
      if (fcmToken == null) {
        log('$_tag token unavailable, will retry');
        _scheduleRetry(customerId: customerId, force: force);
        return false;
      }

      if (!force && fcmToken == _token && await _wasRegistered(fcmToken)) {
        log('$_tag token unchanged and already registered, skipping');
        return true;
      }

      final success = await _postToken(customerId: id, fcmToken: fcmToken);

      if (success) {
        _token = fcmToken;
        await _rememberRegistered(fcmToken);
        _retryTimer?.cancel();
        _retryTimer = null;
        log('$_tag registered for customer $id');
      } else {
        _scheduleRetry(customerId: customerId, force: force);
      }
      return success;
    } finally {
      _isRegistering = false;
      _drainPendingRegistration();
    }
  }

  /// Runs a registration that arrived while one was in flight, so a token is
  /// never left unregistered because of a lost race.
  void _drainPendingRegistration() {
    final queuedId = _pendingCustomerId;
    if (queuedId == null) return;
    final queuedForce = _pendingForce;
    _pendingCustomerId = null;
    _pendingForce = false;
    unawaited(register(customerId: queuedId, force: queuedForce));
  }

  /// Registers the signed-in customer using the locally stored id.
  Future<bool> registerCurrentUser({bool force = false}) async {
    final id = _lastKnownCustomerId ?? await _storedCustomerId();
    if (id == null) {
      log('$_tag no customer id available yet, deferring registration');
      return false;
    }
    return register(customerId: id, force: force);
  }

  String? _lastKnownCustomerId;

  /// Remembers the active customer so launch-time registration can work
  /// without waiting for the next login.
  void setActiveCustomer(String? customerId) {
    if (customerId == null || customerId.isEmpty) return;
    if (_lastKnownCustomerId == customerId) return;
    _lastKnownCustomerId = customerId;
    unawaited(register(customerId: customerId, force: true));
  }

  /// Called from [FirebaseMessaging.onTokenRefresh] and from iOS when APNs
  /// hands over a new device token.
  Future<void> onTokenRefresh(String newToken) async {
    log('$_tag token refreshed');
    if (newToken.isEmpty) return;
    _token = newToken;
    await _forgetRegistered();
    await register(
      customerId: _lastKnownCustomerId ?? await _storedCustomerId(),
      force: true,
    );
  }

  /// Clears local state on logout and tells the backend to stop pushing to
  /// this device.
  Future<void> unregister() async {
    final id = int.tryParse(_lastKnownCustomerId ?? '');
    if (id != null) {
      try {
        await SafeHttpClient.safePost(
          Uri.parse('${AppConst.baseUrl}notification/device-token/delete'),
          headers: await getHeaders(),
          body: json.encode({
            'userId': id,
            'userType': Constant.userRoleCustomer.toUpperCase(),
            'deviceType': _deviceType,
          }),
          timeout: const Duration(seconds: 15),
        );
      } catch (e) {
        log('$_tag unregister failed: $e');
      }
    }
    _token = null;
    _lastKnownCustomerId = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _forgetRegistered();
  }

  Future<bool> _postToken({
    required int customerId,
    required String fcmToken,
  }) async {
    try {
      final url = Uri.parse(
        'http://192.168.0.14:8084/api/notification/device-token',
      );
      final response = await SafeHttpClient.safePost(
        url,
        headers: await getHeaders(),
        body: json.encode({
          'userId': customerId,
          'userType': Constant.userRoleCustomer.toUpperCase(),
          'deviceType': _deviceType,
          'fcmToken': fcmToken,
        }),
        timeout: const Duration(seconds: 15),
      );

      if (response == null) {
        log('$_tag no response (offline)');
        return false;
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('$_tag HTTP ${response.statusCode}: ${response.body}');
        return false;
      }

      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          log('$_tag backend rejected: ${response.body}');
          return false;
        }
      } catch (_) {
        // Non-JSON success responses are fine.
      }

      return true;
    } catch (e) {
      log('$_tag error sending token: $e');
      return false;
    }
  }

  void _scheduleRetry({String? customerId, bool force = false}) {
    if (customerId == null || customerId.isEmpty) return;
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(_retryDelay, () {
      _retryTimer = null;
      unawaited(register(customerId: customerId, force: force));
    });
  }

  Future<String?> _storedCustomerId() async {
    try {
      return await SqlStorageConst.getUserId();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _wasRegistered(String token) async {
    try {
      return await _storage?.read(_prefKey) == token;
    } catch (_) {
      return false;
    }
  }

  Future<void> _rememberRegistered(String token) async {
    try {
      await _storage?.write(_prefKey, token);
    } catch (_) {
      // Non-fatal: worst case the token is re-posted on the next launch.
    }
  }

  Future<void> _forgetRegistered() async {
    try {
      await _storage?.remove(_prefKey);
    } catch (_) {
      // Non-fatal.
    }
  }

  String get _deviceType =>
      Platform.isIOS ? 'IOS' : (Platform.isAndroid ? 'ANDROID' : 'WEB');

  GetStorage? _storage;
}
