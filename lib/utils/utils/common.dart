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
    // 'Authorization': 'Bearer $authToken',
    'Authorization':
        'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMTk0MDAxLCJleHAiOjE3ODIyODA0MDF9.0lRR6EYnZmqmctZVNysujYZNqR4ouPhLAFkov5papOw',
  };
}
