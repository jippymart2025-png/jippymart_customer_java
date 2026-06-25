import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../../utils/utils/app_constant.dart';
import '../../../utils/utils/common.dart';

Future<int?> saveCustomerDeliveryAddress({
  required int customerId,
  required double latitude,
  required double longitude,
  required String doorNo,
  required String buildingName,
  required String laneNo,
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
        'customerId': customerId,
        'latitude': latitude,
        'longitude': longitude,
        'doorNo': doorNo,
        'buildingName': buildingName,
        'laneNo': laneNo,
        'createdBy': createdBy,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final id = data['deliveryAddressId'] ?? data['id'];
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  } catch (e) {
    print('Save Address Error: $e');
    return null;
  }
}
