import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/utils/app_constant.dart';
import '../../../utils/utils/common.dart';
import '../models/listofcommunity.dart';

class CommunityService {
  static const String _baseUrl =
      "http://srv1617582.hstgr.cloud:8084/api/driver";

  Future<List<CommunityZoneModel>> getCommunities(String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/getZonesByType?zoneType=COMMUNITY"),
      headers: {"accept": "*/*", "Authorization": token},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => CommunityZoneModel.fromJson(e)).toList();
    }

    throw Exception(response.body);
  }

  Future<bool> joinCommunity({
    required int customerId,
    required int communityId,
  }) async {
    final response = await http.post(
      Uri.parse(
        "${AppConst.outletBaseUrl}co/community-order/AddOrDropMembersFromCommunity",
      ),
      headers: await getHeaders(),
      body: jsonEncode({
        "customerId": customerId,
        "communityId": communityId,
        "type": "ADD",
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(response.body);
  }
}
