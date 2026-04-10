import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/utils/preferences.dart';

/// Facebook App Events Service
///
/// Provides a wrapper around Facebook App Events SDK for tracking user events
class FacebookAppEventsService {
  static final FacebookAppEventsService _instance =
      FacebookAppEventsService._internal();

  factory FacebookAppEventsService() => _instance;

  FacebookAppEventsService._internal();

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  bool _isInitialized = false;
  DateTime? _lastAppOpenTrackedAt;

  static const String _installTrackedKey = 'fb_install_event_tracked';

  /// Initialize Facebook App Events SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('📱 [FB EVENTS] Already initialized');
      }
      return;
    }

    try {
      // Facebook App Events SDK initializes automatically
      // No explicit initialization needed for version 0.19.2
      _isInitialized = true;
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      await _facebookAppEvents.setAdvertiserTracking(enabled: true, collectId: true);

      if (kDebugMode) {
        final appId = await _facebookAppEvents.getApplicationId();
        print('🔧 [FB EVENTS] SDK app id: $appId');
      }

      // Track first-open once per install and one app-open on init.
      await logInstallOnce();
      await logAppOpen();

      if (kDebugMode) {
        print('✅ [FB EVENTS] Facebook App Events initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error initializing Facebook App Events: $e');
      }
      // Don't rethrow - allow app to continue even if FB events fail
    }
  }

  /// Track app-open safely (throttled to avoid duplicate spam).
  Future<void> logAppOpen() async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    if (_lastAppOpenTrackedAt != null &&
        now.difference(_lastAppOpenTrackedAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastAppOpenTrackedAt = now;

    try {
      await _facebookAppEvents.logEvent(name: 'fb_mobile_activate_app');
      await _facebookAppEvents.flush();

      if (kDebugMode) {
        print('🔥 [FB EVENTS] fb_mobile_activate_app fired');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FB activate_app error: $e');
      }
    }
  }

  /// Track first-open once after install.
  Future<void> logInstallOnce() async {
    if (!_isInitialized) return;

    final alreadyTracked = Preferences.getString(_installTrackedKey) == 'true';

    if (alreadyTracked) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'first_open',
        parameters: <String, dynamic>{
          'source': 'app_launch',
          'ts': DateTime.now().toIso8601String(),
        },
      );
      await _facebookAppEvents.flush();

      if (kDebugMode) {
        print('🔥 [FB EVENTS] first_open tracked');
      }

      await Preferences.setString(_installTrackedKey, 'true');
    } catch (e) {
      if (kDebugMode) {
        print('❌ FB install error: $e');
      }
    }
  }

  /// Log a custom event
  ///
  /// [eventName] - Name of the event
  /// [parameters] - Optional parameters to attach to the event
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters ?? {},
      );

      if (kDebugMode) {
        print('📊 [FB EVENTS] Logged event: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging event $eventName: $e');
      }
    }
  }

  /// Log a purchase event
  ///
  /// [amount] - Purchase amount
  /// [currency] - Currency code (e.g., 'USD', 'INR')
  /// [parameters] - Optional parameters
  Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters ?? {},
      );

      if (kDebugMode) {
        print('💰 [FB EVENTS] Logged purchase: $amount $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging purchase: $e');
      }
    }
  }

  /// Log an add to cart event
  ///
  /// [amount] - Item amount
  /// [currency] - Currency code
  /// [contentId] - Content/product ID
  /// [contentType] - Content type (e.g., 'product')
  Future<void> logAddToCart({
    required double amount,
    required String currency,
    String? contentId,
    String? contentType,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      final parameters = <String, dynamic>{'fb_currency': currency};
      if (contentId != null) {
        parameters['fb_content_id'] = contentId;
      }
      if (contentType != null) {
        parameters['fb_content_type'] = contentType;
      }

      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_add_to_cart',
        valueToSum: amount,
        parameters: parameters,
      );

      if (kDebugMode) {
        print('🛒 [FB EVENTS] Logged add to cart: $amount $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging add to cart: $e');
      }
    }
  }

  /// Log a view content event
  ///
  /// [contentId] - Content/product ID
  /// [contentType] - Content type
  /// [currency] - Currency code
  /// [value] - Value of the content
  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    String? currency,
    double? value,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      final parameters = <String, dynamic>{
        'fb_content_id': contentId,
        'fb_content_type': contentType,
      };

      if (currency != null) {
        parameters['fb_currency'] = currency;
      }
      if (value != null) {
        parameters['fb_value'] = value;
      }

      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_content_view',
        valueToSum: value,
        parameters: parameters,
      );

      if (kDebugMode) {
        print('👁️ [FB EVENTS] Logged view content: $contentId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging view content: $e');
      }
    }
  }

  /// Log a search event
  ///
  /// [searchString] - Search query string
  /// [contentType] - Content type being searched
  Future<void> logSearch({
    required String searchString,
    String? contentType,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      final parameters = <String, dynamic>{'fb_search_string': searchString};

      if (contentType != null) {
        parameters['fb_content_type'] = contentType;
      }

      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: parameters,
      );

      if (kDebugMode) {
        print('🔍 [FB EVENTS] Logged search: $searchString');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging search: $e');
      }
    }
  }

  /// Log an initiate checkout event
  ///
  /// [amount] - Checkout amount
  /// [currency] - Currency code
  /// [numItems] - Number of items in checkout
  Future<void> logInitiateCheckout({
    required double amount,
    required String currency,
    int? numItems,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      final parameters = <String, dynamic>{'fb_currency': currency};

      if (numItems != null) {
        parameters['fb_num_items'] = numItems;
      }

      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_initiated_checkout',
        valueToSum: amount,
        parameters: parameters,
      );

      if (kDebugMode) {
        print('🛍️ [FB EVENTS] Logged initiate checkout: $amount $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error logging initiate checkout: $e');
      }
    }
  }

  /// Flush pending events to Facebook
  Future<void> flush() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          '⚠️ [FB EVENTS] Service not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      await _facebookAppEvents.flush();

      if (kDebugMode) {
        print('📤 [FB EVENTS] Flushed pending events');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB EVENTS] Error flushing events: $e');
      }
    }
  }
}
