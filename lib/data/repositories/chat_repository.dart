import 'dart:convert';
import 'dart:io';

import 'package:jippymart_customer/utils/safe_http_client.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class ChatRepository {
  const ChatRepository();

  Future<Map<String, dynamic>> getChatMessages({
    required String orderId,
    required String chatType,
    required int page,
  }) async {
    try {
      final response = await SafeHttpClient.safeGet(
        Uri.parse(
          '${AppConst.baseUrl}chat/$orderId/messages?chat_type=$chatType&page=$page',
        ),
        headers: await getHeaders(),
        timeout: const Duration(seconds: 15),
      );

      if (response == null) {
        throw SocketException('No internet connection');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load messages');
      }
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }
}
