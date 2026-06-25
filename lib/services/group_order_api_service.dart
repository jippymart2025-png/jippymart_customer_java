import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/group_order_invitation_model.dart';
import 'package:jippymart_customer/models/group_order_join_response.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class GroupOrderApiService {
  GroupOrderApiService._();

  static Future<GroupOrderInvitationModel?> createGroupOrderInvitation({
    required int hostCustomerId,
    required int outletId,
    required int orderCloseDurationInMinutes,
    required String paymentResponsibility,
    required int maxMembers,
    required int createdBy,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/group-orders/createGroupOrderInvitation',
      );

      final body = {
        'hostCustomerId': hostCustomerId,
        'outletId': outletId,
        'orderCloseDurationInMinutes': orderCloseDurationInMinutes,
        'paymentResponsibility': paymentResponsibility,
        'maxMembers': maxMembers,
        'createdBy': createdBy,
      };

      print('[GroupOrderApi] POST $uri');
      print('[GroupOrderApi] body: $body');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      print('[GroupOrderApi] status: ${response.statusCode}');
      print('[GroupOrderApi] response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final data = decoded.containsKey('data') && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded;

      return GroupOrderInvitationModel.fromJson(data);
    } catch (e) {
      print('[GroupOrderApi] createGroupOrderInvitation error: $e');
      return null;
    }
  }

  static Future<GroupOrderJoinResponse?> joinGroupMembers({
    required int groupOrdersInvitationId,
    required int customerId,
    required int deliveryAddressId,
    required String invitationCode,
    required int createdBy,
    bool isDropped = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/group-orders/joinGroupMembers',
      );

      final body = {
        'groupOrdersInvitationId': groupOrdersInvitationId,
        'customerId': customerId,
        'deliveryAddressId': deliveryAddressId,
        'isDropped': isDropped,
        'invitationCode': invitationCode,
        'createdBy': createdBy,
      };

      print('[GroupOrderApi] POST $uri');
      print('[GroupOrderApi] body: $body');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      print('[GroupOrderApi] status: ${response.statusCode}');
      print('[GroupOrderApi] response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      return GroupOrderJoinResponse.fromJson(decoded);
    } catch (e) {
      print('[GroupOrderApi] joinGroupMembers error: $e');
      return null;
    }
  }
}
