import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/utils/app_constant.dart';
import '../../../utils/utils/common.dart';

Future<bool> saveCustomerDeliveryAddress({
  required int customerId,
  required double latitude,
  required double longitude,
  required String doorNo,
  required String buildingName,
  required String laneNo,
  // required int area,
  // required int city,
  required int createdBy,
}) async {
  try {
    final uri = Uri.parse(
      '${AppConst.outletBaseUrl}co/customers/saveCustomerDeliveryAddress',
    );

    final response = await http.post(
      uri,
      headers: {...await getHeaders()},
      body: jsonEncode({
        "customerId": customerId,
        "latitude": latitude,
        "longitude": longitude,
        "doorNo": doorNo,
        "buildingName": buildingName,
        "laneNo": laneNo,
        // "area": area,
        // "city": city,
        "createdBy": createdBy,
      }),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Save Address Error: $e");
    return false;
  }
}
