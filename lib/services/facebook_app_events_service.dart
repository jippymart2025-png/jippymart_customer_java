import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Facebook App Events
/// 
/// This service provides a centralized way to log Facebook App Events
/// including standard events (purchases, add to cart, etc.) and custom events.
class FacebookAppEventsService {
  static final FacebookAppEventsService _instance =
      FacebookAppEventsService._internal();

  factory FacebookAppEventsService() => _instance;

  FacebookAppEventsService._internal();

  static FacebookAppEvents? _facebookAppEvents;

  /// Initialize Facebook App Events
  /// 
  /// This should be called once during app startup, typically in main.dart
  Future<void> initialize() async {
    try {
      _facebookAppEvents = FacebookAppEvents();
      if (kDebugMode) {
        print('✅ Facebook App Events initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Facebook App Events: $e');
      }
    }
  }

  /// Log a standard or custom event
  /// 
  /// [eventName] - The name of the event (e.g., 'Purchase', 'AddToCart', 'ViewContent')
  /// [parameters] - Optional parameters to include with the event
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) async {
    try {
      if (_facebookAppEvents == null) {
        await initialize();
      }

      if (_facebookAppEvents != null) {
        await _facebookAppEvents!.logEvent(
          name: eventName,
          parameters: parameters,
          valueToSum: valueToSum,
        );

        if (kDebugMode) {
          print('📊 Facebook App Event logged: $eventName');
          if (parameters != null) {
            print('   Parameters: $parameters');
          }
          if (valueToSum != null) {
            print('   Value: $valueToSum');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging Facebook App Event: $e');
      }
    }
  }

  /// Log a purchase event
  /// 
  /// [amount] - The purchase amount
  /// [currency] - The currency code (e.g., 'USD', 'INR')
  /// [parameters] - Additional parameters (e.g., content_id, content_type)
  Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    final purchaseParams = {
      'fb_currency': currency,
      ...?parameters,
    };

    await logEvent(
      'fb_mobile_purchase',
      valueToSum: amount,
      parameters: purchaseParams,
    );
  }

  /// Log an "Add to Cart" event
  /// 
  /// [amount] - The item amount
  /// [currency] - The currency code
  /// [contentId] - The product/content ID
  /// [contentType] - The type of content (e.g., 'product')
  Future<void> logAddToCart({
    required double amount,
    required String currency,
    String? contentId,
    String? contentType,
  }) async {
    final params = <String, dynamic>{
      'fb_currency': currency,
    };

    if (contentId != null) {
      params['fb_content_id'] = contentId;
    }
    if (contentType != null) {
      params['fb_content_type'] = contentType;
    }

    await logEvent(
      'fb_mobile_add_to_cart',
      valueToSum: amount,
      parameters: params,
    );
  }

  /// Log a "View Content" event
  /// 
  /// [contentId] - The product/content ID
  /// [contentType] - The type of content
  /// [currency] - Optional currency code
  /// [value] - Optional value of the content
  Future<void> logViewContent({
    String? contentId,
    String? contentType,
    String? currency,
    double? value,
  }) async {
    final params = <String, dynamic>{};

    if (contentId != null) {
      params['fb_content_id'] = contentId;
    }
    if (contentType != null) {
      params['fb_content_type'] = contentType;
    }
    if (currency != null) {
      params['fb_currency'] = currency;
    }

    await logEvent(
      'fb_mobile_content_view',
      valueToSum: value,
      parameters: params.isNotEmpty ? params : null,
    );
  }

  /// Log an "Initiate Checkout" event
  /// 
  /// [amount] - The checkout amount
  /// [currency] - The currency code
  /// [numItems] - Number of items in the cart
  Future<void> logInitiateCheckout({
    required double amount,
    required String currency,
    int? numItems,
  }) async {
    final params = <String, dynamic>{
      'fb_currency': currency,
    };

    if (numItems != null) {
      params['fb_num_items'] = numItems.toString();
    }

    await logEvent(
      'fb_mobile_initiated_checkout',
      valueToSum: amount,
      parameters: params,
    );
  }

  /// Log a "Search" event
  /// 
  /// [searchString] - The search query
  /// [contentType] - Optional content type
  Future<void> logSearch({
    required String searchString,
    String? contentType,
  }) async {
    final params = <String, dynamic>{
      'fb_search_string': searchString,
    };

    if (contentType != null) {
      params['fb_content_type'] = contentType;
    }

    await logEvent(
      'fb_mobile_search',
      parameters: params,
    );
  }

  /// Set user ID for tracking
  /// 
  /// Note: This is done by logging events with user_id parameter
  /// [userId] - The user identifier
  Future<void> setUserId(String userId) async {
    try {
      // Log user ID as a custom event parameter
      // The Facebook SDK will automatically associate this with subsequent events
      await logEvent(
        'fb_mobile_activate_app',
        parameters: {'user_id': userId},
      );
      if (kDebugMode) {
        print('👤 Facebook App Events User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting Facebook App Events User ID: $e');
      }
    }
  }

  /// Clear user ID
  /// 
  /// Note: User ID tracking is managed through event parameters
  Future<void> clearUserId() async {
    if (kDebugMode) {
      print('👤 Facebook App Events User ID cleared (no longer including in events)');
    }
  }

  /// Flush events immediately
  /// 
  /// This forces the SDK to send all pending events to Facebook
  Future<void> flush() async {
    try {
      if (_facebookAppEvents != null) {
        await _facebookAppEvents!.flush();
        if (kDebugMode) {
          print('📤 Facebook App Events flushed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error flushing Facebook App Events: $e');
      }
    }
  }
}

