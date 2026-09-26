import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jippymart_customer/services/device_token_service.dart';
import 'package:jippymart_customer/services/global_deeplink_handler.dart';

/// Top-level background isolate handler.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so
/// it survives the secondary-isolate entry. Data-only messages that arrive
/// while the app is terminated are delivered here.
@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log('[FCM] Background message: ${message.messageId}');
}

/// Owns every push-notification concern in the app:
///
///   * runtime permission (Android 13+ / iOS),
///   * local notification plugin bootstrap,
///   * foreground / background / terminated message handling,
///   * notification tap routing,
///   * FCM token lifecycle (handed off to [DeviceTokenService]),
///   * the order-countdown notification.
///
/// Use [instance]; the default constructor is private so there is exactly one
/// set of listeners for the whole app.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _tag = '[FCM]';

  /// Channel used for every incoming push. Mirrored in AndroidManifest.xml as
  /// `com.google.firebase.messaging.default_notification_channel_id` so that
  /// messages sent without a `channel_id` still land on a known channel.
  static const String defaultChannelId = 'jippymart_default';
  static const String defaultChannelName = 'JippyMart Notifications';

  static const String orderTimerChannelId = 'order_timer_channel';

  /// Notification id reserved for the order countdown so it can be updated and
  /// cancelled without touching real pushes.
  static const int orderTimerNotificationId = 3001;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Absolute id of the navigator key, used to route taps when the app is
  /// already running but no BuildContext is at hand.
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalDeeplinkHandler.navigatorKey;

  bool _initialized = false;
  bool _drainInFlight = false;
  bool _backgroundHandlerRegistered = false;
  bool _tokenRefreshListenerAttached = false;
  bool _messageListenersAttached = false;
  int? _lastOrderTimerMinuteNotified;
  bool _hasShownOrderTimerNotification = false;

  /// The id used for the next foreground push. A fixed id would make every new
  /// push overwrite the previous one.
  int _foregroundNotificationId = 1000;

  /// Completes once the local notification plugin is usable. The order-timer
  /// notifications are driven by the dashboard, which can mount before
  /// [initInfo] has finished, and `show()` on an uninitialised plugin is a
  /// silent no-op.
  final Completer<void> _ready = Completer<void>();

  /// Boots the whole notification stack. Safe to call more than once.
  ///
  /// Called from `main()` after `Firebase.initializeApp`, and again when the
  /// user becomes known. The previous version of this class was only reachable
  /// through a provider that was never instantiated, which is why no push was
  /// ever received.
  Future<void> initInfo() async {
    if (_initialized) {
      log('$_tag already initialized');
      return;
    }
    _initialized = true;

    try {
      _registerBackgroundHandler();
      await _initLocalNotifications();
      final authorized = await _requestPermissions();
      _attachMessageListeners();
      _attachTokenRefreshListener();

      if (authorized) {
        await _subscribeToTopics();
      }

      // Push whatever we can already fetch; the backend token is filled in
      // once the customer id is known.
      await DeviceTokenService.instance.registerCurrentUser();

      log('$_tag initialization complete (authorized=$authorized)');
    } catch (e, st) {
      log('$_tag initialization failed: $e\n$st');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Waits (briefly) for the plugin to be initialised.
  Future<void> _awaitReady() async {
    if (_ready.isCompleted) return;
    try {
      await _ready.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      log('$_tag plugin not ready, showing notification anyway');
    }
  }

  void _registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);
      _backgroundHandlerRegistered = true;
    } catch (e) {
      log('$_tag background handler registration failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(
      // A monochrome drawable is required: a full-colour launcher icon renders
      // as a white square in the status bar.
      '@drawable/ic_launcher_monochrome',
    );
    const iosInit = DarwinInitializationSettings(
      // Do not prompt here; requestPermission() below owns the prompt so that
      // exactly one system dialog is shown.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          defaultChannelId,
          defaultChannelName,
          description: 'Order updates, offers and account alerts',
          importance: Importance.max,
        ),
      );
    } catch (e) {
      log('$_tag local notification init failed: $e');
    }
  }

  /// Asks for the OS-level permission. Returns true when notifications may be
  /// delivered to the tray.
  Future<bool> _requestPermissions() async {
    var authorized = false;

    try {
      if (Platform.isAndroid) {
        final android = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        // Required on Android 13 (API 33). Without it every push is dropped.
        await android?.requestNotificationsPermission();
        authorized = await android?.areNotificationsEnabled() ?? true;
      } else if (Platform.isIOS) {
        // firebase_messaging 16.x returns NotificationSettings.
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        final status = settings.authorizationStatus;
        authorized =
            status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional;
      } else {
        authorized = true;
      }
    } catch (e) {
      log('$_tag permission request failed: $e');
    }

    log('$_tag notifications authorized=$authorized');
    return authorized;
  }

  void _attachMessageListeners() {
    if (_messageListenersAttached) return;
    _messageListenersAttached = true;

    // Foreground: FCM does not render anything, so we show it ourselves.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background: the user tapped the tray notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('$_tag background tap: ${message.messageId}');
      _handleMessage(message);
    });

    // Cold start: the app was launched by tapping a notification.
    unawaited(_handleInitialMessage());
  }

  Future<void> _handleInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return;
      log('$_tag terminated-state message: ${message.messageId}');
      // Give the first frame time to attach before navigating.
      await Future.delayed(const Duration(milliseconds: 600));
      _handleMessage(message);
    } catch (e) {
      log('$_tag getInitialMessage failed: $e');
    }
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      log('$_tag onTokenRefresh');
      DeviceTokenService.instance.onTokenRefresh(token);
    });
  }

  Future<void> _subscribeToTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('customer');
      log('$_tag subscribed to topic "customer"');
    } catch (e) {
      log('$_tag topic subscribe failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    log('$_tag onMessage: ${message.messageId}');
    // The system tray entry is only rendered by FCM itself while the app is in
    // the background, so in the foreground we must draw it.
    display(message);
  }

  /// Renders a foreground message as a tray notification.
  ///
  /// Data-only messages (no `notification` block) are still shown, using the
  /// title/body carried in `data` when present.
  Future<void> display(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title =
        notification?.title ??
        (data['title'] ?? data['subject'] ?? 'JippyMart');
    final body =
        notification?.body ??
        (data['body'] ?? data['message'] ?? data['description'] ?? '');

    if (title.isEmpty && body.isEmpty) {
      log('$_tag nothing to display for ${message.messageId}');
      return;
    }

    // iOS suppresses the OS banner in foreground (see initInfo comments), so
    // this local notification is the only thing the user would see.
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        defaultChannelId,
        defaultChannelName,
        channelDescription: 'Order updates, offers and account alerts',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.event,
        ticker: 'JippyMart',
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        _nextNotificationId(message),
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      log('$_tag display failed: $e');
    }
  }

  /// Distinct id per message so pushes stack instead of replacing each other.
  int _nextNotificationId(RemoteMessage message) {
    final id = _foregroundNotificationId++;
    if (_foregroundNotificationId > 9000) _foregroundNotificationId = 1000;
    return id;
  }

  void _onNotificationTap(NotificationResponse response) {
    log('$_tag local notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _routeFromData(decoded);
      }
    } catch (e) {
      log('$_tag bad tap payload: $e');
    }
  }

  /// Routes a message (tapped or opened) to the right screen.
  void _handleMessage(RemoteMessage message) {
    final data = <String, dynamic>{...message.data};
    // FCM only fills these for notification payloads; copy them into `data` so
    // routing has a single source to read from.
    if (message.notification?.title != null) {
      data.putIfAbsent('title', () => message.notification!.title!);
    }
    if (message.notification?.body != null) {
      data.putIfAbsent('body', () => message.notification!.body!);
    }
    if (data.isEmpty) return;
    _routeFromData(data);
  }

  /// Translates a push payload into a deep link and hands it to the app-wide
  /// deep link handler.
  ///
  /// Backend may send either an explicit `deep_link`/`link` url, or discrete
  /// `type` + `id` fields.
  void _routeFromData(Map<String, dynamic> data) {
    final explicitLink = _firstString(data, const [
      'deep_link',
      'deepLink',
      'link',
      'url',
    ]);
    if (explicitLink != null && explicitLink.isNotEmpty) {
      _navigate(explicitLink);
      return;
    }

    final type = _firstString(data, const [
      'type',
      'notification_type',
      'event',
    ]);
    final id = _firstString(data, const [
      'id',
      'order_id',
      'product_id',
      'restaurant_id',
      'outlet_id',
    ]);
    if (type == null || type.isEmpty) return;

    switch (type.toLowerCase()) {
      case 'order_placed':
      case 'new_order':
      case 'order':
        // Order screens are not built yet; surface the ids for the log and
        // leave the user on the current screen.
        log('$_tag order notification id=$id');
        return;
      case 'chat':
      case 'chat_message':
        log('$_tag chat notification');
        return;
      default:
        if (id != null && id.isNotEmpty) {
          _navigate('jippymart://$type/$id');
        } else {
          log('$_tag unhandled notification type=$type');
        }
    }
  }

  String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  void _navigate(String link) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      GlobalDeeplinkHandler.instance.storeDeeplink(link, context);
      return;
    }
    // Cold start: the navigator is not mounted yet. Park the link and drain it
    // as soon as the first frame is up.
    GlobalDeeplinkHandler.instance.queueLink(link);
    _drainPendingLink();
  }

  /// Polls briefly for the navigator, then hands the parked link over.
  void _drainPendingLink() {
    if (_drainInFlight) return;
    _drainInFlight = true;
    _drainWhenReady();
  }

  Future<void> _drainWhenReady() async {
    try {
      for (var attempt = 0; attempt < 60; attempt++) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          await Future.delayed(const Duration(milliseconds: 400));
          GlobalDeeplinkHandler.instance.navigatePendingDeeplink(context);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      log('$_tag navigator never became ready, link left pending');
    } finally {
      _drainInFlight = false;
    }
  }

  /// The current FCM registration token, or null when unavailable.
  static Future<String?> getToken() => DeviceTokenService.fetchToken();

  /// Fetches and registers the token for [customerId] on the backend.
  Future<bool> registerTokenFor(String customerId) =>
      DeviceTokenService.instance.register(customerId: customerId, force: true);

  // ------------------------------------------------------------------
  // Order countdown notification
  // ------------------------------------------------------------------

  /// Creates or updates the live "order in progress" notification.
  Future<void> showOrUpdateOrderTimerNotification(Duration remaining) async {
    await _awaitReady();

    final totalSeconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    // Update once per minute so the iOS banner does not re-animate every second.
    if (_lastOrderTimerMinuteNotified == minutes) {
      return;
    }
    _lastOrderTimerMinuteNotified = minutes;

    final value =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    const androidDetails = AndroidNotificationDetails(
      orderTimerChannelId,
      'Order Timer',
      channelDescription: 'Shows active order countdown timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: !_hasShownOrderTimerNotification,
        presentBadge: false,
        presentSound: false,
      ),
    );

    try {
      await _localNotifications.show(
        orderTimerNotificationId,
        'Order in progress',
        'Time left: $value',
        details,
      );
      _hasShownOrderTimerNotification = true;
    } catch (e) {
      log('$_tag order timer notification failed: $e');
    }
  }

  Future<void> cancelOrderTimerNotification() async {
    _lastOrderTimerMinuteNotified = null;
    _hasShownOrderTimerNotification = false;
    await _awaitReady();
    try {
      await _localNotifications.cancel(orderTimerNotificationId);
    } catch (e) {
      log('$_tag cancel order timer failed: $e');
    }
  }
}
