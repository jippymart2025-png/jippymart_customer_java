import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

Map<String, String> get headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

Future<Map<String, String>> getHeaders() async {
  final authToken = await SqlStorageConst.getAuthToken();
  print("getHeaders  ${authToken}");
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $authToken',
  };
}
