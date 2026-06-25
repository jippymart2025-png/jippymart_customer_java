import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

Future<List<ShippingAddress>> getCustomerDeliveryAddresses({
  required int customerId,
}) async {
  try {
    final uri = Uri.parse(
      '${AppConst.outletBaseUrl}co/customers/getCustomerDeliveryAddresses',
    ).replace(queryParameters: {'customerId': customerId.toString()});

    final response = await http
        .get(uri, headers: {...await getHeaders()})
        .timeout(const Duration(seconds: 15));

    print('[GetAddresses] status: ${response.statusCode}');
    print('[GetAddresses] body: ${response.body}');

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      list = decoded['data'] as List;
    } else {
      return [];
    }

    final addresses = <ShippingAddress>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) continue;
      addresses.add(
        _mapDeliveryAddress(
          Map<String, dynamic>.from(item),
          isDefault: i == 0,
        ),
      );
    }
    return addresses;
  } catch (e) {
    print('[GetAddresses] error: $e');
    return [];
  }
}

ShippingAddress _mapDeliveryAddress(
  Map<String, dynamic> json, {
  bool isDefault = false,
}) {
  final lat = _toDouble(json['latitude']);
  final lng = _toDouble(json['longitude']);
  final laneNo = json['laneNo']?.toString() ?? '';

  return ShippingAddress(
    id: json['customerAddressId']?.toString(),
    address: json['doorNo']?.toString(),
    locality: json['buildingName']?.toString(),
    landmark: laneNo == 'NA' || laneNo.isEmpty ? null : laneNo,
    addressAs: 'Home',
    isDefault: isDefault,
    latitude: lat,
    longitude: lng,
    location: lat != null && lng != null
        ? UserLocation(latitude: lat, longitude: lng)
        : null,
  );
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
