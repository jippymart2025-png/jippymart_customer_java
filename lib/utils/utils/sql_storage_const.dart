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
    final storage = FlutterSecureStorage();

    // Read existing values so required fields (firstName/email/phoneNumber)
    // are never clobbered with empty/null data.
    final existingId = await storage.read(key: 'user_id');
    final existingFirstName = await storage.read(key: 'user_firstName');
    final existingLastName = await storage.read(key: 'user_lastName');
    final existingEmail = await storage.read(key: 'user_email');
    final existingPhone = await storage.read(key: 'user_phone');
    final existingCountryCode = await storage.read(key: 'user_countryCode');
    final existingProfilePic = await storage.read(key: 'user_profilePicUrl');

    final storedId = user.id ?? existingId;
    final storedFirstName = _valueOr(user.firstName, existingFirstName);
    final storedLastName = _valueOr(user.lastName, existingLastName);
    final storedEmail = _valueOr(user.email, existingEmail);
    final storedPhone = _valueOr(user.phoneNumber, existingPhone);
    final storedProfilePic =
        _valueOr(user.profilePictureURL, existingProfilePic);

    if (storedId == null && user.id == null && storedFirstName == null) {
      return;
    }

    await storage.write(key: 'user_id', value: storedId);
    await storage.write(key: 'firebase_id', value: user.firebaseId);
    await storage.write(key: 'user_firstName', value: storedFirstName);
    await storage.write(key: 'user_lastName', value: storedLastName);
    await storage.write(key: 'user_email', value: storedEmail);
    await storage.write(key: 'user_phone', value: storedPhone);
    await storage.write(
      key: 'user_countryCode',
      value: countryCode ?? user.countryCode ?? existingCountryCode,
    );
    await storage.write(key: 'user_profilePicUrl', value: storedProfilePic);
  }

  static String? _valueOr(String? value, String? fallback) {
    final v = value?.trim();
    if (v != null && v.isNotEmpty) return v;
    return fallback;
  }

  /// Rehydrates the logged-in user's profile from locally saved data
  /// (id, name, email, phone, etc.) without making a network call.
  static Future<UserModel?> getUserModelFromCache() async {
    try {
      final storage = FlutterSecureStorage();
      final id = await storage.read(key: 'user_id');
      final firebaseId = await storage.read(key: 'firebase_id');
      final firstName = await storage.read(key: 'user_firstName');
      final lastName = await storage.read(key: 'user_lastName');
      final email = await storage.read(key: 'user_email');
      final phone = await storage.read(key: 'user_phone');
      final countryCode = await storage.read(key: 'user_countryCode');
      final profilePic = await storage.read(key: 'user_profilePicUrl');

      if ((id == null || id.isEmpty) &&
          (firebaseId == null || firebaseId.isEmpty) &&
          (firstName == null || firstName.isEmpty)) {
        return null;
      }

      return UserModel(
        id: id,
        firebaseId: firebaseId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phone,
        countryCode: countryCode,
        profilePictureURL: profilePic,
        role: 'customer',
        active: true,
      );
    } catch (e) {
      return null;
    }
  }
}
