import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const languageCodeKey = "languageCodeKey";
  static const isFinishOnBoardingKey = "isFinishOnBoardingKey";
  static const foodDeliveryType = "foodDeliveryType";
  static const tokenKey = "tokenKey";

  // Location preferences for tax calculation
  static const selectedLocationLat = "selectedLocationLat";
  static const selectedLocationLng = "selectedLocationLng";
  static const selectedLocationAddress = "selectedLocationAddress";
  static const selectedLocationAddressAs = "selectedLocationAddressAs";
  
  // Zone ID storage
  static const selectedZoneId = "selectedZoneId";

  static const themKey = "themKey";

  static const payFastSettings = "payFastSettings";
  static const mercadoPago = "MercadoPago";
  static const paypalSettings = "paypalSettings";
  static const stripeSettings = "stripeSettings";
  static const flutterWave = "flutterWave";
  static const payStack = "payStack";
  static const paytmSettings = "PaytmSettings";
  static const walletSettings = "walletSettings";
  static const razorpaySettings = "razorpaySettings";
  static const codSettings = "CODSettings";
  static const midTransSettings = "midTransSettings";
  static const orangeMoneySettings = "orangeMoneySettings";
  static const xenditSettings = "xenditSettings";
  
  // Wallet & coin runtime config cache
  static const walletConfigJson = "walletConfigJson";
  static const walletConfigLastUpdatedMillis = "walletConfigLastUpdatedMillis";
  
  // Google Maps API Key stored locally as fallback
  static const googleMapsApiKey = "googleMapsApiKey";

  // FCM notification settings (senderId / projectId and service JSON URL or inline JSON)
  static const fcmSenderId = "fcmSenderId";
  static const fcmServiceJsonUrl = "fcmServiceJsonUrl";
  /// Cached service account JSON string (when API returns it inline instead of URL)
  static const fcmServiceAccountJson = "fcmServiceAccountJson";

  static late SharedPreferences pref;

  static initPref() async {
    pref = await SharedPreferences.getInstance();
  }

  static bool getBoolean(String key) {
    return pref.getBool(key) ?? false;
  }

  static String getString(String key, {String? defaultValue}) {
    return pref.getString(key) ?? defaultValue ?? "";
  }

  static Future<void> setString(String key, String value) async {
    await pref.setString(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return pref.getInt(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    await pref.setInt(key, value);
  }

  static Future<void> clearSharPreference() async {
    await pref.clear();
  }
}
