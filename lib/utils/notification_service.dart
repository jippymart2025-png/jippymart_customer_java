import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
}

class NotificationService {
  static bool _backgroundHandlerRegistered = false;
  static bool _tokenRefreshListenerAttached = false;
  static const int _orderTimerNotificationId = 3001;
  int? _lastOrderTimerMinuteNotified;
  bool _hasShownOrderTimerNotification = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initInfo() async {
    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);
      _backgroundHandlerRegistered = true;
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      // iOS duplicate fix: we show our own local notification in onMessage.
      // Keep system foreground alert off to avoid double notifications.
      alert: false,
      badge: true,
      sound: true,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    log("::::::::::::Notification permission::::::::::::::::: ${request.authorizationStatus}");

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (payload) {});
      await _logAppleAndFcmTokens();
      _attachTokenRefreshListener();
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("::::::::::::Initial message::::::::::::::::: ${initialMessage.messageId}");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
      }
    });
    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("customer");
  }

  static getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  Future<void> _logAppleAndFcmTokens() async {
    try {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      log("::::::::::::APNS TOKEN::::::::::::::::: ${apnsToken ?? 'NULL'}");
      log("::::::::::::FCM TOKEN::::::::::::::::: ${fcmToken ?? 'NULL'}");
    } catch (e) {
      log("::::::::::::TOKEN FETCH ERROR::::::::::::::::: $e");
    }
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      log("::::::::::::FCM TOKEN REFRESH::::::::::::::::: $token");
    });
    _tokenRefreshListenerAttached = true;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');
    try {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        '0',
        'goRide-customer',
        description: 'Show QuickLAI Notification',
        importance: Importance.max,
      );
      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(channel.id, channel.name,
              channelDescription: 'your channel Description',
              importance: Importance.high,
              priority: Priority.high,
              ticker: 'ticker');
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);
      await FlutterLocalNotificationsPlugin().show(
        0,
        message.notification!.title,
        message.notification!.body,
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> showOrUpdateOrderTimerNotification(Duration remaining) async {
    final totalSeconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    // Prevent iOS top-banner "jumping" by avoiding per-second notification updates.
    // We notify on first show and when minute value changes.
    if (_lastOrderTimerMinuteNotified == minutes) {
      return;
    }
    _lastOrderTimerMinuteNotified = minutes;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    final value = '$mm:$ss';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_timer_channel',
      'Order Timer',
      channelDescription: 'Shows active order countdown timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      // Show banner only once, then keep silent notification-center updates.
      presentAlert: !_hasShownOrderTimerNotification,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      _orderTimerNotificationId,
      'Order in progress',
      'Time left: $value',
      details,
    );
    _hasShownOrderTimerNotification = true;
  }

  Future<void> cancelOrderTimerNotification() async {
    _lastOrderTimerMinuteNotified = null;
    _hasShownOrderTimerNotification = false;
    await flutterLocalNotificationsPlugin.cancel(_orderTimerNotificationId);
  }
}
