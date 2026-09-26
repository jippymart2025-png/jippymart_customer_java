import UIKit
import Flutter
import GoogleMaps   // 👈 REQUIRED
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 👇 REQUIRED for Google Maps on iOS
    GMSServices.provideAPIKey("AIzaSyBRdk2BoUowc2FgvAwI0oDF_0fhbazoTQs")

    if FirebaseApp.app() == nil {
      // Uses GoogleService-Info.plist (BUNDLE_ID com.jippymart.customerapp).
      // main.dart also passes DefaultFirebaseOptions; both must describe the
      // same app or FCM token registration fails.
      FirebaseApp.configure()
    }

    UNUserNotificationCenter.current().delegate = self
    // The Dart layer owns the permission prompt, so registering here does not
    // show a second dialog.
    application.registerForRemoteNotifications()

    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    print("[FCM] APNs token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Surfaced in the Xcode log; a failing APNs registration means no FCM token.
    print("[FCM] APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // MARK: - MessagingDelegate

  /// APNs issued a new device token. FlutterFire forwards this to
  /// FirebaseMessaging.onTokenRefresh, which NotificationService listens to in
  /// order to re-publish the token to the backend.
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    print("[FCM] FCM token: \(fcmToken ?? "nil")")
  }

  /// A data-only message that arrived while the app was in the foreground or
  /// background. flutter_local_notifications/FlutterFire already renders
  /// notification payloads; the Dart onMessage handler takes it from here.
  func messaging(
    _ messaging: Messaging,
    didReceiveMessage message: RemoteMessage
  ) {
    print("[FCM] Foreground message: \(message.messageID ?? "no-id")")
  }
}
