import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/models/user_model.dart';

class SqlStorageConst {
  static UserModel userModel = UserModel();

  static Future<bool> isUserLoggedIn() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'api_token');
    return token != null;
  }

  static Future<String?> getAuthToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'api_token');
  }

  static Future<String?> getFirebaseId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'firebase_id');
  }

  /// Backend user id (e.g. user_26c52283-...) used by firestore/orders API.
  static Future<String?> getUserId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'user_id');
  }

  static Future<String?> getUserName() async {
    final storage = FlutterSecureStorage();

    final firstName = await storage.read(key: 'user_firstName');
    final lastName = await storage.read(key: 'user_lastName');

    if (firstName == null && lastName == null) return null;

    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }

  // Store user data locally
  static Future<void> storeUserData(
    UserModel user, {
    String? countryCode,
  }) async {
    print(" storeUserData ${user.firebaseId}");
    final storage = FlutterSecureStorage();
    await storage.write(key: 'user_id', value: user.id);
    await storage.write(key: 'firebase_id', value: user.firebaseId);
    await storage.write(key: 'user_firstName', value: user.firstName);
    await storage.write(key: 'user_lastName', value: user.lastName);
    await storage.write(key: 'user_email', value: user.email);
    await storage.write(key: 'user_phone', value: user.phoneNumber);
    await storage.write(key: 'user_countryCode', value: countryCode);
    await storage.write(key: 'user_countryCode', value: countryCode);
    print(" storeUserData ${user.firebaseId}");
  }
}
