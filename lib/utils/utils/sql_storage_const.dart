import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class SqlStorageConst {
  static UserModel userModel = UserModel();

  static Future<bool> isUserLoggedIn() async {
    final token = await readSecureStorage('api_token');
    return token != null;
  }

  static Future<String?> getAuthToken() async {
    return await readSecureStorage('api_token');
  }

  static Future<String?> getFirebaseId() async {
    return await readSecureStorage('firebase_id');
  }

  /// Backend user id (e.g. user_26c52283-...) used by firestore/orders API.
  static Future<String?> getUserId() async {
    return await readSecureStorage('user_id');
  }

  static Future<String?> getUserName() async {
    final firstName = await readSecureStorage('user_firstName');
    final lastName = await readSecureStorage('user_lastName');

    if (firstName == null && lastName == null) return null;

    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }

  // Store user data locally
  static Future<void> storeUserData(
    UserModel user, {
    String? countryCode,
  }) async {
    // Read existing values so required fields (firstName/email/phoneNumber)
    // are never clobbered with empty/null data.
    final existingId = await readSecureStorage('user_id');
    final existingFirstName = await readSecureStorage('user_firstName');
    final existingLastName = await readSecureStorage('user_lastName');
    final existingEmail = await readSecureStorage('user_email');
    final existingPhone = await readSecureStorage('user_phone');
    final existingCountryCode = await readSecureStorage('user_countryCode');
    final existingProfilePic = await readSecureStorage('user_profilePicUrl');

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

    await writeSecureStorage('user_id', storedId);
    await writeSecureStorage('firebase_id', user.firebaseId);
    await writeSecureStorage('user_firstName', storedFirstName);
    await writeSecureStorage('user_lastName', storedLastName);
    await writeSecureStorage('user_email', storedEmail);
    await writeSecureStorage('user_phone', storedPhone);
    await writeSecureStorage(
      'user_countryCode',
      countryCode ?? user.countryCode ?? existingCountryCode,
    );
    await writeSecureStorage('user_profilePicUrl', storedProfilePic);
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
      final id = await readSecureStorage('user_id');
      final firebaseId = await readSecureStorage('firebase_id');
      final firstName = await readSecureStorage('user_firstName');
      final lastName = await readSecureStorage('user_lastName');
      final email = await readSecureStorage('user_email');
      final phone = await readSecureStorage('user_phone');
      final countryCode = await readSecureStorage('user_countryCode');
      final profilePic = await readSecureStorage('user_profilePicUrl');

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