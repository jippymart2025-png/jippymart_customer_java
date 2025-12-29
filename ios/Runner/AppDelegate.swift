import UIKit
import Flutter
import GoogleMaps   // 👈 REQUIRED

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 👇 REQUIRED for Google Maps on iOS
    GMSServices.provideAPIKey("AIzaSyBRdk2BoUowc2FgvAwI0oDF_0fhbazoTQs")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
