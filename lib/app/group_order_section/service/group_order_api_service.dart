import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/group_order_action_response.dart';
import 'package:jippymart_customer/models/group_order_checkout_model.dart';
import 'package:jippymart_customer/models/group_order_invitation_model.dart';
import 'package:jippymart_customer/models/group_order_join_response.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

import '../../../constant/show_toast_dialog.dart';

class GroupOrderApiService {
  GroupOrderApiService._();

  static Future<GroupOrderInvitationModel?> getGroupOrderInvitation({
    required int hostCustomerId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/group-orders/getGroupOrderInvitation',
      ).replace(queryParameters: {'hostCustomerId': hostCustomerId.toString()});

      debugPrint('[GroupOrderApi] GET $uri');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint('[GroupOrderApi] status: ${response.statusCode}');
      debugPrint('[GroupOrderApi] response: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);

          throw Exception(
            error['errorMessage'] ?? error['message'] ?? 'Something went wrong',
          );
        } catch (_) {
          throw Exception('Something went wrong');
        }
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response');
      }

      final data = decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'])
          : decoded;

      return GroupOrderInvitationModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<GroupOrderInvitationModel?> createGroupOrderInvitation({
    required int hostCustomerId,
    required int outletId,
    required int orderCloseDurationInMinutes,
    required String paymentResponsibility,
    required int maxMembers,
    required String orderType,
    required int createdBy,
  }) async {
    final uri = Uri.parse(
      '${AppConst.outletBaseUrl}co/group-orders/createGroupOrderInvitation',
    );

    final body = {
      "hostCustomerId": hostCustomerId,
      "outletId": outletId,
      "orderCloseDurationInMinutes": orderCloseDurationInMinutes,
      "paymentResponsibility": paymentResponsibility,
      "maxMembers": maxMembers,
      "orderType": orderType,
      "createdBy": createdBy,
    };

    debugPrint("POST : $uri");
    debugPrint("BODY : ${jsonEncode(body)}");

    final response = await http.post(
      uri,
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    debugPrint("STATUS : ${response.statusCode}");
    debugPrint("BODY : ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = "Something went wrong";

      try {
        final error = jsonDecode(response.body);

        if (error is Map<String, dynamic>) {
          message =
              error["errorMessage"] ??
              error["message"] ??
              error["error"] ??
              message;
        }
      } catch (_) {
        // Keep default message if response is not valid JSON
      }

      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);

    debugPrint("DECODED TYPE : ${decoded.runtimeType}");

    if (decoded is Map<String, dynamic>) {
      if (decoded["data"] != null) {
        debugPrint("Parsing data object...");
        return GroupOrderInvitationModel.fromJson(
          Map<String, dynamic>.from(decoded["data"]),
        );
      }

      debugPrint("Parsing root object...");
      return GroupOrderInvitationModel.fromJson(decoded);
    }

    throw Exception("Unexpected response format");
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

  static Future<GroupOrderActionResponse?> addItemsToGroupCart({
    required int groupOrderInvitationId,
    required int customerId,
    required int productId,
    required int quantity,
    required double merchantUnitPrice,
    required double onlineUnitPrice,
    required int createdBy,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/group-orders/addItemsToGroupCart',
      );

      final body = {
        'groupOrderInvitationId': groupOrderInvitationId,
        'customerId': customerId,
        'productId': productId,
        'quantity': quantity,
        'merchantUnitPrice': merchantUnitPrice,
        'onlineUnitPrice': onlineUnitPrice,
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

      return GroupOrderActionResponse.fromJson(decoded);
    } catch (e) {
      print('[GroupOrderApi] addItemsToGroupCart error: $e');
      return null;
    }
  }

  static Future<GroupOrderCheckoutModel?> groupOrderCheckOut({
    required int groupOrdersInvitationId,
    required int hostCustomerId,
  }) async {
    try {
      final uri =
          Uri.parse(
            '${AppConst.outletBaseUrl}co/group-orders/groupOrderCheckOut',
          ).replace(
            queryParameters: {
              'groupOrdersInvitationId': groupOrdersInvitationId.toString(),
              'hostCustomerId': hostCustomerId.toString(),
            },
          );

      print('[GroupOrderApi] GET $uri');

      final response = await http
          .post(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      print('[GroupOrderApi] status: ${response.statusCode}');
      print('[GroupOrderApi] response: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final data = decoded.containsKey('data') && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded;

      return GroupOrderCheckoutModel.fromJson(data);
    } catch (e) {
      print('[GroupOrderApi] groupOrderCheckOut error: $e');
      return null;
    }
  }

  static Map<String, int> quantitiesFromCheckout(
    GroupOrderCheckoutModel? model,
  ) {
    final quantities = <String, int>{};
    if (model == null) return quantities;

    for (final delivery in model.deliveryCheckOutItems) {
      for (final member in delivery.groupOrderCheckoutItems) {
        for (final product in member.products) {
          final key = product.productId.toString();
          quantities[key] = (quantities[key] ?? 0) + product.quantity;
        }
      }
    }
    return quantities;
  }
}
