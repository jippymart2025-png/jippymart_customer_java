import 'dart:developer';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/production_logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class AppLifecycleLogger extends WidgetsBindingObserver {
  static final AppLifecycleLogger _instance = AppLifecycleLogger._internal();

  factory AppLifecycleLogger() => _instance;

  AppLifecycleLogger._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  DateTime? _lastResumeTime;
  DateTime? _lastPauseTime;
  int _appOpenCount = 0;
  bool _isInitialized = false;

  /// **INITIALIZE LIFECYCLE LOGGER**
  static Future<void> initialize() async {
    if (_instance._isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(_instance);
      _instance._isInitialized = true;
      // Log initial state
      await _instance._logAppState(
        'INITIALIZED',
        'App lifecycle logger started',
      );

      log('[LIFECYCLE_LOGGER] Initialized successfully');
    } catch (e) {
      log('[LIFECYCLE_LOGGER] Initialization failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _handleLifecycleChange(state);
  }

  /// **HANDLE LIFECYCLE STATE CHANGES**
  Future<void> _handleLifecycleChange(AppLifecycleState state) async {
    try {
      final timestamp = DateTime.now();
      final stateName = state.toString().split('.').last.toUpperCase();

      switch (state) {
        case AppLifecycleState.resumed:
          _appOpenCount++;
          _lastResumeTime = timestamp;
          await _logAppState(stateName, 'App resumed (count: $_appOpenCount)');
          await _checkAuthenticationState('RESUMED');
          break;

        case AppLifecycleState.paused:
          _lastPauseTime = timestamp;
          await _logAppState(stateName, 'App paused');
          await _saveAppState();
          break;

        case AppLifecycleState.inactive:
          await _logAppState(stateName, 'App inactive');
          break;

        case AppLifecycleState.detached:
          await _logAppState(stateName, 'App detached');
          await _saveAppState();
          break;

        case AppLifecycleState.hidden:
          await _logAppState(stateName, 'App hidden');
          break;
      }

      // Send to Firebase Crashlytics
      FirebaseCrashlytics.instance.log('AppLifecycleState: $stateName');
    } catch (e) {
      log('[LIFECYCLE_LOGGER] Error handling lifecycle change: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  /// **LOG AUTHENTICATION STATE CHANGES**

  /// **LOG USER PROFILE LOADED - Updates auth state with complete profile data**

  /// **CHECK AUTHENTICATION STATE ON RESUME**
  Future<void> _checkAuthenticationState(String trigger) async {
    try {
      final user = await SqlStorageConst.getFirebaseId();

      final apiToken = await _secureStorage.read(key: 'api_token');
      final isOtpVerified = Preferences.getBoolean('isOtpVerified');

      final authStatus = {
        'firebase_user': user,
        'api_token_exists': apiToken != null && apiToken.isNotEmpty,
        'otp_verified': isOtpVerified,
        'trigger': trigger,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _logAppState(
        'AUTH_CHECK',
        'Authentication status: ${authStatus.toString()}',
      );

      // Check for potential logout conditions
      if (user == null && apiToken != null && apiToken.isNotEmpty) {
        await _logAppState(
          'POTENTIAL_LOGOUT',
          'Firebase user null but API token exists',
        );
        FirebaseCrashlytics.instance.log(
          'Potential logout detected: Firebase user null but API token exists',
        );
      }

      if (user != null && (apiToken == null || apiToken.isEmpty)) {
        await _logAppState(
          'POTENTIAL_LOGOUT',
          'Firebase user exists but no API token',
        );
        FirebaseCrashlytics.instance.log(
          'Potential logout detected: Firebase user exists but no API token',
        );
      }
    } catch (e) {
      log('[LIFECYCLE_LOGGER] Error checking auth state: $e');
    }
  }

  /// **SAVE APP STATE**
  Future<void> _saveAppState() async {
    try {
      final appState = {
        'last_resume_time': _lastResumeTime?.toIso8601String(),
        'last_pause_time': _lastPauseTime?.toIso8601String(),
        'app_open_count': _appOpenCount,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await Preferences.setString('app_lifecycle_state', appState.toString());
      await _logAppState(
        'STATE_SAVED',
        'App state saved: ${appState.toString()}',
      );
    } catch (e) {
      log('[LIFECYCLE_LOGGER] Error saving app state: $e');
    }
  }

  /// **LOG APP STATE WITH MULTIPLE OUTPUTS**
  Future<void> _logAppState(String state, String message) async {
    try {
      final logMessage = '[$state] $message';

      // Console logging
      log(logMessage);

      // Production logger
      ProductionLogger.info('LIFECYCLE', logMessage);

      // Firebase Crashlytics
      FirebaseCrashlytics.instance.log(logMessage);
    } catch (e) {
      log('[LIFECYCLE_LOGGER] Error logging app state: $e');
    }
  }

  /// **DISPOSE LOGGER**
  static void dispose() {
    WidgetsBinding.instance.removeObserver(_instance);
    _instance._isInitialized = false;
    log('[LIFECYCLE_LOGGER] Disposed');
  }
}
