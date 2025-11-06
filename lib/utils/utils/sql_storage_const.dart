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

  static Future<String?> getUserId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'user_id');
  }
}
